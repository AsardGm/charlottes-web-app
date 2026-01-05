-- ===========================================
-- Oprava push notifikací v2 - bezpečná verze
-- Notifikace se posílají přes pg_net, ale pokud selže, operace pokračuje
-- ===========================================

-- Nejdřív smaž staré triggery
DROP TRIGGER IF EXISTS on_new_post_notify_followers ON posts;
DROP TRIGGER IF EXISTS on_new_comment_notify_author ON comments;
DROP TRIGGER IF EXISTS on_new_message_notify_recipient ON messages;
DROP TRIGGER IF EXISTS on_new_follower_notify ON follows;
DROP TRIGGER IF EXISTS on_new_reaction_notify ON reactions;

-- Smaž staré funkce
DROP FUNCTION IF EXISTS notify_followers_new_post() CASCADE;
DROP FUNCTION IF EXISTS notify_post_author_new_comment() CASCADE;
DROP FUNCTION IF EXISTS notify_message_recipient() CASCADE;
DROP FUNCTION IF EXISTS notify_new_follower() CASCADE;
DROP FUNCTION IF EXISTS notify_post_reaction() CASCADE;
DROP FUNCTION IF EXISTS send_push_notification(UUID, TEXT, TEXT, TEXT, TEXT, JSONB) CASCADE;
DROP FUNCTION IF EXISTS send_push_notification(UUID, TEXT, TEXT, JSONB) CASCADE;

-- ===========================================
-- Pomocná funkce pro bezpečné odeslání push notifikace
-- Pokud pg_net není dostupné nebo selže, operace pokračuje
-- ===========================================
CREATE OR REPLACE FUNCTION send_push_notification_safe(
  p_user_id UUID,
  p_type TEXT,
  p_actor_name TEXT DEFAULT NULL,
  p_post_title TEXT DEFAULT NULL,
  p_message_preview TEXT DEFAULT NULL,
  p_data JSONB DEFAULT '{}'::JSONB
)
RETURNS VOID AS $$
DECLARE
  supabase_url TEXT := 'https://lzzoquoucfaxsifhtifo.supabase.co';
  service_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6em9xdW91Y2ZheHNpZmh0aWZvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Njg0NzY4OSwiZXhwIjoyMDgyNDIzNjg5fQ.niNwt4wwnLG3T_644WBPuSCTtcHqRLKdLF7VPHf7krg';
  payload JSONB;
  has_pg_net BOOLEAN;
BEGIN
  -- Zkontroluj jestli pg_net existuje
  SELECT EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pg_net'
  ) INTO has_pg_net;

  IF NOT has_pg_net THEN
    RAISE NOTICE 'pg_net extension not available, skipping push notification';
    RETURN;
  END IF;

  -- Sestav payload
  payload := jsonb_build_object(
    'user_id', p_user_id::TEXT,
    'type', p_type
  );

  IF p_actor_name IS NOT NULL THEN
    payload := payload || jsonb_build_object('actor_name', p_actor_name);
  END IF;

  IF p_post_title IS NOT NULL THEN
    payload := payload || jsonb_build_object('post_title', p_post_title);
  END IF;

  IF p_message_preview IS NOT NULL THEN
    payload := payload || jsonb_build_object('message_preview', p_message_preview);
  END IF;

  IF p_data IS NOT NULL AND p_data != '{}'::JSONB THEN
    payload := payload || jsonb_build_object('data', p_data);
  END IF;

  -- Zavolej Edge Function
  PERFORM net.http_post(
    url := supabase_url || '/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || service_key
    ),
    body := payload
  );

EXCEPTION WHEN OTHERS THEN
  -- Loguj chybu ale neblokuj operaci
  RAISE WARNING 'send_push_notification_safe failed: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- Trigger: Nová reakce na příspěvek (like)
-- JEDNODUCHÁ VERZE - minimální kód
-- ===========================================
CREATE OR REPLACE FUNCTION notify_post_reaction()
RETURNS TRIGGER AS $$
DECLARE
  v_reactor_name TEXT;
  v_post_author_id UUID;
  v_post_content TEXT;
  v_author_notifications BOOLEAN;
