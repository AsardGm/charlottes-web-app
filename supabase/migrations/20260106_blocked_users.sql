-- Migrace: Vytvoreni tabulky blocked_users pro blokovani uzivatelu
-- Datum: 2026-01-06
-- Popis: Umoznuje uzivatelum blokovat jine uzivatele

-- Tabulka pro blokovani uzivatelu
CREATE TABLE IF NOT EXISTS public.blocked_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    blocker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Jeden uzivatel muze blokovat jineho jen jednou
    UNIQUE(blocker_id, blocked_id),

    -- Uzivatel nemuze blokovat sam sebe
    CHECK (blocker_id != blocked_id)
);

-- Indexy pro rychlejsi dotazy
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker
    ON public.blocked_users(blocker_id);

CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked
    ON public.blocked_users(blocked_id);

-- RLS politiky
ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

-- Uzivatel vidi sve vlastni bloky
CREATE POLICY "Users can view own blocks" ON public.blocked_users
    FOR SELECT
    USING (auth.uid() = blocker_id);

-- Uzivatel muze vytvorit blok
CREATE POLICY "Users can create blocks" ON public.blocked_users
    FOR INSERT
    WITH CHECK (auth.uid() = blocker_id);

-- Uzivatel muze smazat svuj blok (odblokovat)
CREATE POLICY "Users can delete own blocks" ON public.blocked_users
    FOR DELETE
    USING (auth.uid() = blocker_id);

-- Funkce pro kontrolu, jestli je uzivatel zablokovany
CREATE OR REPLACE FUNCTION is_blocked(checker_id UUID, target_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.blocked_users
        WHERE blocker_id = checker_id AND blocked_id = target_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funkce pro kontrolu vzajemneho blokovani (at uz me zablokoval on nebo ja jeho)
CREATE OR REPLACE FUNCTION is_mutually_blocked(user1_id UUID, user2_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.blocked_users
        WHERE (blocker_id = user1_id AND blocked_id = user2_id)
           OR (blocker_id = user2_id AND blocked_id = user1_id)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Komentar k tabulce
COMMENT ON TABLE public.blocked_users IS 'Tabulka pro blokovani uzivatelu';
COMMENT ON COLUMN public.blocked_users.blocker_id IS 'ID uzivatele, ktery blokuje';
COMMENT ON COLUMN public.blocked_users.blocked_id IS 'ID zablokovaného uzivatele';
