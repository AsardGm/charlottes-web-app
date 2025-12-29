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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withAlpha(40),
                    AppColors.primary.withAlpha(20),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Notifikace',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: AppColors.surface,
            onSelected: (value) {
              if (value == 'read_all') {
                ref.read(notificationNotifierProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Vse oznaceno jako prectene'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
                    Icon(Icons.done_all, color: AppColors.success, size: 20),
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
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
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
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Nacitam notifikace...',
                style: TextStyle(color: AppColors.textMuted),
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
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
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
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withAlpha(30),
                  AppColors.primary.withAlpha(5),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 56,
              color: AppColors.primary.withAlpha(150),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Zadne notifikace',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Az se neco stane, das se tady',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textMuted,
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nepodarilo se nacist',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.read(notificationNotifierProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Zkusit znovu'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              'Smazat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surface
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.white.withAlpha(5)
                : typeInfo.color.withAlpha(40),
            width: notification.isRead ? 1 : 2,
          ),
          boxShadow: notification.isRead
              ? null
              : [
                  BoxShadow(
                    color: typeInfo.color.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar nebo ikona
                  _buildAvatar(typeInfo),
                  const SizedBox(width: 14),
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
                                color: typeInfo.color.withAlpha(20),
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
                                color: AppColors.textMuted,
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
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        // Body
                        if (notification.body != null &&
                            notification.body!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            notification.body!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
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
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            typeInfo.color,
                            typeInfo.color.withAlpha(150),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: typeInfo.color.withAlpha(100),
                            blurRadius: 6,
                          ),
                        ],
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
            size: 48,
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
                  color: AppColors.surface,
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
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            typeInfo.color.withAlpha(40),
            typeInfo.color.withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        typeInfo.icon,
        color: typeInfo.color,
        size: 24,
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
