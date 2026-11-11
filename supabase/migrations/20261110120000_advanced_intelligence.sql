-- Optional persistence for insights already calculated on the device.
-- Additive. Does not change wallet balances, transactions, or other users.
-- Not applied remotely until an explicit approval and a verified backup.

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  merchant text not null,
  currency varchar(10) not null,
  cadence text not null check (cadence in ('weekly', 'monthly', 'quarterly')),
  typical_amount numeric(18,3) not null check (typical_amount > 0),
  last_amount numeric(18,3) not null check (last_amount > 0),
  last_paid_on date not null,
  inactive boolean not null default false,
  price_increased boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.transaction_reconciliations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  receipt_id uuid,
  transaction_id uuid,
  score numeric(6,4) not null check (score >= 0 and score <= 1),
  status text not null check (status in ('matched', 'unmatched', 'duplicate')),
  created_at timestamptz not null default now()
);

create table if not exists public.anomaly_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  transaction_id uuid,
  code text not null,
  severity text not null check (severity in ('low', 'medium', 'high')),
  detail text not null,
  blocks_transaction boolean not null default false check (blocks_transaction = false),
  created_at timestamptz not null default now()
);

create table if not exists public.expense_forecasts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  currency varchar(10) not null,
  horizon_days integer not null check (horizon_days in (7, 30)),
  amount numeric(18,3) not null,
  uncertainty numeric(18,3),
  sample_count integer not null,
  generated_at timestamptz not null default now()
);

create table if not exists public.budget_allocations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category_name text not null,
  currency varchar(10) not null,
  amount numeric(18,3) not null check (amount >= 0),
  note text,
  created_at timestamptz not null default now()
);

create table if not exists public.financial_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  period_start date not null,
  period_end date not null,
  currency varchar(10) not null,
  income numeric(18,3) not null,
  expense numeric(18,3) not null,
  created_at timestamptz not null default now()
);

create table if not exists public.ai_action_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  action text not null check (action in ('draft_transaction', 'create_goal', 'virtual_contribution')),
  payload jsonb not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

do $$
declare
  tbl text;
begin
  foreach tbl in array array[
    'subscriptions', 'transaction_reconciliations', 'anomaly_events',
    'expense_forecasts', 'budget_allocations', 'financial_reports', 'ai_action_requests'
  ]
  loop
    execute format('alter table public.%I enable row level security', tbl);
    execute format('revoke all on public.%I from anon', tbl);
    execute format('grant select, insert, update, delete on public.%I to authenticated', tbl);
    execute format(
      'create policy "own %1$s" on public.%1$I for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid())',
      tbl
    );
  end loop;
end $$;
