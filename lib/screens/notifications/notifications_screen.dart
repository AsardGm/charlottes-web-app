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
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        backgroundColor: AppColors.functionalBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notifikace',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.functionalMuted),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: AppColors.functionalSurface,
            onSelected: (value) {
              if (value == 'read_all') {
                ref.read(notificationNotifierProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Vse oznaceno jako prectene'),
                    backgroundColor: AppColors.functionalSurface,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              } else if (value == 'delete_read') {
                ref.read(notificationNotifierProvider.notifier).deleteReadNotifications();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'read_all',
                child: Row(
                  children: [
                    Icon(Icons.done_all, color: AppColors.accent, size: 20),
                    const SizedBox(width: 12),
                    const Text('Oznacit vse jako prectene'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete_read',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    const Text('Smazat prectene'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          // Rozdeleni na dnes, vcera, starsi
          final today = <NotificationModel>[];
          final yesterday = <NotificationModel>[];
          final older = <NotificationModel>[];
          final now = DateTime.now();

          for (final n in notifications) {
            final diff = now.difference(n.createdAt).inDays;
            if (diff == 0) {
              today.add(n);
            } else if (diff == 1) {
              yesterday.add(n);
            } else {
              older.add(n);
            }
          }

          return RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.functionalSurface,
            onRefresh: () => ref.read(notificationNotifierProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                if (today.isNotEmpty) ...[
                  _buildSectionHeader('Dnes', today.length),
                  ...today.map((n) => _NotificationCard(
                    notification: n,
                    onTap: () => _handleNotificationTap(context, ref, n),
                    onDismiss: () {
                      ref.read(notificationNotifierProvider.notifier).deleteNotification(n.id);
                    },
                  )),
                ],
                if (yesterday.isNotEmpty) ...[
                  _buildSectionHeader('Vcera', yesterday.length),
                  ...yesterday.map((n) => _NotificationCard(
                    notification: n,
                    onTap: () => _handleNotificationTap(context, ref, n),
                    onDismiss: () {
                      ref.read(notificationNotifierProvider.notifier).deleteNotification(n.id);
                    },
                  )),
                ],
                if (older.isNotEmpty) ...[
                  _buildSectionHeader('Starsi', older.length),
                  ...older.map((n) => _NotificationCard(
                    notification: n,
                    onTap: () => _handleNotificationTap(context, ref, n),
                    onDismiss: () {
                      ref.read(notificationNotifierProvider.notifier).deleteNotification(n.id);
                    },
                  )),
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.accent),
              const SizedBox(height: 16),
              Text(
                'Nacitam notifikace...',
                style: TextStyle(color: AppColors.functionalMuted),
              ),
            ],
          ),
        ),
        error: (error, _) => _buildErrorState(ref, error.toString()),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.functionalMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.functionalSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 40,
              color: AppColors.functionalMuted,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Zadne notifikace',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Az se neco stane, das se tady',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.functionalMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.functionalSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nepodarilo se nacist',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.functionalMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => ref.read(notificationNotifierProvider.notifier).refresh(),
              icon: Icon(Icons.refresh, color: AppColors.accent),
              label: Text(
                'Zkusit znovu',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, WidgetRef ref, NotificationModel notification) {
    if (!notification.isRead) {
      ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
    }

    if (notification.postId != null) {
      context.go('/post/${notification.postId}');
    } else if (notification.type == 'follow' && notification.actorId != null) {
      context.go('/user/${notification.actorId}');
    } else if (notification.type == 'chat' && notification.data['conversation_id'] != null) {
      context.go('/chat/${notification.data['conversation_id']}');
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final typeInfo = _getTypeInfo();

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.functionalSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : AppColors.accent.withAlpha(60),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar nebo ikona
                  _buildAvatar(typeInfo),
                  const SizedBox(width: 12),
                  // Obsah
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Typ badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: typeInfo.color.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    typeInfo.icon,
                                    size: 12,
                                    color: typeInfo.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    typeInfo.label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: typeInfo.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Cas
                            Text(
                              Helpers.formatTimeAgo(notification.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.functionalMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Title
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.isRead
                                ? FontWeight.w400
                                : FontWeight.w600,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        // Body
                        if (notification.body != null &&
                            notification.body!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            notification.body!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.functionalMuted,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Unread indicator
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 8, top: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(_NotificationTypeInfo typeInfo) {
    if (notification.actor != null) {
      return Stack(
        children: [
          UserAvatar(
            imageUrl: notification.actor!.avatarUrl,
            name: notification.actor!.username,
            size: 44,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: typeInfo.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.functionalSurface,
                  width: 2,
                ),
              ),
              child: Icon(
                typeInfo.icon,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: typeInfo.color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        typeInfo.icon,
        color: typeInfo.color,
        size: 22,
      ),
    );
  }

  _NotificationTypeInfo _getTypeInfo() {
    switch (notification.type) {
      case 'like':
        return _NotificationTypeInfo(
          icon: Icons.favorite_rounded,
          color: const Color(0xFFE91E63),
          label: 'Like',
        );
      case 'comment':
        return _NotificationTypeInfo(
          icon: Icons.chat_bubble_rounded,
          color: AppColors.info,
          label: 'Komentar',
        );
      case 'mention':
        return _NotificationTypeInfo(
          icon: Icons.alternate_email_rounded,
          color: AppColors.warning,
          label: 'Zmineni',
        );
      case 'follow':
        return _NotificationTypeInfo(
          icon: Icons.person_add_rounded,
          color: AppColors.success,
          label: 'Sledovani',
        );
      case 'reply':
        return _NotificationTypeInfo(
          icon: Icons.reply_rounded,
          color: AppColors.info,
          label: 'Odpoved',
        );
      case 'post':
        return _NotificationTypeInfo(
          icon: Icons.article_rounded,
          color: AppColors.primary,
          label: 'Prispevek',
        );
      case 'chat':
        return _NotificationTypeInfo(
          icon: Icons.message_rounded,
          color: const Color(0xFF00BCD4),
          label: 'Zprava',
        );
      case 'system':
      default:
        return _NotificationTypeInfo(
          icon: Icons.notifications_rounded,
          color: AppColors.textMuted,
          label: 'System',
        );
    }
  }
}

class _NotificationTypeInfo {
  final IconData icon;
  final Color color;
  final String label;

  _NotificationTypeInfo({
    required this.icon,
    required this.color,
    required this.label,
  });
}
