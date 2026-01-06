-- Migrace: Vytvoreni tabulky follow_requests pro soukrome ucty
-- Datum: 2026-01-06
-- Popis: Umoznuje zadosti o sledovani pro soukrome ucty

-- Tabulka pro zadosti o sledovani
CREATE TABLE IF NOT EXISTS public.follow_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    requester_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    target_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Jeden uzivatel muze mit jen jednu aktivni zadost k jinemu uzivateli
    UNIQUE(requester_id, target_id)
);

-- Indexy pro rychlejsi dotazy
CREATE INDEX IF NOT EXISTS idx_follow_requests_target_pending
    ON public.follow_requests(target_id)
    WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_follow_requests_requester
    ON public.follow_requests(requester_id);

CREATE INDEX IF NOT EXISTS idx_follow_requests_status
    ON public.follow_requests(status);

-- RLS politiky
ALTER TABLE public.follow_requests ENABLE ROW LEVEL SECURITY;

-- Kazdy muze videt sve vlastni zadosti (odeslane i prijate)
CREATE POLICY "Users can view own requests" ON public.follow_requests
    FOR SELECT
    USING (
        auth.uid() = requester_id OR
        auth.uid() = target_id
    );

-- Prihlaseny uzivatel muze vytvorit zadost
CREATE POLICY "Users can create requests" ON public.follow_requests
    FOR INSERT
    WITH CHECK (auth.uid() = requester_id);

-- Zadatel muze smazat svou zadost (zrusit zadost)
CREATE POLICY "Requesters can delete own requests" ON public.follow_requests
    FOR DELETE
    USING (auth.uid() = requester_id);

-- Cilovy uzivatel muze aktualizovat status (prijmout/odmitnout)
CREATE POLICY "Target can update request status" ON public.follow_requests
    FOR UPDATE
    USING (auth.uid() = target_id)
    WITH CHECK (auth.uid() = target_id);

-- Trigger pro aktualizaci updated_at
CREATE OR REPLACE FUNCTION update_follow_request_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_follow_request_updated_at
    BEFORE UPDATE ON public.follow_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_follow_request_updated_at();

-- Funkce pro automaticke vytvoreni follow zaznamu pri prijeti zadosti
CREATE OR REPLACE FUNCTION handle_follow_request_acceptance()
RETURNS TRIGGER AS $$
BEGIN
    -- Pokud byla zadost prijata, vytvor follow zaznam
    IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
        INSERT INTO public.follows (follower_id, following_id)
        VALUES (NEW.requester_id, NEW.target_id)
        ON CONFLICT DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_follow_request_accepted
    AFTER UPDATE ON public.follow_requests
    FOR EACH ROW
    WHEN (NEW.status = 'accepted' AND OLD.status = 'pending')
    EXECUTE FUNCTION handle_follow_request_acceptance();

-- Komentar k tabulce
COMMENT ON TABLE public.follow_requests IS 'Zadosti o sledovani pro soukrome ucty';
COMMENT ON COLUMN public.follow_requests.status IS 'pending = cekajici, accepted = prijata, rejected = odmitnuta';
