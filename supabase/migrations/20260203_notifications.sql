-- Notifications System
-- In-app notifications + push notification support

-- Notification Types
CREATE TYPE notification_type AS ENUM (
  'weekly_report_ready',
  'tbreak_reminder',
  'tbreak_milestone',
  'tbreak_completed',
  'post_check_reminder',
  'harm_reduction_alert',
  'achievement_unlocked',
  'cognitive_decline',
  'social_follow',
  'social_comment',
  'social_like',
  'system'
);

-- Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Type & Content
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,

  -- Optional icon and color for UI
  icon TEXT, -- e.g., 'notifications', 'check_circle', 'warning'
  color TEXT, -- e.g., 'primary', 'success', 'warning', 'error'

  -- Navigation
  action_route TEXT, -- e.g., '/insights/weekly', '/tbreak'
  action_label TEXT, -- e.g., 'View Report', 'Continue'

  -- Related data
  data JSONB DEFAULT '{}'::jsonb,
  -- Example: {
  --   "weekly_insight_id": "uuid",
  --   "tbreak_id": "uuid",
  --   "achievement_type": "first_tbreak"
  -- }

  -- Status
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,

  -- Push notification status
  push_sent BOOLEAN DEFAULT FALSE,
  push_sent_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notification Preferences Table
CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- In-app notifications (always enabled)
  in_app_enabled BOOLEAN DEFAULT TRUE,

  -- Push notifications (require FCM token)
  push_enabled BOOLEAN DEFAULT TRUE,
  fcm_token TEXT,

  -- Notification type preferences
  weekly_reports BOOLEAN DEFAULT TRUE,
  tbreak_reminders BOOLEAN DEFAULT TRUE,
  post_check_reminders BOOLEAN DEFAULT TRUE,
  harm_reduction_alerts BOOLEAN DEFAULT TRUE,
  achievements BOOLEAN DEFAULT TRUE,
  cognitive_alerts BOOLEAN DEFAULT TRUE,
  social_notifications BOOLEAN DEFAULT TRUE,

  -- Quiet hours
  quiet_hours_enabled BOOLEAN DEFAULT FALSE,
  quiet_hours_start TIME, -- e.g., '22:00:00'
  quiet_hours_end TIME,   -- e.g., '08:00:00'

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_is_read ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX idx_notification_preferences_user_id ON notification_preferences(user_id);

-- RLS Policies
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (true); -- Allow system/triggers to insert

CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view own preferences"
  ON notification_preferences FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences"
  ON notification_preferences FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences"
  ON notification_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Function to create notification
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id UUID,
  p_type notification_type,
  p_title TEXT,
  p_body TEXT,
  p_icon TEXT DEFAULT NULL,
  p_color TEXT DEFAULT NULL,
  p_action_route TEXT DEFAULT NULL,
  p_action_label TEXT DEFAULT NULL,
  p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
  v_prefs RECORD;
BEGIN
  -- Check user preferences
  SELECT * INTO v_prefs
  FROM notification_preferences
  WHERE user_id = p_user_id;

  -- If no preferences, create default
  IF NOT FOUND THEN
    INSERT INTO notification_preferences (user_id)
    VALUES (p_user_id);

    SELECT * INTO v_prefs
    FROM notification_preferences
    WHERE user_id = p_user_id;
  END IF;

  -- Check if notification type is enabled
  IF (
    (p_type = 'weekly_report_ready' AND NOT v_prefs.weekly_reports) OR
    (p_type IN ('tbreak_reminder', 'tbreak_milestone', 'tbreak_completed') AND NOT v_prefs.tbreak_reminders) OR
    (p_type = 'post_check_reminder' AND NOT v_prefs.post_check_reminders) OR
    (p_type = 'harm_reduction_alert' AND NOT v_prefs.harm_reduction_alerts) OR
    (p_type = 'achievement_unlocked' AND NOT v_prefs.achievements) OR
    (p_type = 'cognitive_decline' AND NOT v_prefs.cognitive_alerts) OR
    (p_type IN ('social_follow', 'social_comment', 'social_like') AND NOT v_prefs.social_notifications)
  ) THEN
    RETURN NULL; -- Notification type disabled
  END IF;

  -- Create notification
  INSERT INTO notifications (
    user_id,
    type,
    title,
    body,
    icon,
    color,
    action_route,
    action_label,
    data
  )
  VALUES (
    p_user_id,
    p_type,
    p_title,
    p_body,
    p_icon,
    p_color,
    p_action_route,
    p_action_label,
    p_data
  )
  RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_notifications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notifications_updated_at
  BEFORE UPDATE ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION update_notifications_updated_at();

CREATE TRIGGER notification_preferences_updated_at
  BEFORE UPDATE ON notification_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_notifications_updated_at();

