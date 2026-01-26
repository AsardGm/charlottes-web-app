-- ============================================
-- RLS politiky pro admin operace
-- Spustte v Supabase SQL Editoru
-- ============================================

-- 1. Nejprve zkontrolujeme existující politiky na profiles
-- (toto je jen informativní, nevyhodí chybu)

-- 2. Přidáme politiku pro adminy - mohou UPDATE na libovolný profil
DROP POLICY IF EXISTS "Admins can update any profile" ON profiles;

CREATE POLICY "Admins can update any profile" ON profiles
FOR UPDATE
USING (
  -- Aktuální uživatel je admin
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'admin'
  )
)
WITH CHECK (
  -- Aktuální uživatel je admin
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'admin'
  )
);

-- 3. Přidáme politiku pro adminy - mohou SELECT na libovolný profil
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;

CREATE POLICY "Admins can view all profiles" ON profiles
FOR SELECT
USING (
  -- Každý může vidět profily (pro mentions, chat atd.)
  true
);

-- 4. Uživatel může upravovat svůj vlastní profil
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

CREATE POLICY "Users can update own profile" ON profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 5. Vytvoříme tabulku audit_log pokud neexistuje
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID REFERENCES profiles(id),
  action TEXT NOT NULL,
  target_user_id UUID REFERENCES profiles(id),
  details TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. RLS pro audit_log
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can insert audit logs" ON audit_log;
CREATE POLICY "Admins can insert audit logs" ON audit_log
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'admin'
  )
);

DROP POLICY IF EXISTS "Admins can view audit logs" ON audit_log;
CREATE POLICY "Admins can view audit logs" ON audit_log
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'admin'
  )
);

-- 7. Vytvoříme tabulku banned_words pokud neexistuje
CREATE TABLE IF NOT EXISTS banned_words (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  word TEXT NOT NULL UNIQUE,
  action TEXT DEFAULT 'warn' CHECK (action IN ('warn', 'delete', 'block')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. RLS pro banned_words
ALTER TABLE banned_words ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read banned words" ON banned_words;
CREATE POLICY "Anyone can read banned words" ON banned_words
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can manage banned words" ON banned_words;
CREATE POLICY "Admins can manage banned words" ON banned_words
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'admin'
  )
);

-- Hotovo!
-- Po spuštění by měl admin být schopen měnit role uživatelů.
