-- =====================================================
-- EXTENDED FEATURES - Notifikace, Bookmarky, Tagy, Follow
-- =====================================================

-- =====================================================
-- NOTIFICATIONS - In-app notifikace
-- =====================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    -- Typ notifikace
    type TEXT NOT NULL CHECK (type IN (
        'like', 'comment', 'mention', 'follow',
        'reply', 'post', 'system', 'chat'
    )),
    -- Reference na související objekty
    actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    -- Obsah notifikace
    title TEXT NOT NULL,
    body TEXT,
    -- Metadata (např. pro deep linking)
    data JSONB DEFAULT '{}',
    -- Stav
    is_read BOOLEAN NOT NULL DEFAULT false,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(user_id) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_notifications_created ON public.notifications(created_at DESC);

-- =====================================================
-- BOOKMARKS - Uložené příspěvky
-- =====================================================
CREATE TABLE IF NOT EXISTS public.bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON public.bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_post ON public.bookmarks(post_id);

-- =====================================================
-- TAGS - Tagy/Hashtags
-- =====================================================
CREATE TABLE IF NOT EXISTS public.tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    post_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.post_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES public.tags(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(post_id, tag_id)
);

CREATE INDEX IF NOT EXISTS idx_tags_name ON public.tags(name);
CREATE INDEX IF NOT EXISTS idx_tags_slug ON public.tags(slug);
CREATE INDEX IF NOT EXISTS idx_post_tags_post ON public.post_tags(post_id);
CREATE INDEX IF NOT EXISTS idx_post_tags_tag ON public.post_tags(tag_id);

-- =====================================================
-- FOLLOWS - Sledování uživatelů
-- =====================================================
CREATE TABLE IF NOT EXISTS public.follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(follower_id, following_id),
    CHECK (follower_id != following_id)
);

CREATE INDEX IF NOT EXISTS idx_follows_follower ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON public.follows(following_id);

-- =====================================================
-- PROFILE EXTENSIONS - Rozšíření profilu
-- =====================================================
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS bio TEXT,
    ADD COLUMN IF NOT EXISTS website TEXT,
    ADD COLUMN IF NOT EXISTS location TEXT,
    ADD COLUMN IF NOT EXISTS follower_count INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS following_count INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS post_count INTEGER NOT NULL DEFAULT 0;

-- =====================================================
-- USER SETTINGS - Nastavení uživatele
-- =====================================================
CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
    -- Theme
    theme TEXT NOT NULL DEFAULT 'dark' CHECK (theme IN ('dark', 'light', 'system')),
    -- Notifikace
    notifications_enabled BOOLEAN NOT NULL DEFAULT true,
    email_notifications BOOLEAN NOT NULL DEFAULT false,
    -- Soukromí
    show_online_status BOOLEAN NOT NULL DEFAULT true,
    allow_messages_from TEXT NOT NULL DEFAULT 'everyone' CHECK (allow_messages_from IN ('everyone', 'followers', 'nobody')),
    -- Ostatní
    language TEXT NOT NULL DEFAULT 'cs',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================

-- Notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "System can create notifications" ON public.notifications;
CREATE POLICY "System can create notifications" ON public.notifications
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;
CREATE POLICY "Users can delete own notifications" ON public.notifications
    FOR DELETE USING (user_id = auth.uid());

-- Bookmarks
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own bookmarks" ON public.bookmarks;
CREATE POLICY "Users can view own bookmarks" ON public.bookmarks
    FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can create own bookmarks" ON public.bookmarks;
CREATE POLICY "Users can create own bookmarks" ON public.bookmarks
    FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own bookmarks" ON public.bookmarks;
CREATE POLICY "Users can delete own bookmarks" ON public.bookmarks
    FOR DELETE USING (user_id = auth.uid());

-- Tags
ALTER TABLE public.tags ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view tags" ON public.tags;
CREATE POLICY "Anyone can view tags" ON public.tags
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can create tags" ON public.tags;
CREATE POLICY "Authenticated users can create tags" ON public.tags
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Post tags
ALTER TABLE public.post_tags ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view post tags" ON public.post_tags;
CREATE POLICY "Anyone can view post tags" ON public.post_tags
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Post authors can manage tags" ON public.post_tags;
CREATE POLICY "Post authors can manage tags" ON public.post_tags
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.posts WHERE id = post_id AND author_id = auth.uid())
    );

-- Follows
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view follows" ON public.follows;
CREATE POLICY "Anyone can view follows" ON public.follows
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage own follows" ON public.follows;
CREATE POLICY "Users can manage own follows" ON public.follows
    FOR ALL USING (follower_id = auth.uid());

-- User settings
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own settings" ON public.user_settings;
CREATE POLICY "Users can view own settings" ON public.user_settings
    FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can manage own settings" ON public.user_settings;
