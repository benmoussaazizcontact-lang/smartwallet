-- Race-safe idempotency for create_transaction and one receipt row per transaction.
-- Additive: no table drops, no RLS changes, existing rows are kept.

BEGIN;

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

  BEGIN
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
  EXCEPTION
    WHEN unique_violation THEN
      SELECT id INTO v_transaction_id
      FROM public.transactions
      WHERE user_id = p_user_id
        AND client_request_id = p_client_request_id;
      IF v_transaction_id IS NOT NULL THEN
        RETURN v_transaction_id;
      END IF;
      RAISE;
  END;

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

REVOKE ALL ON FUNCTION app_private.create_transaction(uuid, uuid, text, numeric, text, uuid, text, timestamptz, numeric, numeric, uuid[], uuid) FROM PUBLIC, anon, authenticated;

CREATE UNIQUE INDEX IF NOT EXISTS receipts_user_transaction_uidx
  ON public.receipts (user_id, transaction_id)
  WHERE transaction_id IS NOT NULL;

COMMIT;
