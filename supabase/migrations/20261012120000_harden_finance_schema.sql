-- Additive hardening for Wallet & Transactions.
-- Does not drop user tables or existing financial data.

BEGIN;

CREATE SCHEMA IF NOT EXISTS app_private;
REVOKE ALL ON SCHEMA app_private FROM PUBLIC;
REVOKE ALL ON SCHEMA app_private FROM anon, authenticated;
GRANT USAGE ON SCHEMA app_private TO postgres, service_role;

-- ---------------------------------------------------------------------------
-- Columns
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS preferred_currency varchar(10) NOT NULL DEFAULT 'TND',
  ADD COLUMN IF NOT EXISTS theme_mode varchar(20) NOT NULL DEFAULT 'system',
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_preferred_currency_check;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_preferred_currency_check
  CHECK (preferred_currency IN ('TND', 'EUR', 'USD'));

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_theme_mode_check;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_theme_mode_check
  CHECK (theme_mode IN ('system', 'light', 'dark'));

ALTER TABLE public.wallets
  ADD COLUMN IF NOT EXISTS is_archived boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS credit_limit numeric(18,3) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS crypto_symbol varchar(20),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.wallets
  DROP CONSTRAINT IF EXISTS wallets_credit_limit_check;
ALTER TABLE public.wallets
  ADD CONSTRAINT wallets_credit_limit_check CHECK (credit_limit >= 0);

ALTER TABLE public.wallets
  DROP CONSTRAINT IF EXISTS wallets_currency_format_check;
ALTER TABLE public.wallets
  ADD CONSTRAINT wallets_currency_format_check
  CHECK (currency ~ '^[A-Z]{3,10}$');

ALTER TABLE public.categories
  ADD COLUMN IF NOT EXISTS color varchar(16);

ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS status varchar(16) NOT NULL DEFAULT 'POSTED',
  ADD COLUMN IF NOT EXISTS client_request_id uuid,
  ADD COLUMN IF NOT EXISTS voided_at timestamptz,
  ADD COLUMN IF NOT EXISTS void_reason text;

ALTER TABLE public.transactions
  DROP CONSTRAINT IF EXISTS transactions_status_check;
ALTER TABLE public.transactions
  ADD CONSTRAINT transactions_status_check
  CHECK (status IN ('POSTED', 'VOIDED'));

ALTER TABLE public.transfers
  ADD COLUMN IF NOT EXISTS client_request_id uuid;

ALTER TABLE public.recurring_transactions
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS merchant varchar(255),
  ADD COLUMN IF NOT EXISTS currency varchar(10) NOT NULL DEFAULT 'TND',
  ADD COLUMN IF NOT EXISTS last_executed_on date;

CREATE TABLE IF NOT EXISTS public.recurring_executions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recurring_id uuid NOT NULL REFERENCES public.recurring_transactions(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  transaction_id uuid REFERENCES public.transactions(id) ON DELETE SET NULL,
  executed_on date NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (recurring_id, executed_on)
);

CREATE UNIQUE INDEX IF NOT EXISTS transactions_user_client_request_uidx
  ON public.transactions (user_id, client_request_id)
  WHERE client_request_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS transfers_user_client_request_uidx
  ON public.transfers (user_id, client_request_id)
  WHERE client_request_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS tags_user_name_uidx
  ON public.tags (user_id, lower(name));

CREATE INDEX IF NOT EXISTS idx_transactions_user_date
  ON public.transactions (user_id, transaction_date DESC);

CREATE INDEX IF NOT EXISTS idx_transactions_wallet
  ON public.transactions (wallet_id);

CREATE INDEX IF NOT EXISTS idx_transactions_category
  ON public.transactions (category_id);

CREATE INDEX IF NOT EXISTS idx_wallets_user
  ON public.wallets (user_id)
  WHERE is_archived = false;

CREATE INDEX IF NOT EXISTS idx_recurring_due
  ON public.recurring_transactions (next_execution_date)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_recurring_executions_user
  ON public.recurring_executions (user_id, executed_on DESC);

