-- Admin-only account metrics. No account-level personal data is returned.
BEGIN;

CREATE OR REPLACE FUNCTION public.admin_user_overview()
RETURNS TABLE (
  total_accounts bigint,
  signups_last_30_days bigint,
  active_last_30_days bigint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF (auth.jwt() -> 'app_metadata' ->> 'role') IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'Administrator role required'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    count(*)::bigint,
    count(*) FILTER (WHERE u.created_at >= now() - interval '30 days')::bigint,
    count(*) FILTER (WHERE u.last_sign_in_at >= now() - interval '30 days')::bigint
  FROM auth.users AS u;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_user_overview() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_user_overview() TO authenticated;

COMMIT;
