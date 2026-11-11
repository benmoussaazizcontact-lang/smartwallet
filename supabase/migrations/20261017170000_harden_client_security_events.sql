-- These rows are client-reported Wallet activity, not Supabase Auth audit logs.
-- A mobile client must never be allowed to claim server-observed IP/location.
ALTER TABLE public.security_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS security_events_insert_own ON public.security_events;
CREATE POLICY security_events_insert_own
  ON public.security_events
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = (SELECT auth.uid())
    AND event_type = ANY (ARRAY[
      'sign_in', 'sign_up', 'sign_out', 'mfa_verify', 'mfa_enroll',
      'mfa_disable', 'biometric', 'password_reset', 'password_change',
      'profile_update'
    ])
    AND ip_address IS NULL
    AND user_agent IS NULL
    AND location IS NULL
  );

DROP POLICY IF EXISTS security_events_select_own ON public.security_events;
CREATE POLICY security_events_select_own
  ON public.security_events
  FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

REVOKE UPDATE, DELETE ON public.security_events FROM authenticated;
REVOKE INSERT ON public.security_events FROM authenticated;
-- Let Postgres supply the event ID, timestamp and risk_score default; the
-- authenticated client can only report its own event and non-sensitive context.
GRANT SELECT ON public.security_events TO authenticated;
GRANT INSERT (user_id, event_type, success, metadata)
  ON public.security_events TO authenticated;