-- ---------------------------------------------------------------------------
-- Protect immutable financial fields
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION app_private.protect_wallet_immutable_fields()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF NEW.user_id IS DISTINCT FROM OLD.user_id THEN
      RAISE EXCEPTION 'Le proprietaire du wallet ne peut pas etre modifie';
    END IF;
    IF NEW.initial_balance IS DISTINCT FROM OLD.initial_balance THEN
      RAISE EXCEPTION 'Le solde initial ne peut pas etre modifie';
    END IF;
    IF NEW.currency IS DISTINCT FROM OLD.currency THEN
      RAISE EXCEPTION 'La devise du wallet ne peut pas etre modifiee';
    END IF;
    IF NEW.credit_limit < 0 THEN
      RAISE EXCEPTION 'Plafond credit invalide';
    END IF;
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS wallets_protect_immutable ON public.wallets;
CREATE TRIGGER wallets_protect_immutable
  BEFORE UPDATE ON public.wallets
  FOR EACH ROW
  EXECUTE FUNCTION app_private.protect_wallet_immutable_fields();

CREATE OR REPLACE FUNCTION app_private.protect_profile_identity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF NEW.id IS DISTINCT FROM OLD.id THEN
    RAISE EXCEPTION 'Identifiant profil immuable';
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_protect_identity ON public.profiles;
CREATE TRIGGER profiles_protect_identity
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION app_private.protect_profile_identity();

-- ---------------------------------------------------------------------------
-- View (RLS of underlying tables applies)
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS public.wallet_balances;
CREATE VIEW public.wallet_balances
WITH (security_invoker = true) AS
SELECT
  w.id AS wallet_id,
  w.user_id,
  w.name,
  w.wallet_type,
  w.currency,
  w.initial_balance,
  w.initial_balance + COALESCE((
    SELECT SUM(m.amount) FROM public.wallet_movements m WHERE m.wallet_id = w.id
  ), 0) AS current_balance,
  w.credit_limit,
  CASE
    WHEN w.wallet_type = 'CREDIT_CARD'
      THEN GREATEST(0, -(w.initial_balance + COALESCE((
        SELECT SUM(m.amount) FROM public.wallet_movements m WHERE m.wallet_id = w.id
      ), 0)))
    ELSE 0
  END AS debt,
  CASE
    WHEN w.wallet_type = 'CREDIT_CARD'
      THEN w.credit_limit + (w.initial_balance + COALESCE((
        SELECT SUM(m.amount) FROM public.wallet_movements m WHERE m.wallet_id = w.id
      ), 0))
    ELSE NULL
  END AS available_credit,
  w.crypto_symbol,
  w.is_archived,
  w.created_at
FROM public.wallets w;

GRANT SELECT ON public.wallet_balances TO authenticated;
REVOKE ALL ON public.wallet_balances FROM anon;

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION app_private.assert_amount(p_amount numeric)
RETURNS void
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF p_amount IS NULL
     OR p_amount <= 0
     OR p_amount > 999999999999999.999
     OR p_amount <> round(p_amount, 3)
  THEN
    RAISE EXCEPTION 'Montant invalide';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.wallet_current_balance(p_wallet_id uuid)
RETURNS numeric
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT w.initial_balance + COALESCE((
    SELECT SUM(m.amount) FROM public.wallet_movements m WHERE m.wallet_id = w.id
  ), 0)
  FROM public.wallets w
  WHERE w.id = p_wallet_id;
$$;

