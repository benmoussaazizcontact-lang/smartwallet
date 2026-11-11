-- Demo data for azizbenmoussa125@gmail.com only.
-- Re-runnable: fixed client_request_id values make money movements no-ops the second time.
-- Does not delete rows, does not change passwords, and does not touch other users.
-- Refuses to start unless the additive SmartWallet module tables already exist.
-- Run only after explicit approval:
--   supabase db query --remote -f supabase/seeds/demo_azizbenmoussa125.sql

do $$
declare
  v_user uuid := 'c19ec2bd-0480-428a-9f10-13a4640d9293';
  v_email text;
  v_biat uuid;
  v_cash uuid;
  v_savings uuid;
  v_card uuid;
  v_crypto uuid;
  v_food uuid;
  v_transport uuid;
  v_shopping uuid;
  v_housing uuid;
  v_entertainment uuid;
  v_health uuid;
  v_income uuid;
  v_goal uuid;
  v_portfolio uuid;
  v_asset uuid;
begin
  select email into v_email from auth.users where id = v_user;
  if v_email is distinct from 'azizbenmoussa125@gmail.com' then
    raise exception 'Refusing to seed: expected azizbenmoussa125@gmail.com, found %', coalesce(v_email, 'nobody');
  end if;

  if to_regclass('public.budgets') is null
     or to_regclass('public.financial_goals') is null
     or to_regclass('public.goal_contributions') is null
     or to_regclass('public.investment_portfolios') is null
     or to_regclass('public.investment_assets') is null
     or to_regclass('public.investment_transactions') is null
     or to_regclass('public.investment_price_history') is null then
    raise exception 'Module tables are missing. Apply 20261106120000_smartwallet_modules.sql before this seed.';
  end if;

  select id into v_food from public.categories
  where user_id is null and parent_id is null and name = 'Food' limit 1;
  select id into v_transport from public.categories
  where user_id is null and parent_id is null and name = 'Transport' limit 1;
  select id into v_shopping from public.categories
  where user_id is null and parent_id is null and name = 'Shopping' limit 1;
  select id into v_housing from public.categories
  where user_id is null and parent_id is null and name = 'Housing' limit 1;
  select id into v_entertainment from public.categories
  where user_id is null and parent_id is null and name = 'Entertainment' limit 1;
  select id into v_health from public.categories
  where user_id is null and parent_id is null and name = 'Health' limit 1;
  select id into v_income from public.categories
  where user_id is null and parent_id is null and name = 'Income' limit 1;
  if v_food is null or v_transport is null or v_shopping is null or v_housing is null
     or v_entertainment is null or v_health is null or v_income is null then
    raise exception 'A required global category is missing';
  end if;

  insert into public.wallets (user_id, name, wallet_type, currency, initial_balance, credit_limit, icon, color)
  select v_user, 'BIAT', 'BANK_ACCOUNT', 'TND', 301.500, 0, 'account_balance', '#1D4ED8'
  where not exists (select 1 from public.wallets w where w.user_id = v_user and w.name = 'BIAT');
  insert into public.wallets (user_id, name, wallet_type, currency, initial_balance, credit_limit, icon, color)
  select v_user, 'Espèces', 'CASH', 'TND', 929.500, 0, 'payments', '#0F766E'
  where not exists (select 1 from public.wallets w where w.user_id = v_user and w.name = 'Espèces');
  insert into public.wallets (user_id, name, wallet_type, currency, initial_balance, credit_limit, icon, color)
  select v_user, 'Épargne', 'SAVINGS', 'TND', 2700.000, 0, 'savings', '#047857'
  where not exists (select 1 from public.wallets w where w.user_id = v_user and w.name = 'Épargne');
  insert into public.wallets (user_id, name, wallet_type, currency, initial_balance, credit_limit, icon, color)
  select v_user, 'Carte bancaire', 'CREDIT_CARD', 'TND', 0, 2000.000, 'credit_card', '#B45309'
  where not exists (select 1 from public.wallets w where w.user_id = v_user and w.name = 'Carte bancaire');
  insert into public.wallets (user_id, name, wallet_type, currency, initial_balance, credit_limit, crypto_symbol, icon, color)
  select v_user, 'Crypto', 'CRYPTO', 'TND', 500.000, 0, 'BTC', 'currency_bitcoin', '#7C3AED'
  where not exists (select 1 from public.wallets w where w.user_id = v_user and w.name = 'Crypto');

  select id into v_biat from public.wallets where user_id = v_user and name = 'BIAT';
  select id into v_cash from public.wallets where user_id = v_user and name = 'Espèces';
  select id into v_savings from public.wallets where user_id = v_user and name = 'Épargne';
  select id into v_card from public.wallets where user_id = v_user and name = 'Carte bancaire';
  select id into v_crypto from public.wallets where user_id = v_user and name = 'Crypto';

  -- Opening balances are chosen so that, after these RPC movements, the visible
  -- balances are BIAT 5,000 / Espèces 800 / Épargne 3,000 / Crypto 500.
  -- The card starts at 0 and ends 131.700 TND in debt, inside the 2,000 limit.

  perform app_private.create_transaction(v_user, v_biat, 'INCOME', 2200.000, 'Salaire septembre', v_income, 'Employeur', '2026-09-01', null, null, null, 'a1250001-0000-4000-8000-000000000001');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 186.500, 'Courses alimentaires', v_food, 'Carrefour', '2026-09-03', null, null, null, 'a1250001-0000-4000-8000-000000000002');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 95.000, 'Shopping', v_shopping, 'Monoprix', '2026-09-06', null, null, null, 'a1250001-0000-4000-8000-000000000003');
  perform app_private.create_transaction(v_user, v_cash, 'EXPENSE', 62.000, 'Repas', v_food, 'Restaurant', '2026-09-08', null, null, null, 'a1250001-0000-4000-8000-000000000004');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 80.000, 'Carburant', v_transport, 'Shell', '2026-09-11', null, null, null, 'a1250001-0000-4000-8000-000000000005');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 74.000, 'Électricité', v_housing, 'STEG', '2026-09-14', null, null, null, 'a1250001-0000-4000-8000-000000000006');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 39.000, 'Téléphone', v_housing, 'Ooredoo', '2026-09-16', null, null, null, 'a1250001-0000-4000-8000-000000000007');
  perform app_private.create_transaction(v_user, v_card, 'EXPENSE', 29.900, 'Abonnement', v_entertainment, 'Netflix', '2026-09-18', null, null, null, 'a1250001-0000-4000-8000-000000000008');
  perform app_private.create_transaction(v_user, v_cash, 'EXPENSE', 31.500, 'Santé', v_health, 'Pharmacie', '2026-09-22', null, null, null, 'a1250001-0000-4000-8000-000000000009');

  perform app_private.create_transaction(v_user, v_biat, 'INCOME', 2200.000, 'Salaire octobre', v_income, 'Employeur', '2026-10-01', null, null, null, 'a1250001-0000-4000-8000-000000000010');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 172.000, 'Courses alimentaires', v_food, 'Carrefour', '2026-10-04', null, null, null, 'a1250001-0000-4000-8000-000000000011');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 120.000, 'Shopping', v_shopping, 'Monoprix', '2026-10-07', null, null, null, 'a1250001-0000-4000-8000-000000000012');
  perform app_private.create_transaction(v_user, v_cash, 'EXPENSE', 48.000, 'Repas', v_food, 'Restaurant', '2026-10-09', null, null, null, 'a1250001-0000-4000-8000-000000000013');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 90.000, 'Carburant', v_transport, 'Shell', '2026-10-12', null, null, null, 'a1250001-0000-4000-8000-000000000014');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 81.000, 'Électricité', v_housing, 'STEG', '2026-10-15', null, null, null, 'a1250001-0000-4000-8000-000000000015');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 39.000, 'Téléphone', v_housing, 'Ooredoo', '2026-10-16', null, null, null, 'a1250001-0000-4000-8000-000000000016');
  perform app_private.create_transaction(v_user, v_card, 'EXPENSE', 29.900, 'Abonnement', v_entertainment, 'Netflix', '2026-10-18', null, null, null, 'a1250001-0000-4000-8000-000000000017');
  perform app_private.create_transaction(v_user, v_cash, 'EXPENSE', 26.000, 'Santé', v_health, 'Pharmacie', '2026-10-21', null, null, null, 'a1250001-0000-4000-8000-000000000018');
  perform app_private.transfer_money(v_user, v_biat, v_savings, 500.000, 'Vers épargne', 'a1250001-0000-4000-8000-000000000019');
  perform app_private.transfer_money(v_user, v_biat, v_cash, 150.000, 'Retrait espèces', 'a1250001-0000-4000-8000-000000000020');

  perform app_private.create_transaction(v_user, v_biat, 'INCOME', 2200.000, 'Salaire novembre', v_income, 'Employeur', '2026-11-01', null, null, null, 'a1250001-0000-4000-8000-000000000021');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 98.000, 'Courses alimentaires', v_food, 'Carrefour', '2026-11-02', null, null, null, 'a1250001-0000-4000-8000-000000000022');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 75.000, 'Shopping', v_shopping, 'Monoprix', '2026-11-03', null, null, null, 'a1250001-0000-4000-8000-000000000023');
  perform app_private.create_transaction(v_user, v_cash, 'EXPENSE', 54.000, 'Repas', v_food, 'Restaurant', '2026-11-03', null, null, null, 'a1250001-0000-4000-8000-000000000024');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 55.000, 'Carburant', v_transport, 'Shell', '2026-11-04', null, null, null, 'a1250001-0000-4000-8000-000000000025');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 68.000, 'Électricité', v_housing, 'STEG', '2026-11-04', null, null, null, 'a1250001-0000-4000-8000-000000000026');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 39.000, 'Téléphone', v_housing, 'Ooredoo', '2026-11-05', null, null, null, 'a1250001-0000-4000-8000-000000000027');
  perform app_private.create_transaction(v_user, v_card, 'EXPENSE', 29.900, 'Abonnement', v_entertainment, 'Netflix', '2026-11-05', null, null, null, 'a1250001-0000-4000-8000-000000000028');
  perform app_private.create_transaction(v_user, v_cash, 'EXPENSE', 18.000, 'Santé', v_health, 'Pharmacie', '2026-11-05', null, null, null, 'a1250001-0000-4000-8000-000000000029');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 80.000, 'Courses alimentaires', v_food, 'Carrefour', '2026-11-06', null, null, null, 'a1250001-0000-4000-8000-000000000030');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 40.000, 'Carburant', v_transport, 'Shell', '2026-11-06', null, null, null, 'a1250001-0000-4000-8000-000000000031');
  perform app_private.create_transaction(v_user, v_biat, 'EXPENSE', 60.000, 'Shopping', v_shopping, 'Monoprix', '2026-11-06', null, null, null, 'a1250001-0000-4000-8000-000000000032');
  perform app_private.create_transaction(v_user, v_card, 'EXPENSE', 42.000, 'Courses alimentaires', v_food, 'Carrefour', '2026-11-06', null, null, null, 'a1250001-0000-4000-8000-000000000033');
  perform app_private.transfer_money(v_user, v_savings, v_biat, 200.000, 'Retour depuis épargne', 'a1250001-0000-4000-8000-000000000034');
  perform app_private.transfer_money(v_user, v_cash, v_biat, 40.000, 'Dépôt espèces', 'a1250001-0000-4000-8000-000000000035');

  insert into public.budgets (user_id, name, period, category_id, currency, limit_amount)
  select v_user, 'Food', 'monthly', v_food, 'TND', 400.000
  where not exists (
    select 1 from public.budgets b
    where b.user_id = v_user and b.archived = false and b.period = 'monthly' and b.currency = 'TND' and b.category_id = v_food
  );
  insert into public.budgets (user_id, name, period, category_id, currency, limit_amount)
  select v_user, 'Transport', 'monthly', v_transport, 'TND', 200.000
  where not exists (
    select 1 from public.budgets b
    where b.user_id = v_user and b.archived = false and b.period = 'monthly' and b.currency = 'TND' and b.category_id = v_transport
  );
  insert into public.budgets (user_id, name, period, category_id, currency, limit_amount)
  select v_user, 'Shopping', 'monthly', v_shopping, 'TND', 300.000
  where not exists (
    select 1 from public.budgets b
    where b.user_id = v_user and b.archived = false and b.period = 'monthly' and b.currency = 'TND' and b.category_id = v_shopping
  );
  insert into public.budgets (user_id, name, period, category_id, currency, limit_amount)
  select v_user, 'Bills', 'monthly', v_housing, 'TND', 250.000
  where not exists (
    select 1 from public.budgets b
    where b.user_id = v_user and b.archived = false and b.period = 'monthly' and b.currency = 'TND' and b.category_id = v_housing
  );
  insert into public.budgets (user_id, name, period, category_id, currency, limit_amount)
  select v_user, 'Monthly total', 'monthly', null, 'TND', 1500.000
  where not exists (
    select 1 from public.budgets b
    where b.user_id = v_user and b.archived = false and b.period = 'monthly' and b.currency = 'TND' and b.category_id is null
  );

  insert into public.financial_goals (user_id, name, kind, target_amount, currency, target_date, priority, icon, color, status)
  select v_user, 'Acheter un ordinateur', 'laptop', 3500.000, 'TND', '2027-06-01', 1, 'laptop', '#2563EB', 'active'
  where not exists (select 1 from public.financial_goals g where g.user_id = v_user and g.name = 'Acheter un ordinateur');
  insert into public.financial_goals (user_id, name, kind, target_amount, currency, target_date, priority, icon, color, status)
  select v_user, 'Voyage', 'travel', 5000.000, 'TND', '2027-08-01', 2, 'flight', '#0891B2', 'active'
  where not exists (select 1 from public.financial_goals g where g.user_id = v_user and g.name = 'Voyage');
  insert into public.financial_goals (user_id, name, kind, target_amount, currency, target_date, priority, icon, color, status)
  select v_user, 'Voiture', 'car', 40000.000, 'TND', '2028-11-01', 3, 'directions_car', '#334155', 'active'
  where not exists (select 1 from public.financial_goals g where g.user_id = v_user and g.name = 'Voiture');

  select id into v_goal from public.financial_goals where user_id = v_user and name = 'Acheter un ordinateur';
  insert into public.goal_contributions (user_id, goal_id, amount, currency, contributed_on, note, client_request_id)
  select v_user, v_goal, 2100.000, 'TND', '2026-10-20', 'Suivi virtuel, aucun débit de portefeuille', 'a1250001-0000-4000-8000-000000000041'
  where not exists (select 1 from public.goal_contributions c where c.user_id = v_user and c.client_request_id = 'a1250001-0000-4000-8000-000000000041');
  select id into v_goal from public.financial_goals where user_id = v_user and name = 'Voyage';
  insert into public.goal_contributions (user_id, goal_id, amount, currency, contributed_on, note, client_request_id)
  select v_user, v_goal, 1250.000, 'TND', '2026-10-20', 'Suivi virtuel, aucun débit de portefeuille', 'a1250001-0000-4000-8000-000000000042'
  where not exists (select 1 from public.goal_contributions c where c.user_id = v_user and c.client_request_id = 'a1250001-0000-4000-8000-000000000042');
  select id into v_goal from public.financial_goals where user_id = v_user and name = 'Voiture';
  insert into public.goal_contributions (user_id, goal_id, amount, currency, contributed_on, note, client_request_id)
  select v_user, v_goal, 4000.000, 'TND', '2026-10-20', 'Suivi virtuel, aucun débit de portefeuille', 'a1250001-0000-4000-8000-000000000043'
  where not exists (select 1 from public.goal_contributions c where c.user_id = v_user and c.client_request_id = 'a1250001-0000-4000-8000-000000000043');

  insert into public.investment_portfolios (user_id, name, base_currency)
  select v_user, 'Démo — prix fictifs', 'TND'
  where not exists (select 1 from public.investment_portfolios p where p.user_id = v_user and p.name = 'Démo — prix fictifs');
  select id into v_portfolio from public.investment_portfolios where user_id = v_user and name = 'Démo — prix fictifs';

  insert into public.investment_assets (user_id, portfolio_id, symbol, name, asset_class, currency, current_price, price_updated_at, manual_price)
  select v_user, v_portfolio, 'DEMO-TPR', 'FICTIF Tunisie Profil', 'stock', 'TND', 9.200, now(), true
  where not exists (select 1 from public.investment_assets a where a.user_id = v_user and a.symbol = 'DEMO-TPR');
  insert into public.investment_assets (user_id, portfolio_id, symbol, name, asset_class, currency, current_price, price_updated_at, manual_price)
  select v_user, v_portfolio, 'DEMO-ETF', 'FICTIF World ETF', 'etf', 'TND', 162.000, now(), true
  where not exists (select 1 from public.investment_assets a where a.user_id = v_user and a.symbol = 'DEMO-ETF');
  insert into public.investment_assets (user_id, portfolio_id, symbol, name, asset_class, currency, current_price, price_updated_at, manual_price)
  select v_user, v_portfolio, 'DEMO-BTC', 'FICTIF Bitcoin', 'crypto', 'TND', 190000.000, now(), true
  where not exists (select 1 from public.investment_assets a where a.user_id = v_user and a.symbol = 'DEMO-BTC');

  select id into v_asset from public.investment_assets where user_id = v_user and symbol = 'DEMO-TPR';
  insert into public.investment_transactions (user_id, asset_id, side, quantity, unit_price, traded_on, client_request_id)
  select v_user, v_asset, 'buy', 30.00000000, 8.500, '2026-09-12', 'a1250001-0000-4000-8000-000000000051'
  where not exists (select 1 from public.investment_transactions t where t.user_id = v_user and t.client_request_id = 'a1250001-0000-4000-8000-000000000051');
  insert into public.investment_price_history (user_id, asset_id, price)
  select v_user, v_asset, 9.200
  where not exists (select 1 from public.investment_price_history h where h.user_id = v_user and h.asset_id = v_asset and h.price = 9.200);

  select id into v_asset from public.investment_assets where user_id = v_user and symbol = 'DEMO-ETF';
  insert into public.investment_transactions (user_id, asset_id, side, quantity, unit_price, traded_on, client_request_id)
  select v_user, v_asset, 'buy', 2.00000000, 150.000, '2026-10-03', 'a1250001-0000-4000-8000-000000000052'
  where not exists (select 1 from public.investment_transactions t where t.user_id = v_user and t.client_request_id = 'a1250001-0000-4000-8000-000000000052');
  insert into public.investment_price_history (user_id, asset_id, price)
  select v_user, v_asset, 162.000
  where not exists (select 1 from public.investment_price_history h where h.user_id = v_user and h.asset_id = v_asset and h.price = 162.000);

  select id into v_asset from public.investment_assets where user_id = v_user and symbol = 'DEMO-BTC';
  insert into public.investment_transactions (user_id, asset_id, side, quantity, unit_price, traded_on, client_request_id)
  select v_user, v_asset, 'buy', 0.00150000, 180000.000, '2026-10-19', 'a1250001-0000-4000-8000-000000000053'
  where not exists (select 1 from public.investment_transactions t where t.user_id = v_user and t.client_request_id = 'a1250001-0000-4000-8000-000000000053');
  insert into public.investment_price_history (user_id, asset_id, price)
  select v_user, v_asset, 190000.000
  where not exists (select 1 from public.investment_price_history h where h.user_id = v_user and h.asset_id = v_asset and h.price = 190000.000);
end $$;
