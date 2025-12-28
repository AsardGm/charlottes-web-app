import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../utils/helpers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Oznacit vse jako prectene',
            onPressed: () {
              ref.read(notificationNotifierProvider.notifier).markAllAsRead();
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(notificationNotifierProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _NotificationTile(
                  notification: notifications[index],
                  onTap: () => _handleNotificationTap(context, ref, notifications[index]),
                  onDismiss: () {
                    ref.read(notificationNotifierProvider.notifier)
                        .deleteNotification(notifications[index].id);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Chyba: ${error.toString()}'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(notificationNotifierProvider.notifier).refresh(),
                child: const Text('Zkusit znovu'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withAlpha(20),
                  AppColors.primary.withAlpha(5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withAlpha(30),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: AppColors.primary.withAlpha(180),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Zadne notifikace',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tady uvidis vsechny novinky',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, WidgetRef ref, NotificationModel notification) {
    // Oznac jako prectene
    if (!notification.isRead) {
      ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
    }

    // Naviguj podle typu
    if (notification.postId != null) {
      context.go('/post/${notification.postId}');
    } else if (notification.type == 'follow' && notification.actorId != null) {
      // TODO: Navigate to user profile
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Material(
        color: notification.isRead
            ? Colors.transparent
            : AppColors.primary.withAlpha(10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withAlpha(5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon nebo avatar
                _buildLeading(),
                const SizedBox(width: 12),
                // Obsah
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: notification.isRead
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (notification.body != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          notification.body!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        Helpers.formatTimeAgo(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Unread indicator
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6, left: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (notification.actor != null) {
      return UserAvatar(
        imageUrl: notification.actor!.avatarUrl,
        name: notification.actor!.username,
        size: 44,
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _getTypeColor().withAlpha(20),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getTypeIcon(),
        color: _getTypeColor(),
        size: 22,
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case 'like':
        return Icons.thumb_up;
      case 'comment':
        return Icons.chat_bubble;
      case 'mention':
        return Icons.alternate_email;
      case 'follow':
        return Icons.person_add;
      case 'reply':
        return Icons.reply;
      case 'post':
        return Icons.article;
      case 'chat':
        return Icons.message;
      case 'system':
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case 'like':
        return AppColors.primary;
      case 'comment':
        return AppColors.info;
      case 'mention':
        return AppColors.warning;
      case 'follow':
        return AppColors.success;
      case 'reply':
        return AppColors.info;
      case 'post':
        return AppColors.primary;
      case 'chat':
        return AppColors.success;
      case 'system':
      default:
        return AppColors.textMuted;
    }
  }
}
