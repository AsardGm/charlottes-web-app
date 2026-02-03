-- Strain Journal & Rating System
-- Detailed tracking of strain experiences with AI analysis

-- ============================================================================
-- JOURNAL ENTRIES
-- ============================================================================

-- Table: strain_journal_entries
-- Detailed strain experience logs with comprehensive effect tracking
CREATE TABLE IF NOT EXISTS strain_journal_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  strain_id UUID NOT NULL REFERENCES strains(id) ON DELETE CASCADE,
  consumption_log_id UUID REFERENCES consumption_logs(id) ON DELETE SET NULL,

  -- Basic info
  consumed_at TIMESTAMPTZ NOT NULL,
  method TEXT, -- 'vaporizer', 'joint', 'edible', 'bong', etc.
  amount DECIMAL(5,2), -- grams or other unit
  amount_unit TEXT DEFAULT 'g',

  -- Setting & Context
  setting TEXT[], -- ['home', 'outdoors', 'social', 'alone']
  activities TEXT[], -- ['gaming', 'reading', 'exercising', 'creative_work']
  mood_before INT, -- 1-10
  intention TEXT, -- 'relaxation', 'creativity', 'pain_relief', 'sleep', etc.

  -- Physical Effects (1-10 scale, null if not experienced)
  body_high INT,
  energy_level INT,
  appetite INT,
  dry_mouth INT,
  red_eyes INT,
  physical_relaxation INT,
  pain_relief INT,
  sleepiness INT,

  -- Mental Effects (1-10 scale)
  head_high INT,
  focus INT,
  creativity INT,
  euphoria INT,
  mental_clarity INT,
  memory_impact INT, -- negative scale: 1 = no impact, 10 = significant impairment
  paranoia INT, -- 0-10, 0 = none

  -- Emotional Effects (1-10 scale)
  happiness INT,
  anxiety_relief INT,
  stress_relief INT,
  sociability INT,
  introspection INT,

  -- Duration tracking
  onset_time INT, -- minutes until effects start
  peak_time INT, -- minutes to peak
  total_duration INT, -- total minutes

  -- Overall experience
  overall_rating DECIMAL(2,1), -- 1.0 - 5.0 stars
  would_use_again BOOLEAN,

  -- User notes
  title TEXT,
  notes TEXT,
  highlights TEXT[], -- Positive aspects
  drawbacks TEXT[], -- Negative aspects

  -- Tags
  tags TEXT[], -- Custom user tags

  -- Media
  photos TEXT[], -- Array of photo URLs

  -- AI Analysis (populated by Charlotte AI)
  ai_summary TEXT,
  ai_recommendations JSONB DEFAULT '[]'::jsonb,
  ai_analyzed_at TIMESTAMPTZ,

  -- Metadata
  is_favorite BOOLEAN DEFAULT FALSE,
  is_private BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CHECK (overall_rating >= 1.0 AND overall_rating <= 5.0),
  CHECK (body_high IS NULL OR (body_high >= 0 AND body_high <= 10)),
  CHECK (head_high IS NULL OR (head_high >= 0 AND head_high <= 10))
);

CREATE INDEX idx_journal_user ON strain_journal_entries(user_id);
CREATE INDEX idx_journal_strain ON strain_journal_entries(strain_id);
CREATE INDEX idx_journal_consumed_at ON strain_journal_entries(consumed_at DESC);
CREATE INDEX idx_journal_rating ON strain_journal_entries(overall_rating DESC);
CREATE INDEX idx_journal_favorite ON strain_journal_entries(is_favorite) WHERE is_favorite = TRUE;

-- ============================================================================
-- QUICK RATINGS
-- ============================================================================

-- Table: strain_quick_ratings
-- Simple star ratings without full journal entry
CREATE TABLE IF NOT EXISTS strain_quick_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  strain_id UUID NOT NULL REFERENCES strains(id) ON DELETE CASCADE,

  rating DECIMAL(2,1) NOT NULL, -- 1.0 - 5.0
  quick_notes TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  CHECK (rating >= 1.0 AND rating <= 5.0),
  UNIQUE(user_id, strain_id, created_at) -- Allow multiple ratings over time
);

CREATE INDEX idx_quick_rating_user ON strain_quick_ratings(user_id);
CREATE INDEX idx_quick_rating_strain ON strain_quick_ratings(strain_id);

-- ============================================================================
-- EFFECT TEMPLATES
-- ============================================================================

-- Table: effect_templates
-- User-created templates for quick logging
CREATE TABLE IF NOT EXISTS effect_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  name TEXT NOT NULL,
  description TEXT,

  -- Template values (all optional)
  method TEXT,
  setting TEXT[],
  activities TEXT[],
  intention TEXT,

  -- Default effect ratings
  default_effects JSONB DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, name)
);

CREATE INDEX idx_templates_user ON effect_templates(user_id);

-- ============================================================================
-- STRAIN COMPARISONS
-- ============================================================================

-- Table: strain_comparisons
-- Side-by-side strain comparisons
CREATE TABLE IF NOT EXISTS strain_comparisons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  strain_a_id UUID NOT NULL REFERENCES strains(id) ON DELETE CASCADE,
  strain_b_id UUID NOT NULL REFERENCES strains(id) ON DELETE CASCADE,

  comparison_notes TEXT,
  winner TEXT, -- 'strain_a', 'strain_b', 'tie'

  created_at TIMESTAMPTZ DEFAULT NOW(),

  CHECK (strain_a_id != strain_b_id)
);

