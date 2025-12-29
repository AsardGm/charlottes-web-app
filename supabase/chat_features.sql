-- =====================================================
-- ADVANCED CHAT FEATURES
-- Připnuté zprávy, ankety, přeposílání, archivace
-- =====================================================

-- =====================================================
-- PINNED MESSAGES - Připnuté zprávy
-- =====================================================
CREATE TABLE IF NOT EXISTS public.pinned_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    pinned_by UUID NOT NULL REFERENCES public.profiles(id),
    pinned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(conversation_id, message_id)
);

ALTER TABLE public.pinned_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants can view pinned" ON public.pinned_messages;
CREATE POLICY "Participants can view pinned" ON public.pinned_messages
    FOR SELECT USING (
        conversation_id IN (SELECT get_user_conversation_ids(auth.uid()))
    );

DROP POLICY IF EXISTS "Participants can pin messages" ON public.pinned_messages;
CREATE POLICY "Participants can pin messages" ON public.pinned_messages
    FOR INSERT WITH CHECK (
        conversation_id IN (SELECT get_user_conversation_ids(auth.uid()))
    );

DROP POLICY IF EXISTS "Participants can unpin messages" ON public.pinned_messages;
CREATE POLICY "Participants can unpin messages" ON public.pinned_messages
    FOR DELETE USING (
        conversation_id IN (SELECT get_user_conversation_ids(auth.uid()))
    );

CREATE INDEX IF NOT EXISTS idx_pinned_messages_conversation ON public.pinned_messages(conversation_id);

