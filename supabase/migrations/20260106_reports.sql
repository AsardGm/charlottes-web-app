-- Migrace: Vytvoreni tabulky reports pro nahlasovani obsahu
-- Datum: 2026-01-06
-- Popis: Umoznuje uzivatelum nahlasit nevhodny obsah (prispevky, komentare, uzivatele)

-- Enum pro typ nahlaseneho obsahu
CREATE TYPE report_content_type AS ENUM ('post', 'comment', 'user', 'message');

-- Enum pro duvod nahlaseni
CREATE TYPE report_reason AS ENUM (
    'spam',
    'harassment',
    'hate_speech',
    'violence',
    'nudity',
    'false_information',
    'scam',
    'self_harm',
    'other'
);

-- Enum pro stav nahlaseni
CREATE TYPE report_status AS ENUM ('pending', 'reviewing', 'resolved', 'dismissed');

-- Tabulka pro nahlaseni
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

    -- Typ a ID nahlaseneho obsahu
    content_type report_content_type NOT NULL,
    content_id UUID NOT NULL,

    -- Duvod a popis
    reason report_reason NOT NULL,
    description TEXT,

    -- Stav zpracovani
    status report_status DEFAULT 'pending',

    -- Admin zpracovani
    reviewed_by UUID REFERENCES public.profiles(id),
    reviewed_at TIMESTAMPTZ,
    admin_note TEXT,
    action_taken TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Jeden uzivatel muze nahlasit stejny obsah jen jednou
    UNIQUE(reporter_id, content_type, content_id)
);

-- Indexy
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_content ON public.reports(content_type, content_id);
CREATE INDEX IF NOT EXISTS idx_reports_reporter ON public.reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_created ON public.reports(created_at DESC);

-- RLS politiky
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Uzivatel muze vytvorit nahlaseni
CREATE POLICY "Users can create reports" ON public.reports
    FOR INSERT
    WITH CHECK (auth.uid() = reporter_id);

-- Uzivatel vidi sve vlastni nahlaseni
CREATE POLICY "Users can view own reports" ON public.reports
    FOR SELECT
    USING (auth.uid() = reporter_id);

-- Admin vidi vsechna nahlaseni
CREATE POLICY "Admins can view all reports" ON public.reports
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Admin muze aktualizovat nahlaseni
CREATE POLICY "Admins can update reports" ON public.reports
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Funkce pro aktualizaci updated_at
CREATE OR REPLACE FUNCTION update_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pro automatickou aktualizaci updated_at
DROP TRIGGER IF EXISTS trigger_reports_updated_at ON public.reports;
CREATE TRIGGER trigger_reports_updated_at
    BEFORE UPDATE ON public.reports
    FOR EACH ROW
    EXECUTE FUNCTION update_reports_updated_at();

-- Funkce pro ziskani poctu nevyrizenych nahlaseni (pro adminy)
CREATE OR REPLACE FUNCTION get_pending_reports_count()
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*) FROM public.reports
        WHERE status = 'pending'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Komentare
COMMENT ON TABLE public.reports IS 'Tabulka pro nahlaseni nevhodneho obsahu';
COMMENT ON COLUMN public.reports.content_type IS 'Typ nahlaseneho obsahu (post, comment, user, message)';
COMMENT ON COLUMN public.reports.content_id IS 'ID nahlaseneho obsahu';
COMMENT ON COLUMN public.reports.reason IS 'Duvod nahlaseni';
COMMENT ON COLUMN public.reports.status IS 'Stav zpracovani nahlaseni';
