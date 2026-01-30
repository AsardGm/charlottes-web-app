-- Plant → Mind Feedback Loop
-- Personal science platform pro tracking strain effects

-- Table: consumption_logs
-- Ukládá záznamy o užití strain
CREATE TABLE IF NOT EXISTS consumption_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  strain_id TEXT NOT NULL, -- Reference to strain database

  -- Consumption details
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  amount FLOAT NOT NULL, -- grams
  method TEXT NOT NULL CHECK (method IN ('joint', 'vape', 'bong', 'edible', 'pipe', 'other')),

  -- Context
  time_of_day TEXT CHECK (time_of_day IN ('morning', 'afternoon', 'evening', 'night')),
  context TEXT, -- 'work', 'relax', 'social', 'creative', etc.
  notes TEXT,

  -- Pre-consumption state (optional)
  pre_cognitive_score INT CHECK (pre_cognitive_score >= 0 AND pre_cognitive_score <= 100),
  pre_mood INT CHECK (pre_mood >= 1 AND pre_mood <= 10),
  pre_energy INT CHECK (pre_energy >= 1 AND pre_energy <= 10),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT consumption_logs_user_timestamp_key UNIQUE (user_id, timestamp)
);

CREATE INDEX idx_consumption_logs_user_timestamp ON consumption_logs(user_id, timestamp DESC);
CREATE INDEX idx_consumption_logs_strain ON consumption_logs(strain_id);

-- Table: post_consumption_checks
-- Quick assessment 30-60 min po užití
CREATE TABLE IF NOT EXISTS post_consumption_checks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  consumption_log_id UUID NOT NULL REFERENCES consumption_logs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Timing
  check_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  minutes_after_consumption INT, -- Calculated

  -- Subjective effects (1-10 scales)
  focus_score INT NOT NULL CHECK (focus_score >= 1 AND focus_score <= 10),
  mood_score INT NOT NULL CHECK (mood_score >= 1 AND mood_score <= 10),
  energy_score INT NOT NULL CHECK (energy_score >= 1 AND energy_score <= 10),
  anxiety_level INT NOT NULL CHECK (anxiety_level >= 0 AND anxiety_level <= 10), -- 0 = none, 10 = high
  creativity_score INT CHECK (creativity_score >= 1 AND creativity_score <= 10),

  -- Body state
  body_state TEXT NOT NULL CHECK (body_state IN ('relaxed', 'heavy', 'clear', 'tense', 'energized', 'numb')),

  -- Additional effects (optional)
  appetite_change TEXT CHECK (appetite_change IN ('increased', 'decreased', 'no_change')),
  pain_relief INT CHECK (pain_relief >= 0 AND pain_relief <= 10),

  -- Free text
  notes TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT post_checks_unique_per_consumption UNIQUE (consumption_log_id)
);

CREATE INDEX idx_post_checks_user ON post_consumption_checks(user_id);
CREATE INDEX idx_post_checks_consumption ON post_consumption_checks(consumption_log_id);

-- Table: strain_user_correlations
-- Ukládá vypočítané korelace mezi strain a efekty pro konkrétního usera
CREATE TABLE IF NOT EXISTS strain_user_correlations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  strain_id TEXT NOT NULL,

  -- Aggregated stats (from post-checks)
  total_consumptions INT NOT NULL DEFAULT 0,
  avg_focus_score FLOAT,
  avg_mood_score FLOAT,
  avg_energy_score FLOAT,
  avg_anxiety_level FLOAT,
  avg_creativity_score FLOAT,

  -- Overall rating for this user
  personal_rating FLOAT, -- 0-10, calculated

  -- Most common effects
  most_common_body_state TEXT,

  -- Last updated
  last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT strain_user_correlations_unique UNIQUE (user_id, strain_id)
);

CREATE INDEX idx_strain_correlations_user ON strain_user_correlations(user_id);
CREATE INDEX idx_strain_correlations_rating ON strain_user_correlations(user_id, personal_rating DESC);

-- Table: terpene_user_sensitivities
-- Tracking jak konkrétní terpeny ovlivňují usera
CREATE TABLE IF NOT EXISTS terpene_user_sensitivities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  terpene_name TEXT NOT NULL,

  -- Effect modifiers (calculated from correlations)
  focus_modifier FLOAT, -- +/- percentage
  mood_modifier FLOAT,
  anxiety_modifier FLOAT,
  energy_modifier FLOAT,

  -- Confidence (based on sample size)
  sample_size INT NOT NULL DEFAULT 0,
  confidence_score FLOAT, -- 0-1

  last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT terpene_sensitivities_unique UNIQUE (user_id, terpene_name)
);

CREATE INDEX idx_terpene_sensitivities_user ON terpene_user_sensitivities(user_id);

-- Table: consumption_insights
-- Generated insights pro usera
CREATE TABLE IF NOT EXISTS consumption_insights (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Insight details
  insight_type TEXT NOT NULL CHECK (insight_type IN (
    'strain_recommendation',
    'terpene_sensitivity',
    'timing_pattern',
    'tolerance_warning',
    'cognitive_impact',
    'best_match',
    'worst_match'
  )),

  title TEXT NOT NULL,
  description TEXT NOT NULL,

  -- Supporting data
  data JSONB, -- Flexible data storage for different insight types

  -- Metadata
  confidence_score FLOAT, -- 0-1
  priority INT DEFAULT 0, -- For sorting
  is_active BOOLEAN DEFAULT true,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ -- Optional expiry
);

