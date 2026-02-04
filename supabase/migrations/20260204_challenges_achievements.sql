-- Challenges & Achievements System
-- Gamification layer to motivate healthy cannabis use

-- ============================================================================
-- CHALLENGES
-- ============================================================================

-- Table: challenges
-- Predefined challenges for users to complete
CREATE TABLE IF NOT EXISTS challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Challenge info
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL, -- 'tbreak', 'journal', 'cognitive', 'social', 'wellness'

  -- Requirements
  target_type TEXT NOT NULL, -- 'streak', 'count', 'quality', 'duration'
  target_value INT NOT NULL,
  target_unit TEXT, -- 'days', 'entries', 'tests', 'score'

  -- Metadata
  difficulty TEXT NOT NULL, -- 'easy', 'medium', 'hard', 'legendary'
  points INT DEFAULT 0,
  badge_icon TEXT,
  badge_color TEXT,

  -- Timing
  is_repeatable BOOLEAN DEFAULT FALSE,
  cooldown_days INT, -- Days before can repeat

  -- Visibility
  is_active BOOLEAN DEFAULT TRUE,
  required_level INT DEFAULT 0, -- Minimum user level to see

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_challenges_category ON challenges(category);
CREATE INDEX idx_challenges_difficulty ON challenges(difficulty);
CREATE INDEX idx_challenges_active ON challenges(is_active) WHERE is_active = TRUE;

-- Table: user_challenges
-- User progress on challenges
CREATE TABLE IF NOT EXISTS user_challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,

  -- Progress tracking
  status TEXT NOT NULL DEFAULT 'in_progress', -- 'in_progress', 'completed', 'failed', 'abandoned'
  current_progress INT DEFAULT 0,
  target_progress INT NOT NULL,

  -- Timestamps
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ, -- For time-limited challenges

  -- Streak tracking (for streak-based challenges)
  current_streak INT DEFAULT 0,
  longest_streak INT DEFAULT 0,
  last_activity_date DATE,

  -- Metadata
  notes TEXT,

  UNIQUE(user_id, challenge_id, started_at)
);

CREATE INDEX idx_user_challenges_user ON user_challenges(user_id);
CREATE INDEX idx_user_challenges_status ON user_challenges(status);
CREATE INDEX idx_user_challenges_completed ON user_challenges(completed_at DESC);

-- ============================================================================
-- ACHIEVEMENTS
-- ============================================================================

-- Table: achievements
-- Unlockable achievements with conditions
CREATE TABLE IF NOT EXISTS achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Achievement info
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,

  -- Visual
  icon TEXT NOT NULL,
  color TEXT,
  rarity TEXT NOT NULL, -- 'common', 'rare', 'epic', 'legendary'

  -- Unlock conditions (JSONB for flexibility)
  unlock_conditions JSONB NOT NULL,
  -- Examples:
  -- {"type": "challenge_complete", "challenge_ids": ["uuid1", "uuid2"]}
  -- {"type": "streak", "days": 7, "activity": "journal"}
  -- {"type": "total_count", "metric": "journal_entries", "count": 100}
  -- {"type": "quality", "metric": "avg_rating", "value": 4.5}

  -- Rewards
  points INT DEFAULT 0,
  unlocks_feature TEXT, -- Optional feature unlock

  -- Visibility
  is_secret BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_achievements_category ON achievements(category);
CREATE INDEX idx_achievements_rarity ON achievements(rarity);
CREATE INDEX idx_achievements_active ON achievements(is_active) WHERE is_active = TRUE;

-- Table: user_achievements
-- User's unlocked achievements
CREATE TABLE IF NOT EXISTS user_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,

  -- Unlock info
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  progress_data JSONB, -- Additional data about how it was unlocked

  -- Display
  is_showcased BOOLEAN DEFAULT FALSE, -- Display on profile

  UNIQUE(user_id, achievement_id)
);

CREATE INDEX idx_user_achievements_user ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_unlocked ON user_achievements(unlocked_at DESC);
CREATE INDEX idx_user_achievements_showcased ON user_achievements(is_showcased) WHERE is_showcased = TRUE;

