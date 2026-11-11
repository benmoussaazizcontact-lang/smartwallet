import { createClient } from "npm:@supabase/supabase-js@2";

const maxRows = 2000;

function json(body: Record<string, unknown>, status = 200): Response {
  return Response.json(body, { status });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ status: "statistical_baseline", executed: false }, 405);
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const authorization = req.headers.get("Authorization") ?? "";
  if (!supabaseUrl || !anonKey || !authorization.startsWith("Bearer ")) {
    return json({ status: "statistical_baseline", reason: "authentication_required", executed: false }, 401);
  }
  const accessToken = authorization.slice("Bearer ".length).trim();
  const caller = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: authorization } },
  });
  const { data: userData, error: userError } = await caller.auth.getUser(accessToken);
  if (userError || !userData.user) {
    return json({ status: "statistical_baseline", reason: "authentication_required", executed: false }, 401);
  }
  const userId = userData.user.id;
  const { data, error } = await caller
    .from("transactions")
    .select("transaction_type, amount, currency, status, transaction_date, merchant, categories(name)")
    .eq("user_id", userId)
    .limit(maxRows);
  if (error) return json({ status: "statistical_baseline", reason: "read_failed", executed: false }, 403);

  const transactions = (data ?? [])
    .filter((row) => row.status !== "VOIDED")
    .map((row) => ({
      date: String(row.transaction_date ?? "").slice(0, 10),
      type: String(row.transaction_type ?? "EXPENSE"),
      amount: Number(row.amount ?? 0),
      merchant: String(row.merchant ?? ""),
      category: String((row.categories as { name?: string } | null)?.name ?? "other").toLowerCase(),
      recurring: false,
    }));

  let task = "expense";
  try {
    const body = await req.json();
    if (body && ["expense", "overrun", "anomaly", "cashflow"].includes(body.task)) task = body.task;
  } catch {
    task = "expense";
  }

  const mlUrl = Deno.env.get("SMARTWALLET_ML_URL")?.trim() ?? "";
  if (!mlUrl.startsWith("https://")) {
    console.log(`smartwallet-ml fallback=awaiting_deployment user=${userId.slice(0, 8)}`);
    return json({
      status: "awaiting_deployment",
      fallback: "statistical_baseline",
      real_world_validated: false,
      row_count: transactions.length,
      executed: false,
      blocks_transaction: false,
    });
  }

  let budgets: Array<{ category: string; limit: number }> = [];
  if (task === "overrun") {
    const { data: budgetRows } = await caller
      .from("budgets")
      .select("name, limit_amount, currency, archived")
      .eq("user_id", userId)
      .eq("archived", false);
    budgets = ((budgetRows ?? []) as Array<Record<string, unknown>>).map((row) => ({
      category: String(row.name ?? "other").toLowerCase(),
      limit: Number(row.limit_amount ?? 0),
    }));
  }

  try {
    const response = await fetch(`${mlUrl.replace(/\/$/, "")}/v1/score`, {
      method: "POST",
      headers: { Authorization: authorization, "Content-Type": "application/json" },
      body: JSON.stringify({ user_id: userId, task, transactions, budgets }),
      signal: AbortSignal.timeout(20000),
    });
    if (!response.ok) {
      console.log(`smartwallet-ml fallback=model_service_unavailable status=${response.status}`);
      return json({ status: "statistical_baseline", reason: "model_service_unavailable", executed: false, real_world_validated: false });
    }
    const scored = await response.json();
    if (!scored || scored.user_id !== userId || scored.executed === true || scored.blocks_transaction === true) {
      return json({ status: "statistical_baseline", reason: "rejected_model_response", executed: false, real_world_validated: false });
    }
    console.log(`smartwallet-ml user=${userId.slice(0, 8)} task=${task} status=${scored.status}`);
    return json({ ...scored, real_world_validated: false, executed: false, blocks_transaction: false });
  } catch (error) {
    console.log(`smartwallet-ml fallback=model_service_unavailable error=${error instanceof Error ? error.name : "Error"}`);
    return json({ status: "statistical_baseline", reason: "model_service_unavailable", executed: false, real_world_validated: false });
  }
});
