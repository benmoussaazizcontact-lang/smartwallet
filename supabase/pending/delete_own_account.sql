-- Pending. Do not apply with supabase db push.
-- This function deletes only the signed-in auth user. Existing foreign keys
-- that cascade from auth.users remove that user's rows. It does nothing when
-- no session is present.
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;
