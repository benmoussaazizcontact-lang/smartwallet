-- SmartWallet modules: budgets, goals, investments, and assistant history.
-- Additive only. Existing wallets and transactions are not modified.

create table if not exists public.budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  period text not null check (period in ('monthly', 'weekly')),
  category_id uuid references public.categories(id) on delete set null,
  currency varchar(10) not null,
  limit_amount numeric(18,3) not null check (limit_amount > 0),
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint budgets_currency_format check (currency ~ '^[A-Z]{3,10}$')
);

create unique index if not exists budgets_one_active_scope
  on public.budgets (
    user_id,
    period,
    currency,
    coalesce(category_id, '00000000-0000-0000-0000-000000000000'::uuid)
  )
  where archived = false;

create index if not exists budgets_user_idx on public.budgets (user_id, archived);

create table if not exists public.budget_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  budget_id uuid not null references public.budgets(id) on delete cascade,
  threshold integer not null check (threshold in (50, 80, 90, 100)),
  period_key text not null,
  created_at timestamptz not null default now(),
  unique (budget_id, threshold, period_key)
);

create table if not exists public.financial_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  kind text not null check (kind in (
    'laptop', 'car', 'travel', 'house', 'education', 'emergency', 'phone', 'investments', 'custom'
  )),
  target_amount numeric(18,3) not null check (target_amount > 0),
  currency varchar(10) not null,
  target_date date,
  priority integer not null default 2 check (priority between 1 and 3),
  icon text,
  color varchar(16),
  status text not null default 'active' check (status in ('active', 'completed', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint goals_currency_format check (currency ~ '^[A-Z]{3,10}$')
);

create index if not exists financial_goals_user_idx on public.financial_goals (user_id, status);

-- Virtual tracking. A row here does not move wallet balances.
create table if not exists public.goal_contributions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  goal_id uuid not null references public.financial_goals(id) on delete cascade,
  amount numeric(18,3) not null check (amount > 0),
  currency varchar(10) not null,
  contributed_on date not null default current_date,
  note text,
  client_request_id uuid,
  created_at timestamptz not null default now()
);

create unique index if not exists goal_contributions_request_uidx
  on public.goal_contributions (user_id, client_request_id)
  where client_request_id is not null;

create table if not exists public.goal_schedules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  goal_id uuid not null references public.financial_goals(id) on delete cascade,
  amount numeric(18,3) not null check (amount > 0),
  frequency text not null check (frequency in ('weekly', 'monthly')),
  next_on date not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.investment_portfolios (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  base_currency varchar(10) not null,
  created_at timestamptz not null default now(),
  constraint portfolios_currency_format check (base_currency ~ '^[A-Z]{3,10}$')
);

create table if not exists public.investment_assets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  portfolio_id uuid not null references public.investment_portfolios(id) on delete cascade,
  symbol text not null,
  name text not null,
  asset_class text not null check (asset_class in ('stock', 'etf', 'crypto', 'other')),
  currency varchar(10) not null,
  current_price numeric(18,6),
  price_updated_at timestamptz,
  manual_price boolean not null default true,
  created_at timestamptz not null default now(),
  constraint assets_currency_format check (currency ~ '^[A-Z]{3,10}$')
);

create index if not exists investment_assets_portfolio_idx
  on public.investment_assets (portfolio_id, user_id);

create table if not exists public.investment_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  asset_id uuid not null references public.investment_assets(id) on delete cascade,
  side text not null check (side in ('buy', 'sell')),
  quantity numeric(24,8) not null check (quantity > 0),
  unit_price numeric(18,6) not null check (unit_price >= 0),
  traded_on date not null default current_date,
  client_request_id uuid,
  created_at timestamptz not null default now()
);

create unique index if not exists investment_transactions_request_uidx
  on public.investment_transactions (user_id, client_request_id)
  where client_request_id is not null;

create table if not exists public.investment_price_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  asset_id uuid not null references public.investment_assets(id) on delete cascade,
  price numeric(18,6) not null check (price >= 0),
  recorded_at timestamptz not null default now()
);

create table if not exists public.ai_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.ai_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  conversation_id uuid not null references public.ai_conversations(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  body text not null check (char_length(body) <= 4000),
  created_at timestamptz not null default now()
);

create index if not exists ai_messages_conversation_idx
  on public.ai_messages (conversation_id, created_at);

do $$
declare
  tbl text;
