-- Admin user management, support requests and admin audit trail.
-- Account privileges are checked against auth.jwt().app_metadata.role.
BEGIN;

-- The first dashboard migration installed this function with a smaller result
-- shape. Drop it before replacing its RETURNS TABLE declaration.
DROP FUNCTION IF EXISTS public.admin_user_overview();

CREATE TABLE IF NOT EXISTS public.support_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  request_type text NOT NULL DEFAULT 'question'
    CHECK (request_type IN ('question', 'account_deletion')),
  subject text NOT NULL CHECK (length(btrim(subject)) BETWEEN 3 AND 160),
  message text NOT NULL CHECK (length(btrim(message)) BETWEEN 5 AND 5000),
  status text NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
  admin_response text CHECK (admin_response IS NULL OR length(admin_response) <= 5000),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  handled_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS support_requests_owner_created_idx
  ON public.support_requests(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS support_requests_status_created_idx
  ON public.support_requests(status, created_at DESC);

ALTER TABLE public.support_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS support_requests_select_own ON public.support_requests;
CREATE POLICY support_requests_select_own ON public.support_requests
  FOR SELECT TO authenticated USING (user_id = (SELECT auth.uid()));
DROP POLICY IF EXISTS support_requests_insert_own ON public.support_requests;
CREATE POLICY support_requests_insert_own ON public.support_requests
  FOR INSERT TO authenticated WITH CHECK (user_id = (SELECT auth.uid()));
REVOKE ALL ON public.support_requests FROM anon, authenticated;
GRANT SELECT ON public.support_requests TO authenticated;
GRANT INSERT (user_id, request_type, subject, message)
  ON public.support_requests TO authenticated;

CREATE TABLE IF NOT EXISTS public.admin_audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  target_user_id uuid,
  action text NOT NULL CHECK (length(action) BETWEEN 1 AND 80),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS admin_audit_created_idx
  ON public.admin_audit_log(created_at DESC);
ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.admin_audit_log FROM PUBLIC, anon, authenticated;
GRANT INSERT ON public.admin_audit_log TO service_role;

-- Make a suspension effective for existing JWTs on database/storage requests,
-- not only on the next password sign-in. JWTs are stateless, so RLS checks the
-- current ban state in Auth for every request.
CREATE OR REPLACE FUNCTION app_private.is_current_user_active()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users u
    WHERE u.id = auth.uid()
      AND (u.banned_until IS NULL OR u.banned_until <= now())
  );
$$;
REVOKE ALL ON FUNCTION app_private.is_current_user_active() FROM PUBLIC, anon;
GRANT USAGE ON SCHEMA app_private TO authenticated;
GRANT EXECUTE ON FUNCTION app_private.is_current_user_active() TO authenticated;

DO $$
DECLARE v_table text;
BEGIN
  FOREACH v_table IN ARRAY ARRAY[
    'profiles', 'wallets', 'categories', 'transactions', 'transfers',
    'wallet_movements', 'tags', 'transaction_tags', 'recurring_transactions',
    'recurring_executions', 'receipts', 'ai_classifications',
    'classification_corrections', 'security_events', 'support_requests'
  ] LOOP
    IF to_regclass(format('public.%I', v_table)) IS NOT NULL THEN
      EXECUTE format('DROP POLICY IF EXISTS active_account_only ON public.%I', v_table);
      EXECUTE format(
        'CREATE POLICY active_account_only ON public.%I AS RESTRICTIVE FOR ALL TO authenticated USING (app_private.is_current_user_active()) WITH CHECK (app_private.is_current_user_active())',
        v_table
      );
    END IF;
  END LOOP;
END;
$$;

DROP POLICY IF EXISTS active_account_storage_only ON storage.objects;
CREATE POLICY active_account_storage_only ON storage.objects
  AS RESTRICTIVE FOR ALL TO authenticated
  USING (app_private.is_current_user_active())
  WITH CHECK (app_private.is_current_user_active());

