-- =====================================================
-- THREAD TYPES & STATES SCHEMA
-- Reddit-style + CRM komunita
-- =====================================================

-- Typy vláken
CREATE TABLE IF NOT EXISTS public.thread_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    icon TEXT NOT NULL,
    color TEXT NOT NULL,
    -- Které role mohou vytvářet tento typ
    allowed_roles TEXT[] NOT NULL DEFAULT ARRAY['member', 'core', 'admin'],
    -- Zda tento typ může mít stav "vyřešeno"
    can_be_resolved BOOLEAN NOT NULL DEFAULT false,
    -- Zda tento typ může mít deadline
    has_deadline BOOLEAN NOT NULL DEFAULT false,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Výchozí typy vláken
INSERT INTO public.thread_types (name, slug, description, icon, color, allowed_roles, can_be_resolved, has_deadline, sort_order) VALUES
    ('Diskuze', 'discussion', 'Obecná diskuze a konverzace', 'forum', '#8B5CF6', ARRAY['member', 'core', 'admin'], false, false, 1),
    ('Otázka', 'question', 'Otázky s možností označení nejlepší odpovědi', 'help', '#3B82F6', ARRAY['member', 'core', 'admin'], true, false, 2),
    ('Případ', 'case', 'Problémy a případy k řešení', 'build', '#F59E0B', ARRAY['core', 'admin'], true, true, 3),
    ('Návrh', 'proposal', 'Návrhy a nápady ke schválení', 'lightbulb', '#22C55E', ARRAY['member', 'core', 'admin'], true, false, 4),
    ('Oznámení', 'announcement', 'Důležitá oznámení od administrátorů', 'campaign', '#EF4444', ARRAY['admin'], false, false, 5)
ON CONFLICT (slug) DO NOTHING;

-- Přidat nové sloupce do posts tabulky
ALTER TABLE public.posts
ADD COLUMN IF NOT EXISTS thread_type_id UUID REFERENCES public.thread_types(id),
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved', 'locked')),
ADD COLUMN IF NOT EXISTS deadline TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS resolved_by UUID REFERENCES public.profiles(id),
ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS view_count INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS accepted_comment_id UUID;

-- Index pro rychlejší filtrování
CREATE INDEX IF NOT EXISTS idx_posts_thread_type ON public.posts(thread_type_id);
CREATE INDEX IF NOT EXISTS idx_posts_status ON public.posts(status);
CREATE INDEX IF NOT EXISTS idx_posts_deadline ON public.posts(deadline) WHERE deadline IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_posts_is_pinned ON public.posts(is_pinned) WHERE is_pinned = true;

-- RLS policies pro thread_types
ALTER TABLE public.thread_types ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Thread types jsou veřejně čitelné" ON public.thread_types;
CREATE POLICY "Thread types jsou veřejně čitelné" ON public.thread_types
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Pouze admini mohou upravovat thread types" ON public.thread_types;
CREATE POLICY "Pouze admini mohou upravovat thread types" ON public.thread_types
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Funkce pro aktualizaci view_count
CREATE OR REPLACE FUNCTION increment_view_count(post_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.posts
    SET view_count = view_count + 1
    WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funkce pro označení příspěvku jako vyřešeného
CREATE OR REPLACE FUNCTION resolve_post(post_id UUID, resolver_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.posts
    SET status = 'resolved',
        resolved_at = now(),
        resolved_by = resolver_id
    WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funkce pro přijetí komentáře jako nejlepší odpovědi
CREATE OR REPLACE FUNCTION accept_answer(post_id UUID, comment_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.posts
    SET accepted_comment_id = comment_id,
        status = 'resolved',
        resolved_at = now(),
        resolved_by = auth.uid()
    WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
