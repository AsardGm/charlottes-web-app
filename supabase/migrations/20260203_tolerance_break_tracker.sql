-- Tolerance Break Tracker
-- Comprehensive support system for cannabis tolerance breaks

-- Table: tolerance_breaks
CREATE TABLE IF NOT EXISTS tolerance_breaks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- T-break details
  start_date TIMESTAMPTZ NOT NULL,
  target_end_date TIMESTAMPTZ NOT NULL,
  target_days INT NOT NULL CHECK (target_days > 0),

  -- Status
  status TEXT NOT NULL CHECK (status IN ('active', 'completed', 'failed')),

  -- Motivation
  motivation TEXT NOT NULL CHECK (motivation IN (
    'lowerTolerance',
    'health',
    'saveMoney',
    'resetReceptors',
    'proveMyself',
    'other'
  )),
  custom_motivation TEXT,

  -- Progress
  days_completed INT NOT NULL DEFAULT 0 CHECK (days_completed >= 0),
  completed_date TIMESTAMPTZ,
  failed_date TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table: tbreak_checkins
-- Daily check-ins during tolerance break
CREATE TABLE IF NOT EXISTS tbreak_checkins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tbreak_id UUID NOT NULL REFERENCES tolerance_breaks(id) ON DELETE CASCADE,

  -- Date & progress
  date DATE NOT NULL,
  day_number INT NOT NULL CHECK (day_number > 0),

  -- Mood & feelings (1-10 scale)
  mood_score INT NOT NULL CHECK (mood_score >= 1 AND mood_score <= 10),
  had_cravings BOOLEAN NOT NULL DEFAULT false,
  sleep_quality INT NOT NULL CHECK (sleep_quality >= 1 AND sleep_quality <= 10),
  anxiety_level INT NOT NULL CHECK (anxiety_level >= 1 AND anxiety_level <= 10),

  -- Symptoms (array of strings)
  symptoms TEXT[],
  notes TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Constraints
  CONSTRAINT tbreak_checkins_unique_date UNIQUE (tbreak_id, date)
);

-- Indexes
CREATE INDEX idx_tolerance_breaks_user_status
ON tolerance_breaks(user_id, status);

CREATE INDEX idx_tolerance_breaks_user_created
ON tolerance_breaks(user_id, created_at DESC);

CREATE INDEX idx_tbreak_checkins_tbreak_date
ON tbreak_checkins(tbreak_id, date DESC);

-- RLS Policies
ALTER TABLE tolerance_breaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE tbreak_checkins ENABLE ROW LEVEL SECURITY;

-- tolerance_breaks policies
CREATE POLICY "Users can view their own tolerance breaks"
  ON tolerance_breaks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own tolerance breaks"
  ON tolerance_breaks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tolerance breaks"
  ON tolerance_breaks FOR UPDATE
  USING (auth.uid() = user_id);

-- tbreak_checkins policies
CREATE POLICY "Users can view their own check-ins"
  ON tbreak_checkins FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tolerance_breaks
      WHERE tolerance_breaks.id = tbreak_checkins.tbreak_id
      AND tolerance_breaks.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert their own check-ins"
  ON tbreak_checkins FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tolerance_breaks
      WHERE tolerance_breaks.id = tbreak_checkins.tbreak_id
      AND tolerance_breaks.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own check-ins"
  ON tbreak_checkins FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM tolerance_breaks
      WHERE tolerance_breaks.id = tbreak_checkins.tbreak_id
      AND tolerance_breaks.user_id = auth.uid()
    )
  );

-- Function: Update days_completed when check-in is added
CREATE OR REPLACE FUNCTION update_tbreak_progress()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE tolerance_breaks
  SET
    days_completed = NEW.day_number,
    updated_at = NOW()
  WHERE id = NEW.tbreak_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Auto-update progress on check-in
DROP TRIGGER IF EXISTS trigger_update_tbreak_progress ON tbreak_checkins;
CREATE TRIGGER trigger_update_tbreak_progress
  AFTER INSERT ON tbreak_checkins
  FOR EACH ROW
  EXECUTE FUNCTION update_tbreak_progress();

-- Function: Auto-complete T-break when target reached
CREATE OR REPLACE FUNCTION check_tbreak_completion()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.days_completed >= NEW.target_days AND NEW.status = 'active' THEN
    NEW.status := 'completed';
    NEW.completed_date := NOW();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Check completion on update
DROP TRIGGER IF EXISTS trigger_check_tbreak_completion ON tolerance_breaks;
CREATE TRIGGER trigger_check_tbreak_completion
  BEFORE UPDATE ON tolerance_breaks
  FOR EACH ROW
  WHEN (OLD.days_completed IS DISTINCT FROM NEW.days_completed)
  EXECUTE FUNCTION check_tbreak_completion();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON tolerance_breaks TO authenticated;
GRANT SELECT, INSERT, UPDATE ON tbreak_checkins TO authenticated;

-- Comments
COMMENT ON TABLE tolerance_breaks IS 'Tolerance breaks - user-initiated breaks from consumption for tolerance reset and harm reduction';
COMMENT ON TABLE tbreak_checkins IS 'Daily check-ins during tolerance break - mood, cravings, symptoms tracking';
COMMENT ON COLUMN tolerance_breaks.status IS 'active=ongoing, completed=successfully finished, failed=ended early';
COMMENT ON COLUMN tbreak_checkins.symptoms IS 'Array of withdrawal symptoms experienced that day';
