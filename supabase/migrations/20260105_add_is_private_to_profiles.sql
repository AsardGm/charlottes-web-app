-- Migrace: Pridani sloupce is_private do tabulky profiles
-- Datum: 2026-01-05
-- Popis: Umoznuje uzivatelum nastavit soukromy ucet

-- Pridani sloupce is_private
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false;

-- Vytvoreni indexu pro rychlejsi dotazy
CREATE INDEX IF NOT EXISTS idx_profiles_is_private ON public.profiles(is_private);

-- Komentar ke sloupci
COMMENT ON COLUMN public.profiles.is_private IS 'Urcuje, zda je ucet soukromy (true = soukromy, false = verejny)';
