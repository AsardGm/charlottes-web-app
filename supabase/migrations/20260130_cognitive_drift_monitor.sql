-- Cognitive Drift Monitor tables
-- Měří mentální stav uživatele pomocí 3 mikrotestů (reakce, paměť, vzory)

-- Table: cognitive_test_results
-- Ukládá výsledky jednotlivých testů
CREATE TABLE IF NOT EXISTS cognitive_test_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Reaction time test
  reaction_time JSONB NOT NULL,
  -- Structure: {
  --   reaction_times_ms: [int],
  --   average_ms: int,
  --   best_ms: int,
  --   worst_ms: int,
  --   score: int (0-100)
  -- }

  -- Memory flash test
  memory_flash JSONB NOT NULL,
  -- Structure: {
  --   total_attempts: int,
  --   correct_answers: int,
  --   score: int (0-100)
  -- }

  -- Pattern recognition test
  pattern_recognition JSONB NOT NULL,
  -- Structure: {
  --   total_attempts: int,
  --   correct_answers: int,
  --   average_time_ms: int,
  --   score: int (0-100)
  -- }

  -- Overall results
  total_score INT NOT NULL CHECK (total_score >= 0 AND total_score <= 100),
  status TEXT NOT NULL CHECK (status IN ('sharp', 'normal', 'tired', 'blurry', 'overloaded')),

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Indexes
  CONSTRAINT cognitive_test_results_user_timestamp_key UNIQUE (user_id, timestamp)
);

-- Index for fast queries by user and date
CREATE INDEX idx_cognitive_test_results_user_timestamp
ON cognitive_test_results(user_id, timestamp DESC);

-- Table: cognitive_baselines
-- Ukládá baseline (průměr posledních 7 testů) pro každého uživatele
CREATE TABLE IF NOT EXISTS cognitive_baselines (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Baseline metrics (calculated from last 7 tests)
  average_score INT NOT NULL CHECK (average_score >= 0 AND average_score <= 100),
  average_reaction_ms INT NOT NULL,
  average_memory_accuracy FLOAT NOT NULL CHECK (average_memory_accuracy >= 0 AND average_memory_accuracy <= 1),
  average_pattern_accuracy FLOAT NOT NULL CHECK (average_pattern_accuracy >= 0 AND average_pattern_accuracy <= 1),

  -- Stats
  total_tests INT NOT NULL DEFAULT 0,
  current_streak INT NOT NULL DEFAULT 0, -- Consecutive days with tests
  longest_streak INT NOT NULL DEFAULT 0,
  last_test_date DATE,

  -- Timestamps
  last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table: cognitive_daily_streak
-- Tracking denních testů pro streak badge
CREATE TABLE IF NOT EXISTS cognitive_daily_tests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  test_date DATE NOT NULL,
  test_count INT NOT NULL DEFAULT 1,

  CONSTRAINT cognitive_daily_tests_user_date_key UNIQUE (user_id, test_date)
);

CREATE INDEX idx_cognitive_daily_tests_user_date
ON cognitive_daily_tests(user_id, test_date DESC);

-- RLS Policies
ALTER TABLE cognitive_test_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE cognitive_baselines ENABLE ROW LEVEL SECURITY;
ALTER TABLE cognitive_daily_tests ENABLE ROW LEVEL SECURITY;

-- cognitive_test_results policies
CREATE POLICY "Users can view their own test results"
  ON cognitive_test_results FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own test results"
  ON cognitive_test_results FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- cognitive_baselines policies
CREATE POLICY "Users can view their own baseline"
  ON cognitive_baselines FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own baseline"
  ON cognitive_baselines FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own baseline"
  ON cognitive_baselines FOR UPDATE
  USING (auth.uid() = user_id);

-- cognitive_daily_tests policies
CREATE POLICY "Users can view their own daily tests"
  ON cognitive_daily_tests FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own daily tests"
  ON cognitive_daily_tests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own daily tests"
  ON cognitive_daily_tests FOR UPDATE
  USING (auth.uid() = user_id);

