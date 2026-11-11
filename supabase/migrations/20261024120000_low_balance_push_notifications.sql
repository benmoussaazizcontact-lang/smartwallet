-- FCM registration and a server-only transition guard for low balance alerts.
-- The threshold is 100 units per currency (currencies are never mixed).

BEGIN;

CREATE TABLE IF NOT EXISTS public.push_tokens (
  token text PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  platform text NOT NULL CHECK (platform IN ('android', 'iOS')),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS push_tokens_user_id_idx
  ON public.push_tokens (user_id);

ALTER TABLE public.push_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own push tokens" ON public.push_tokens;
CREATE POLICY "Users read own push tokens"
  ON public.push_tokens FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users register own push tokens" ON public.push_tokens;
CREATE POLICY "Users register own push tokens"
  ON public.push_tokens FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users update own push tokens" ON public.push_tokens;
CREATE POLICY "Users update own push tokens"
  ON public.push_tokens FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users delete own push tokens" ON public.push_tokens;
CREATE POLICY "Users delete own push tokens"
  ON public.push_tokens FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.push_tokens TO authenticated;
REVOKE ALL ON public.push_tokens FROM anon;

-- Internal transition state stops a new notification on every transaction.
CREATE TABLE IF NOT EXISTS public.low_balance_alert_state (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  currency text NOT NULL,
  is_below_threshold boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, currency)
);

ALTER TABLE public.low_balance_alert_state ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.low_balance_alert_state FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.low_balance_alert_state TO service_role;

CREATE OR REPLACE FUNCTION public.claim_low_balance_alert(
  p_user_id uuid,
  p_currency text,
  p_is_below_threshold boolean
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_claimed boolean := false;
BEGIN
  IF p_user_id IS NULL OR p_currency IS NULL OR btrim(p_currency) = '' THEN
    RAISE EXCEPTION 'User and currency are required';
  END IF;

  IF p_is_below_threshold THEN
    INSERT INTO public.low_balance_alert_state AS current_state (
      user_id, currency, is_below_threshold, updated_at
    ) VALUES (p_user_id, p_currency, true, now())
    ON CONFLICT (user_id, currency) DO UPDATE
      SET is_below_threshold = true, updated_at = now()
      WHERE current_state.is_below_threshold = false
    RETURNING true INTO v_claimed;
    RETURN COALESCE(v_claimed, false);
  END IF;

  INSERT INTO public.low_balance_alert_state (
    user_id, currency, is_below_threshold, updated_at
  ) VALUES (p_user_id, p_currency, false, now())
  ON CONFLICT (user_id, currency) DO UPDATE
    SET is_below_threshold = false, updated_at = now();
  RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION public.claim_low_balance_alert(uuid, text, boolean)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.claim_low_balance_alert(uuid, text, boolean)
  TO service_role;

COMMIT;
