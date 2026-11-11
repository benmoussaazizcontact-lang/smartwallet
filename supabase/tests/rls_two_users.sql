-- Run in Supabase SQL Editor after creating two test users.
-- Replace the UUIDs with real auth.users ids.
-- Expected: each user only sees their own wallets/transactions.

-- SELECT id, email FROM auth.users;

-- SET ROLE authenticated;
-- SELECT set_config('request.jwt.claim.sub', '<user-a-uuid>', true);
-- SELECT * FROM public.wallets;
-- SELECT * FROM public.wallet_balances;
-- SELECT * FROM public.transactions;

-- Repeat with user B and confirm empty overlap.