CREATE INDEX idx_insights_user_active ON consumption_insights(user_id, is_active, priority DESC);
CREATE INDEX idx_insights_type ON consumption_insights(user_id, insight_type);

-- RLS Policies
ALTER TABLE consumption_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_consumption_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE strain_user_correlations ENABLE ROW LEVEL SECURITY;
ALTER TABLE terpene_user_sensitivities ENABLE ROW LEVEL SECURITY;
ALTER TABLE consumption_insights ENABLE ROW LEVEL SECURITY;

-- consumption_logs policies
CREATE POLICY "Users can view their own consumption logs"
  ON consumption_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own consumption logs"
  ON consumption_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own consumption logs"
  ON consumption_logs FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own consumption logs"
  ON consumption_logs FOR DELETE
  USING (auth.uid() = user_id);

-- post_consumption_checks policies
CREATE POLICY "Users can view their own post-checks"
  ON post_consumption_checks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own post-checks"
  ON post_consumption_checks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- strain_user_correlations policies (read-only for users, updated by triggers)
CREATE POLICY "Users can view their own correlations"
  ON strain_user_correlations FOR SELECT
  USING (auth.uid() = user_id);

-- terpene_user_sensitivities policies
CREATE POLICY "Users can view their own terpene sensitivities"
  ON terpene_user_sensitivities FOR SELECT
  USING (auth.uid() = user_id);

-- consumption_insights policies
CREATE POLICY "Users can view their own insights"
  ON consumption_insights FOR SELECT
  USING (auth.uid() = user_id);

-- Function: calculate_minutes_after_consumption
CREATE OR REPLACE FUNCTION calculate_minutes_after_consumption()
RETURNS TRIGGER AS $$
BEGIN
  NEW.minutes_after_consumption := EXTRACT(EPOCH FROM (NEW.check_timestamp - (
    SELECT timestamp FROM consumption_logs WHERE id = NEW.consumption_log_id
  ))) / 60;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: auto-calculate minutes after consumption
DROP TRIGGER IF EXISTS trigger_calculate_minutes_after ON post_consumption_checks;
CREATE TRIGGER trigger_calculate_minutes_after
  BEFORE INSERT ON post_consumption_checks
  FOR EACH ROW
  EXECUTE FUNCTION calculate_minutes_after_consumption();

-- Function: update_strain_correlations
-- Přepočítá korelace pro strain když je přidán nový post-check
CREATE OR REPLACE FUNCTION update_strain_correlations()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id UUID;
  v_strain_id TEXT;
BEGIN
  -- Get user_id and strain_id from consumption log
  SELECT user_id, strain_id INTO v_user_id, v_strain_id
  FROM consumption_logs
  WHERE id = NEW.consumption_log_id;

  -- Update or insert correlation
  INSERT INTO strain_user_correlations (
    user_id,
    strain_id,
    total_consumptions,
    avg_focus_score,
    avg_mood_score,
    avg_energy_score,
    avg_anxiety_level,
    avg_creativity_score,
    personal_rating,
    last_updated
  )
  SELECT
    v_user_id,
    v_strain_id,
    COUNT(*),
    AVG(pc.focus_score),
    AVG(pc.mood_score),
    AVG(pc.energy_score),
    AVG(pc.anxiety_level),
    AVG(pc.creativity_score),
    -- Personal rating: high mood/focus/energy, low anxiety
    (AVG(pc.mood_score) + AVG(pc.focus_score) + AVG(pc.energy_score) - AVG(pc.anxiety_level)) / 3.0,
    NOW()
  FROM consumption_logs cl
  JOIN post_consumption_checks pc ON cl.id = pc.consumption_log_id
  WHERE cl.user_id = v_user_id AND cl.strain_id = v_strain_id
  GROUP BY v_user_id, v_strain_id
  ON CONFLICT (user_id, strain_id) DO UPDATE SET
    total_consumptions = EXCLUDED.total_consumptions,
    avg_focus_score = EXCLUDED.avg_focus_score,
    avg_mood_score = EXCLUDED.avg_mood_score,
    avg_energy_score = EXCLUDED.avg_energy_score,
    avg_anxiety_level = EXCLUDED.avg_anxiety_level,
    avg_creativity_score = EXCLUDED.avg_creativity_score,
    personal_rating = EXCLUDED.personal_rating,
    last_updated = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: update correlations after post-check
DROP TRIGGER IF EXISTS trigger_update_correlations ON post_consumption_checks;
CREATE TRIGGER trigger_update_correlations
  AFTER INSERT ON post_consumption_checks
  FOR EACH ROW
  EXECUTE FUNCTION update_strain_correlations();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON consumption_logs TO authenticated;
GRANT SELECT, INSERT ON post_consumption_checks TO authenticated;
GRANT SELECT ON strain_user_correlations TO authenticated;
GRANT SELECT ON terpene_user_sensitivities TO authenticated;
GRANT SELECT ON consumption_insights TO authenticated;
