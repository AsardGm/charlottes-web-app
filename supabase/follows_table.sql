-- Tabulka pro sledování uživatelů (follows)
-- Spusťte tento SQL v Supabase SQL Editoru

-- 1. Vytvoření tabulky follows
CREATE TABLE IF NOT EXISTS public.follows (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Unikátní kombinace - uživatel může sledovat jiného jen jednou
    UNIQUE(follower_id, following_id),

    -- Uživatel nemůže sledovat sám sebe
    CHECK (follower_id != following_id)
);

-- 2. Indexy pro rychlé vyhledávání
CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON public.follows(following_id);

-- 3. RLS politiky
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

-- Každý může vidět kdo koho sleduje
CREATE POLICY "Follows jsou veřejné" ON public.follows
    FOR SELECT USING (true);

-- Uživatel může přidat sledování pouze za sebe
CREATE POLICY "Uživatel může sledovat" ON public.follows
    FOR INSERT WITH CHECK (auth.uid() = follower_id);

-- Uživatel může zrušit pouze své sledování
CREATE POLICY "Uživatel může přestat sledovat" ON public.follows
    FOR DELETE USING (auth.uid() = follower_id);

-- 4. Přidání sloupců do profiles pro počty (volitelné - pro rychlejší zobrazení)
-- Pokud chcete mít počty přímo v profiles tabulce:

-- ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS follower_count INTEGER DEFAULT 0;
-- ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS following_count INTEGER DEFAULT 0;
-- ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS post_count INTEGER DEFAULT 0;

-- 5. Trigger pro aktualizaci počtů (volitelné)
-- CREATE OR REPLACE FUNCTION update_follow_counts()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     IF TG_OP = 'INSERT' THEN
--         UPDATE profiles SET follower_count = follower_count + 1 WHERE id = NEW.following_id;
--         UPDATE profiles SET following_count = following_count + 1 WHERE id = NEW.follower_id;
--     ELSIF TG_OP = 'DELETE' THEN
--         UPDATE profiles SET follower_count = follower_count - 1 WHERE id = OLD.following_id;
--         UPDATE profiles SET following_count = following_count - 1 WHERE id = OLD.follower_id;
--     END IF;
--     RETURN NULL;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER on_follow_change
-- AFTER INSERT OR DELETE ON public.follows
-- FOR EACH ROW EXECUTE FUNCTION update_follow_counts();

-- Hotovo! Po spuštění tohoto SQL bude fungovat tlačítko Sledovat.
