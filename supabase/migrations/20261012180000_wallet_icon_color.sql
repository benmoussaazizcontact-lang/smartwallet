-- Additive: wallet presentation fields. Does not drop data or change balances.

ALTER TABLE public.wallets
  ADD COLUMN IF NOT EXISTS icon varchar(64),
  ADD COLUMN IF NOT EXISTS color varchar(16);

DROP VIEW IF EXISTS public.wallet_balances;
CREATE VIEW public.wallet_balances
WITH (security_invoker = true) AS
SELECT
  w.id AS wallet_id,
  w.user_id,
  w.name,
  w.wallet_type,
  w.currency,
  w.initial_balance,
  w.initial_balance + COALESCE((
    SELECT SUM(m.amount) FROM public.wallet_movements m WHERE m.wallet_id = w.id
  ), 0) AS current_balance,
  w.credit_limit,
  CASE
    WHEN w.wallet_type = 'CREDIT_CARD'
      THEN GREATEST(0, -(w.initial_balance + COALESCE((
        SELECT SUM(m.amount) FROM public.wallet_movements m WHERE m.wallet_id = w.id
      ), 0)))
    ELSE 0
  END AS debt,
  CASE
    WHEN w.wallet_type = 'CREDIT_CARD'
      THEN w.credit_limit + (w.initial_balance + COALESCE((
        SELECT SUM(m.amount) FROM public.wallet_movements m WHERE m.wallet_id = w.id
      ), 0))
    ELSE NULL
  END AS available_credit,
  w.crypto_symbol,
  w.icon,
  w.color,
  w.is_archived,
  w.created_at
FROM public.wallets w;

GRANT SELECT ON public.wallet_balances TO authenticated;
REVOKE ALL ON public.wallet_balances FROM anon;
