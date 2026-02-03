-- Personal Science Dashboard Schema
-- Tracks correlations between strains, cognitive performance, and well-being

-- ============================================================================
-- STRAIN EFFECTIVENESS TRACKING
-- ============================================================================

-- Table: strain_effects
-- Aggregates user's subjective experience with specific strains
CREATE TABLE IF NOT EXISTS strain_effects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  strain_id UUID NOT NULL REFERENCES strains(id) ON DELETE CASCADE,

  -- Aggregated metrics (calculated from post-checks)
  total_sessions INT DEFAULT 0,
  avg_mood_before DECIMAL(3,1),
  avg_mood_after DECIMAL(3,1),
  avg_energy_before DECIMAL(3,1),
  avg_energy_after DECIMAL(3,1),
  avg_focus_before DECIMAL(3,1),
  avg_focus_after DECIMAL(3,1),
  avg_anxiety_before DECIMAL(3,1),
  avg_anxiety_after DECIMAL(3,1),

  -- Cognitive impact
  avg_cognitive_score DECIMAL(5,2),
  cognitive_sessions INT DEFAULT 0,

  -- Effects distribution (JSONB array of effect tags with counts)
  common_effects JSONB DEFAULT '[]'::jsonb,

  -- User rating
  user_rating DECIMAL(2,1),

  -- Timestamps
  first_used_at TIMESTAMPTZ,
  last_used_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, strain_id)
);

CREATE INDEX idx_strain_effects_user ON strain_effects(user_id);
CREATE INDEX idx_strain_effects_strain ON strain_effects(strain_id);
CREATE INDEX idx_strain_effects_rating ON strain_effects(user_rating DESC);

-- ============================================================================
-- CORRELATION ANALYSIS
-- ============================================================================

-- Table: correlation_insights
-- Stores computed correlations between various factors
CREATE TABLE IF NOT EXISTS correlation_insights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Correlation type
  type TEXT NOT NULL, -- 'strain_cognitive', 'time_of_day', 'consumption_pattern', etc.

  -- Factor A and B
  factor_a TEXT NOT NULL,
  factor_b TEXT NOT NULL,

  -- Statistical measures
  correlation_coefficient DECIMAL(4,3), -- -1.0 to 1.0
  p_value DECIMAL(10,8),
  sample_size INT,
  confidence_level TEXT, -- 'high', 'medium', 'low'

  -- Insight data
  insight_data JSONB DEFAULT '{}'::jsonb,

  -- Human-readable insight
  summary TEXT,
  recommendation TEXT,

  -- Timestamps
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ, -- Invalidate after 30 days

  UNIQUE(user_id, type, factor_a, factor_b)
);

CREATE INDEX idx_correlation_user ON correlation_insights(user_id);
CREATE INDEX idx_correlation_type ON correlation_insights(type);
CREATE INDEX idx_correlation_expires ON correlation_insights(expires_at);

-- ============================================================================
-- OPTIMAL CONSUMPTION PATTERNS
-- ============================================================================

-- Table: consumption_patterns
-- Analyzes when user performs best cognitively
CREATE TABLE IF NOT EXISTS consumption_patterns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Time-based patterns
  best_time_of_day TEXT[], -- e.g., ['evening', 'night']
  worst_time_of_day TEXT[],

  best_day_of_week TEXT[],
  worst_day_of_week TEXT[],

  -- Dosage patterns
  optimal_dosage_range JSONB, -- {min: X, max: Y, unit: 'g'}

  -- Frequency patterns
  optimal_frequency TEXT, -- 'daily', 'every_other_day', 'weekly'
  break_recommendation INT, -- Days recommended between sessions

  -- Method patterns
  best_methods TEXT[], -- ['vaporizer', 'edible']

  -- Combined with activities
  best_activities JSONB, -- [{activity: 'creative_work', boost: 0.8}, ...]

  -- Confidence score
  confidence DECIMAL(3,2), -- 0.0 to 1.0

  -- Metadata
  based_on_sessions INT,
  calculated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id)
);

CREATE INDEX idx_patterns_user ON consumption_patterns(user_id);

-- ============================================================================
-- STRAIN RECOMMENDATIONS
-- ============================================================================

-- Table: strain_recommendations
-- AI-generated strain recommendations based on personal science
CREATE TABLE IF NOT EXISTS strain_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  strain_id UUID NOT NULL REFERENCES strains(id) ON DELETE CASCADE,

  -- Recommendation score
  score DECIMAL(3,2), -- 0.0 to 1.0

  -- Reasoning
  reasons JSONB DEFAULT '[]'::jsonb, -- Array of reason objects

  -- Context
  recommended_for TEXT[], -- ['focus', 'relaxation', 'creativity']
  recommended_times TEXT[], -- ['evening', 'weekend']

  -- Expected outcomes (based on similar users or user's past data)
  expected_mood_boost DECIMAL(3,1),
  expected_energy_change DECIMAL(3,1),
  expected_focus_change DECIMAL(3,1),

  -- Status
  is_tried BOOLEAN DEFAULT FALSE,
  actual_rating DECIMAL(2,1),

  -- Timestamps
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '30 days',
  tried_at TIMESTAMPTZ,

  UNIQUE(user_id, strain_id)
);

