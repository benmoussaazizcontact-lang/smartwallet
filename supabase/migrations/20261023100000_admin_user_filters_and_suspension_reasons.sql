-- Adds server-filtered account role/status filters and exposes the
-- administrator-entered suspension reason to authorized administrators only.
BEGIN;

DROP FUNCTION IF EXISTS public.admin_search_users(text, timestamptz, timestamptz, integer, integer);
DROP FUNCTION IF EXISTS public.admin_search_users(text, timestamptz, timestamptz, text, text, integer, integer);

CREATE FUNCTION public.admin_search_users(
  p_query text DEFAULT NULL,
  p_created_from timestamptz DEFAULT NULL,
  p_created_to timestamptz DEFAULT NULL,
  p_role text DEFAULT NULL,
  p_status text DEFAULT NULL,
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
  account_role text,
  suspension_reason text
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
  IF p_role IS NOT NULL AND p_role NOT IN ('user', 'admin') THEN
    RAISE EXCEPTION 'Invalid role filter' USING ERRCODE = '22023';
  END IF;
  IF p_status IS NOT NULL AND p_status NOT IN ('active', 'suspended') THEN
    RAISE EXCEPTION 'Invalid status filter' USING ERRCODE = '22023';
  END IF;

  RETURN QUERY
  SELECT u.id, u.email::text, p.first_name::text, p.last_name::text,
         u.created_at, u.last_sign_in_at, u.email_confirmed_at, u.banned_until,
         coalesce(u.raw_app_meta_data ->> 'role', 'user'),
         nullif(u.raw_app_meta_data ->> 'admin_suspension_reason', '')
  FROM auth.users u
  LEFT JOIN public.profiles p ON p.id = u.id
  WHERE (v_query IS NULL OR
         u.email ILIKE '%' || v_query || '%' OR
         p.first_name ILIKE '%' || v_query || '%' OR
         p.last_name ILIKE '%' || v_query || '%' OR
         concat_ws(' ', p.first_name, p.last_name) ILIKE '%' || v_query || '%')
    AND (p_created_from IS NULL OR u.created_at >= p_created_from)
    AND (p_created_to IS NULL OR u.created_at < p_created_to)
    AND (p_role IS NULL OR coalesce(u.raw_app_meta_data ->> 'role', 'user') = p_role)
    AND (p_status IS NULL OR
         (p_status = 'suspended' AND u.banned_until > now()) OR
         (p_status = 'active' AND (u.banned_until IS NULL OR u.banned_until <= now())))
  ORDER BY u.created_at DESC
  LIMIT greatest(1, least(coalesce(p_page_size, 30), 100))
  OFFSET greatest(0, coalesce(p_page, 0)) * greatest(1, least(coalesce(p_page_size, 30), 100));
END;
$$;

REVOKE ALL ON FUNCTION public.admin_search_users(text, timestamptz, timestamptz, text, text, integer, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_search_users(text, timestamptz, timestamptz, text, text, integer, integer) TO authenticated;

NOTIFY pgrst, 'reload schema';

COMMIT;
