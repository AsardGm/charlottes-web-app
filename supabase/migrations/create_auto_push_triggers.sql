-- ===========================================
-- Automatické push notifikace
-- ===========================================

-- Funkce pro odeslání push notifikace přes Edge Function
CREATE OR REPLACE FUNCTION send_push_notification(
  p_user_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_data JSONB DEFAULT '{}'::JSONB
)
RETURNS VOID AS $$
DECLARE
  supabase_url TEXT;
  service_key TEXT;
BEGIN
  -- Získej URL a klíč z konfigurace
  supabase_url := current_setting('app.settings.supabase_url', true);
  service_key := current_setting('app.settings.service_role_key', true);

  -- Pokud nejsou nastavené, použij hardcoded hodnoty
  IF supabase_url IS NULL THEN
    supabase_url := 'https://lzzoquoucfaxsifhtifo.supabase.co';
  END IF;

  -- Zavolej Edge Function
  PERFORM net.http_post(
    url := supabase_url || '/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json'
    ),
    body := jsonb_build_object(
      'user_id', p_user_id::TEXT,
      'title', p_title,
      'body', p_body,
      'data', p_data
    )
  );
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
  SELECT display_name INTO author_name
  FROM profiles
  WHERE id = NEW.user_id;

  -- Pošli notifikaci všem sledujícím
  FOR follower_record IN
    SELECT f.follower_id
    FROM follows f
    JOIN user_settings us ON us.user_id = f.follower_id
    WHERE f.following_id = NEW.user_id
    AND us.notifications_enabled = true
  LOOP
    PERFORM send_push_notification(
      follower_record.follower_id,
      COALESCE(author_name, 'Uživatel') || ' přidal nový příspěvek',
      LEFT(NEW.title, 100),
      jsonb_build_object(
        'type', 'new_post',
        'post_id', NEW.id::TEXT,
        'author_id', NEW.user_id::TEXT
      )
    );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_new_post_notify_followers ON posts;
CREATE TRIGGER on_new_post_notify_followers
  AFTER INSERT ON posts
  FOR EACH ROW
  EXECUTE FUNCTION notify_followers_new_post();

-- ===========================================
-- Trigger: Nový komentář - notifikace autorovi příspěvku
-- ===========================================
CREATE OR REPLACE FUNCTION notify_post_author_new_comment()
RETURNS TRIGGER AS $$
DECLARE
  commenter_name TEXT;
  post_author_id UUID;
  post_title TEXT;
  author_notifications BOOLEAN;
BEGIN
  -- Získej autora příspěvku
  SELECT user_id, title INTO post_author_id, post_title
  FROM posts
  WHERE id = NEW.post_id;

  -- Neposílej notifikaci pokud komentuje sám autor
  IF post_author_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  -- Zkontroluj nastavení notifikací
  SELECT notifications_enabled INTO author_notifications
  FROM user_settings
  WHERE user_id = post_author_id;

  IF author_notifications IS NOT TRUE THEN
    RETURN NEW;
  END IF;

  -- Získej jméno komentujícího
  SELECT display_name INTO commenter_name
  FROM profiles
  WHERE id = NEW.user_id;

  -- Pošli notifikaci
  PERFORM send_push_notification(
    post_author_id,
    COALESCE(commenter_name, 'Uživatel') || ' okomentoval tvůj příspěvek',
    LEFT(NEW.content, 100),
    jsonb_build_object(
      'type', 'new_comment',
      'post_id', NEW.post_id::TEXT,
      'comment_id', NEW.id::TEXT
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_new_comment_notify_author ON comments;
CREATE TRIGGER on_new_comment_notify_author
  AFTER INSERT ON comments
  FOR EACH ROW
  EXECUTE FUNCTION notify_post_author_new_comment();

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
  SELECT display_name INTO sender_name
  FROM profiles
  WHERE id = NEW.sender_id;

  -- Najdi příjemce (ostatní účastníky konverzace)
  FOR recipient_id IN
    SELECT cp.user_id
    FROM conversation_participants cp
    WHERE cp.conversation_id = NEW.conversation_id
    AND cp.user_id != NEW.sender_id
  LOOP
    -- Zkontroluj nastavení notifikací
    SELECT notifications_enabled INTO recipient_notifications
    FROM user_settings
    WHERE user_id = recipient_id;

    IF recipient_notifications IS TRUE THEN
      PERFORM send_push_notification(
        recipient_id,
        'Nová zpráva od ' || COALESCE(sender_name, 'Uživatel'),
        LEFT(NEW.content, 100),
        jsonb_build_object(
          'type', 'new_message',
          'conversation_id', NEW.conversation_id::TEXT,
          'sender_id', NEW.sender_id::TEXT
        )
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_new_message_notify_recipient ON messages;
CREATE TRIGGER on_new_message_notify_recipient
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION notify_message_recipient();

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
  SELECT notifications_enabled INTO followed_notifications
  FROM user_settings
  WHERE user_id = NEW.following_id;

  IF followed_notifications IS NOT TRUE THEN
    RETURN NEW;
  END IF;

  -- Získej jméno sledujícího
  SELECT display_name INTO follower_name
  FROM profiles
  WHERE id = NEW.follower_id;

  -- Pošli notifikaci
  PERFORM send_push_notification(
    NEW.following_id,
    'Nový sledující',
    COALESCE(follower_name, 'Uživatel') || ' tě začal sledovat',
    jsonb_build_object(
      'type', 'new_follower',
      'follower_id', NEW.follower_id::TEXT
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_new_follower_notify ON follows;
CREATE TRIGGER on_new_follower_notify
  AFTER INSERT ON follows
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_follower();

-- ===========================================
-- Trigger: Nová reakce na příspěvek
-- ===========================================
CREATE OR REPLACE FUNCTION notify_post_reaction()
RETURNS TRIGGER AS $$
DECLARE
  reactor_name TEXT;
  post_author_id UUID;
  author_notifications BOOLEAN;
BEGIN
  -- Získej autora příspěvku
  SELECT user_id INTO post_author_id
  FROM posts
  WHERE id = NEW.post_id;

  -- Neposílej notifikaci pokud reaguje sám autor
  IF post_author_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  -- Zkontroluj nastavení notifikací
  SELECT notifications_enabled INTO author_notifications
  FROM user_settings
  WHERE user_id = post_author_id;

  IF author_notifications IS NOT TRUE THEN
    RETURN NEW;
  END IF;

  -- Získej jméno reagujícího
  SELECT display_name INTO reactor_name
  FROM profiles
  WHERE id = NEW.user_id;

  -- Pošli notifikaci
  PERFORM send_push_notification(
    post_author_id,
    COALESCE(reactor_name, 'Uživatel') || ' reagoval na tvůj příspěvek',
    NEW.type,
    jsonb_build_object(
      'type', 'new_reaction',
      'post_id', NEW.post_id::TEXT
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_new_reaction_notify ON reactions;
CREATE TRIGGER on_new_reaction_notify
  AFTER INSERT ON reactions
  FOR EACH ROW
  EXECUTE FUNCTION notify_post_reaction();
