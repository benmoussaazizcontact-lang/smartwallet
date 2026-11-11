import { createClient } from "npm:@supabase/supabase-js@2";

const maxBodyBytes = 24_000;
const maxTextLength = 4_000;
const maxMerchantLength = 160;
const maxCategories = 80;
const maxNameLength = 80;
const windowMs = 60_000;
const maxRequestsPerWindow = 12;

const recentCalls = new Map<string, number[]>();

type CategoryPayload = {
  id?: unknown;
  name?: unknown;
  parentName?: unknown;
};

function json(body: Record<string, unknown>, status = 200): Response {
  return Response.json(body, { status });
}

function tooMany(userId: string): boolean {
  const now = Date.now();
  const recent = (recentCalls.get(userId) ?? []).filter((at) => now - at < windowMs);
  if (recent.length >= maxRequestsPerWindow) {
    recentCalls.set(userId, recent);
    return true;
  }
  recent.push(now);
  recentCalls.set(userId, recent);
  return false;
}

function asLimitedString(value: unknown, max: number): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (trimmed.length === 0 || trimmed.length > max) return null;
  return trimmed;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204 });
  if (req.method !== "POST") {
    return json({ available: false, reason: "Method not allowed." }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const authorization = req.headers.get("Authorization");
  if (!supabaseUrl || !anonKey || !authorization?.startsWith("Bearer ")) {
    return json({ available: false, reason: "Authentication required." }, 401);
  }
  const accessToken = authorization.slice("Bearer ".length).trim();
  if (accessToken.length < 20) {
    return json({ available: false, reason: "Authentication required." }, 401);
  }

  const caller = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: authorization } },
  });
  const { data: userData, error: userError } = await caller.auth.getUser(accessToken);
  if (userError || !userData.user) {
    return json({ available: false, reason: "Authentication required." }, 401);
  }

  const declaredLength = Number(req.headers.get("content-length") ?? "0");
  if (Number.isFinite(declaredLength) && declaredLength > maxBodyBytes) {
    return json({ available: false, reason: "Request is too large." }, 413);
  }

  const raw = await req.text();
  if (raw.length > maxBodyBytes) {
    return json({ available: false, reason: "Request is too large." }, 413);
  }

  if (tooMany(userData.user.id)) {
    return json(
      { available: false, reason: "Too many classification requests. Try again shortly." },
      429,
    );
  }

  let body: {
    text?: unknown;
    merchant?: unknown;
    amount?: unknown;
    categories?: unknown;
  };
  try {
    const parsed = JSON.parse(raw);
    if (parsed == null || typeof parsed !== "object" || Array.isArray(parsed)) {
      return json({ available: false, reason: "Invalid JSON body." }, 400);
    }
    body = parsed;
  } catch {
    return json({ available: false, reason: "Invalid JSON body." }, 400);
  }

  const text = asLimitedString(body.text, maxTextLength) ?? "";
  const merchant = asLimitedString(body.merchant, maxMerchantLength) ?? "";
  if (text.length === 0 && merchant.length === 0) {
    return json({ available: false, reason: "Text or merchant is required." }, 400);
  }
  const amount = typeof body.amount === "number" && Number.isFinite(body.amount)
    ? body.amount
    : null;
  if (!Array.isArray(body.categories) || body.categories.length === 0) {
    return json({ available: false, reason: "No categories were provided to the model." }, 400);
  }
  if (body.categories.length > maxCategories) {
    return json({ available: false, reason: "Too many categories." }, 400);
  }

  const categories = [];
  for (const entry of body.categories as CategoryPayload[]) {
    const id = asLimitedString(entry?.id, 80);
    const name = asLimitedString(entry?.name, maxNameLength);
    if (!id || !name) {
      return json({ available: false, reason: "A category is missing an id or name." }, 400);
    }
    const parentName = asLimitedString(entry?.parentName, maxNameLength);
    categories.push({ id, name, parentName });
  }

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    return json({
      available: false,
      reason: "Advanced AI classification is not configured.",
    });
  }

  const catalog = categories
    .map((category) =>
      `${category.id} | ${category.parentName ? `${category.parentName} / ` : ""}${category.name}`
    )
    .join("\n");
  const prompt =
    `Classify this personal-finance transaction into exactly one category id from the catalog.\n` +
    `Merchant: ${merchant}\nText: ${text}\nAmount: ${amount ?? ""}\n\nCatalog:\n${catalog}\n\n` +
    `Return JSON {"category_id":"<id or null>","confidence":<0-1 or null>,"reason":"<short>"}. ` +
    `If unsure, category_id must be null. If you cannot measure confidence, confidence must be null. Never invent an id.`;

  let response: Response;
  try {
    response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        temperature: 0,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content:
              "You classify expenses into an existing category catalog. Never invent categories or confidence.",
          },
          { role: "user", content: prompt },
        ],
      }),
    });
  } catch {
    return json({ available: false, reason: "Advanced AI classification is unavailable." });
  }

  if (!response.ok) {
    return json({
      available: false,
      reason: "Advanced AI classification is unavailable.",
    });
  }

  let payload: { choices?: Array<{ message?: { content?: string } }> };
  try {
    payload = await response.json();
  } catch {
    return json({ available: false, reason: "The AI model returned unreadable JSON." });
  }

  let parsed: { category_id?: unknown; confidence?: unknown; reason?: unknown } = {};
  try {
    parsed = JSON.parse(payload.choices?.[0]?.message?.content ?? "");
  } catch {
    return json({ available: false, reason: "The AI model returned unreadable JSON." });
  }

  const allowed = new Set(categories.map((category) => category.id));
  const categoryId = typeof parsed.category_id === "string" && allowed.has(parsed.category_id)
    ? parsed.category_id
    : null;
  const confidence = typeof parsed.confidence === "number" && Number.isFinite(parsed.confidence)
    ? Math.min(1, Math.max(0, parsed.confidence))
    : null;

  return json({
    available: true,
    category_id: categoryId,
    confidence,
    reason: typeof parsed.reason === "string" ? parsed.reason.slice(0, 240) : "edge-ai",
    model_name: "gpt-4o-mini",
  });
});
