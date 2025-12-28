-- =============================================
-- Charlotte's Web - Categories (Channels/Threads)
-- =============================================
-- Spust tento SQL pro pridani kategorii/vlaken

-- =============================================
-- CATEGORIES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    icon TEXT NOT NULL DEFAULT 'forum',
    color TEXT NOT NULL DEFAULT '#8B5CF6',
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Categories policies
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON public.categories;
CREATE POLICY "Categories are viewable by everyone"
    ON public.categories FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Only admins can manage categories" ON public.categories;
CREATE POLICY "Only admins can manage categories"
    ON public.categories FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- =============================================
-- ADD CATEGORY TO POSTS
-- =============================================
ALTER TABLE public.posts
ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL;

-- Index for faster category filtering
CREATE INDEX IF NOT EXISTS idx_posts_category_id ON public.posts(category_id);

-- =============================================
-- INSERT DEFAULT CATEGORIES
-- =============================================
INSERT INTO public.categories (name, slug, description, icon, color, sort_order) VALUES
    ('Blog', 'blog', 'Clanky a novinky od tymu', 'article', '#3B82F6', 1),
    ('Komunita', 'komunita', 'Diskuze a prispevky od clenu', 'forum', '#22C55E', 2),
    ('Info', 'info', 'Dulezite informace a oznameni', 'info', '#F59E0B', 3),
    ('Zajimavosti', 'zajimavosti', 'Tipy, triky a zajimave clanky', 'lightbulb', '#EC4899', 4)
ON CONFLICT (slug) DO NOTHING;

-- =============================================
-- UPDATE EXISTING POSTS (optional - set default category)
-- =============================================
-- UPDATE public.posts SET category_id = (SELECT id FROM categories WHERE slug = 'komunita') WHERE category_id IS NULL;

-- =============================================
-- VERIFICATION
-- =============================================
-- SELECT * FROM categories ORDER BY sort_order;
-- SELECT p.*, c.name as category_name FROM posts p LEFT JOIN categories c ON p.category_id = c.id;
