-- ============================================
-- AI Strain Scanner - Databázové tabulky
-- Spusťte v Supabase SQL Editoru
-- ============================================

-- 1. Tabulka odrůd (katalog pro rychlejší matching)
CREATE TABLE IF NOT EXISTS strains (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE,
  type TEXT CHECK (type IN ('indica', 'sativa', 'hybrid')),
  thc_min DECIMAL,
  thc_max DECIMAL,
  cbd_min DECIMAL,
  cbd_max DECIMAL,
  effects TEXT[],           -- ['relaxace', 'euforie', 'kreativita']
  flavors TEXT[],           -- ['citrus', 'boruvka', 'zemity']
  description TEXT,
  genetics TEXT,            -- Rodičovské odrůdy
  grow_difficulty TEXT CHECK (grow_difficulty IN ('easy', 'medium', 'hard')),
  grow_time_weeks INT,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Historie skenů uživatele
CREATE TABLE IF NOT EXISTS scan_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  ai_response JSONB,        -- Celá odpověď od AI
  identified_strain TEXT,   -- Název identifikované odrůdy
  strain_type TEXT,         -- indica/sativa/hybrid
  confidence DECIMAL,       -- Jistota identifikace (0-100)
  is_favorite BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Indexy pro rychlejší vyhledávání
CREATE INDEX IF NOT EXISTS idx_strains_name ON strains(name);
CREATE INDEX IF NOT EXISTS idx_strains_type ON strains(type);
CREATE INDEX IF NOT EXISTS idx_strains_slug ON strains(slug);
CREATE INDEX IF NOT EXISTS idx_scan_history_user ON scan_history(user_id);
CREATE INDEX IF NOT EXISTS idx_scan_history_created ON scan_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_scan_history_favorite ON scan_history(user_id, is_favorite) WHERE is_favorite = true;

-- 4. RLS politiky pro strains
ALTER TABLE strains ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read strains" ON strains;
CREATE POLICY "Anyone can read strains" ON strains
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can manage strains" ON strains;
CREATE POLICY "Admins can manage strains" ON strains
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'admin'
  )
);

-- 5. RLS politiky pro scan_history
ALTER TABLE scan_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own scans" ON scan_history;
CREATE POLICY "Users can view own scans" ON scan_history
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own scans" ON scan_history;
CREATE POLICY "Users can insert own scans" ON scan_history
FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own scans" ON scan_history;
CREATE POLICY "Users can update own scans" ON scan_history
FOR UPDATE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own scans" ON scan_history;
CREATE POLICY "Users can delete own scans" ON scan_history
FOR DELETE
USING (auth.uid() = user_id);

-- 6. Trigger pro updated_at na strains
CREATE OR REPLACE FUNCTION update_strains_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS strains_updated_at ON strains;
CREATE TRIGGER strains_updated_at
  BEFORE UPDATE ON strains
  FOR EACH ROW
  EXECUTE FUNCTION update_strains_updated_at();

-- 7. Základní seed data - populární odrůdy
INSERT INTO strains (name, slug, type, thc_min, thc_max, cbd_min, cbd_max, effects, flavors, description, genetics, grow_difficulty, grow_time_weeks) VALUES
  ('Blue Dream', 'blue-dream', 'hybrid', 17, 24, 0.1, 0.2,
   ARRAY['relaxace', 'euforie', 'kreativita', 'energie'],
   ARRAY['borůvka', 'sladká', 'vanilka'],
   'Populární hybridní odrůda známá pro vyvážené účinky a sladkou borůvkovou vůni.',
   'Blueberry x Haze', 'easy', 9),

  ('OG Kush', 'og-kush', 'hybrid', 19, 26, 0.1, 0.3,
   ARRAY['relaxace', 'euforie', 'hlad'],
   ARRAY['zemitá', 'borovice', 'citrus'],
   'Legendární odrůda z Kalifornie s charakteristickou zemitou vůní.',
   'Chemdawg x Hindu Kush', 'medium', 8),

  ('Northern Lights', 'northern-lights', 'indica', 16, 21, 0.1, 0.1,
   ARRAY['relaxace', 'spánek', 'úleva od bolesti'],
   ARRAY['sladká', 'kořeněná', 'zemitá'],
   'Klasická indica známá pro své uklidňující účinky a rychlý růst.',
   'Afghani x Thai', 'easy', 7),

  ('Sour Diesel', 'sour-diesel', 'sativa', 20, 25, 0.1, 0.2,
   ARRAY['energie', 'kreativita', 'euforie', 'soustředění'],
   ARRAY['diesel', 'citrus', 'zemitá'],
   'Energizující sativa s charakteristickou dieselovou vůní.',
   'Chemdawg x Super Skunk', 'medium', 10),

  ('Girl Scout Cookies', 'girl-scout-cookies', 'hybrid', 25, 28, 0.1, 0.2,
   ARRAY['euforie', 'relaxace', 'kreativita', 'hlad'],
   ARRAY['sladká', 'zemitá', 'máta'],
   'Silná hybridní odrůda se sladkou chutí a vysokým obsahem THC.',
   'OG Kush x Durban Poison', 'hard', 9),

  ('White Widow', 'white-widow', 'hybrid', 18, 25, 0.1, 0.2,
   ARRAY['euforie', 'energie', 'kreativita'],
   ARRAY['zemitá', 'dřevitá', 'ammonia'],
   'Holandská klasika s bílými trichomy a vyváženými účinky.',
   'Brazilian x South Indian', 'easy', 8),

  ('Amnesia Haze', 'amnesia-haze', 'sativa', 20, 25, 0.1, 0.1,
   ARRAY['energie', 'euforie', 'kreativita', 'soustředění'],
   ARRAY['citrus', 'zemitá', 'sladká'],
   'Populární sativa s citrusovou vůní a silnými cerebrálními účinky.',
   'Jamaican x Hawaiian x Afghan', 'hard', 12),

  ('Gorilla Glue', 'gorilla-glue', 'hybrid', 25, 30, 0.1, 0.1,
   ARRAY['relaxace', 'euforie', 'spánek'],
   ARRAY['diesel', 'zemitá', 'borovice'],
   'Silná hybridní odrůda s lepkavými pupeny a vysokým obsahem THC.',
   'Chem Sister x Sour Dubb x Chocolate Diesel', 'medium', 8),

  ('Jack Herer', 'jack-herer', 'sativa', 18, 24, 0.1, 0.2,
   ARRAY['energie', 'kreativita', 'soustředění', 'euforie'],
   ARRAY['borovice', 'zemitá', 'kořeněná'],
   'Pojmenována po aktivistovi, známá pro jasné, kreativní účinky.',
   'Haze x Northern Lights x Shiva Skunk', 'medium', 10),

  ('Purple Haze', 'purple-haze', 'sativa', 17, 20, 0.1, 0.1,
   ARRAY['energie', 'euforie', 'kreativita'],
   ARRAY['sladká', 'zemitá', 'bobule'],
   'Psychedelická klasika s fialovým zabarvením a nostalgickou historií.',
   'Haze x Purple Thai', 'medium', 9)
ON CONFLICT (slug) DO NOTHING;

-- Hotovo!
-- Po spuštění budou k dispozici tabulky strains a scan_history.