-- =====================================================
-- POLLS - Ankety/Hlasování
-- =====================================================
CREATE TABLE IF NOT EXISTS public.polls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    message_id UUID REFERENCES public.messages(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES public.profiles(id),
    question TEXT NOT NULL,
    -- Typ: 'single' = jedna odpověď, 'multiple' = více odpovědí
    poll_type TEXT NOT NULL DEFAULT 'single' CHECK (poll_type IN ('single', 'multiple')),
    -- Nastavení
    is_anonymous BOOLEAN NOT NULL DEFAULT false,
    allows_add_options BOOLEAN NOT NULL DEFAULT false,
    expires_at TIMESTAMPTZ,
    is_closed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.poll_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    poll_id UUID NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    added_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.poll_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    poll_id UUID NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES public.poll_options(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(poll_id, option_id, user_id)
);

ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;

-- Polls policies
DROP POLICY IF EXISTS "Participants can view polls" ON public.polls;
CREATE POLICY "Participants can view polls" ON public.polls
    FOR SELECT USING (
        conversation_id IN (SELECT get_user_conversation_ids(auth.uid()))
    );

DROP POLICY IF EXISTS "Participants can create polls" ON public.polls;
CREATE POLICY "Participants can create polls" ON public.polls
    FOR INSERT WITH CHECK (
        created_by = auth.uid() AND
        conversation_id IN (SELECT get_user_conversation_ids(auth.uid()))
    );

DROP POLICY IF EXISTS "Creator can update polls" ON public.polls;
CREATE POLICY "Creator can update polls" ON public.polls
    FOR UPDATE USING (created_by = auth.uid());

-- Poll options policies
DROP POLICY IF EXISTS "Participants can view options" ON public.poll_options;
CREATE POLICY "Participants can view options" ON public.poll_options
    FOR SELECT USING (
        poll_id IN (
            SELECT id FROM public.polls
            WHERE conversation_id IN (SELECT get_user_conversation_ids(auth.uid()))
        )
    );

DROP POLICY IF EXISTS "Can add options" ON public.poll_options;
CREATE POLICY "Can add options" ON public.poll_options
    FOR INSERT WITH CHECK (
        poll_id IN (
            SELECT id FROM public.polls
            WHERE conversation_id IN (SELECT get_user_conversation_ids(auth.uid()))
            AND (created_by = auth.uid() OR allows_add_options = true)
        )
    );

-- Poll votes policies
DROP POLICY IF EXISTS "Participants can view votes" ON public.poll_votes;
CREATE POLICY "Participants can view votes" ON public.poll_votes
    FOR SELECT USING (
        poll_id IN (
            SELECT id FROM public.polls
            WHERE conversation_id IN (SELECT get_user_conversation_ids(auth.uid()))
        )
    );

DROP POLICY IF EXISTS "Participants can vote" ON public.poll_votes;
CREATE POLICY "Participants can vote" ON public.poll_votes
    FOR INSERT WITH CHECK (
        user_id = auth.uid() AND
        poll_id IN (
            SELECT id FROM public.polls
            WHERE conversation_id IN (SELECT get_user_conversation_ids(auth.uid()))
            AND is_closed = false
        )
    );

DROP POLICY IF EXISTS "Users can remove own votes" ON public.poll_votes;
CREATE POLICY "Users can remove own votes" ON public.poll_votes
    FOR DELETE USING (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_polls_conversation ON public.polls(conversation_id);
CREATE INDEX IF NOT EXISTS idx_poll_options_poll ON public.poll_options(poll_id);
CREATE INDEX IF NOT EXISTS idx_poll_votes_poll ON public.poll_votes(poll_id);
CREATE INDEX IF NOT EXISTS idx_poll_votes_option ON public.poll_votes(option_id);

-- =====================================================
-- ARCHIVED CONVERSATIONS - Archivované konverzace
-- =====================================================
ALTER TABLE public.conversation_participants
    ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;

-- =====================================================
-- MESSAGE FORWARDING - Přeposílání zpráv
-- =====================================================
-- Již existuje v messages tabulce: forwarded_from_id
-- Přidáme sloupec pro původní odesílatele
ALTER TABLE public.messages
    ADD COLUMN IF NOT EXISTS original_sender_id UUID REFERENCES public.profiles(id);

-- =====================================================
-- VOICE MESSAGES STORAGE
-- =====================================================
-- Storage bucket: voice-messages (nutno vytvořit v Supabase Dashboard)
-- message_type = 'voice' s metadata: { duration: seconds, waveform: [...] }

-- =====================================================
-- FILE ATTACHMENTS STORAGE
-- =====================================================
-- Storage bucket: chat-files (nutno vytvořit v Supabase Dashboard)
-- message_type = 'file' s metadata: { file_name, file_size, mime_type }

-- =====================================================
-- LOCATION MESSAGES
-- =====================================================
-- message_type = 'location' s metadata: { latitude, longitude, address }

-- =====================================================
-- REALTIME SUBSCRIPTIONS
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'pinned_messages'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.pinned_messages;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'polls'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.polls;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'poll_votes'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.poll_votes;
    END IF;
END $$;

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Funkce pro získání počtu hlasů pro možnost
CREATE OR REPLACE FUNCTION get_poll_option_votes(option_uuid UUID)
RETURNS INTEGER AS $$
    SELECT COUNT(*)::INTEGER FROM public.poll_votes WHERE option_id = option_uuid;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Funkce pro kontrolu, zda uživatel hlasoval
CREATE OR REPLACE FUNCTION has_user_voted(poll_uuid UUID, option_uuid UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.poll_votes
        WHERE poll_id = poll_uuid AND option_id = option_uuid AND user_id = auth.uid()
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- =====================================================
-- STORAGE BUCKETS (dokumentace)
-- =====================================================
-- V Supabase Dashboard vytvořte tyto buckety:
--
-- 1. voice-messages (private)
--    - RLS: Jen účastníci konverzace mohou nahrávat/stahovat
--
-- 2. chat-files (private)
--    - RLS: Jen účastníci konverzace mohou nahrávat/stahovat
--
-- Příklad RLS pro storage:
-- CREATE POLICY "Chat participants can upload"
-- ON storage.objects FOR INSERT
-- WITH CHECK (
--     bucket_id IN ('voice-messages', 'chat-files') AND
--     auth.role() = 'authenticated'
-- );
