-- ===========================================
-- Oprava push notifikací - použití nového API
-- POZOR: posts má author_id (ne user_id) a content (ne title)
-- ===========================================

-- Nejdřív smaž staré triggery aby nedělaly chyby
DROP TRIGGER IF EXISTS on_new_post_notify_followers ON posts;
DROP TRIGGER IF EXISTS on_new_comment_notify_author ON comments;
DROP TRIGGER IF EXISTS on_new_message_notify_recipient ON messages;
DROP TRIGGER IF EXISTS on_new_follower_notify ON follows;
DROP TRIGGER IF EXISTS on_new_reaction_notify ON reactions;

-- Funkce pro odeslání push notifikace přes Edge Function (nové API)
CREATE OR REPLACE FUNCTION send_push_notification(
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
BEGIN
  -- Sestav payload
  payload := jsonb_build_object(
    'user_id', p_user_id::TEXT,
    'type', p_type
  );

  -- Přidej volitelné parametry
  IF p_actor_name IS NOT NULL THEN
    payload := payload || jsonb_build_object('actor_name', p_actor_name);
  END IF;

  IF p_post_title IS NOT NULL THEN
    payload := payload || jsonb_build_object('post_title', p_post_title);
  END IF;

  IF p_message_preview IS NOT NULL THEN
    payload := payload || jsonb_build_object('message_preview', p_message_preview);
  END IF;

  -- Přidej extra data (post_id, conversation_id, atd.)
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
  RAISE WARNING 'send_push_notification error: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- Trigger: Nový příspěvek - notifikace sledujícím
-- ===========================================
CREATE OR REPLACE FUNCTION notify_followers_new_post()
RETURNS TRIGGER AS $$
DECLARE
  author_name TEXT;
  follower_record RECORD;
BEGIN
  -- Získej jméno autora
  SELECT COALESCE(display_name, username, 'Uživatel') INTO author_name
  FROM profiles
  WHERE id = NEW.author_id;

  -- Pošli notifikaci všem sledujícím
  FOR follower_record IN
    SELECT f.follower_id
    FROM follows f
    LEFT JOIN user_settings us ON us.user_id = f.follower_id
    WHERE f.following_id = NEW.author_id
    AND COALESCE(us.notifications_enabled, true) = true
  LOOP
    PERFORM send_push_notification(
      follower_record.follower_id,
      'post',
      author_name,
      LEFT(NEW.content, 100),
      NULL,
      jsonb_build_object(
        'post_id', NEW.id::TEXT,
        'actor_id', NEW.author_id::TEXT
      )
    );
  END LOOP;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'notify_followers_new_post error: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- Trigger: Nový komentář - notifikace autorovi příspěvku
-- ===========================================
CREATE OR REPLACE FUNCTION notify_post_author_new_comment()
RETURNS TRIGGER AS $$
DECLARE
  commenter_name TEXT;
  post_author_id UUID;
  post_content TEXT;
  author_notifications BOOLEAN;
BEGIN
  -- Získej autora příspěvku
  SELECT p.author_id, LEFT(p.content, 100) INTO post_author_id, post_content
  FROM posts p
  WHERE p.id = NEW.post_id;

  -- Neposílej notifikaci pokud komentuje sám autor
  IF post_author_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  -- Zkontroluj nastavení notifikací
  SELECT COALESCE(us.notifications_enabled, true) INTO author_notifications
  FROM user_settings us
  WHERE us.user_id = post_author_id;

  IF author_notifications IS NULL THEN
    author_notifications := true;
  END IF;

  IF author_notifications IS NOT TRUE THEN
    RETURN NEW;
  END IF;

  -- Získej jméno komentujícího
  SELECT COALESCE(pr.display_name, pr.username, 'Uživatel') INTO commenter_name
  FROM profiles pr
  WHERE pr.id = NEW.user_id;

  -- Pošli notifikaci
  PERFORM send_push_notification(
    post_author_id,
    'comment',
    commenter_name,
    post_content,
    LEFT(NEW.content, 100),
    jsonb_build_object(
      'post_id', NEW.post_id::TEXT,
      'comment_id', NEW.id::TEXT,
      'actor_id', NEW.user_id::TEXT
    )
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'notify_post_author_new_comment error: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- Trigger: Nová zpráva - notifikace příjemci
-- ===========================================
CREATE OR REPLACE FUNCTION notify_message_recipient()
RETURNS TRIGGER AS $$
DECLARE
  sender_name TEXT;
  recipient_id UUID;
  recipient_notifications BOOLEAN;
BEGIN
  -- Získej jméno odesílatele
  SELECT COALESCE(pr.display_name, pr.username, 'Uživatel') INTO sender_name
  FROM profiles pr
  WHERE pr.id = NEW.sender_id;

  -- Najdi příjemce (ostatní účastníky konverzace)
  FOR recipient_id IN
    SELECT cp.user_id
    FROM conversation_participants cp
    WHERE cp.conversation_id = NEW.conversation_id
    AND cp.user_id != NEW.sender_id
  LOOP
    -- Zkontroluj nastavení notifikací
    SELECT COALESCE(us.notifications_enabled, true) INTO recipient_notifications
    FROM user_settings us
    WHERE us.user_id = recipient_id;

    IF recipient_notifications IS NULL THEN
      recipient_notifications := true;
    END IF;

    IF recipient_notifications IS TRUE THEN
      PERFORM send_push_notification(
        recipient_id,
        'chat',
        sender_name,
        NULL,
        LEFT(NEW.content, 100),
        jsonb_build_object(
          'conversation_id', NEW.conversation_id::TEXT,
          'actor_id', NEW.sender_id::TEXT
        )
      );
    END IF;
  END LOOP;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'notify_message_recipient error: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- Trigger: Nový sledující - notifikace sledovanému
-- ===========================================
CREATE OR REPLACE FUNCTION notify_new_follower()
RETURNS TRIGGER AS $$
DECLARE
  follower_name TEXT;
  followed_notifications BOOLEAN;
BEGIN
  -- Zkontroluj nastavení notifikací
  SELECT COALESCE(us.notifications_enabled, true) INTO followed_notifications
  FROM user_settings us
  WHERE us.user_id = NEW.following_id;

  IF followed_notifications IS NULL THEN
    followed_notifications := true;
  END IF;

  IF followed_notifications IS NOT TRUE THEN
    RETURN NEW;
  END IF;

  -- Získej jméno sledujícího
  SELECT COALESCE(pr.display_name, pr.username, 'Uživatel') INTO follower_name
  FROM profiles pr
  WHERE pr.id = NEW.follower_id;

  -- Pošli notifikaci
  PERFORM send_push_notification(
    NEW.following_id,
    'follow',
    follower_name,
    NULL,
    NULL,
    jsonb_build_object(
      'actor_id', NEW.follower_id::TEXT
    )
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'notify_new_follower error: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- Trigger: Nová reakce na příspěvek (like)
-- ===========================================
CREATE OR REPLACE FUNCTION notify_post_reaction()
RETURNS TRIGGER AS $$
DECLARE
  reactor_name TEXT;
  post_author_id UUID;
  post_content TEXT;
  author_notifications BOOLEAN;
BEGIN
  -- Získej autora a obsah příspěvku
  SELECT p.author_id, LEFT(p.content, 100) INTO post_author_id, post_content
  FROM posts p
  WHERE p.id = NEW.post_id;

  -- Neposílej notifikaci pokud reaguje sám autor
  IF post_author_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  -- Zkontroluj nastavení notifikací
  SELECT COALESCE(us.notifications_enabled, true) INTO author_notifications
  FROM user_settings us
  WHERE us.user_id = post_author_id;

  IF author_notifications IS NULL THEN
    author_notifications := true;
  END IF;

  IF author_notifications IS NOT TRUE THEN
    RETURN NEW;
  END IF;

  -- Získej jméno reagujícího
  SELECT COALESCE(pr.display_name, pr.username, 'Uživatel') INTO reactor_name
  FROM profiles pr
  WHERE pr.id = NEW.user_id;

  -- Pošli notifikaci
  PERFORM send_push_notification(
    post_author_id,
    'like',
    reactor_name,
    post_content,
    NULL,
    jsonb_build_object(
      'post_id', NEW.post_id::TEXT,
      'actor_id', NEW.user_id::TEXT
    )
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'notify_post_reaction error: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Znovu vytvoř triggery
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