CREATE POLICY "Users can manage own settings" ON public.user_settings
    FOR ALL USING (user_id = auth.uid());

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Funkce pro vytvoření notifikace
CREATE OR REPLACE FUNCTION create_notification(
    p_user_id UUID,
    p_type TEXT,
    p_title TEXT,
    p_body TEXT DEFAULT NULL,
    p_actor_id UUID DEFAULT NULL,
    p_post_id UUID DEFAULT NULL,
    p_comment_id UUID DEFAULT NULL,
    p_data JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    notification_id UUID;
BEGIN
    -- Nevytvářej notifikaci pro sebe
    IF p_user_id = p_actor_id THEN
        RETURN NULL;
    END IF;

    INSERT INTO public.notifications (
        user_id, type, title, body, actor_id, post_id, comment_id, data
    ) VALUES (
        p_user_id, p_type, p_title, p_body, p_actor_id, p_post_id, p_comment_id, p_data
    ) RETURNING id INTO notification_id;

    RETURN notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pro notifikaci při reakci
CREATE OR REPLACE FUNCTION notify_on_reaction()
RETURNS TRIGGER AS $$
DECLARE
    post_author_id UUID;
    actor_username TEXT;
BEGIN
    -- Získej autora příspěvku
    SELECT author_id INTO post_author_id FROM public.posts WHERE id = NEW.post_id;
    SELECT username INTO actor_username FROM public.profiles WHERE id = NEW.user_id;

    -- Vytvoř notifikaci
    PERFORM create_notification(
        post_author_id,
        'like',
        actor_username || ' reagoval na tvuj prispevek',
        NULL,
        NEW.user_id,
        NEW.post_id
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notify_on_reaction ON public.reactions;
CREATE TRIGGER trigger_notify_on_reaction
    AFTER INSERT ON public.reactions
    FOR EACH ROW
    EXECUTE FUNCTION notify_on_reaction();

-- Trigger pro notifikaci při komentáři
CREATE OR REPLACE FUNCTION notify_on_comment()
RETURNS TRIGGER AS $$
DECLARE
    post_author_id UUID;
    actor_username TEXT;
BEGIN
    SELECT author_id INTO post_author_id FROM public.posts WHERE id = NEW.post_id;
    SELECT username INTO actor_username FROM public.profiles WHERE id = NEW.author_id;

    PERFORM create_notification(
        post_author_id,
        'comment',
        actor_username || ' okomentoval tvuj prispevek',
        LEFT(NEW.content, 100),
        NEW.author_id,
        NEW.post_id,
        NEW.id
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notify_on_comment ON public.comments;
CREATE TRIGGER trigger_notify_on_comment
    AFTER INSERT ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION notify_on_comment();

-- Trigger pro notifikaci při follow
CREATE OR REPLACE FUNCTION notify_on_follow()
RETURNS TRIGGER AS $$
DECLARE
    actor_username TEXT;
BEGIN
    SELECT username INTO actor_username FROM public.profiles WHERE id = NEW.follower_id;

    PERFORM create_notification(
        NEW.following_id,
        'follow',
        actor_username || ' te zacal sledovat',
        NULL,
        NEW.follower_id
    );

    -- Aktualizuj počítadla
    UPDATE public.profiles SET follower_count = follower_count + 1 WHERE id = NEW.following_id;
    UPDATE public.profiles SET following_count = following_count + 1 WHERE id = NEW.follower_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notify_on_follow ON public.follows;
CREATE TRIGGER trigger_notify_on_follow
    AFTER INSERT ON public.follows
    FOR EACH ROW
    EXECUTE FUNCTION notify_on_follow();

-- Trigger pro unfollow (aktualizace počítadel)
CREATE OR REPLACE FUNCTION update_on_unfollow()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.profiles SET follower_count = GREATEST(0, follower_count - 1) WHERE id = OLD.following_id;
    UPDATE public.profiles SET following_count = GREATEST(0, following_count - 1) WHERE id = OLD.follower_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_on_unfollow ON public.follows;
CREATE TRIGGER trigger_update_on_unfollow
    AFTER DELETE ON public.follows
    FOR EACH ROW
    EXECUTE FUNCTION update_on_unfollow();

-- Funkce pro aktualizaci počtu tagů
CREATE OR REPLACE FUNCTION update_tag_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.tags SET post_count = post_count + 1 WHERE id = NEW.tag_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.tags SET post_count = GREATEST(0, post_count - 1) WHERE id = OLD.tag_id;
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_tag_count ON public.post_tags;
CREATE TRIGGER trigger_update_tag_count
    AFTER INSERT OR DELETE ON public.post_tags
    FOR EACH ROW
    EXECUTE FUNCTION update_tag_count();

-- Funkce pro získání nebo vytvoření tagu
CREATE OR REPLACE FUNCTION get_or_create_tag(tag_name TEXT)
RETURNS UUID AS $$
DECLARE
    tag_id UUID;
    tag_slug TEXT;
BEGIN
    tag_slug := LOWER(REGEXP_REPLACE(tag_name, '[^a-zA-Z0-9]', '', 'g'));

    SELECT id INTO tag_id FROM public.tags WHERE slug = tag_slug;

    IF tag_id IS NULL THEN
        INSERT INTO public.tags (name, slug)
        VALUES (tag_name, tag_slug)
        RETURNING id INTO tag_id;
    END IF;

    RETURN tag_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Realtime pro notifikace
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- =====================================================
-- VERIFICATION
-- =====================================================
-- SELECT * FROM notifications LIMIT 10;
-- SELECT * FROM bookmarks LIMIT 10;
-- SELECT * FROM tags ORDER BY post_count DESC LIMIT 10;
-- SELECT * FROM follows LIMIT 10;
