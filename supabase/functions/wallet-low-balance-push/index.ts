import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { GoogleAuth } from "npm:google-auth-library@9";

type WebhookRow = Record<string, unknown> | null;
type DatabaseWebhook = {
  type?: string;
  schema?: string;
  table?: string;
  record?: WebhookRow;
  old_record?: WebhookRow;
};

const threshold = 100;

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") {
    return Response.json({ error: "Method not allowed" }, { status: 405 });
  }

  const webhookSecret = Deno.env.get("WALLET_PUSH_WEBHOOK_SECRET");
  if (!webhookSecret || request.headers.get("x-wallet-webhook-secret") !== webhookSecret) {
    return Response.json({ error: "Unauthorized" }, { status: 401 });
  }

  let payload: DatabaseWebhook;
  try {
    payload = await request.json();
  } catch {
    return Response.json({ error: "Invalid JSON" }, { status: 400 });
  }

  if (payload.schema !== "public" ||
      !["wallets", "wallet_movements", "push_tokens"].includes(payload.table ?? "")) {
    return Response.json({ error: "Unsupported database event" }, { status: 400 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const serviceAccountJson = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (!supabaseUrl || !serviceKey || !serviceAccountJson) {
    console.error("Low-balance push is missing server configuration.");
    return Response.json({ error: "Push service is not configured" }, { status: 503 });
  }

  let serviceAccount: {
    project_id?: string;
    client_email?: string;
    private_key?: string;
  };
  try {
    serviceAccount = JSON.parse(serviceAccountJson);
  } catch {
    console.error("FCM service-account JSON is invalid.");
    return Response.json({ error: "Push service is not configured" }, { status: 503 });
  }

  const projectId = serviceAccount.project_id;
  if (!projectId || !serviceAccount.client_email || !serviceAccount.private_key) {
    console.error("FCM service-account fields are incomplete.");
    return Response.json({ error: "Push service is not configured" }, { status: 503 });
  }

  const row = payload.record ?? payload.old_record;
  const walletId = payload.table === "wallets" ? row?.id : row?.wallet_id;
  if (payload.table !== "push_tokens" && typeof walletId !== "string") {
    return Response.json({ error: "Wallet id is missing" }, { status: 400 });
  }

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  try {
    let userId: string | null = null;
    if (payload.table === "push_tokens") {
      userId = typeof row?.user_id === "string" ? row.user_id : null;
    } else {
      const { data: wallet, error: walletError } = await admin
        .from("wallet_balances")
        .select("user_id")
        .eq("wallet_id", walletId as string)
        .maybeSingle();
      if (walletError) throw walletError;
      userId = typeof wallet?.user_id === "string" ? wallet.user_id : null;
    }
    if (userId == null) return Response.json({ skipped: "User is unavailable" });

    const { data: balances, error: balancesError } = await admin
      .from("wallet_balances")
      .select("currency,current_balance,is_archived,crypto_symbol")
      .eq("user_id", userId)
      .eq("is_archived", false)
      .is("crypto_symbol", null);
    if (balancesError) throw balancesError;

    const totals = new Map<string, number>();
    for (const balance of balances ?? []) {
      const currency = balance.currency;
      const amount = Number(balance.current_balance);
      if (typeof currency === "string" && Number.isFinite(amount)) {
        totals.set(currency, (totals.get(currency) ?? 0) + amount);
      }
    }

    const { data: tokens, error: tokensError } = await admin
      .from("push_tokens")
      .select("token")
      .eq("user_id", userId);
    if (tokensError) throw tokensError;

    const tokenList = (tokens ?? [])
      .map((entry) => entry.token)
      .filter((token): token is string => typeof token === "string" && token.length > 0);

    const auth = new GoogleAuth({
      credentials: serviceAccount,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const accessToken = await auth.getAccessToken();
    if (!accessToken) throw new Error("Could not acquire FCM access token");

    let sentCount = 0;
    let sendFailed = false;
    for (const [currency, balance] of totals) {
      const belowThreshold = balance < threshold;
      if (belowThreshold && tokenList.length === 0) continue;
      const { data: shouldSend, error: claimError } = await admin.rpc(
        "claim_low_balance_alert",
        {
          p_user_id: userId,
          p_currency: currency,
          p_is_below_threshold: belowThreshold,
        },
      );
      if (claimError) throw claimError;
      if (!belowThreshold || shouldSend !== true) continue;

      for (const token of tokenList) {
        let response: Response;
        try {
          response = await fetch(
            `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
            {
              method: "POST",
              headers: {
                Authorization: `Bearer ${accessToken}`,
                "Content-Type": "application/json; charset=UTF-8",
              },
              body: JSON.stringify({
                message: {
                  token,
                  notification: {
                    title: "Solde faible — Wallet",
                    body: `Le solde total de vos portefeuilles en ${currency} est passé sous 100.`,
                  },
                  data: { type: "low_balance", currency },
                  android: { priority: "high" },
                  apns: { headers: { "apns-priority": "10" } },
                },
              }),
            },
          );
        } catch {
          console.error("FCM delivery failed because the provider is unreachable.");
          sendFailed = true;
          continue;
        }

        if (response.ok) {
          sentCount++;
          continue;
        }

        const responseText = await response.text();
        if (responseText.includes("UNREGISTERED") || responseText.includes("registration-token-not-registered")) {
          await admin.from("push_tokens").delete().eq("token", token);
        } else {
          // Do not log tokens or credential material.
          console.error(`FCM delivery failed with HTTP ${response.status}.`);
          sendFailed = true;
        }
      }

      if (sendFailed) {
        await admin.rpc("claim_low_balance_alert", {
          p_user_id: userId,
          p_currency: currency,
          p_is_below_threshold: false,
        });
      }
    }

    return Response.json({ sent: sentCount });
  } catch (error) {
    // Keep server logs useful without exposing tokens, balances or credentials.
    console.error("Low-balance notification processing failed:", error instanceof Error ? error.message : "unknown error");
    return Response.json({ error: "Could not process low-balance notification" }, { status: 500 });
  }
});
