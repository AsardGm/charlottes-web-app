-- Tabulka pro FCM push tokeny
CREATE TABLE IF NOT EXISTS push_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'web', -- 'web', 'ios', 'android'
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  UNIQUE(user_id, platform)
);

-- RLS policies
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;

-- Uživatel může vidět a upravovat pouze své tokeny
CREATE POLICY "Users can view own tokens" ON push_tokens
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tokens" ON push_tokens
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tokens" ON push_tokens
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own tokens" ON push_tokens
  FOR DELETE USING (auth.uid() = user_id);

-- Index pro rychlé vyhledávání podle user_id
CREATE INDEX IF NOT EXISTS idx_push_tokens_user_id ON push_tokens(user_id);

-- Funkce pro odeslání push notifikace (volá se z Edge Function nebo triggeru)
-- Toto je pouze placeholder - skutečné odeslání bude přes Edge Function
CREATE OR REPLACE FUNCTION notify_user(
  p_user_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_data JSONB DEFAULT '{}'
) RETURNS VOID AS $$
BEGIN
  -- Zde by se volala Edge Function pro odeslání FCM
  -- Pro teď pouze logujeme
  RAISE NOTICE 'Push notification: user=%, title=%, body=%', p_user_id, p_title, p_body;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
