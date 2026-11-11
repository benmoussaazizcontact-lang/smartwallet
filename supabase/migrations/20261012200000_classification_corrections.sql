-- Additive: store user category corrections for future local suggestions.
-- Never rewrite historical transactions.

ALTER TABLE public.ai_classifications
  ADD COLUMN IF NOT EXISTS actual_category_id uuid REFERENCES public.categories (id),
  ADD COLUMN IF NOT EXISTS merchant_key text,
  ADD COLUMN IF NOT EXISTS was_corrected boolean NOT NULL DEFAULT false;

CREATE TABLE IF NOT EXISTS public.classification_corrections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  merchant_key text NOT NULL,
  category_id uuid NOT NULL REFERENCES public.categories (id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, merchant_key)
);

ALTER TABLE public.classification_corrections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Own classification corrections" ON public.classification_corrections;
CREATE POLICY "Own classification corrections"
  ON public.classification_corrections
  FOR ALL
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.classification_corrections TO authenticated;
