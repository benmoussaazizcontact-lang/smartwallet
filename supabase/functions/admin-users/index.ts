import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return Response.json(body, { status, headers: corsHeaders });
}

async function audit(
  client: SupabaseClient,
  actorId: string,
  targetId: string,
  action: string,
  metadata: Record<string, unknown> = {},
) {
  const { error } = await client.from("admin_audit_log").insert({
    actor_id: actorId,
    target_user_id: targetId,
    action,
    metadata,
  });
  if (error) console.error("admin audit insert failed", error.message);
}

async function removeUserStorage(client: SupabaseClient, userId: string) {
  for (const bucket of ["avatars", "receipts"]) {
    const storage = client.storage.from(bucket);
    const paths: string[] = [];

    async function collect(prefix: string, depth = 0): Promise<void> {
      if (depth > 8) throw new Error("Storage folder nesting limit exceeded");
      let offset = 0;
      while (true) {
        const { data, error } = await storage.list(prefix, { limit: 100, offset });
        if (error) throw error;
        if (!data || data.length === 0) break;
        for (const item of data) {
          const path = `${prefix}/${item.name}`;
          if (item.id == null) await collect(path, depth + 1);
          else paths.push(path);
        }
        offset += data.length;
      }
    }

    await collect(userId);
    for (let i = 0; i < paths.length; i += 100) {
      const { error } = await storage.remove(paths.slice(i, i + 100));
      if (error) throw error;
    }
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const bearer = req.headers.get("Authorization");
  if (!url || !anonKey || !serviceKey || !bearer?.startsWith("Bearer ")) {
    return json({ error: "Function configuration or authorization is missing." }, 401);
  }

  const callerClient = createClient(url, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: bearer } },
  });
  const accessToken = bearer.slice("Bearer ".length);
  const { data: callerData, error: callerError } = await callerClient.auth.getUser(accessToken);
  if (callerError || !callerData.user) return json({ error: "Session invalid." }, 401);
  if (callerData.user.banned_until && new Date(callerData.user.banned_until) > new Date()) {
    return json({ error: "This administrator account is suspended." }, 403);
  }
  if (callerData.user.app_metadata?.role !== "admin") {
    return json({ error: "Administrator role required." }, 403);
  }

  const service = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  let body: {
    action?: string;
    user_id?: string;
    role?: string;
    confirm_email?: string;
    reason?: string;
    duration_days?: number;
  };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body." }, 400);
  }
  const action = body.action;
  const targetId = body.user_id;
  if (!targetId || !/^[0-9a-f-]{36}$/i.test(targetId)) {
    return json({ error: "A valid user_id is required." }, 400);
  }
  if (targetId === callerData.user.id) {
    return json({ error: "You cannot change or delete your own administrator account here." }, 400);
  }

  const { data: targetData, error: targetError } = await service.auth.admin.getUserById(targetId);
  const target = targetData.user;
  if (targetError || !target) return json({ error: "User not found." }, 404);

  try {
    if (action === "set_role") {
      if (body.role !== "user" && body.role !== "admin") {
        return json({ error: "Role must be user or admin." }, 400);
      }
      if (target.app_metadata?.role === "admin" && body.role === "user") {
        let adminCount = 0;
        for (let page = 1; page <= 100; page++) {
          const { data, error } = await service.auth.admin.listUsers({ page, perPage: 1000 });
          if (error) throw error;
          adminCount += data.users.filter((u) => u.app_metadata?.role === "admin").length;
          if (data.users.length < 1000) break;
        }
        if (adminCount <= 1) {
          return json({ error: "At least one administrator must remain." }, 409);
        }
      }
      const nextMetadata = { ...target.app_metadata, role: body.role };
      const { error } = await service.auth.admin.updateUserById(targetId, {
        app_metadata: nextMetadata,
      });
      if (error) throw error;
      await audit(service, callerData.user.id, targetId, "user_role_changed", { role: body.role });
      return json({ success: true });
    }

    if (action === "suspend" || action === "reactivate") {
      if (target.app_metadata?.role === "admin") {
        return json({ error: "Administrator accounts cannot be suspended here." }, 409);
      }
      let update: Record<string, unknown>;
      let auditMetadata: Record<string, unknown> = {};
      if (action === "suspend") {
        const reason = body.reason?.trim();
        const durationDays = body.duration_days;
        if (!reason || reason.length < 3 || reason.length > 500) {
          return json({ error: "A suspension reason between 3 and 500 characters is required." }, 400);
        }
        if (typeof durationDays !== "number" || ![1, 7, 30, 90].includes(durationDays)) {
          return json({ error: "Suspension duration must be 1, 7, 30, or 90 days." }, 400);
        }
        const until = new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000);
        update = {
          ban_duration: `${durationDays * 24}h`,
          app_metadata: {
            ...target.app_metadata,
            admin_suspension_reason: reason,
            admin_suspension_until: until.toISOString(),
          },
        };
        auditMetadata = { reason, duration_days: durationDays, suspended_until: until.toISOString() };
      } else {
        const nextMetadata = { ...target.app_metadata };
        delete nextMetadata.admin_suspension_reason;
        delete nextMetadata.admin_suspension_until;
        update = { ban_duration: "none", app_metadata: nextMetadata };
      }
      const { error } = await service.auth.admin.updateUserById(targetId, update);
      if (error) throw error;
      await audit(
        service,
        callerData.user.id,
        targetId,
        action === "suspend" ? "user_suspended" : "user_reactivated",
        auditMetadata,
      );
      return json({ success: true });
    }

    if (action === "delete") {
      if (!target.email || body.confirm_email?.toLowerCase() !== target.email.toLowerCase()) {
        return json({ error: "Exact account email confirmation is required." }, 400);
      }
      if (target.app_metadata?.role === "admin") {
        return json({ error: "Administrator accounts cannot be deleted here." }, 409);
      }
      // Supabase Auth refuses deleting an identity that owns Storage objects.
      // Remove private per-user files first, then Auth cascades database rows.
      await removeUserStorage(service, targetId);
      const { error } = await service.auth.admin.deleteUser(targetId);
      if (error) throw error;
      await audit(service, callerData.user.id, targetId, "user_deleted", {
        retention: "auth and cascading user-owned database rows deleted; audit retained",
      });
      return json({ success: true });
    }
    return json({ error: "Unsupported action." }, 400);
  } catch (error) {
    console.error(
      "admin-users action failed",
      action ?? "unknown",
      error instanceof Error ? error.name : "unknown error",
    );
    await audit(service, callerData.user.id, targetId, "admin_action_failed", {
      action: action ?? "unknown",
      error_type: error instanceof Error ? error.name : "unknown",
    });
    return json({ error: "The requested account action failed. Check server logs." }, 500);
  }
});