CREATE OR REPLACE FUNCTION public.admin_user_overview()
RETURNS TABLE (
  total_accounts bigint,
  signups_last_30_days bigint,
  active_last_30_days bigint,
  suspended_accounts bigint,
  open_support_requests bigint
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  IF (auth.jwt() -> 'app_metadata' ->> 'role') IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'Administrator role required' USING ERRCODE = '42501';
  END IF;
  IF NOT app_private.is_current_user_active() THEN
    RAISE EXCEPTION 'Active administrator session required' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT
    count(*)::bigint,
    count(*) FILTER (WHERE u.created_at >= now() - interval '30 days')::bigint,
    count(*) FILTER (WHERE u.last_sign_in_at >= now() - interval '30 days')::bigint,
    count(*) FILTER (WHERE u.banned_until IS NOT NULL AND u.banned_until > now())::bigint,
    (SELECT count(*) FROM public.support_requests s WHERE s.status IN ('open', 'in_progress'))::bigint
  FROM auth.users u;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_search_users(
  p_query text DEFAULT NULL,
  p_created_from timestamptz DEFAULT NULL,
  p_created_to timestamptz DEFAULT NULL,
  p_page integer DEFAULT 0,
  p_page_size integer DEFAULT 30
)
RETURNS TABLE (
  id uuid,
  email text,
  first_name text,
  last_name text,
  created_at timestamptz,
  last_sign_in_at timestamptz,
  email_confirmed_at timestamptz,
  banned_until timestamptz,
  account_role text
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_query text := nullif(btrim(p_query), '');
BEGIN
  IF (auth.jwt() -> 'app_metadata' ->> 'role') IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'Administrator role required' USING ERRCODE = '42501';
  END IF;
  IF NOT app_private.is_current_user_active() THEN
    RAISE EXCEPTION 'Active administrator session required' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT u.id, u.email::text, p.first_name::text, p.last_name::text,
         u.created_at, u.last_sign_in_at, u.email_confirmed_at, u.banned_until,
         coalesce(u.raw_app_meta_data ->> 'role', 'user')
  FROM auth.users u
  LEFT JOIN public.profiles p ON p.id = u.id
  WHERE (v_query IS NULL OR
         u.email ILIKE '%' || v_query || '%' OR
         p.first_name ILIKE '%' || v_query || '%' OR
         p.last_name ILIKE '%' || v_query || '%' OR
         concat_ws(' ', p.first_name, p.last_name) ILIKE '%' || v_query || '%')
    AND (p_created_from IS NULL OR u.created_at >= p_created_from)
    AND (p_created_to IS NULL OR u.created_at < p_created_to)
  ORDER BY u.created_at DESC
  LIMIT greatest(1, least(coalesce(p_page_size, 30), 100))
  OFFSET greatest(0, coalesce(p_page, 0)) * greatest(1, least(coalesce(p_page_size, 30), 100));
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_list_support_requests(p_status text DEFAULT NULL)
RETURNS TABLE (
  id uuid, user_id uuid, email text, subject text, message text,
  request_type text, status text, admin_response text, created_at timestamptz,
  updated_at timestamptz, handled_by uuid
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  IF (auth.jwt() -> 'app_metadata' ->> 'role') IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'Administrator role required' USING ERRCODE = '42501';
  END IF;
  IF NOT app_private.is_current_user_active() THEN
    RAISE EXCEPTION 'Active administrator session required' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT s.id, s.user_id, u.email::text, s.subject, s.message,
         s.request_type, s.status,
         s.admin_response, s.created_at, s.updated_at, s.handled_by
  FROM public.support_requests s
  LEFT JOIN auth.users u ON u.id = s.user_id
  WHERE p_status IS NULL OR s.status = p_status
  ORDER BY s.created_at DESC LIMIT 200;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_update_support_request(
  p_request_id uuid, p_status text, p_response text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE v_actor uuid := auth.uid();
BEGIN
  IF (auth.jwt() -> 'app_metadata' ->> 'role') IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'Administrator role required' USING ERRCODE = '42501';
  END IF;
  IF NOT app_private.is_current_user_active() THEN
    RAISE EXCEPTION 'Active administrator session required' USING ERRCODE = '42501';
  END IF;
  IF p_status NOT IN ('open', 'in_progress', 'resolved', 'closed') THEN
    RAISE EXCEPTION 'Invalid support status' USING ERRCODE = '22023';
  END IF;
  UPDATE public.support_requests
  SET status = p_status,
      admin_response = nullif(btrim(p_response), ''),
      updated_at = now(), handled_by = v_actor
  WHERE id = p_request_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Support request not found' USING ERRCODE = 'P0002'; END IF;
  INSERT INTO public.admin_audit_log(actor_id, target_user_id, action, metadata)
  SELECT v_actor, s.user_id, 'support_request_updated',
         jsonb_build_object('request_id', s.id, 'status', p_status)
  FROM public.support_requests s WHERE s.id = p_request_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_list_audit_log()
RETURNS TABLE (
  id uuid, actor_email text, target_user_id uuid, action text,
  metadata jsonb, created_at timestamptz
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  IF (auth.jwt() -> 'app_metadata' ->> 'role') IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'Administrator role required' USING ERRCODE = '42501';
  END IF;
  IF NOT app_private.is_current_user_active() THEN
    RAISE EXCEPTION 'Active administrator session required' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT l.id, u.email::text, l.target_user_id, l.action, l.metadata, l.created_at
  FROM public.admin_audit_log l
  LEFT JOIN auth.users u ON u.id = l.actor_id
  ORDER BY l.created_at DESC LIMIT 200;
END;
$$;

-- The client may submit support requests for itself but cannot update their status.
REVOKE UPDATE ON public.support_requests FROM authenticated;
REVOKE ALL ON FUNCTION public.admin_user_overview() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_search_users(text, timestamptz, timestamptz, integer, integer) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_list_support_requests(text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_update_support_request(uuid, text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_list_audit_log() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_user_overview() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_search_users(text, timestamptz, timestamptz, integer, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_list_support_requests(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_support_request(uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_list_audit_log() TO authenticated;

-- Keep financial SECURITY DEFINER RPCs subject to the account suspension check.
CREATE OR REPLACE FUNCTION public.create_transaction(
  p_wallet_id uuid, p_type text, p_amount numeric,
  p_description text DEFAULT NULL, p_category_id uuid DEFAULT NULL,
  p_merchant text DEFAULT NULL, p_transaction_date timestamptz DEFAULT now(),
  p_latitude numeric DEFAULT NULL, p_longitude numeric DEFAULT NULL,
  p_tag_ids uuid[] DEFAULT NULL, p_client_request_id uuid DEFAULT NULL
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  IF NOT app_private.is_current_user_active() THEN
    RAISE EXCEPTION 'Active user session required' USING ERRCODE = '42501';
  END IF;
  RETURN app_private.create_transaction(
    auth.uid(), p_wallet_id, p_type, p_amount, p_description, p_category_id,
    p_merchant, p_transaction_date, p_latitude, p_longitude, p_tag_ids,
    p_client_request_id
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.transfer_money(
  p_from_wallet uuid, p_to_wallet uuid, p_amount numeric,
  p_description text DEFAULT NULL, p_client_request_id uuid DEFAULT NULL
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  IF NOT app_private.is_current_user_active() THEN
    RAISE EXCEPTION 'Active user session required' USING ERRCODE = '42501';
  END IF;
  RETURN app_private.transfer_money(
    auth.uid(), p_from_wallet, p_to_wallet, p_amount, p_description,
    p_client_request_id
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.void_transaction(
  p_transaction_id uuid, p_reason text DEFAULT NULL
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  IF NOT app_private.is_current_user_active() THEN
    RAISE EXCEPTION 'Active user session required' USING ERRCODE = '42501';
  END IF;
  RETURN app_private.void_transaction(auth.uid(), p_transaction_id, p_reason);
END;
$$;

COMMIT;
