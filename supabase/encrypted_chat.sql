-- =====================================================
-- END-TO-END ENCRYPTED CHAT SYSTEM
-- Signal Protocol inspired - E2EE messaging
-- =====================================================

-- =====================================================
-- USER KEYS - Veřejné klíče pro E2EE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.user_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    -- Identity key (dlouhodobý veřejný klíč)
    identity_public_key TEXT NOT NULL,
    -- Signed pre-key (střednědobý klíč podepsaný identity key)
    signed_prekey_public TEXT NOT NULL,
    signed_prekey_signature TEXT NOT NULL,
    -- One-time pre-keys (jednorázové klíče pro inicializaci)
    one_time_prekeys TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id)
);

-- =====================================================
-- CONVERSATIONS - Konverzace (1:1 i skupiny)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- Typ: 'direct' pro 1:1, 'group' pro skupiny
    type TEXT NOT NULL DEFAULT 'direct' CHECK (type IN ('direct', 'group')),
    -- Pro skupiny - název a nastavení
    name TEXT,
    description TEXT,
    avatar_url TEXT,
    -- Nastavení
    is_encrypted BOOLEAN NOT NULL DEFAULT true,
    -- Mizící zprávy (0 = vypnuto, jinak sekundy)
    disappearing_messages_ttl INTEGER DEFAULT 0,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================
-- CONVERSATION PARTICIPANTS - Členové konverzace
-- =====================================================
CREATE TABLE IF NOT EXISTS public.conversation_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    -- Role: 'admin', 'member'
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    -- Šifrovaný session key pro tuto konverzaci (šifrovaný veřejným klíčem uživatele)
    encrypted_session_key TEXT,
    -- Stav
    is_muted BOOLEAN NOT NULL DEFAULT false,
    last_read_at TIMESTAMPTZ,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(conversation_id, user_id)
);

-- =====================================================
-- MESSAGES - Šifrované zprávy
-- =====================================================
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    -- Šifrovaný obsah (AES-256-GCM encrypted, base64)
    encrypted_content TEXT NOT NULL,
    -- IV/Nonce pro dešifrování (base64)
    iv TEXT NOT NULL,
    -- Typ zprávy: 'text', 'image', 'file', 'voice', 'system'
    message_type TEXT NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'voice', 'system')),
    -- Metadata (nešifrované) - např. velikost souboru, MIME type
    metadata JSONB DEFAULT '{}',
    -- Reply na jinou zprávu
    reply_to_id UUID REFERENCES public.messages(id) ON DELETE SET NULL,
    -- Forwarded z jiné zprávy
    forwarded_from_id UUID REFERENCES public.messages(id) ON DELETE SET NULL,
    -- Čas kdy zpráva zmizí (pro disappearing messages)
    expires_at TIMESTAMPTZ,
    -- Byl obsah smazán? (zachová metadata pro "zpráva byla smazána")
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    edited_at TIMESTAMPTZ
);

-- =====================================================
-- MESSAGE RECEIPTS - Potvrzení doručení/přečtení
-- =====================================================
CREATE TABLE IF NOT EXISTS public.message_receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    -- Status: 'delivered', 'read'
    status TEXT NOT NULL CHECK (status IN ('delivered', 'read')),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(message_id, user_id, status)
);

-- =====================================================
-- MESSAGE REACTIONS - Reakce na zprávy
-- =====================================================
CREATE TABLE IF NOT EXISTS public.message_reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    -- Emoji reakce
    emoji TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(message_id, user_id, emoji)
);

-- =====================================================
-- KEY EXCHANGE SESSIONS - Pro X3DH key exchange
-- =====================================================
CREATE TABLE IF NOT EXISTS public.key_exchange_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    initiator_id UUID NOT NULL REFERENCES public.profiles(id),
    recipient_id UUID NOT NULL REFERENCES public.profiles(id),
    -- Ephemeral public key použitý při inicializaci
    ephemeral_public_key TEXT NOT NULL,
    -- Použitý one-time prekey (pokud byl dostupný)
    used_one_time_prekey TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================
-- INDEXES
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_user_keys_user_id ON public.user_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_user ON public.conversation_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_conv ON public.conversation_participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON public.messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_expires ON public.messages(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_message_receipts_message ON public.message_receipts(message_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_message ON public.message_reactions(message_id);

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================

-- User keys
ALTER TABLE public.user_keys ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view any public keys" ON public.user_keys;
CREATE POLICY "Users can view any public keys" ON public.user_keys
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage own keys" ON public.user_keys;
CREATE POLICY "Users can manage own keys" ON public.user_keys
    FOR ALL USING (user_id = auth.uid());

-- Conversations
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own conversations" ON public.conversations;
CREATE POLICY "Users can view own conversations" ON public.conversations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants
            WHERE conversation_id = id AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can create conversations" ON public.conversations;
CREATE POLICY "Users can create conversations" ON public.conversations
    FOR INSERT WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS "Admins can update conversations" ON public.conversations;
CREATE POLICY "Admins can update conversations" ON public.conversations
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants
            WHERE conversation_id = id AND user_id = auth.uid() AND role = 'admin'
        )
    );