-- ============================================================================
-- USER STATS & LEVELS
-- ============================================================================

-- Table: user_gamification_stats
-- Aggregate user stats for gamification
CREATE TABLE IF NOT EXISTS user_gamification_stats (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Points & Level
  total_points INT DEFAULT 0,
  current_level INT DEFAULT 1,
  points_to_next_level INT DEFAULT 100,

  -- Counts
  challenges_completed INT DEFAULT 0,
  achievements_unlocked INT DEFAULT 0,

  -- Streaks
  current_daily_streak INT DEFAULT 0,
  longest_daily_streak INT DEFAULT 0,
  last_activity_date DATE,

  -- Milestones
  total_journal_entries INT DEFAULT 0,
  total_tbreak_days INT DEFAULT 0,
  total_cognitive_tests INT DEFAULT 0,

  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_gamification_level ON user_gamification_stats(current_level DESC);
CREATE INDEX idx_gamification_points ON user_gamification_stats(total_points DESC);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- challenges - public read
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active challenges"
  ON challenges FOR SELECT
  USING (is_active = TRUE);

-- user_challenges
ALTER TABLE user_challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own challenges"
  ON user_challenges FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own challenges"
  ON user_challenges FOR ALL
  USING (auth.uid() = user_id);

-- achievements - public read
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view non-secret achievements"
  ON achievements FOR SELECT
  USING (is_active = TRUE AND (is_secret = FALSE OR id IN (
    SELECT achievement_id FROM user_achievements WHERE user_id = auth.uid()
  )));

-- user_achievements
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own achievements"
  ON user_achievements FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own achievements"
  ON user_achievements FOR UPDATE
  USING (auth.uid() = user_id);

-- user_gamification_stats
ALTER TABLE user_gamification_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own stats"
  ON user_gamification_stats FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own stats"
  ON user_gamification_stats FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function: Award points to user
CREATE OR REPLACE FUNCTION award_points(p_user_id UUID, p_points INT)
RETURNS VOID AS $$
DECLARE
  v_current_points INT;
  v_current_level INT;
  v_new_points INT;
  v_points_for_next INT;
BEGIN
  -- Get current stats
  SELECT total_points, current_level, points_to_next_level
  INTO v_current_points, v_current_level, v_points_for_next
  FROM user_gamification_stats
  WHERE user_id = p_user_id;

  -- If no stats exist, create them
  IF NOT FOUND THEN
    INSERT INTO user_gamification_stats (user_id, total_points)
    VALUES (p_user_id, p_points);
    RETURN;
  END IF;

  v_new_points := v_current_points + p_points;

  -- Check for level up
  WHILE v_new_points >= v_points_for_next LOOP
    v_current_level := v_current_level + 1;
    v_new_points := v_new_points - v_points_for_next;
    v_points_for_next := v_points_for_next + (v_current_level * 50); -- Progressive leveling
  END LOOP;

  -- Update stats
  UPDATE user_gamification_stats
  SET
    total_points = total_points + p_points,
    current_level = v_current_level,
    points_to_next_level = v_points_for_next,
    updated_at = NOW()
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Complete challenge
CREATE OR REPLACE FUNCTION complete_challenge(p_user_challenge_id UUID)
RETURNS VOID AS $$
DECLARE
  v_user_id UUID;
  v_challenge_id UUID;
  v_points INT;
BEGIN
  -- Get challenge info
  SELECT uc.user_id, uc.challenge_id, c.points
  INTO v_user_id, v_challenge_id, v_points
  FROM user_challenges uc
  JOIN challenges c ON uc.challenge_id = c.id
  WHERE uc.id = p_user_challenge_id;

  -- Update challenge status
  UPDATE user_challenges
  SET
    status = 'completed',
    completed_at = NOW(),
    current_progress = target_progress
  WHERE id = p_user_challenge_id;

  -- Award points
  PERFORM award_points(v_user_id, v_points);

  -- Update stats
  UPDATE user_gamification_stats
  SET
    challenges_completed = challenges_completed + 1,
    updated_at = NOW()
  WHERE user_id = v_user_id;

  -- Check for achievements
  PERFORM check_achievements(v_user_id);

  -- Create notification
  INSERT INTO notifications (user_id, type, title, body, icon, color, action_route)
  VALUES (
    v_user_id,
    'achievement_unlocked',
    'Challenge Complete! 🎉',
    'You earned ' || v_points || ' points!',
    'emoji_events',
    '#FFB300',
    '/challenges'
  );
END;
$$ LANGUAGE plpgsql;

-- Function: Unlock achievement
CREATE OR REPLACE FUNCTION unlock_achievement(p_user_id UUID, p_achievement_id UUID)
RETURNS VOID AS $$
DECLARE
  v_points INT;
  v_title TEXT;
BEGIN
  -- Check if already unlocked
  IF EXISTS (
    SELECT 1 FROM user_achievements
    WHERE user_id = p_user_id AND achievement_id = p_achievement_id
  ) THEN
    RETURN;
  END IF;

  -- Get achievement info
  SELECT points, title
  INTO v_points, v_title
  FROM achievements
  WHERE id = p_achievement_id;

  -- Unlock achievement
  INSERT INTO user_achievements (user_id, achievement_id)
  VALUES (p_user_id, p_achievement_id);

  -- Award points
  PERFORM award_points(p_user_id, v_points);

  -- Update stats
  UPDATE user_gamification_stats
  SET
    achievements_unlocked = achievements_unlocked + 1,
    updated_at = NOW()
  WHERE user_id = p_user_id;

  -- Create notification
  INSERT INTO notifications (user_id, type, title, body, icon, color, action_route)
  VALUES (
    p_user_id,
    'achievement_unlocked',
    'Achievement Unlocked! 🏆',
    v_title,
    'stars',
    '#FFB300',
    '/achievements'
  );
END;
$$ LANGUAGE plpgsql;

-- Function: Check and unlock achievements
CREATE OR REPLACE FUNCTION check_achievements(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_achievement RECORD;
  v_condition_type TEXT;
  v_condition_met BOOLEAN;
BEGIN
  -- Check each achievement
  FOR v_achievement IN
    SELECT * FROM achievements
    WHERE is_active = TRUE
    AND id NOT IN (SELECT achievement_id FROM user_achievements WHERE user_id = p_user_id)
  LOOP
    v_condition_type := v_achievement.unlock_conditions->>'type';
    v_condition_met := FALSE;

    -- Check condition based on type
    -- This is simplified - expand based on actual conditions
    IF v_condition_type = 'total_count' THEN
      -- Check if user has reached count threshold
      v_condition_met := TRUE; -- Placeholder
    END IF;

    IF v_condition_met THEN
      PERFORM unlock_achievement(p_user_id, v_achievement.id);
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function: Update daily streak
CREATE OR REPLACE FUNCTION update_daily_streak(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_last_date DATE;
  v_current_streak INT;
BEGIN
  SELECT last_activity_date, current_daily_streak
  INTO v_last_date, v_current_streak
  FROM user_gamification_stats
  WHERE user_id = p_user_id;

  -- If no stats, create them
  IF NOT FOUND THEN
    INSERT INTO user_gamification_stats (user_id, current_daily_streak, longest_daily_streak, last_activity_date)
    VALUES (p_user_id, 1, 1, CURRENT_DATE);
    RETURN;
  END IF;

  -- Check if consecutive day
  IF v_last_date = CURRENT_DATE - INTERVAL '1 day' THEN
    -- Increment streak
    v_current_streak := v_current_streak + 1;
  ELSIF v_last_date < CURRENT_DATE - INTERVAL '1 day' THEN
    -- Streak broken
    v_current_streak := 1;
  ELSE
    -- Same day, no change
    RETURN;
  END IF;

  -- Update stats
  UPDATE user_gamification_stats
  SET
    current_daily_streak = v_current_streak,
    longest_daily_streak = GREATEST(longest_daily_streak, v_current_streak),
    last_activity_date = CURRENT_DATE,
    updated_at = NOW()
  WHERE user_id = p_user_id;

  -- Check for streak achievements
  PERFORM check_achievements(p_user_id);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SEED DATA - Initial Challenges
-- ============================================================================

INSERT INTO challenges (title, description, category, target_type, target_value, target_unit, difficulty, points, badge_icon, badge_color) VALUES
-- T-Break Challenges
('T-Break Rookie', 'Complete a 3-day tolerance break', 'tbreak', 'duration', 3, 'days', 'easy', 100, 'fitness_center', '#4CAF50'),
('T-Break Warrior', 'Complete a 7-day tolerance break', 'tbreak', 'duration', 7, 'days', 'medium', 250, 'emoji_events', '#FFC107'),
('T-Break Legend', 'Complete a 30-day tolerance break', 'tbreak', 'duration', 30, 'days', 'legendary', 1000, 'military_tech', '#9C27B0'),

-- Journal Challenges
('Journal Starter', 'Log 5 strain journal entries', 'journal', 'count', 5, 'entries', 'easy', 50, 'book', '#2196F3'),
('Dedicated Journaler', 'Log 25 strain journal entries', 'journal', 'count', 25, 'entries', 'medium', 200, 'library_books', '#2196F3'),
('Master Journalist', 'Log 100 strain journal entries', 'journal', 'count', 100, 'entries', 'hard', 500, 'auto_stories', '#2196F3'),

-- Cognitive Challenges
('Mind Tester', 'Complete 5 cognitive tests', 'cognitive', 'count', 5, 'tests', 'easy', 75, 'psychology', '#E91E63'),
('Sharp Mind', 'Maintain 80%+ average cognitive score for 7 days', 'cognitive', 'quality', 7, 'days', 'medium', 300, 'psychology_alt', '#E91E63'),

-- Streak Challenges
('Daily Tracker', 'Log activity for 7 consecutive days', 'wellness', 'streak', 7, 'days', 'medium', 150, 'whatshot', '#FF5722'),
('Consistency King', 'Log activity for 30 consecutive days', 'wellness', 'streak', 30, 'days', 'hard', 500, 'local_fire_department', '#FF5722');

-- ============================================================================
-- SEED DATA - Initial Achievements
-- ============================================================================

INSERT INTO achievements (title, description, category, icon, color, rarity, unlock_conditions, points) VALUES
-- First Time Achievements
('First Entry', 'Log your first strain journal entry', 'journal', 'edit_note', '#4CAF50', 'common', '{"type": "total_count", "metric": "journal_entries", "count": 1}', 10),
('First T-Break', 'Complete your first tolerance break', 'tbreak', 'pause_circle', '#4CAF50', 'common', '{"type": "total_count", "metric": "tbreaks_completed", "count": 1}', 25),
('First Test', 'Complete your first cognitive test', 'cognitive', 'quiz', '#4CAF50', 'common', '{"type": "total_count", "metric": "cognitive_tests", "count": 1}', 10),

-- Milestone Achievements
('Century Club', 'Log 100 journal entries', 'journal', 'workspace_premium', '#9C27B0', 'epic', '{"type": "total_count", "metric": "journal_entries", "count": 100}', 250),
('T-Break Master', 'Complete 10 tolerance breaks', 'tbreak', 'emoji_events', '#FFB300', 'rare', '{"type": "total_count", "metric": "tbreaks_completed", "count": 10}', 200),

-- Quality Achievements
('Perfectionist', 'Receive 10 journal entries with 5-star ratings', 'journal', 'star', '#FFB300', 'rare', '{"type": "quality", "metric": "five_star_entries", "count": 10}', 150),
('Mental Athlete', 'Score 100% on a cognitive test', 'cognitive', 'military_tech', '#E91E63', 'epic', '{"type": "quality", "metric": "perfect_cognitive_score", "count": 1}', 300),

-- Streak Achievements
('Week Warrior', '7-day activity streak', 'wellness', 'local_fire_department', '#FF5722', 'rare', '{"type": "streak", "days": 7, "activity": "any"}', 100),
('Month Master', '30-day activity streak', 'wellness', 'whatshot', '#FF5722', 'epic', '{"type": "streak", "days": 30, "activity": "any"}', 500);