-- Trigger: Create notification when weekly insight is generated
CREATE OR REPLACE FUNCTION notify_weekly_insight_ready()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM create_notification(
    NEW.user_id,
    'weekly_report_ready',
    '📊 Weekly Report Ready',
    'Your weekly insights are ready to view!',
    'assignment',
    'primary',
    '/insights/weekly/' || NEW.id,
    'View Report',
    jsonb_build_object('weekly_insight_id', NEW.id)
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER weekly_insight_notification
  AFTER INSERT ON weekly_insights
  FOR EACH ROW
  EXECUTE FUNCTION notify_weekly_insight_ready();

-- Trigger: Create notification when T-break milestone reached
CREATE OR REPLACE FUNCTION notify_tbreak_milestone()
RETURNS TRIGGER AS $$
DECLARE
  v_milestone TEXT;
BEGIN
  -- Check for milestones (3, 7, 14, 21, 30 days)
  IF NEW.days_completed IN (3, 7, 14, 21, 30) AND
     (OLD.days_completed IS NULL OR OLD.days_completed != NEW.days_completed) THEN

    CASE NEW.days_completed
      WHEN 3 THEN v_milestone := '🎯 3-Day Milestone! Peak withdrawal - you''re doing great!';
      WHEN 7 THEN v_milestone := '🌟 Week Complete! Receptors resetting, tolerance dropping.';
      WHEN 14 THEN v_milestone := '💪 2 Weeks Done! Major progress - you''re crushing it!';
      WHEN 21 THEN v_milestone := '🚀 3 Weeks! Tolerance significantly reset.';
      WHEN 30 THEN v_milestone := '👑 30 Days! Full reset achieved - legendary!';
    END CASE;

    PERFORM create_notification(
      NEW.user_id,
      'tbreak_milestone',
      'T-Break Milestone 🎉',
      v_milestone,
      'emoji_events',
      'success',
      '/tbreak',
      'View Progress',
      jsonb_build_object('tbreak_id', NEW.id, 'milestone_days', NEW.days_completed)
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tbreak_milestone_notification
  AFTER UPDATE ON tolerance_breaks
  FOR EACH ROW
  WHEN (NEW.status = 'active')
  EXECUTE FUNCTION notify_tbreak_milestone();

-- Trigger: Create notification when T-break completed
CREATE OR REPLACE FUNCTION notify_tbreak_completed()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status = 'active' THEN
    PERFORM create_notification(
      NEW.user_id,
      'tbreak_completed',
      '🎉 T-Break Completed!',
      format('Congratulations! You completed your %s-day tolerance break. Your receptors are reset!', NEW.target_days),
      'celebration',
      'success',
      '/tbreak',
      'View Stats',
      jsonb_build_object('tbreak_id', NEW.id, 'days_completed', NEW.days_completed)
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tbreak_completed_notification
  AFTER UPDATE ON tolerance_breaks
  FOR EACH ROW
  EXECUTE FUNCTION notify_tbreak_completed();

-- Function to send post-check reminder (called by scheduled job)
CREATE OR REPLACE FUNCTION send_post_check_reminders()
RETURNS void AS $$
DECLARE
  v_log RECORD;
  v_time_since_consumption INT;
BEGIN
  -- Find consumption logs 30-180 min ago without post-check
  FOR v_log IN
    SELECT cl.id, cl.user_id, cl.timestamp
    FROM consumption_logs cl
    LEFT JOIN post_consumption_checks pcc ON pcc.consumption_log_id = cl.id
    WHERE pcc.id IS NULL
      AND cl.timestamp > NOW() - INTERVAL '180 minutes'
      AND cl.timestamp < NOW() - INTERVAL '30 minutes'
  LOOP
    v_time_since_consumption := EXTRACT(EPOCH FROM (NOW() - v_log.timestamp)) / 60;

    -- Check if notification already sent for this log
    IF NOT EXISTS (
      SELECT 1 FROM notifications
      WHERE user_id = v_log.user_id
        AND type = 'post_check_reminder'
        AND data->>'consumption_log_id' = v_log.id::text
    ) THEN
      PERFORM create_notification(
        v_log.user_id,
        'post_check_reminder',
        '⏰ Post-Check Reminder',
        format('It''s been %s minutes since your session. How are you feeling?', v_time_since_consumption),
        'psychology',
        'accent',
        '/consumption/post-check/' || v_log.id,
        'Check In',
        jsonb_build_object('consumption_log_id', v_log.id)
      );
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark all notifications as read
CREATE OR REPLACE FUNCTION mark_all_notifications_read(p_user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE notifications
  SET is_read = true, read_at = NOW()
  WHERE user_id = p_user_id AND is_read = false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete old read notifications (cleanup)
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS void AS $$
BEGIN
  -- Delete read notifications older than 30 days
  DELETE FROM notifications
  WHERE is_read = true
    AND read_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON TABLE notifications IS 'In-app and push notifications for users';
COMMENT ON TABLE notification_preferences IS 'User notification preferences and FCM tokens';