CREATE INDEX idx_comparison_user ON strain_comparisons(user_id);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- strain_journal_entries
ALTER TABLE strain_journal_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own journal entries"
  ON strain_journal_entries FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own journal entries"
  ON strain_journal_entries FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own journal entries"
  ON strain_journal_entries FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own journal entries"
  ON strain_journal_entries FOR DELETE
  USING (auth.uid() = user_id);

-- strain_quick_ratings
ALTER TABLE strain_quick_ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own ratings"
  ON strain_quick_ratings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own ratings"
  ON strain_quick_ratings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own ratings"
  ON strain_quick_ratings FOR DELETE
  USING (auth.uid() = user_id);

-- effect_templates
ALTER TABLE effect_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own templates"
  ON effect_templates FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own templates"
  ON effect_templates FOR ALL
  USING (auth.uid() = user_id);

-- strain_comparisons
ALTER TABLE strain_comparisons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own comparisons"
  ON strain_comparisons FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own comparisons"
  ON strain_comparisons FOR ALL
  USING (auth.uid() = user_id);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function: Get strain average rating
CREATE OR REPLACE FUNCTION get_strain_average_rating(p_strain_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  v_avg DECIMAL;
BEGIN
  SELECT AVG(overall_rating)
  INTO v_avg
  FROM strain_journal_entries
  WHERE strain_id = p_strain_id
    AND overall_rating IS NOT NULL;

  RETURN COALESCE(v_avg, 0);
END;
$$ LANGUAGE plpgsql;

-- Function: Get strain rating distribution
CREATE OR REPLACE FUNCTION get_strain_rating_distribution(p_strain_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_distribution JSONB;
BEGIN
  SELECT jsonb_object_agg(rating_bucket, count)
  INTO v_distribution
  FROM (
    SELECT
      CASE
        WHEN overall_rating >= 4.5 THEN '5_stars'
        WHEN overall_rating >= 3.5 THEN '4_stars'
        WHEN overall_rating >= 2.5 THEN '3_stars'
        WHEN overall_rating >= 1.5 THEN '2_stars'
        ELSE '1_star'
      END as rating_bucket,
      COUNT(*) as count
    FROM strain_journal_entries
    WHERE strain_id = p_strain_id
      AND overall_rating IS NOT NULL
    GROUP BY rating_bucket
  ) subq;

  RETURN COALESCE(v_distribution, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function: Get strain most common effects
CREATE OR REPLACE FUNCTION get_strain_common_effects(p_strain_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_effects JSONB;
BEGIN
  -- This is a simplified version
  -- In production, aggregate all effect fields

  SELECT jsonb_build_object(
    'avg_body_high', AVG(body_high),
    'avg_head_high', AVG(head_high),
    'avg_energy', AVG(energy_level),
    'avg_focus', AVG(focus),
    'avg_creativity', AVG(creativity),
    'avg_euphoria', AVG(euphoria),
    'avg_relaxation', AVG(physical_relaxation),
    'avg_happiness', AVG(happiness)
  )
  INTO v_effects
  FROM strain_journal_entries
  WHERE strain_id = p_strain_id;

  RETURN COALESCE(v_effects, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function: Auto-update strain_effects from journal entries
CREATE OR REPLACE FUNCTION update_strain_effects_from_journal()
RETURNS TRIGGER AS $$
BEGIN
  -- Update or insert strain_effects based on journal entry
  INSERT INTO strain_effects (
    user_id,
    strain_id,
    total_sessions,
    user_rating,
    first_used_at,
    last_used_at,
    updated_at
  )
  VALUES (
    NEW.user_id,
    NEW.strain_id,
    1,
    NEW.overall_rating,
    NEW.consumed_at,
    NEW.consumed_at,
    NOW()
  )
  ON CONFLICT (user_id, strain_id) DO UPDATE SET
    total_sessions = strain_effects.total_sessions + 1,
    user_rating = CASE
      WHEN NEW.overall_rating IS NOT NULL THEN
        (COALESCE(strain_effects.user_rating, 0) * strain_effects.total_sessions + NEW.overall_rating) / (strain_effects.total_sessions + 1)
      ELSE strain_effects.user_rating
    END,
    last_used_at = NEW.consumed_at,
    updated_at = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_journal_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger: Update strain_effects when journal entry created/updated
CREATE TRIGGER journal_update_strain_effects
  AFTER INSERT OR UPDATE ON strain_journal_entries
  FOR EACH ROW
  EXECUTE FUNCTION update_strain_effects_from_journal();

-- Trigger: Update updated_at on journal entry change
CREATE TRIGGER journal_update_timestamp
  BEFORE UPDATE ON strain_journal_entries
  FOR EACH ROW
  EXECUTE FUNCTION update_journal_updated_at();

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View: Strain journal entries with strain info
CREATE OR REPLACE VIEW strain_journal_with_strain AS
SELECT
  j.*,
  s.name as strain_name,
  s.category as strain_category,
  s.thc_min,
  s.thc_max,
  s.cbd_min,
  s.cbd_max,
  s.dominant_terpene
FROM strain_journal_entries j
JOIN strains s ON j.strain_id = s.id;

-- View: User's favorite strains based on journal
CREATE OR REPLACE VIEW user_favorite_strains AS
SELECT
  user_id,
  strain_id,
  COUNT(*) as entry_count,
  AVG(overall_rating) as avg_rating,
  MAX(consumed_at) as last_consumed
FROM strain_journal_entries
WHERE is_favorite = TRUE OR overall_rating >= 4.0
GROUP BY user_id, strain_id
HAVING COUNT(*) >= 2
ORDER BY avg_rating DESC, entry_count DESC;
