-- Funkce pro odeslani push notifikace pri nove zprave
CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER AS $$
DECLARE
  sender_name TEXT;
  receiver_settings RECORD;
BEGIN
  -- Zjisti jmeno odesilatele
  SELECT display_name INTO sender_name
  FROM profiles
  WHERE id = NEW.sender_id;

  -- Zjisti nastaveni prijemce
  SELECT notifications_enabled INTO receiver_settings
  FROM user_settings
  WHERE user_id = NEW.receiver_id;

  -- Pokud ma prijemce zapnute notifikace, posli push
  IF receiver_settings.notifications_enabled THEN
    PERFORM net.http_post(
      url := current_setting('app.supabase_url') || '/functions/v1/send-push',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.service_role_key')
      ),
      body := jsonb_build_object(
        'user_id', NEW.receiver_id,
        'title', 'Nova zprava od ' || COALESCE(sender_name, 'Uzivatel'),
        'body', LEFT(NEW.content, 100),
        'data', jsonb_build_object(
          'type', 'message',
          'chat_id', NEW.chat_id,
          'sender_id', NEW.sender_id
        )
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funkce pro odeslani push notifikace pri novem komentari
CREATE OR REPLACE FUNCTION notify_new_comment()
RETURNS TRIGGER AS $$
DECLARE
  commenter_name TEXT;
  post_author_id UUID;
  author_settings RECORD;
BEGIN
  -- Zjisti autora prispevku
  SELECT user_id INTO post_author_id
  FROM posts
  WHERE id = NEW.post_id;

  -- Neposilej notifikaci pokud komentuje sam autor
  IF post_author_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  -- Zjisti jmeno komentatora
  SELECT display_name INTO commenter_name
  FROM profiles
  WHERE id = NEW.user_id;

  -- Zjisti nastaveni autora prispevku
  SELECT notifications_enabled INTO author_settings
  FROM user_settings
  WHERE user_id = post_author_id;

  -- Pokud ma autor zapnute notifikace, posli push
  IF author_settings.notifications_enabled THEN
    PERFORM net.http_post(
      url := current_setting('app.supabase_url') || '/functions/v1/send-push',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.service_role_key')
      ),
      body := jsonb_build_object(
        'user_id', post_author_id,
        'title', COALESCE(commenter_name, 'Uzivatel') || ' okomentoval tvuj prispevek',
        'body', LEFT(NEW.content, 100),
        'data', jsonb_build_object(
          'type', 'comment',
          'post_id', NEW.post_id,
          'comment_id', NEW.id
        )
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funkce pro odeslani push notifikace pri novem sledujicim
CREATE OR REPLACE FUNCTION notify_new_follower()
RETURNS TRIGGER AS $$
DECLARE
  follower_name TEXT;
  followed_settings RECORD;
BEGIN
  -- Zjisti jmeno sledujiciho
  SELECT display_name INTO follower_name
  FROM profiles
  WHERE id = NEW.follower_id;

  -- Zjisti nastaveni sledovaneho
  SELECT notifications_enabled INTO followed_settings
  FROM user_settings
  WHERE user_id = NEW.following_id;

  -- Pokud ma sledovany zapnute notifikace, posli push
  IF followed_settings.notifications_enabled THEN
    PERFORM net.http_post(
      url := current_setting('app.supabase_url') || '/functions/v1/send-push',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.service_role_key')
      ),
      body := jsonb_build_object(
        'user_id', NEW.following_id,
        'title', 'Novy sledujici',
        'body', COALESCE(follower_name, 'Uzivatel') || ' te zacal sledovat',
        'data', jsonb_build_object(
          'type', 'follow',
          'follower_id', NEW.follower_id
        )
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggery (zakomentovane - odkomentuj az budes mit Edge Function nasazenou)
-- Pro zpravy - odkomentuj az bude existovat tabulka messages
-- DROP TRIGGER IF EXISTS on_new_message ON messages;
-- CREATE TRIGGER on_new_message
--   AFTER INSERT ON messages
--   FOR EACH ROW
--   EXECUTE FUNCTION notify_new_message();

-- Pro komentare - odkomentuj az bude existovat tabulka comments
-- DROP TRIGGER IF EXISTS on_new_comment ON comments;
-- CREATE TRIGGER on_new_comment
--   AFTER INSERT ON comments
--   FOR EACH ROW
--   EXECUTE FUNCTION notify_new_comment();

-- Pro sledovani - odkomentuj az bude existovat tabulka follows
-- DROP TRIGGER IF EXISTS on_new_follower ON follows;
-- CREATE TRIGGER on_new_follower
--   AFTER INSERT ON follows
--   FOR EACH ROW
--   EXECUTE FUNCTION notify_new_follower();