CREATE INDEX idx_recommendations_user ON strain_recommendations(user_id);
CREATE INDEX idx_recommendations_score ON strain_recommendations(score DESC);
CREATE INDEX idx_recommendations_expires ON strain_recommendations(expires_at);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- strain_effects
ALTER TABLE strain_effects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own strain effects"
  ON strain_effects FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own strain effects"
  ON strain_effects FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own strain effects"
  ON strain_effects FOR UPDATE
  USING (auth.uid() = user_id);

-- correlation_insights
ALTER TABLE correlation_insights ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own correlations"
  ON correlation_insights FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own correlations"
  ON correlation_insights FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- consumption_patterns
ALTER TABLE consumption_patterns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own patterns"
  ON consumption_patterns FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own patterns"
  ON consumption_patterns FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own patterns"
  ON consumption_patterns FOR UPDATE
  USING (auth.uid() = user_id);

-- strain_recommendations
ALTER TABLE strain_recommendations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own recommendations"
  ON strain_recommendations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own recommendations"
  ON strain_recommendations FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function: Update strain effects after new post-check
CREATE OR REPLACE FUNCTION update_strain_effects()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process if consumption log has strain_id
  IF NEW.strain_id IS NOT NULL THEN
    INSERT INTO strain_effects (
      user_id,
      strain_id,
      total_sessions,
      avg_mood_before,
      avg_mood_after,
      avg_energy_before,
      avg_energy_after,
      avg_focus_before,
      avg_focus_after,
      avg_anxiety_before,
      avg_anxiety_after,
      first_used_at,
      last_used_at
    )
    SELECT
      NEW.user_id,
      NEW.strain_id,
      1,
      NEW.mood_before,
      NEW.mood_after,
      NEW.energy_before,
      NEW.energy_after,
      NEW.focus_before,
      NEW.focus_after,
      NEW.anxiety_before,
      NEW.anxiety_after,
      NEW.created_at,
      NEW.created_at
    ON CONFLICT (user_id, strain_id) DO UPDATE SET
      total_sessions = strain_effects.total_sessions + 1,
      avg_mood_before = (strain_effects.avg_mood_before * strain_effects.total_sessions + NEW.mood_before) / (strain_effects.total_sessions + 1),
      avg_mood_after = (strain_effects.avg_mood_after * strain_effects.total_sessions + NEW.mood_after) / (strain_effects.total_sessions + 1),
      avg_energy_before = (strain_effects.avg_energy_before * strain_effects.total_sessions + NEW.energy_before) / (strain_effects.total_sessions + 1),
      avg_energy_after = (strain_effects.avg_energy_after * strain_effects.total_sessions + NEW.energy_after) / (strain_effects.total_sessions + 1),
      avg_focus_before = (strain_effects.avg_focus_before * strain_effects.total_sessions + NEW.focus_before) / (strain_effects.total_sessions + 1),
      avg_focus_after = (strain_effects.avg_focus_after * strain_effects.total_sessions + NEW.focus_after) / (strain_effects.total_sessions + 1),
      avg_anxiety_before = (strain_effects.avg_anxiety_before * strain_effects.total_sessions + NEW.anxiety_before) / (strain_effects.total_sessions + 1),
      avg_anxiety_after = (strain_effects.avg_anxiety_after * strain_effects.total_sessions + NEW.anxiety_after) / (strain_effects.total_sessions + 1),
      last_used_at = NEW.created_at,
      updated_at = NOW();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function: Calculate correlation coefficient (Pearson's r)
CREATE OR REPLACE FUNCTION calculate_correlation(
  p_user_id UUID,
  p_factor_a TEXT,
  p_factor_b TEXT
)
RETURNS DECIMAL AS $$
DECLARE
  v_correlation DECIMAL;
BEGIN
  -- This is a simplified placeholder
  -- In production, implement proper Pearson correlation calculation
  -- using arrays of x and y values

  v_correlation := 0.0;

  RETURN v_correlation;
END;
$$ LANGUAGE plpgsql;

-- Function: Generate strain recommendations
CREATE OR REPLACE FUNCTION generate_strain_recommendations(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Delete expired recommendations
  DELETE FROM strain_recommendations
  WHERE user_id = p_user_id AND expires_at < NOW();

  -- Generate new recommendations based on:
  -- 1. Strains with positive effects for similar users
  -- 2. Strains matching user's preferred terpene profiles
  -- 3. Strains user hasn't tried yet

  -- This is a placeholder - actual implementation would use ML/similarity algorithms

  RAISE NOTICE 'Generating recommendations for user %', p_user_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger: Update strain effects on post-check completion
-- Note: This assumes consumption_logs table has been extended with post-check fields
-- If post-checks are in separate table, adjust accordingly

-- CREATE TRIGGER update_strain_effects_trigger
--   AFTER INSERT OR UPDATE ON consumption_logs
--   FOR EACH ROW
--   WHEN (NEW.mood_after IS NOT NULL) -- Only when post-check is completed
--   EXECUTE FUNCTION update_strain_effects();

-- ============================================================================
-- SEED DATA / INITIAL SETUP
-- ============================================================================

-- Function to call for initial pattern calculation for a user
CREATE OR REPLACE FUNCTION initialize_personal_science(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Calculate initial patterns if user has enough data
  -- Minimum 10 sessions recommended

  PERFORM generate_strain_recommendations(p_user_id);

  RAISE NOTICE 'Initialized personal science for user %', p_user_id;
END;
$$ LANGUAGE plpgsql;
