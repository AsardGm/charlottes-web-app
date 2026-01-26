-- ============================================
-- Terpene Brain Map - Databázové tabulky
-- Spusťte v Supabase SQL Editoru
-- ============================================

-- 1. Tabulka terpenů
CREATE TABLE IF NOT EXISTS terpenes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  slug TEXT UNIQUE,
  chemical_formula TEXT,
  description TEXT,
  aroma TEXT,
  color TEXT DEFAULT '#00D4FF',
  moods TEXT[],
  effects TEXT[],
  benefits TEXT[],
  cautions TEXT[],
  natural_sources TEXT[],
  boiling_point DECIMAL,
  brain_region TEXT DEFAULT 'limbic',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Komunitní zkušenosti s terpeny
CREATE TABLE IF NOT EXISTS terpene_experiences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  terpene_id UUID REFERENCES terpenes(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  rating INT CHECK (rating >= 1 AND rating <= 5),
  tags TEXT[],
  helpful_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Helpful votes (kdo hlasoval)
CREATE TABLE IF NOT EXISTS terpene_experience_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  experience_id UUID REFERENCES terpene_experiences(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(experience_id, user_id)
);

-- 4. Indexy
CREATE INDEX IF NOT EXISTS idx_terpenes_slug ON terpenes(slug);
CREATE INDEX IF NOT EXISTS idx_terpene_exp_terpene ON terpene_experiences(terpene_id);
CREATE INDEX IF NOT EXISTS idx_terpene_exp_user ON terpene_experiences(user_id);
CREATE INDEX IF NOT EXISTS idx_terpene_exp_rating ON terpene_experiences(rating);

-- 5. RLS politiky
ALTER TABLE terpenes ENABLE ROW LEVEL SECURITY;
ALTER TABLE terpene_experiences ENABLE ROW LEVEL SECURITY;
ALTER TABLE terpene_experience_votes ENABLE ROW LEVEL SECURITY;

-- Terpeny může číst každý
CREATE POLICY "Anyone can read terpenes" ON terpenes FOR SELECT USING (true);

-- Zkušenosti může číst každý
CREATE POLICY "Anyone can read experiences" ON terpene_experiences FOR SELECT USING (true);

-- Zkušenosti může přidávat přihlášený uživatel
CREATE POLICY "Users can insert own experiences" ON terpene_experiences
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Zkušenosti může mazat vlastník nebo admin
CREATE POLICY "Users can delete own experiences" ON terpene_experiences
FOR DELETE USING (
  auth.uid() = user_id OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Hlasy může číst každý
CREATE POLICY "Anyone can read votes" ON terpene_experience_votes FOR SELECT USING (true);

-- Hlasovat může přihlášený uživatel
CREATE POLICY "Users can vote" ON terpene_experience_votes
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Hlas může odebrat vlastník
CREATE POLICY "Users can remove own vote" ON terpene_experience_votes
FOR DELETE USING (auth.uid() = user_id);

-- 6. Seed data - hlavní terpeny
INSERT INTO terpenes (name, slug, chemical_formula, description, aroma, color, moods, effects, benefits, cautions, natural_sources, boiling_point, brain_region) VALUES

('Myrcen', 'myrcene', 'C₁₀H₁₆',
 'Nejběžnější terpen v konopí. Má silné relaxační účinky a podporuje vstřebávání dalších látek.',
 'Zemitá, muškátová, hřebíčková',
 '#8B4513',
 ARRAY['relaxace', 'klid', 'ospalost'],
 ARRAY['sedativní', 'protizánětlivý', 'analgetický', 'svalový relaxant'],
 ARRAY['Večerní relaxace', 'Pomoc se spánkem', 'Úleva od bolesti svalů', 'Snížení stresu'],
 ARRAY['Může způsobit ospalost', 'Nevhodné před řízením', 'Opatrně při kombinaci s alkoholem'],
 ARRAY['mango', 'chmel', 'citronová tráva', 'tymián'],
 168,
 'limbic'),

('Limonen', 'limonene', 'C₁₀H₁₆',
 'Citrusový terpen s povzbuzujícími účinky. Podporuje dobrou náladu a může pomoci s úzkostí.',
 'Citrusová, citrónová, pomerančová',
 '#FFD700',
 ARRAY['euforie', 'energie', 'optimismus', 'soustředění'],
 ARRAY['antidepresivní', 'anxiolytický', 'antibakteriální', 'antioxidační'],
 ARRAY['Ranní produktivita', 'Zlepšení nálady', 'Sociální situace', 'Kreativní práce'],
 ARRAY['Může zvýšit energii - nevhodné večer', 'U citlivých osob může způsobit neklid'],
 ARRAY['citróny', 'pomeranče', 'grep', 'jalovec'],
 176,
 'prefrontal'),

('Pinen', 'pinene', 'C₁₀H₁₆',
 'Terpen s vůní borovice. Podporuje soustředění a paměť, má bronchodilatační účinky.',
 'Borovicová, lesní, svěží',
 '#228B22',
 ARRAY['bdělost', 'jasnost', 'soustředění'],
 ARRAY['bronchodilatační', 'protizánětlivý', 'neuroprotektivní', 'paměť'],
 ARRAY['Studium a učení', 'Outdoor aktivity', 'Respirační podpora', 'Mentální jasnost'],
 ARRAY['Vysoké dávky mohou způsobit úzkost', 'Opatrně u astmatiků'],
 ARRAY['borovice', 'rozmarýn', 'bazalka', 'petržel'],
 155,
 'hippocampus'),

('Linalool', 'linalool', 'C₁₀H₁₈O',
 'Květinový terpen známý pro uklidňující vlastnosti. Používá se v aromaterapii proti stresu.',
 'Květinová, levandulová, kořeněná',
 '#E6E6FA',
 ARRAY['klid', 'relaxace', 'vyrovnanost'],
 ARRAY['anxiolytický', 'sedativní', 'antikonvulzivní', 'analgetický'],
 ARRAY['Úzkostné stavy', 'Problémy se spánkem', 'Stresové situace', 'Meditace'],
 ARRAY['Silně sedativní - opatrně s dávkováním', 'Může zesílit účinky jiných sedativ'],
 ARRAY['levandule', 'koriandr', 'sladké dřevo', 'bergamot'],
 198,
 'amygdala'),

('Caryofylen', 'caryophyllene', 'C₁₅H₂₄',
 'Jediný terpen, který se váže na CB2 receptory. Má silné protizánětlivé účinky.',
 'Pepřová, kořeněná, dřevitá',
 '#8B0000',
 ARRAY['uvolnění', 'úleva', 'stabilita'],
 ARRAY['protizánětlivý', 'analgetický', 'gastroprotektivní', 'anxiolytický'],
 ARRAY['Chronická bolest', 'Zánětlivé stavy', 'Žaludeční problémy', 'Stres'],
 ARRAY['Může interagovat s některými léky', 'Konzultujte s lékařem při užívání léků'],
 ARRAY['černý pepř', 'hřebíček', 'skořice', 'oregano'],
 130,
 'peripheral'),

('Humulen', 'humulene', 'C₁₅H₂₄',
 'Terpen s chmelovou vůní. Má anorektické účinky - může potlačovat chuť k jídlu.',
 'Chmelová, zemitá, dřevitá',
 '#556B2F',
 ARRAY['soustředění', 'jasnost', 'vyrovnanost'],
 ARRAY['protizánětlivý', 'antibakteriální', 'anorektický'],
 ARRAY['Kontrola chuti k jídlu', 'Zánětlivé stavy', 'Denní použití bez ospalosti'],
 ARRAY['Může potlačit chuť k jídlu', 'Nevhodné při poruchách příjmu potravy'],
 ARRAY['chmel', 'koriandr', 'bazalka', 'hřebíček'],
 106,
 'hypothalamus'),

('Terpinolen', 'terpinolene', 'C₁₀H₁₆',
 'Komplexní terpen s multidimenzionální vůní. Má sedativní i povzbuzující vlastnosti.',
 'Květinová, bylinková, lehce citrusová',
 '#DDA0DD',
 ARRAY['kreativita', 'snění', 'introspekce'],
 ARRAY['sedativní', 'antioxidační', 'antibakteriální'],
 ARRAY['Kreativní činnosti', 'Relaxace s jasnou myslí', 'Umělecká tvorba'],
 ARRAY['Účinky se mohou lišit podle jednotlivce', 'Může způsobit ospalost'],
 ARRAY['čajovník', 'muškátový oříšek', 'jablka', 'kmín'],
 186,
 'creative'),

('Ocimen', 'ocimene', 'C₁₀H₁₆',
 'Sladký terpen s ochranými vlastnostmi. Často se vyskytuje v tropických rostlinách.',
 'Sladká, bylinková, dřevitá',
 '#98FB98',
 ARRAY['svěžest', 'energie', 'pozitivita'],
 ARRAY['antivirový', 'antifungální', 'dekongestivní'],
 ARRAY['Podpora imunity', 'Respirační problémy', 'Povzbuzení energie'],
 ARRAY['Může dráždit citlivou pokožku', 'Opatrně při alergiích'],
 ARRAY['bazalka', 'mango', 'orchideje', 'pepř'],
 100,
 'immune')

ON CONFLICT (slug) DO NOTHING;

-- Hotovo!