BEGIN
  -- Vše v EXCEPTION bloku
  BEGIN
    -- Získej autora a obsah příspěvku
    SELECT p.author_id, LEFT(p.content, 100)
    INTO v_post_author_id, v_post_content
    FROM posts p
    WHERE p.id = NEW.post_id;

    -- Neposílej notifikaci pokud reaguje sám autor
    IF v_post_author_id IS NULL OR v_post_author_id = NEW.user_id THEN
      RETURN NEW;
    END IF;

    -- Zkontroluj nastavení notifikací (default true)
    SELECT COALESCE(us.notifications_enabled, true)
    INTO v_author_notifications
    FROM user_settings us
    WHERE us.user_id = v_post_author_id;

    IF v_author_notifications IS NULL THEN
      v_author_notifications := true;
    END IF;

    IF NOT v_author_notifications THEN
      RETURN NEW;
    END IF;

    -- Získej jméno reagujícího
    SELECT COALESCE(pr.display_name, pr.username, 'Uživatel')
    INTO v_reactor_name
    FROM profiles pr
    WHERE pr.id = NEW.user_id;

    -- Pošli notifikaci (bezpečně)
    PERFORM send_push_notification_safe(
      v_post_author_id,
      'like',
      v_reactor_name,
      v_post_content,
      NULL,
      jsonb_build_object(
        'post_id', NEW.post_id::TEXT,
        'actor_id', NEW.user_id::TEXT
      )
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'notify_post_reaction error: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
  END;

  -- VŽDY vrať NEW aby INSERT prošel
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- Trigger: Nový příspěvek - notifikace sledujícím
-- ===========================================
CREATE OR REPLACE FUNCTION notify_followers_new_post()
RETURNS TRIGGER AS $$
DECLARE
  v_author_name TEXT;
  v_follower_record RECORD;
BEGIN
  BEGIN
    SELECT COALESCE(display_name, username, 'Uživatel')
    INTO v_author_name
    FROM profiles
    WHERE id = NEW.author_id;

    FOR v_follower_record IN
      SELECT f.follower_id
      FROM follows f
      LEFT JOIN user_settings us ON us.user_id = f.follower_id
      WHERE f.following_id = NEW.author_id
      AND COALESCE(us.notifications_enabled, true) = true
    LOOP
      PERFORM send_push_notification_safe(
        v_follower_record.follower_id,
        'post',
        v_author_name,
        LEFT(NEW.content, 100),
        NULL,
        jsonb_build_object(
          'post_id', NEW.id::TEXT,
          'actor_id', NEW.author_id::TEXT
        )
      );
    END LOOP;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'notify_followers_new_post error: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- Trigger: Nový komentář - notifikace autorovi příspěvku
-- ===========================================
CREATE OR REPLACE FUNCTION notify_post_author_new_comment()
RETURNS TRIGGER AS $$
DECLARE
  v_commenter_name TEXT;
  v_post_author_id UUID;
  v_post_content TEXT;
  v_author_notifications BOOLEAN;
BEGIN
  BEGIN
    SELECT p.author_id, LEFT(p.content, 100)
    INTO v_post_author_id, v_post_content
    FROM posts p
    WHERE p.id = NEW.post_id;

    IF v_post_author_id IS NULL OR v_post_author_id = NEW.user_id THEN
      RETURN NEW;
    END IF;

    SELECT COALESCE(us.notifications_enabled, true)
    INTO v_author_notifications
    FROM user_settings us
    WHERE us.user_id = v_post_author_id;

    IF v_author_notifications IS NULL THEN
      v_author_notifications := true;
    END IF;

    IF NOT v_author_notifications THEN
      RETURN NEW;
    END IF;

    SELECT COALESCE(pr.display_name, pr.username, 'Uživatel')
    INTO v_commenter_name
    FROM profiles pr
    WHERE pr.id = NEW.user_id;

    PERFORM send_push_notification_safe(
      v_post_author_id,
      'comment',
      v_commenter_name,
      v_post_content,
      LEFT(NEW.content, 100),
      jsonb_build_object(
        'post_id', NEW.post_id::TEXT,
        'comment_id', NEW.id::TEXT,
        'actor_id', NEW.user_id::TEXT
      )
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'notify_post_author_new_comment error: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- Trigger: Nová zpráva - notifikace příjemci
-- ===========================================
CREATE OR REPLACE FUNCTION notify_message_recipient()
RETURNS TRIGGER AS $$
DECLARE
  v_sender_name TEXT;
  v_recipient_id UUID;
  v_recipient_notifications BOOLEAN;
BEGIN
  BEGIN
    SELECT COALESCE(pr.display_name, pr.username, 'Uživatel')
    INTO v_sender_name
    FROM profiles pr
    WHERE pr.id = NEW.sender_id;

    FOR v_recipient_id IN
      SELECT cp.user_id
      FROM conversation_participants cp
      WHERE cp.conversation_id = NEW.conversation_id
      AND cp.user_id != NEW.sender_id
    LOOP
      SELECT COALESCE(us.notifications_enabled, true)
      INTO v_recipient_notifications
      FROM user_settings us
      WHERE us.user_id = v_recipient_id;

      IF v_recipient_notifications IS NULL THEN
        v_recipient_notifications := true;
      END IF;

      IF v_recipient_notifications THEN
        PERFORM send_push_notification_safe(
          v_recipient_id,
          'chat',
          v_sender_name,
          NULL,
          LEFT(NEW.content, 100),
          jsonb_build_object(
            'conversation_id', NEW.conversation_id::TEXT,
            'actor_id', NEW.sender_id::TEXT
          )
        );
      END IF;
    END LOOP;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'notify_message_recipient error: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- Trigger: Nový sledující - notifikace sledovanému
-- ===========================================
CREATE OR REPLACE FUNCTION notify_new_follower()
RETURNS TRIGGER AS $$
DECLARE
  v_follower_name TEXT;
  v_followed_notifications BOOLEAN;
BEGIN
  BEGIN
    SELECT COALESCE(us.notifications_enabled, true)
    INTO v_followed_notifications
    FROM user_settings us
    WHERE us.user_id = NEW.following_id;

    IF v_followed_notifications IS NULL THEN
      v_followed_notifications := true;
    END IF;

    IF NOT v_followed_notifications THEN
      RETURN NEW;
    END IF;

    SELECT COALESCE(pr.display_name, pr.username, 'Uživatel')
    INTO v_follower_name
    FROM profiles pr
    WHERE pr.id = NEW.follower_id;

    PERFORM send_push_notification_safe(
      NEW.following_id,
      'follow',
      v_follower_name,
      NULL,
      NULL,
      jsonb_build_object(
        'actor_id', NEW.follower_id::TEXT
      )
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'notify_new_follower error: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- Znovu vytvoř triggery
-- ===========================================
CREATE TRIGGER on_new_post_notify_followers
  AFTER INSERT ON posts
  FOR EACH ROW
  EXECUTE FUNCTION notify_followers_new_post();

CREATE TRIGGER on_new_comment_notify_author
  AFTER INSERT ON comments
  FOR EACH ROW
  EXECUTE FUNCTION notify_post_author_new_comment();

CREATE TRIGGER on_new_message_notify_recipient
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION notify_message_recipient();

CREATE TRIGGER on_new_follower_notify
  AFTER INSERT ON follows
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_follower();

CREATE TRIGGER on_new_reaction_notify
  AFTER INSERT ON reactions
  FOR EACH ROW
  EXECUTE FUNCTION notify_post_reaction();

-- Potvrzení
DO $$
BEGIN
  RAISE NOTICE 'Push notification triggers installed successfully (v2 - safe version)';
END $$;
