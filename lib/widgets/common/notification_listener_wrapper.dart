import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_handler_provider.dart';
import '../../services/notification_handler_service.dart';
import 'celebration_overlay.dart';

/// Wrapper widget that listens for notifications and shows celebrations
class NotificationListenerWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationListenerWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<NotificationListenerWrapper> createState() =>
      _NotificationListenerWrapperState();
}

class _NotificationListenerWrapperState
    extends ConsumerState<NotificationListenerWrapper> {
  @override
  void initState() {
    super.initState();

    // Register notification callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final handler = ref.read(notificationHandlerProvider);
      handler.registerCallback(_handleNotification);
    });
  }

  void _handleNotification(NotificationEvent event) {
    if (!mounted) return;

    switch (event.type) {
      case NotificationType.challengeComplete:
        CelebrationOverlay.showAchievement(
          context: context,
          title: event.title,
          description: event.description,
          icon: event.data['icon'] as String? ?? '🏆',
          color: _getCategoryColor(event.data['category'] as String?),
        );
        break;

      case NotificationType.achievementUnlock:
        CelebrationOverlay.showAchievement(
          context: context,
          title: event.title,
          description: event.description,
          icon: event.data['icon'] as String? ?? '⭐',
          color: _parseColor(event.data['color'] as String?),
        );
        break;

      case NotificationType.levelUp:
        CelebrationOverlay.showLevelUp(
          context: context,
          level: event.data['level'] as int,
          pointsEarned: event.data['points'] as int,
        );
        break;

      case NotificationType.streakMilestone:
        CelebrationOverlay.showStreak(
          context: context,
          days: event.data['days'] as int,
          message: event.description,
        );
        break;

      case NotificationType.xpGain:
        CelebrationOverlay.showXPGain(
          context: context,
          xp: event.data['xp'] as int,
        );
        break;

      case NotificationType.dailyReminder:
      case NotificationType.weeklyInsight:
        // These are handled by the notification screen
        break;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'wellness':
        return const Color(0xFF66BB6A);
      case 'journal':
        return const Color(0xFFAB47BC);
      case 'tbreak':
        return const Color(0xFF66BB6A);
      case 'cognitive':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFFFFB74D);
    }
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null) return const Color(0xFFFFB74D);

    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFFFFB74D);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
