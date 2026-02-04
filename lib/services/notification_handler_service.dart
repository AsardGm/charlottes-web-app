import 'package:supabase_flutter/supabase_flutter.dart';
import 'haptic_service.dart';

/// Service for handling in-app notifications and celebration triggers
class NotificationHandlerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Callback for triggering UI celebrations
  Function(NotificationEvent)? onNotification;

  /// Register notification callback
  void registerCallback(Function(NotificationEvent) callback) {
    onNotification = callback;
  }

  /// Trigger challenge completion notification
  Future<void> notifyChallengeComplete({
    required String challengeTitle,
    required String challengeDescription,
    required int pointsEarned,
    required String icon,
    required String category,
  }) async {
    HapticService.success();

    final event = NotificationEvent(
      type: NotificationType.challengeComplete,
      title: challengeTitle,
      description: challengeDescription,
      data: {
        'points': pointsEarned,
        'icon': icon,
        'category': category,
      },
    );

    onNotification?.call(event);
    await _createNotificationRecord(event);
  }

  /// Trigger achievement unlock notification
  Future<void> notifyAchievementUnlocked({
    required String achievementTitle,
    required String achievementDescription,
    required int pointsEarned,
    required String icon,
    String? color,
  }) async {
    HapticService.success();

    final event = NotificationEvent(
      type: NotificationType.achievementUnlock,
      title: achievementTitle,
      description: achievementDescription,
      data: {
        'points': pointsEarned,
        'icon': icon,
        'color': color,
      },
    );

    onNotification?.call(event);
    await _createNotificationRecord(event);
  }

  /// Trigger level up notification
  Future<void> notifyLevelUp({
    required int newLevel,
    required int pointsEarned,
  }) async {
    HapticService.levelUp();

    final event = NotificationEvent(
      type: NotificationType.levelUp,
      title: 'Level Up!',
      description: 'Dosáhl jsi level $newLevel',
      data: {
        'level': newLevel,
        'points': pointsEarned,
      },
    );

    onNotification?.call(event);
    await _createNotificationRecord(event);
  }

  /// Trigger streak milestone notification
  Future<void> notifyStreakMilestone({
    required int days,
    required String category,
    String? message,
  }) async {
    HapticService.streak();

    final event = NotificationEvent(
      type: NotificationType.streakMilestone,
      title: '$days dní v řadě!',
      description: message ?? 'Skvělá práce!',
      data: {
        'days': days,
        'category': category,
      },
    );

    onNotification?.call(event);
    await _createNotificationRecord(event);
  }

  /// Trigger XP gain notification (quick, non-intrusive)
  Future<void> notifyXPGain({
    required int xp,
    required String source,
  }) async {
    HapticService.light();

    final event = NotificationEvent(
      type: NotificationType.xpGain,
      title: '+$xp XP',
      description: source,
      data: {
        'xp': xp,
        'source': source,
      },
    );

    onNotification?.call(event);
  }

  /// Create notification record in database
  Future<void> _createNotificationRecord(NotificationEvent event) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('in_app_notifications').insert({
        'user_id': userId,
        'type': event.type.name,
        'title': event.title,
        'message': event.description,
        'data': event.data,
        'is_read': false,
      });
    } catch (e) {
      // Silent fail - notification record is not critical
    }
  }

  /// Send daily reminder (for local notifications)
  Future<void> scheduleDailyReminder({
    required String userId,
    required String title,
    required String message,
    required DateTime scheduledTime,
  }) async {
    // This would integrate with flutter_local_notifications
    // For now, just create a scheduled notification record
    try {
      await _supabase.from('scheduled_notifications').insert({
        'user_id': userId,
        'type': 'daily_reminder',
        'title': title,
        'message': message,
        'scheduled_for': scheduledTime.toIso8601String(),
        'is_sent': false,
      });
    } catch (e) {
      // Silent fail
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('in_app_notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId);
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('in_app_notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}

/// Notification event types
enum NotificationType {
  challengeComplete,
  achievementUnlock,
  levelUp,
  streakMilestone,
  xpGain,
  dailyReminder,
  weeklyInsight,
}

/// Notification event data
class NotificationEvent {
  final NotificationType type;
  final String title;
  final String description;
  final Map<String, dynamic> data;

  NotificationEvent({
    required this.type,
    required this.title,
    required this.description,
    this.data = const {},
  });
}