CREATE OR REPLACE FUNCTION app_private.assert_funds(
  p_wallet public.wallets,
  p_debit numeric
)
RETURNS void
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_balance numeric;
BEGIN
  v_balance := app_private.wallet_current_balance(p_wallet.id);
  IF p_wallet.wallet_type = 'CREDIT_CARD' THEN
    IF v_balance - p_debit < -p_wallet.credit_limit THEN
      RAISE EXCEPTION 'Plafond de credit depasse';
    END IF;
  ELSE
    IF v_balance < p_debit THEN
      RAISE EXCEPTION 'Solde insuffisant';
    END IF;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.create_transaction(
  p_user_id uuid,
  p_wallet_id uuid,
  p_type text,
  p_amount numeric,
  p_description text DEFAULT NULL,
  p_category_id uuid DEFAULT NULL,
  p_merchant text DEFAULT NULL,
  p_transaction_date timestamptz DEFAULT now(),
  p_latitude numeric DEFAULT NULL,
  p_longitude numeric DEFAULT NULL,
  p_tag_ids uuid[] DEFAULT NULL,
  p_client_request_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_wallet public.wallets%ROWTYPE;
  v_transaction_id uuid;
  v_movement numeric(18,3);
  v_tag uuid;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifie';
  END IF;

  IF p_type IS NULL OR p_type NOT IN ('EXPENSE', 'INCOME', 'PAYMENT', 'REFUND') THEN
    RAISE EXCEPTION 'Type de transaction invalide';
  END IF;

  PERFORM app_private.assert_amount(p_amount);

  IF p_client_request_id IS NOT NULL THEN
    SELECT id INTO v_transaction_id
    FROM public.transactions
    WHERE user_id = p_user_id AND client_request_id = p_client_request_id;
    IF FOUND THEN
      RETURN v_transaction_id;
    END IF;
  END IF;

  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE id = p_wallet_id AND user_id = p_user_id AND is_archived = false
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wallet introuvable ou non autorise';
  END IF;

  IF p_category_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM public.categories
       WHERE id = p_category_id
         AND (user_id = p_user_id OR user_id IS NULL)
     )
  THEN
    RAISE EXCEPTION 'Categorie non autorisee';
  END IF;

  v_movement := CASE
    WHEN p_type IN ('EXPENSE', 'PAYMENT') THEN -p_amount
    ELSE p_amount
  END;

  IF v_movement < 0 THEN
    PERFORM app_private.assert_funds(v_wallet, abs(v_movement));
  END IF;

  INSERT INTO public.transactions (
    user_id, wallet_id, category_id, transaction_type, amount, currency,
    description, merchant, transaction_date, latitude, longitude,
    client_request_id, status
  ) VALUES (
    p_user_id, p_wallet_id, p_category_id, p_type, p_amount, v_wallet.currency,
    p_description, p_merchant, COALESCE(p_transaction_date, now()),
    p_latitude, p_longitude, p_client_request_id, 'POSTED'
  )
  RETURNING id INTO v_transaction_id;

  INSERT INTO public.wallet_movements (wallet_id, transaction_id, amount)
  VALUES (p_wallet_id, v_transaction_id, v_movement);

  IF p_tag_ids IS NOT NULL THEN
    FOREACH v_tag IN ARRAY p_tag_ids LOOP
      IF NOT EXISTS (
        SELECT 1 FROM public.tags WHERE id = v_tag AND user_id = p_user_id
      ) THEN
        RAISE EXCEPTION 'Tag non autorise';
      END IF;
      INSERT INTO public.transaction_tags (transaction_id, tag_id)
      VALUES (v_transaction_id, v_tag)
      ON CONFLICT DO NOTHING;
    END LOOP;
  END IF;

  RETURN v_transaction_id;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.transfer_money(
  p_user_id uuid,
  p_from_wallet uuid,
  p_to_wallet uuid,
  p_amount numeric,
  p_description text DEFAULT NULL,
  p_client_request_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_from public.wallets%ROWTYPE;
  v_to public.wallets%ROWTYPE;
  v_transfer_id uuid;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'Non authentifie';
  END IF;

  IF p_from_wallet IS NULL OR p_to_wallet IS NULL OR p_from_wallet = p_to_wallet THEN
    RAISE EXCEPTION 'Wallets invalides';
  END IF;

  PERFORM app_private.assert_amount(p_amount);

  IF p_client_request_id IS NOT NULL THEN
    SELECT id INTO v_transfer_id
    FROM public.transfers
    WHERE user_id = p_user_id AND client_request_id = p_client_request_id;
    IF FOUND THEN
      RETURN v_transfer_id;
    END IF;
  END IF;

  PERFORM 1
  FROM public.wallets
  WHERE id IN (p_from_wallet, p_to_wallet) AND user_id = p_user_id
  ORDER BY id
  FOR UPDATE;

  SELECT * INTO v_from FROM public.wallets
  WHERE id = p_from_wallet AND user_id = p_user_id AND is_archived = false;
  SELECT * INTO v_to FROM public.wallets
  WHERE id = p_to_wallet AND user_id = p_user_id AND is_archived = false;

  IF v_from.id IS NULL OR v_to.id IS NULL THEN
    RAISE EXCEPTION 'Wallet non autorise';
  END IF;

  IF v_from.currency <> v_to.currency THEN
    RAISE EXCEPTION 'Conversion de devises non configuree';
  END IF;

  PERFORM app_private.assert_funds(v_from, p_amount);

  INSERT INTO public.transfers (
    user_id, from_wallet_id, to_wallet_id, amount, currency, description, client_request_id
  ) VALUES (
    p_user_id, p_from_wallet, p_to_wallet, p_amount, v_from.currency, p_description, p_client_request_id
  )
  RETURNING id INTO v_transfer_id;

  INSERT INTO public.wallet_movements (wallet_id, transfer_id, amount)
  VALUES
    (p_from_wallet, v_transfer_id, -p_amount),
    (p_to_wallet, v_transfer_id, p_amount);

  RETURN v_transfer_id;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.void_transaction(
  p_user_id uuid,
  p_transaction_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_tx public.transactions%ROWTYPE;
  v_movement numeric(18,3);
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'Non authentifie';
  END IF;

  SELECT * INTO v_tx
  FROM public.transactions
  WHERE id = p_transaction_id AND user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction introuvable';
  END IF;

  IF v_tx.status = 'VOIDED' THEN
    RETURN v_tx.id;
  END IF;

  SELECT amount INTO v_movement
  FROM public.wallet_movements
  WHERE transaction_id = v_tx.id
  ORDER BY created_at
  LIMIT 1;

  IF v_movement IS NULL THEN
    RAISE EXCEPTION 'Mouvement comptable introuvable';
  END IF;

  INSERT INTO public.wallet_movements (wallet_id, transaction_id, amount)
  VALUES (v_tx.wallet_id, v_tx.id, -v_movement);

  UPDATE public.transactions
  SET status = 'VOIDED',
      voided_at = now(),
      void_reason = p_reason
  WHERE id = v_tx.id;

  RETURN v_tx.id;
END;
$$;

CREATE OR REPLACE FUNCTION app_private.process_due_recurring_transactions()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  r public.recurring_transactions%ROWTYPE;
  v_tx uuid;
  v_count integer := 0;
  v_next date;
BEGIN
  FOR r IN
    SELECT *
    FROM public.recurring_transactions
    WHERE is_active = true
      AND next_execution_date <= CURRENT_DATE
    ORDER BY next_execution_date, id
    FOR UPDATE SKIP LOCKED
  LOOP
    BEGIN
      INSERT INTO public.recurring_executions (recurring_id, user_id, executed_on)
      VALUES (r.id, r.user_id, r.next_execution_date);
    EXCEPTION
      WHEN unique_violation THEN
        v_next := CASE r.frequency
          WHEN 'DAILY' THEN r.next_execution_date + INTERVAL '1 day'
          WHEN 'WEEKLY' THEN r.next_execution_date + INTERVAL '7 days'
          WHEN 'MONTHLY' THEN r.next_execution_date + INTERVAL '1 month'
          WHEN 'YEARLY' THEN r.next_execution_date + INTERVAL '1 year'
        END;
        UPDATE public.recurring_transactions
        SET next_execution_date = v_next::date
        WHERE id = r.id;
        CONTINUE;
    END;

    v_tx := app_private.create_transaction(
      r.user_id,
      r.wallet_id,
      r.transaction_type,
      r.amount,
      COALESCE(r.description, 'Recurring'),
      r.category_id,
      r.merchant,
      (r.next_execution_date::timestamptz),
      NULL,
      NULL,
      NULL,
      NULL
    );

    UPDATE public.recurring_executions
    SET transaction_id = v_tx
    WHERE recurring_id = r.id AND executed_on = r.next_execution_date;

    v_next := CASE r.frequency
      WHEN 'DAILY' THEN r.next_execution_date + INTERVAL '1 day'
      WHEN 'WEEKLY' THEN r.next_execution_date + INTERVAL '7 days'
      WHEN 'MONTHLY' THEN r.next_execution_date + INTERVAL '1 month'
      WHEN 'YEARLY' THEN r.next_execution_date + INTERVAL '1 year'
    END;

    UPDATE public.recurring_transactions
    SET last_executed_on = r.next_execution_date,
        next_execution_date = v_next::date
    WHERE id = r.id;

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

-- ---------------------------------------------------------------------------
-- Public RPC wrappers
-- ---------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.create_transaction(uuid, text, numeric, text, uuid);

CREATE OR REPLACE FUNCTION public.create_transaction(
  p_wallet_id uuid,
  p_type text,
  p_amount numeric,
  p_description text DEFAULT NULL,
  p_category_id uuid DEFAULT NULL,
  p_merchant text DEFAULT NULL,
  p_transaction_date timestamptz DEFAULT now(),
  p_latitude numeric DEFAULT NULL,
  p_longitude numeric DEFAULT NULL,
  p_tag_ids uuid[] DEFAULT NULL,
  p_client_request_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN app_private.create_transaction(
    auth.uid(),
    p_wallet_id,
    p_type,
    p_amount,
    p_description,
    p_category_id,
    p_merchant,
    p_transaction_date,
    p_latitude,
    p_longitude,
    p_tag_ids,
    p_client_request_id
  );
END;
$$;

DROP FUNCTION IF EXISTS public.transfer_money(uuid, uuid, numeric, text);

CREATE OR REPLACE FUNCTION public.transfer_money(
  p_from_wallet uuid,
  p_to_wallet uuid,
  p_amount numeric,
  p_description text DEFAULT NULL,
  p_client_request_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN app_private.transfer_money(
    auth.uid(),
    p_from_wallet,
    p_to_wallet,
    p_amount,
    p_description,
    p_client_request_id
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.void_transaction(
  p_transaction_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN app_private.void_transaction(auth.uid(), p_transaction_id, p_reason);
END;
$$;

REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO postgres, service_role;
DO $grant$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
    GRANT EXECUTE ON FUNCTION public.handle_new_user() TO supabase_auth_admin;
  END IF;
END
$grant$;

REVOKE ALL ON FUNCTION public.create_transaction(uuid, text, numeric, text, uuid, text, timestamptz, numeric, numeric, uuid[], uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_transaction(uuid, text, numeric, text, uuid, text, timestamptz, numeric, numeric, uuid[], uuid) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.transfer_money(uuid, uuid, numeric, text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.transfer_money(uuid, uuid, numeric, text, uuid) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.void_transaction(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.void_transaction(uuid, text) TO authenticated, service_role;

REVOKE ALL ON FUNCTION app_private.process_due_recurring_transactions() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION app_private.process_due_recurring_transactions() TO postgres, service_role;

REVOKE ALL ON FUNCTION app_private.create_transaction(uuid, uuid, text, numeric, text, uuid, text, timestamptz, numeric, numeric, uuid[], uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION app_private.transfer_money(uuid, uuid, uuid, numeric, text, uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION app_private.void_transaction(uuid, uuid, text) FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Grants: ledger is RPC-only
-- ---------------------------------------------------------------------------
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.wallet_movements FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.transactions FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.transfers FROM anon, authenticated;
GRANT SELECT ON public.wallet_movements TO authenticated;
GRANT SELECT ON public.transactions TO authenticated;
GRANT SELECT ON public.transfers TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.recurring_executions TO authenticated;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
ALTER TABLE public.recurring_executions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Own recurring executions" ON public.recurring_executions;
CREATE POLICY "Own recurring executions"
  ON public.recurring_executions
  FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Own receipts write" ON public.receipts;
DROP POLICY IF EXISTS "Own receipts insert" ON public.receipts;
DROP POLICY IF EXISTS "Own receipts update" ON public.receipts;
CREATE POLICY "Own receipts insert"
  ON public.receipts
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Own receipts update"
  ON public.receipts
  FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Own AI write" ON public.ai_classifications;
DROP POLICY IF EXISTS "Own AI insert" ON public.ai_classifications;
DROP POLICY IF EXISTS "Own AI update" ON public.ai_classifications;
CREATE POLICY "Own AI insert"
  ON public.ai_classifications
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Own AI update"
  ON public.ai_classifications
  FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Own transaction tags write" ON public.transaction_tags;
DROP POLICY IF EXISTS "Own transaction tags insert" ON public.transaction_tags;
DROP POLICY IF EXISTS "Own transaction tags delete" ON public.transaction_tags;
CREATE POLICY "Own transaction tags insert"
  ON public.transaction_tags
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.transactions t
      WHERE t.id = transaction_id AND t.user_id = (SELECT auth.uid())
    )
    AND EXISTS (
      SELECT 1 FROM public.tags g
      WHERE g.id = tag_id AND g.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Own transaction tags delete"
  ON public.transaction_tags
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.transactions t
      WHERE t.id = transaction_id AND t.user_id = (SELECT auth.uid())
    )
  );

-- ---------------------------------------------------------------------------
-- Global categories (idempotent)
-- ---------------------------------------------------------------------------
INSERT INTO public.categories (id, user_id, name, parent_id, icon, color)
SELECT gen_random_uuid(), NULL, seed.name, NULL, seed.icon, seed.color
FROM (VALUES
  ('Food', 'restaurant', '#F97316'),
  ('Shopping', 'shopping_bag', '#8B5CF6'),
  ('Transport', 'directions_car', '#0EA5E9'),
  ('Housing', 'home', '#6366F1'),
  ('Health', 'favorite', '#EF4444'),
  ('Entertainment', 'movie', '#EC4899'),
  ('Income', 'payments', '#10B981'),
  ('Savings', 'savings', '#14B8A6')
) AS seed(name, icon, color)
WHERE NOT EXISTS (
  SELECT 1 FROM public.categories c
  WHERE c.user_id IS NULL AND c.parent_id IS NULL AND c.name = seed.name
);

INSERT INTO public.categories (user_id, name, parent_id, icon, color)
SELECT NULL, child.name, parent.id, child.icon, parent.color
FROM public.categories parent
JOIN (VALUES
  ('Food', 'Restaurants', 'restaurant'),
  ('Food', 'Groceries', 'local_grocery_store'),
  ('Food', 'Coffee', 'local_cafe'),
  ('Shopping', 'Clothes', 'checkroom'),
  ('Shopping', 'Electronics', 'devices'),
  ('Shopping', 'Supermarket', 'storefront'),
  ('Transport', 'Fuel', 'local_gas_station'),
  ('Transport', 'Taxi', 'local_taxi'),
  ('Transport', 'Public Transport', 'directions_bus'),
  ('Housing', 'Rent', 'apartment'),
  ('Housing', 'Electricity', 'bolt'),
  ('Housing', 'Water', 'water_drop'),
  ('Housing', 'Internet', 'wifi'),
  ('Health', 'Pharmacy', 'local_pharmacy'),
  ('Health', 'Doctor', 'medical_services'),
  ('Entertainment', 'Cinema', 'theaters'),
  ('Entertainment', 'Games', 'sports_esports'),
  ('Entertainment', 'Subscriptions', 'subscriptions'),
  ('Income', 'Salary', 'work'),
  ('Income', 'Freelance', 'computer'),
  ('Income', 'Gift', 'card_giftcard'),
  ('Savings', 'Savings', 'savings'),
  ('Savings', 'Investments', 'trending_up')
) AS child(parent_name, name, icon) ON parent.name = child.parent_name
WHERE parent.user_id IS NULL AND parent.parent_id IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.categories c
    WHERE c.user_id IS NULL AND c.parent_id = parent.id AND c.name = child.name
  );

-- ---------------------------------------------------------------------------
-- Storage bucket
-- ---------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'receipts',
  'receipts',
  false,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Users read own receipts" ON storage.objects;
DROP POLICY IF EXISTS "Users upload own receipts" ON storage.objects;
DROP POLICY IF EXISTS "Users update own receipts" ON storage.objects;
DROP POLICY IF EXISTS "Users delete own receipts" ON storage.objects;

CREATE POLICY "Users read own receipts"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'receipts' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);

CREATE POLICY "Users upload own receipts"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'receipts' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);

CREATE POLICY "Users update own receipts"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'receipts' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text)
  WITH CHECK (bucket_id = 'receipts' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);

CREATE POLICY "Users delete own receipts"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'receipts' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);

COMMIT;