begin
  foreach tbl in array array[
    'budgets', 'budget_alerts', 'financial_goals', 'goal_contributions', 'goal_schedules',
    'investment_portfolios', 'investment_assets', 'investment_transactions',
    'investment_price_history', 'ai_conversations', 'ai_messages'
  ]
  loop
    execute format('alter table public.%I enable row level security', tbl);
    execute format('revoke all on public.%I from anon', tbl);
    execute format('grant select, insert, update, delete on public.%I to authenticated', tbl);
  end loop;
end $$;

create policy "own budgets select" on public.budgets for select to authenticated using (user_id = auth.uid());
create policy "own budgets insert" on public.budgets for insert to authenticated with check (user_id = auth.uid());
create policy "own budgets update" on public.budgets for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own budgets delete" on public.budgets for delete to authenticated using (user_id = auth.uid());

create policy "own budget alerts select" on public.budget_alerts for select to authenticated using (user_id = auth.uid());
create policy "own budget alerts insert" on public.budget_alerts for insert to authenticated with check (
  user_id = auth.uid()
  and exists (select 1 from public.budgets b where b.id = budget_id and b.user_id = auth.uid())
);

create policy "own goals select" on public.financial_goals for select to authenticated using (user_id = auth.uid());
create policy "own goals insert" on public.financial_goals for insert to authenticated with check (user_id = auth.uid());
create policy "own goals update" on public.financial_goals for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own goals delete" on public.financial_goals for delete to authenticated using (user_id = auth.uid());

create policy "own contributions select" on public.goal_contributions for select to authenticated using (user_id = auth.uid());
create policy "own contributions insert" on public.goal_contributions for insert to authenticated with check (
  user_id = auth.uid()
  and exists (select 1 from public.financial_goals g where g.id = goal_id and g.user_id = auth.uid())
);
create policy "own contributions delete" on public.goal_contributions for delete to authenticated using (user_id = auth.uid());

create policy "own schedules select" on public.goal_schedules for select to authenticated using (user_id = auth.uid());
create policy "own schedules insert" on public.goal_schedules for insert to authenticated with check (
  user_id = auth.uid()
  and exists (select 1 from public.financial_goals g where g.id = goal_id and g.user_id = auth.uid())
);
create policy "own schedules update" on public.goal_schedules for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own schedules delete" on public.goal_schedules for delete to authenticated using (user_id = auth.uid());

create policy "own portfolios select" on public.investment_portfolios for select to authenticated using (user_id = auth.uid());
create policy "own portfolios insert" on public.investment_portfolios for insert to authenticated with check (user_id = auth.uid());
create policy "own portfolios update" on public.investment_portfolios for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own portfolios delete" on public.investment_portfolios for delete to authenticated using (user_id = auth.uid());

create policy "own assets select" on public.investment_assets for select to authenticated using (user_id = auth.uid());
create policy "own assets insert" on public.investment_assets for insert to authenticated with check (
  user_id = auth.uid()
  and exists (select 1 from public.investment_portfolios p where p.id = portfolio_id and p.user_id = auth.uid())
);
create policy "own assets update" on public.investment_assets for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own assets delete" on public.investment_assets for delete to authenticated using (user_id = auth.uid());

create policy "own investment tx select" on public.investment_transactions for select to authenticated using (user_id = auth.uid());
create policy "own investment tx insert" on public.investment_transactions for insert to authenticated with check (
  user_id = auth.uid()
  and exists (select 1 from public.investment_assets a where a.id = asset_id and a.user_id = auth.uid())
);

create policy "own prices select" on public.investment_price_history for select to authenticated using (user_id = auth.uid());
create policy "own prices insert" on public.investment_price_history for insert to authenticated with check (
  user_id = auth.uid()
  and exists (select 1 from public.investment_assets a where a.id = asset_id and a.user_id = auth.uid())
);

create policy "own conversations select" on public.ai_conversations for select to authenticated using (user_id = auth.uid());
create policy "own conversations insert" on public.ai_conversations for insert to authenticated with check (user_id = auth.uid());
create policy "own conversations delete" on public.ai_conversations for delete to authenticated using (user_id = auth.uid());

create policy "own messages select" on public.ai_messages for select to authenticated using (user_id = auth.uid());
create policy "own messages insert" on public.ai_messages for insert to authenticated with check (
  user_id = auth.uid()
  and exists (select 1 from public.ai_conversations c where c.id = conversation_id and c.user_id = auth.uid())
);
