import { createClient } from "npm:@supabase/supabase-js@2";

const maxBodyBytes = 12_000;
const windowMs = 60_000;
const maxRequests = 10;
const recent = new Map<string, number[]>();

function json(body: Record<string, unknown>, status = 200): Response {
  return Response.json(body, { status });
}

function limited(userId: string): boolean {
  const now = Date.now();
  const hits = (recent.get(userId) ?? []).filter((at) => now - at < windowMs);
  if (hits.length >= maxRequests) {
    recent.set(userId, hits);
    return true;
  }
  hits.push(now);
  recent.set(userId, hits);
  return false;
}

function monthSpend(rows: Array<Record<string, unknown>>, currency: string): number {
  const now = new Date();
  const start = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1);
  const end = Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1);
  let total = 0;
  for (const row of rows) {
    const type = String(row.transaction_type ?? "");
    const status = String(row.status ?? "POSTED");
    if (status === "VOIDED") continue;
    if (type !== "EXPENSE" && type !== "PAYMENT") continue;
    if (String(row.currency ?? "") !== currency) continue;
    const date = Date.parse(String(row.transaction_date ?? ""));
    if (!Number.isFinite(date) || date < start || date >= end) continue;
    total += Number(row.amount ?? 0);
  }
  return Math.round(total * 1000) / 1000;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ available: false, reason: "Method not allowed." }, 405);
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const authorization = req.headers.get("Authorization") ?? "";
  if (!supabaseUrl || !anonKey || !authorization.startsWith("Bearer ")) {
    return json({ available: false, reason: "Authentication required." }, 401);
  }
  const accessToken = authorization.slice("Bearer ".length).trim();
  const caller = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: authorization } },
  });
  const { data: userData, error: userError } = await caller.auth.getUser(accessToken);
  if (userError || !userData.user) {
    return json({ available: false, reason: "Authentication required." }, 401);
  }
  if (limited(userData.user.id)) {
    return json({ available: false, reason: "Too many requests." }, 429);
  }
  const raw = await req.text();
  if (raw.length > maxBodyBytes) return json({ available: false, reason: "Request is too large." }, 413);
  let body: { currency?: unknown; language?: unknown } = {};
  try {
    body = JSON.parse(raw);
  } catch {
    return json({ available: false, reason: "Invalid request." }, 400);
  }
  const currency = typeof body.currency === "string" && /^[A-Z]{3,10}$/.test(body.currency)
    ? body.currency
    : "TND";
  const language = body.language === "fr" || body.language === "ar" ? body.language : "en";

  const { data, error } = await caller
    .from("transactions")
    .select("transaction_type, amount, currency, status, transaction_date")
    .eq("user_id", userData.user.id)
    .limit(1000);
  if (error) return json({ available: false, reason: "Could not read transactions." }, 403);

  const spent = monthSpend((data ?? []) as Array<Record<string, unknown>>, currency);
  const spentText = spent.toFixed(3);
  const local = language === "fr"
    ? `Vous avez dépensé ${spentText} ${currency} ce mois-ci.`
    : language === "ar"
    ? `أنفقت ${spentText} ${currency} هذا الشهر.`
    : `You spent ${spentText} ${currency} this month.`;

  const openAiKey = Deno.env.get("OPENAI_API_KEY");
  const now = new Date();
  const monthStart = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1);
  const monthEnd = Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1);
  let monthIncome = 0;
  for (const row of (data ?? []) as Array<Record<string, unknown>>) {
    if (String(row.status ?? "") === "VOIDED" || String(row.transaction_type ?? "") !== "INCOME") continue;
    if (String(row.currency ?? "") !== currency) continue;
    const date = Date.parse(String(row.transaction_date ?? ""));
    if (!Number.isFinite(date) || date < monthStart || date >= monthEnd) continue;
    monthIncome += Number(row.amount ?? 0);
  }
  monthIncome = Math.round(monthIncome * 1000) / 1000;
  const budgetsResult = await caller.from("budgets").select("name, limit_amount, currency, archived").eq("user_id", userData.user.id).eq("archived", false);
  const budgetRows = budgetsResult.error ? [] : budgetsResult.data;
  const budgetLimits = ((budgetRows ?? []) as Array<Record<string, unknown>>)
    .filter((row) => String(row.currency ?? "") === currency)
    .map((row) => ({ name: String(row.name ?? ""), limit: Number(row.limit_amount ?? 0) }));
  const goalsResult = await caller.from("financial_goals").select("id, name, target_amount, currency, status").eq("user_id", userData.user.id).eq("status", "active");
  const contributionsResult = await caller.from("goal_contributions").select("goal_id, amount, currency").eq("user_id", userData.user.id);
  const goalRows = goalsResult.error ? [] : goalsResult.data;
  const contributionRows = contributionsResult.error ? [] : contributionsResult.data;
  const savedByGoal = new Map<string, number>();
  for (const row of (contributionRows ?? []) as Array<Record<string, unknown>>) {
    if (String(row.currency ?? "") !== currency) continue;
    const id = String(row.goal_id ?? "");
    savedByGoal.set(id, (savedByGoal.get(id) ?? 0) + Number(row.amount ?? 0));
  }
  const goals = ((goalRows ?? []) as Array<Record<string, unknown>>)
    .filter((row) => String(row.currency ?? "") === currency)
    .map((row) => {
      const target = Number(row.target_amount ?? 0);
      const saved = Math.round((savedByGoal.get(String(row.id ?? "")) ?? 0) * 1000) / 1000;
      return { name: String(row.name ?? ""), gap: Math.round((target - saved) * 1000) / 1000 };
    });
  const verified = {
    month_spend: spent,
    month_income: monthIncome,
    net: Math.round((monthIncome - spent) * 1000) / 1000,
    currency,
    budgets: budgetLimits,
    goals,
    tools: ["month_spend", "month_income", "budget_limits", "goal_gap", "simulation", "draft", "report"],
    simulation: { spend_cut_15: Math.round(spent * 0.15 * 1000) / 1000, remaining_if_income_halves: Math.round((monthIncome * 0.5 - spent) * 1000) / 1000 },
    draft: { requires_confirmation: true, executes: false },
  };
  if (!openAiKey) {
    return json({ available: false, fallback: true, spent, currency, text: local, verified, executed: false });
  }

  const model = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${openAiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      temperature: 0,
      messages: [
        {
          role: "system",
          content:
            "Explain only the verified total and the verified tool object. Do not add amounts, do not say a payment was executed, and do not give a trade instruction. Reply in the requested language. Include the exact total.",
        },
        {
          role: "user",
          content: `Language: ${language}. Verified month spending: ${spentText} ${currency}. Verified tools: ${JSON.stringify(verified)}.`,
        },
      ],
    }),
  });
  if (!model.ok) return json({ available: false, fallback: true, spent, currency, text: local, verified, executed: false });
  const payload = await model.json();
  const narrative = payload?.choices?.[0]?.message?.content;
  const text = typeof narrative === "string" && narrative.includes(spentText) && !/executed|garanti/i.test(narrative)
    ? narrative
    : local;
  return json({ available: true, spent, currency, text, verified, executed: false });
});
