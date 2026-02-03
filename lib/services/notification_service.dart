import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'dart:async';

/// Service for managing in-app notifications
class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Stream controller for real-time notifications
  final _notificationController = StreamController<List<NotificationModel>>.broadcast();

  /// Real-time subscription
  RealtimeChannel? _subscription;

  /// Get notifications stream
  Stream<List<NotificationModel>> get notificationsStream => _notificationController.stream;

  /// Get all notifications for user
  Future<List<NotificationModel>> getNotifications(String userId) async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((json) => NotificationModel.fromJson(json))
        .toList();
  }

  /// Get unread notifications count
  Future<int> getUnreadCount(String userId) async {
    final response = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (response as List).length;
  }

  /// Get unread notifications
  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => NotificationModel.fromJson(json))
        .toList();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _supabase.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', notificationId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    await _supabase.rpc('mark_all_notifications_read', params: {
      'p_user_id': userId,
    });
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _supabase.from('notifications').delete().eq('id', notificationId);
  }

  /// Delete all read notifications
  Future<void> deleteAllRead(String userId) async {
    await _supabase
        .from('notifications')
        .delete()
        .eq('user_id', userId)
        .eq('is_read', true);
  }

  /// Create notification (manual creation)
  Future<NotificationModel> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? icon,
    String? color,
    String? actionRoute,
    String? actionLabel,
    Map<String, dynamic>? data,
  }) async {
    final response = await _supabase
        .from('notifications')
        .insert({
          'user_id': userId,
          'type': type,
          'title': title,
          'body': body,
          'icon': icon,
          'color': color,
          'action_route': actionRoute,
          'action_label': actionLabel,
          'data': data ?? {},
        })
        .select()
        .single();

    return NotificationModel.fromJson(response);
  }

  /// Subscribe to real-time notifications
  void subscribeToNotifications(String userId) {
    _subscription?.unsubscribe();

    _subscription = _supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            // Fetch updated notifications
            final notifications = await getNotifications(userId);
            _notificationController.add(notifications);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            final notifications = await getNotifications(userId);
            _notificationController.add(notifications);
          },
        )
        .subscribe();
  }

  /// Unsubscribe from notifications
  void unsubscribe() {
    _subscription?.unsubscribe();
    _subscription = null;
  }

  /// Dispose
  void dispose() {
    unsubscribe();
    _notificationController.close();
  }

  // ========== NOTIFICATION TRIGGERS ==========

  /// Send post-check reminder notification
  Future<void> sendPostCheckReminder({
    required String userId,
    required String consumptionLogId,
    required int minutesSince,
  }) async {
    await createNotification(
      userId: userId,
      type: 'post_check_reminder',
      title: '⏰ Post-Check Reminder',
      body: 'It\'s been $minutesSince minutes since your session. How are you feeling?',
      icon: 'psychology',
      color: 'accent',
      actionRoute: '/consumption/post-check/$consumptionLogId',
      actionLabel: 'Check In',
      data: {'consumption_log_id': consumptionLogId},
    );
  }

  /// Send T-break daily reminder
  Future<void> sendTBreakReminder({
    required String userId,
    required String tbreakId,
    required int daysCompleted,
    required int targetDays,
  }) async {
    final daysRemaining = targetDays - daysCompleted;

    await createNotification(
      userId: userId,
      type: 'tbreak_reminder',
      title: '💪 T-Break Day $daysCompleted',
      body: '$daysRemaining days to go. You\'re doing amazing!',
      icon: 'fitness_center',
      color: 'success',
      actionRoute: '/tbreak',
      actionLabel: 'Check In',
      data: {
        'tbreak_id': tbreakId,
        'days_completed': daysCompleted,
        'days_remaining': daysRemaining,
      },
    );
  }

  /// Send harm reduction alert
  Future<void> sendHarmReductionAlert({
    required String userId,
    required String message,
    required String severity,
  }) async {
    String title;
    String icon;
    String color;

    switch (severity) {
      case 'high':
        title = '🚨 Harm Reduction Alert';
        icon = 'warning';
        color = 'error';
        break;
      case 'medium':
        title = '⚠️ Harm Reduction Notice';
        icon = 'info';
        color = 'warning';
        break;
      default:
        title = '💡 Harm Reduction Tip';
        icon = 'tips_and_updates';
        color = 'primary';
    }

    await createNotification(
      userId: userId,
      type: 'harm_reduction_alert',
      title: title,
      body: message,
      icon: icon,
      color: color,
      actionRoute: '/harm-reduction',
      actionLabel: 'Learn More',
      data: {'severity': severity},
    );
  }

  /// Send achievement notification
  Future<void> sendAchievementNotification({
    required String userId,
    required String achievementType,
    required String title,
    required String description,
  }) async {
    await createNotification(
      userId: userId,
      type: 'achievement_unlocked',
      title: '🏆 Achievement Unlocked!',
      body: '$title - $description',
      icon: 'stars',
      color: 'success',
      actionRoute: '/gamification',
      actionLabel: 'View Achievements',
      data: {'achievement_type': achievementType},
    );
  }

  /// Send cognitive decline alert
  Future<void> sendCognitiveDeclineAlert({
    required String userId,
    required double currentScore,
    required double baselineScore,
    required double declinePercent,
  }) async {
    await createNotification(
      userId: userId,
      type: 'cognitive_decline',
      title: '📉 Cognitive Performance Alert',
      body:
          'Your cognitive score has declined by ${declinePercent.toStringAsFixed(1)}%. Consider a tolerance break.',
      icon: 'trending_down',
      color: 'warning',
      actionRoute: '/quantum',
      actionLabel: 'View Details',
      data: {
        'current_score': currentScore,
        'baseline_score': baselineScore,
        'decline_percent': declinePercent,
      },
    );
  }
}
