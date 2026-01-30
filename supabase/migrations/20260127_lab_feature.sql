-- ============================================
-- Lab Feature - Databazove tabulky
-- Chronos (timeline), Alchymista (nutrients),
-- Oci Arasaky (AI diagnostika), Ghost Protocol
-- Spustte v Supabase SQL Editoru
-- ============================================

-- 1. Hlavni tabulka grows (pestovania)
CREATE TABLE IF NOT EXISTS lab_grows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  strain_name TEXT,
  phase TEXT NOT NULL DEFAULT 'germination'
    CHECK (phase IN ('germination', 'seedling', 'vegetative', 'flowering', 'harvest', 'drying', 'curing', 'completed')),
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date DATE,
  environment TEXT CHECK (environment IN ('indoor', 'outdoor', 'greenhouse')),
  medium TEXT CHECK (medium IN ('soil', 'coco', 'hydro', 'aero', 'dwc')),
  notes TEXT,
  cover_image_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  is_burner BOOLEAN DEFAULT FALSE,
  is_local_only BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Timeline zaznamy (Chronos)
CREATE TABLE IF NOT EXISTS lab_timeline_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  grow_id UUID REFERENCES lab_grows(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  day_number INT NOT NULL DEFAULT 1,
  event_type TEXT NOT NULL DEFAULT 'note'
    CHECK (event_type IN ('note', 'photo', 'phase_change', 'milestone', 'water', 'feed', 'transplant', 'training', 'issue', 'harvest')),
  milestone_type TEXT
    CHECK (milestone_type IN ('first_leaves', 'first_pistils', 'trichome_cloudy', 'trichome_amber', 'harvest_ready', 'custom')),
  title TEXT,
  description TEXT,
  image_url TEXT,
  phase_at_time TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Nutrient logy (Alchymista)
CREATE TABLE IF NOT EXISTS lab_nutrient_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  grow_id UUID REFERENCES lab_grows(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  day_number INT NOT NULL DEFAULT 1,
  ph_value DECIMAL,
  ec_value DECIMAL,
  ppm_value DECIMAL,
  water_amount_ml INT,
  temperature DECIMAL,
  humidity DECIMAL,
  nutrients JSONB,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. AI diagnostiky (Oci Arasaky)
CREATE TABLE IF NOT EXISTS lab_ai_diagnostics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  grow_id UUID REFERENCES lab_grows(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  diagnostic_type TEXT NOT NULL DEFAULT 'health'
    CHECK (diagnostic_type IN ('deficiency', 'trichome', 'health', 'pest')),
  image_url TEXT NOT NULL,
  ai_response JSONB,
  severity TEXT CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  diagnosis TEXT,
  recommendations TEXT[],
  confidence DECIMAL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Feeding schedules (Alchymista prednastavene recepty)
CREATE TABLE IF NOT EXISTS lab_feeding_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  brand TEXT,
  is_public BOOLEAN DEFAULT FALSE,
  is_system BOOLEAN DEFAULT FALSE,
  schedule_data JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXY
-- ============================================

CREATE INDEX IF NOT EXISTS idx_lab_grows_user ON lab_grows(user_id);
CREATE INDEX IF NOT EXISTS idx_lab_grows_active ON lab_grows(user_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_lab_grows_phase ON lab_grows(phase);

CREATE INDEX IF NOT EXISTS idx_lab_timeline_grow ON lab_timeline_entries(grow_id);
CREATE INDEX IF NOT EXISTS idx_lab_timeline_user ON lab_timeline_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_lab_timeline_day ON lab_timeline_entries(grow_id, day_number);
CREATE INDEX IF NOT EXISTS idx_lab_timeline_type ON lab_timeline_entries(event_type);

CREATE INDEX IF NOT EXISTS idx_lab_nutrient_grow ON lab_nutrient_logs(grow_id);
CREATE INDEX IF NOT EXISTS idx_lab_nutrient_user ON lab_nutrient_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_lab_nutrient_day ON lab_nutrient_logs(grow_id, day_number);

CREATE INDEX IF NOT EXISTS idx_lab_diagnostic_grow ON lab_ai_diagnostics(grow_id);
CREATE INDEX IF NOT EXISTS idx_lab_diagnostic_user ON lab_ai_diagnostics(user_id);
CREATE INDEX IF NOT EXISTS idx_lab_diagnostic_type ON lab_ai_diagnostics(diagnostic_type);

CREATE INDEX IF NOT EXISTS idx_lab_schedules_user ON lab_feeding_schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_lab_schedules_public ON lab_feeding_schedules(is_public) WHERE is_public = true;

-- ============================================
-- RLS POLITIKY
-- ============================================

-- lab_grows
ALTER TABLE lab_grows ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own grows" ON lab_grows;
CREATE POLICY "Users can view own grows" ON lab_grows
FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own grows" ON lab_grows;
CREATE POLICY "Users can insert own grows" ON lab_grows
FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own grows" ON lab_grows;
CREATE POLICY "Users can update own grows" ON lab_grows
FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own grows" ON lab_grows;
CREATE POLICY "Users can delete own grows" ON lab_grows
FOR DELETE USING (auth.uid() = user_id);

-- lab_timeline_entries
ALTER TABLE lab_timeline_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own timeline" ON lab_timeline_entries;
CREATE POLICY "Users can view own timeline" ON lab_timeline_entries
FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own timeline" ON lab_timeline_entries;
CREATE POLICY "Users can insert own timeline" ON lab_timeline_entries
FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own timeline" ON lab_timeline_entries;
CREATE POLICY "Users can update own timeline" ON lab_timeline_entries
FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own timeline" ON lab_timeline_entries;
CREATE POLICY "Users can delete own timeline" ON lab_timeline_entries
FOR DELETE USING (auth.uid() = user_id);

-- lab_nutrient_logs
ALTER TABLE lab_nutrient_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own nutrients" ON lab_nutrient_logs;
CREATE POLICY "Users can view own nutrients" ON lab_nutrient_logs
FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own nutrients" ON lab_nutrient_logs;
CREATE POLICY "Users can insert own nutrients" ON lab_nutrient_logs
FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own nutrients" ON lab_nutrient_logs;
CREATE POLICY "Users can update own nutrients" ON lab_nutrient_logs
FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own nutrients" ON lab_nutrient_logs;
CREATE POLICY "Users can delete own nutrients" ON lab_nutrient_logs
FOR DELETE USING (auth.uid() = user_id);

-- lab_ai_diagnostics
ALTER TABLE lab_ai_diagnostics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own diagnostics" ON lab_ai_diagnostics;
CREATE POLICY "Users can view own diagnostics" ON lab_ai_diagnostics
FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own diagnostics" ON lab_ai_diagnostics;
CREATE POLICY "Users can insert own diagnostics" ON lab_ai_diagnostics
FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own diagnostics" ON lab_ai_diagnostics;
CREATE POLICY "Users can delete own diagnostics" ON lab_ai_diagnostics
FOR DELETE USING (auth.uid() = user_id);

-- lab_feeding_schedules
ALTER TABLE lab_feeding_schedules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own and public schedules" ON lab_feeding_schedules;
CREATE POLICY "Users can view own and public schedules" ON lab_feeding_schedules
FOR SELECT USING (auth.uid() = user_id OR is_public = true OR is_system = true);

DROP POLICY IF EXISTS "Users can insert own schedules" ON lab_feeding_schedules;
CREATE POLICY "Users can insert own schedules" ON lab_feeding_schedules
FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own schedules" ON lab_feeding_schedules;
CREATE POLICY "Users can update own schedules" ON lab_feeding_schedules
FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own schedules" ON lab_feeding_schedules;
CREATE POLICY "Users can delete own schedules" ON lab_feeding_schedules
FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- TRIGGERY pro updated_at
-- ============================================

CREATE OR REPLACE FUNCTION update_lab_grows_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS lab_grows_updated_at ON lab_grows;
CREATE TRIGGER lab_grows_updated_at
  BEFORE UPDATE ON lab_grows
  FOR EACH ROW
  EXECUTE FUNCTION update_lab_grows_updated_at();

CREATE OR REPLACE FUNCTION update_lab_schedules_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS lab_schedules_updated_at ON lab_feeding_schedules;
CREATE TRIGGER lab_schedules_updated_at
  BEFORE UPDATE ON lab_feeding_schedules
  FOR EACH ROW
  EXECUTE FUNCTION update_lab_schedules_updated_at();

-- ============================================
-- SEED DATA - Prednastavene feeding schedules
-- ============================================

INSERT INTO lab_feeding_schedules (name, description, brand, is_system, is_public, schedule_data) VALUES
  ('BioBizz Indoor', 'Zakladni BioBizz schema pro indoor', 'BioBizz', true, true,
   '{"weeks": [{"week": 1, "phase": "seedling", "products": [{"name": "Root-Juice", "ml_per_l": 1}]}, {"week": 3, "phase": "vegetative", "products": [{"name": "Bio-Grow", "ml_per_l": 2}, {"name": "Root-Juice", "ml_per_l": 2}]}, {"week": 5, "phase": "flowering", "products": [{"name": "Bio-Bloom", "ml_per_l": 3}, {"name": "Top-Max", "ml_per_l": 1}]}, {"week": 8, "phase": "late_flowering", "products": [{"name": "Bio-Bloom", "ml_per_l": 4}, {"name": "Top-Max", "ml_per_l": 4}]}]}'::jsonb),

  ('General Hydroponics Flora', 'GHE FloraSeries zaklad', 'GHE', true, true,
   '{"weeks": [{"week": 1, "phase": "seedling", "products": [{"name": "FloraGro", "ml_per_l": 0.5}, {"name": "FloraMicro", "ml_per_l": 0.5}]}, {"week": 3, "phase": "vegetative", "products": [{"name": "FloraGro", "ml_per_l": 2}, {"name": "FloraMicro", "ml_per_l": 1.5}, {"name": "FloraBloom", "ml_per_l": 0.5}]}, {"week": 5, "phase": "flowering", "products": [{"name": "FloraGro", "ml_per_l": 0.5}, {"name": "FloraMicro", "ml_per_l": 1.5}, {"name": "FloraBloom", "ml_per_l": 2.5}]}]}'::jsonb),

  ('Plagron Terra', 'Plagron pro zeminu', 'Plagron', true, true,
   '{"weeks": [{"week": 1, "phase": "seedling", "products": [{"name": "Power Roots", "ml_per_l": 1}]}, {"week": 3, "phase": "vegetative", "products": [{"name": "Terra Grow", "ml_per_l": 3}, {"name": "Power Roots", "ml_per_l": 1}]}, {"week": 5, "phase": "flowering", "products": [{"name": "Terra Bloom", "ml_per_l": 4}, {"name": "Green Sensation", "ml_per_l": 0.5}]}]}'::jsonb)
ON CONFLICT DO NOTHING;

-- Hotovo!
-- Po spusteni budou k dispozici tabulky pro Lab feature.