-- Conversation participants
ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants can view conversation members" ON public.conversation_participants;
CREATE POLICY "Participants can view conversation members" ON public.conversation_participants
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp
            WHERE cp.conversation_id = conversation_id AND cp.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can join conversations" ON public.conversation_participants;
CREATE POLICY "Users can join conversations" ON public.conversation_participants
    FOR INSERT WITH CHECK (user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.conversation_participants
            WHERE conversation_id = conversation_participants.conversation_id
            AND user_id = auth.uid() AND role = 'admin'
        )
    );

DROP POLICY IF EXISTS "Users can update own participation" ON public.conversation_participants;
CREATE POLICY "Users can update own participation" ON public.conversation_participants
    FOR UPDATE USING (user_id = auth.uid());

-- Messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants can view messages" ON public.messages;
CREATE POLICY "Participants can view messages" ON public.messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants
            WHERE conversation_id = messages.conversation_id AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Participants can send messages" ON public.messages;
CREATE POLICY "Participants can send messages" ON public.messages
    FOR INSERT WITH CHECK (
        sender_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.conversation_participants
            WHERE conversation_id = messages.conversation_id AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Senders can update own messages" ON public.messages;
CREATE POLICY "Senders can update own messages" ON public.messages
    FOR UPDATE USING (sender_id = auth.uid());

-- Message receipts
ALTER TABLE public.message_receipts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants can view receipts" ON public.message_receipts;
CREATE POLICY "Participants can view receipts" ON public.message_receipts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.messages m
            JOIN public.conversation_participants cp ON cp.conversation_id = m.conversation_id
            WHERE m.id = message_id AND cp.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can create own receipts" ON public.message_receipts;
CREATE POLICY "Users can create own receipts" ON public.message_receipts
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Message reactions
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants can view reactions" ON public.message_reactions;
CREATE POLICY "Participants can view reactions" ON public.message_reactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.messages m
            JOIN public.conversation_participants cp ON cp.conversation_id = m.conversation_id
            WHERE m.id = message_id AND cp.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can manage own reactions" ON public.message_reactions;
CREATE POLICY "Users can manage own reactions" ON public.message_reactions
    FOR ALL USING (user_id = auth.uid());

-- Key exchange sessions
ALTER TABLE public.key_exchange_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants can view key exchanges" ON public.key_exchange_sessions;
CREATE POLICY "Participants can view key exchanges" ON public.key_exchange_sessions
    FOR SELECT USING (initiator_id = auth.uid() OR recipient_id = auth.uid());

DROP POLICY IF EXISTS "Users can create key exchanges" ON public.key_exchange_sessions;
CREATE POLICY "Users can create key exchanges" ON public.key_exchange_sessions
    FOR INSERT WITH CHECK (initiator_id = auth.uid());

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Funkce pro smazání expirovaných zpráv
CREATE OR REPLACE FUNCTION delete_expired_messages()
RETURNS void AS $$
BEGIN
    DELETE FROM public.messages
    WHERE expires_at IS NOT NULL AND expires_at < now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funkce pro získání nebo vytvoření direct konverzace
CREATE OR REPLACE FUNCTION get_or_create_direct_conversation(other_user_id UUID)
RETURNS UUID AS $$
DECLARE
    conv_id UUID;
    current_user_id UUID := auth.uid();
BEGIN
    -- Najdi existující direct konverzaci mezi těmito dvěma uživateli
    SELECT c.id INTO conv_id
    FROM public.conversations c
    JOIN public.conversation_participants cp1 ON cp1.conversation_id = c.id AND cp1.user_id = current_user_id
    JOIN public.conversation_participants cp2 ON cp2.conversation_id = c.id AND cp2.user_id = other_user_id
    WHERE c.type = 'direct'
    LIMIT 1;

    -- Pokud neexistuje, vytvoř novou
    IF conv_id IS NULL THEN
        INSERT INTO public.conversations (type, created_by)
        VALUES ('direct', current_user_id)
        RETURNING id INTO conv_id;

        -- Přidej oba účastníky
        INSERT INTO public.conversation_participants (conversation_id, user_id, role)
        VALUES
            (conv_id, current_user_id, 'admin'),
            (conv_id, other_user_id, 'admin');
    END IF;

    RETURN conv_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Realtime subscription pro zprávy
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.message_receipts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.message_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversation_participants;

-- =====================================================
-- VERIFICATION
-- =====================================================
-- SELECT * FROM user_keys;
-- SELECT * FROM conversations;
-- SELECT * FROM messages ORDER BY created_at DESC LIMIT 10;
