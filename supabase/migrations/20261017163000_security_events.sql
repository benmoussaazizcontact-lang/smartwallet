-- Journal des événements de sécurité (connexion, MFA, biométrie, etc.)

CREATE TABLE IF NOT EXISTS public.security_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  event_type text NOT NULL,
  success boolean NOT NULL DEFAULT true,
  risk_score integer NOT NULL DEFAULT 0 CHECK (risk_score >= 0 AND risk_score <= 100),
  ip_address text,
  user_agent text,
  location text,
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS security_events_user_created_idx
  ON public.security_events (user_id, created_at DESC);

ALTER TABLE public.security_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS security_events_select_own ON public.security_events;
CREATE POLICY security_events_select_own
  ON public.security_events
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS security_events_insert_own ON public.security_events;
CREATE POLICY security_events_insert_own
  ON public.security_events
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

GRANT SELECT, INSERT ON public.security_events TO authenticated;
