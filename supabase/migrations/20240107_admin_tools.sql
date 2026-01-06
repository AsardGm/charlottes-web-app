-- ============================================
-- Admin Tools Migration
-- Přidává tabulky a sloupce pro admin nástroje
-- ============================================

-- 1. Audit Log tabulka
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  target_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  details TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pro rychlejší dotazy
CREATE INDEX IF NOT EXISTS idx_audit_log_admin ON audit_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created ON audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log(action);

-- RLS pro audit log (pouze admini)
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view audit log"
  ON audit_log FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admins can insert audit log"
  ON audit_log FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- 2. Banned Words tabulka
CREATE TABLE IF NOT EXISTS banned_words (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  word TEXT NOT NULL UNIQUE,
  action TEXT NOT NULL DEFAULT 'warn' CHECK (action IN ('warn', 'delete', 'block')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pro rychlejší vyhledávání
CREATE INDEX IF NOT EXISTS idx_banned_words_word ON banned_words(word);

-- RLS pro banned words (pouze admini)
ALTER TABLE banned_words ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage banned words"
  ON banned_words FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- 3. Přidat nové sloupce do profiles
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS ban_until TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS ban_reason TEXT,
  ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ DEFAULT NOW();

-- 4. Přidat is_pinned do posts
ALTER TABLE posts
  ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;

-- Index pro připnuté příspěvky
CREATE INDEX IF NOT EXISTS idx_posts_pinned ON posts(is_pinned) WHERE is_pinned = TRUE;

-- 5. Funkce pro automatické odblokování uživatelů s vypršeným banem
CREATE OR REPLACE FUNCTION check_expired_bans()
RETURNS void AS $$
BEGIN
  UPDATE profiles
  SET
    is_blocked = FALSE,
    ban_until = NULL,
    ban_reason = NULL
  WHERE
    is_blocked = TRUE
    AND ban_until IS NOT NULL
    AND ban_until < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Funkce pro aktualizaci last_seen
CREATE OR REPLACE FUNCTION update_last_seen()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles
  SET last_seen = NOW()
  WHERE id = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pro aktualizaci last_seen při vytvoření příspěvku nebo komentáře
DROP TRIGGER IF EXISTS update_last_seen_on_post ON posts;
CREATE TRIGGER update_last_seen_on_post
  AFTER INSERT ON posts
  FOR EACH ROW
  EXECUTE FUNCTION update_last_seen();

DROP TRIGGER IF EXISTS update_last_seen_on_comment ON comments;
CREATE TRIGGER update_last_seen_on_comment
  AFTER INSERT ON comments
  FOR EACH ROW
  EXECUTE FUNCTION update_last_seen();

-- 7. Přidat broadcast typ do notifications (pokud není)
-- Toto je bezpečné, i když typ už existuje
DO $$
BEGIN
  -- Zkontrolovat jestli typ broadcast existuje
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    WHERE t.typname = 'notification_type' AND e.enumlabel = 'broadcast'
  ) THEN
    -- Pokud notification_type je enum, přidat hodnotu
    -- Pokud je to text constraint, nic nedělat
    BEGIN
      ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'broadcast';
    EXCEPTION
      WHEN undefined_object THEN
        -- notification_type není enum, ignorovat
        NULL;
    END;
  END IF;
END $$;

-- 8. Přidat warning typ do notifications (pokud není)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    WHERE t.typname = 'notification_type' AND e.enumlabel = 'warning'
  ) THEN
    BEGIN
      ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'warning';
    EXCEPTION
      WHEN undefined_object THEN
        NULL;
    END;
  END IF;
END $$;

-- Hotovo!
COMMENT ON TABLE audit_log IS 'Log všech admin akcí pro audit trail';
COMMENT ON TABLE banned_words IS 'Seznam zakázaných slov pro automatickou moderaci';
