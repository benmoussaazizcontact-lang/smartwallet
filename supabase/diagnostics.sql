-- Run in Supabase Dashboard → SQL Editor if you need to re-check the live schema.

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY 1;

SELECT n.nspname, p.proname, p.prosecdef
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname IN ('public', 'app_private')
ORDER BY 1, 2;

SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE schemaname IN ('public', 'storage')
ORDER BY 1, 2, 3;

SELECT * FROM public.wallet_balances LIMIT 20;
SELECT COUNT(*) FROM public.categories WHERE user_id IS NULL;
