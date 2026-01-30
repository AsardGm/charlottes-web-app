-- Create user_preferences table for personalization

CREATE TABLE IF NOT EXISTS user_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Preference data (stored as JSON strings to match enum names)
  role TEXT,
  experience_level TEXT,
  interests TEXT[], -- Array of interest names
  goals TEXT[], -- Array of goal names

  -- Onboarding completion tracking
  onboarding_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP WITH TIME ZONE,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Ensure one preferences per user
  UNIQUE(user_id)
);

-- Add RLS policies
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Users can read their own preferences
CREATE POLICY "Users can read own preferences"
  ON user_preferences
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own preferences
CREATE POLICY "Users can insert own preferences"
  ON user_preferences
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own preferences
CREATE POLICY "Users can update own preferences"
  ON user_preferences
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own preferences
CREATE POLICY "Users can delete own preferences"
  ON user_preferences
  FOR DELETE
  USING (auth.uid() = user_id);

-- Create index for faster user lookups
CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);

-- Function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_user_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function
CREATE TRIGGER user_preferences_updated_at
  BEFORE UPDATE ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_user_preferences_updated_at();

-- Comments for documentation
COMMENT ON TABLE user_preferences IS 'Stores user personalization preferences from Smart Onboarding';
COMMENT ON COLUMN user_preferences.role IS 'User role: grower, consumer, both, learner';
COMMENT ON COLUMN user_preferences.experience_level IS 'Experience level: beginner, intermediate, experienced, expert';
COMMENT ON COLUMN user_preferences.interests IS 'Array of user interests (genetics, terpenes, growing, etc.)';
COMMENT ON COLUMN user_preferences.goals IS 'Array of user goals (trackConsumption, improveGrows, etc.)';