-- Function: update_cognitive_baseline
-- Automaticky přepočítá baseline po vložení nového testu
CREATE OR REPLACE FUNCTION update_cognitive_baseline()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id UUID;
  v_avg_score INT;
  v_avg_reaction INT;
  v_avg_memory_acc FLOAT;
  v_avg_pattern_acc FLOAT;
  v_total_tests INT;
  v_current_streak INT;
  v_longest_streak INT;
  v_last_test_date DATE;
  v_yesterday DATE;
BEGIN
  v_user_id := NEW.user_id;
  v_last_test_date := DATE(NEW.timestamp);
  v_yesterday := v_last_test_date - INTERVAL '1 day';

  -- Calculate averages from last 7 tests
  SELECT
    ROUND(AVG(total_score))::INT,
    ROUND(AVG((reaction_time->>'average_ms')::INT))::INT,
    AVG(((memory_flash->>'correct_answers')::FLOAT / (memory_flash->>'total_attempts')::FLOAT)),
    AVG(((pattern_recognition->>'correct_answers')::FLOAT / (pattern_recognition->>'total_attempts')::FLOAT)),
    COUNT(*)::INT
  INTO
    v_avg_score,
    v_avg_reaction,
    v_avg_memory_acc,
    v_avg_pattern_acc,
    v_total_tests
  FROM (
    SELECT * FROM cognitive_test_results
    WHERE user_id = v_user_id
    ORDER BY timestamp DESC
    LIMIT 7
  ) recent_tests;

  -- Calculate streak
  SELECT
    COALESCE(current_streak, 0),
    COALESCE(longest_streak, 0)
  INTO v_current_streak, v_longest_streak
  FROM cognitive_baselines
  WHERE user_id = v_user_id;

  -- Check if test was done yesterday or today
  IF EXISTS (
    SELECT 1 FROM cognitive_daily_tests
    WHERE user_id = v_user_id
    AND test_date = v_yesterday
  ) THEN
    v_current_streak := v_current_streak + 1;
  ELSIF NOT EXISTS (
    SELECT 1 FROM cognitive_daily_tests
    WHERE user_id = v_user_id
    AND test_date = v_last_test_date
  ) THEN
    v_current_streak := 1;
  END IF;

  -- Update longest streak
  IF v_current_streak > v_longest_streak THEN
    v_longest_streak := v_current_streak;
  END IF;

  -- Update or insert baseline
  INSERT INTO cognitive_baselines (
    user_id,
    average_score,
    average_reaction_ms,
    average_memory_accuracy,
    average_pattern_accuracy,
    total_tests,
    current_streak,
    longest_streak,
    last_test_date,
    last_updated
  ) VALUES (
    v_user_id,
    v_avg_score,
    v_avg_reaction,
    v_avg_memory_acc,
    v_avg_pattern_acc,
    v_total_tests,
    v_current_streak,
    v_longest_streak,
    v_last_test_date,
    NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    average_score = EXCLUDED.average_score,
    average_reaction_ms = EXCLUDED.average_reaction_ms,
    average_memory_accuracy = EXCLUDED.average_memory_accuracy,
    average_pattern_accuracy = EXCLUDED.average_pattern_accuracy,
    total_tests = (
      SELECT COUNT(*) FROM cognitive_test_results WHERE user_id = v_user_id
    ),
    current_streak = EXCLUDED.current_streak,
    longest_streak = EXCLUDED.longest_streak,
    last_test_date = EXCLUDED.last_test_date,
    last_updated = NOW();

  -- Update daily tests
  INSERT INTO cognitive_daily_tests (user_id, test_date, test_count)
  VALUES (v_user_id, v_last_test_date, 1)
  ON CONFLICT (user_id, test_date) DO UPDATE SET
    test_count = cognitive_daily_tests.test_count + 1;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: update baseline after test insert
DROP TRIGGER IF EXISTS trigger_update_cognitive_baseline ON cognitive_test_results;
CREATE TRIGGER trigger_update_cognitive_baseline
  AFTER INSERT ON cognitive_test_results
  FOR EACH ROW
  EXECUTE FUNCTION update_cognitive_baseline();

-- Grant permissions
GRANT SELECT, INSERT ON cognitive_test_results TO authenticated;
GRANT SELECT, INSERT, UPDATE ON cognitive_baselines TO authenticated;
GRANT SELECT, INSERT, UPDATE ON cognitive_daily_tests TO authenticated;
