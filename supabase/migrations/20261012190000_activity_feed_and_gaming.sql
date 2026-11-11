-- Additive: unified activity feed for chronological pagination of
-- transactions + transfers, and Entertainment > Gaming subcategory.

CREATE OR REPLACE VIEW public.activity_feed
WITH (security_invoker = true) AS
SELECT
  t.id,
  t.user_id,
  t.wallet_id,
  t.transaction_type,
  t.amount,
  t.currency,
  t.description,
  t.merchant,
  t.category_id,
  c.name AS category_name,
  t.transaction_date,
  t.status,
  t.latitude,
  t.longitude
FROM public.transactions t
LEFT JOIN public.categories c ON c.id = t.category_id
UNION ALL
SELECT
  tr.id,
  tr.user_id,
  tr.from_wallet_id,
  'TRANSFER_OUT',
  tr.amount,
  tr.currency,
  COALESCE(tr.description, 'Transfer'),
  NULL,
  NULL,
  NULL,
  tr.created_at,
  'POSTED',
  NULL,
  NULL
FROM public.transfers tr
UNION ALL
SELECT
  tr.id,
  tr.user_id,
  tr.to_wallet_id,
  'TRANSFER',
  tr.amount,
  tr.currency,
  COALESCE(tr.description, 'Transfer'),
  NULL,
  NULL,
  NULL,
  tr.created_at,
  'POSTED',
  NULL,
  NULL
FROM public.transfers tr;

GRANT SELECT ON public.activity_feed TO authenticated;

-- Make the view available immediately to the Supabase Data API/PostgREST.
NOTIFY pgrst, 'reload schema';

INSERT INTO public.categories (user_id, name, parent_id, icon, color)
SELECT NULL, 'Gaming', parent.id, 'sports_esports', parent.color
FROM public.categories parent
WHERE parent.user_id IS NULL
  AND parent.parent_id IS NULL
  AND parent.name = 'Entertainment'
  AND NOT EXISTS (
    SELECT 1 FROM public.categories c
    WHERE c.user_id IS NULL AND c.parent_id = parent.id AND c.name = 'Gaming'
  );
