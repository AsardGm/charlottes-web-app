import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  return ref.read(notificationServiceProvider).getNotifications(userId);
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return 0;
  return ref.read(notificationServiceProvider).getUnreadCount(userId);
});

class NotificationNotifier extends Notifier<AsyncValue<List<NotificationModel>>> {
  late NotificationService _service;
  late String _userId;

  @override
  AsyncValue<List<NotificationModel>> build() {
    _service = ref.read(notificationServiceProvider);
    _userId = Supabase.instance.client.auth.currentUser!.id;
    _loadNotifications();
    _subscribeToRealtime();
    return const AsyncValue.loading();
  }
  Future<void> _loadNotifications() async {
    try {
      final notifications = await _service.getNotifications(_userId);
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeToRealtime() {
    _service.subscribeToNotifications(_userId);
    _service.notificationsStream.listen((notifications) {
      state = AsyncValue.data(notifications);
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadNotifications();
    ref.invalidate(unreadCountProvider);
  }

  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);

    // Aktualizuj lokální stav
    state.whenData((notifications) {
      final updated = notifications.map((n) {
        if (n.id == notificationId) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            body: n.body,
            actorId: n.actorId,
            postId: n.postId,
            commentId: n.commentId,
            data: n.data,
            isRead: true,
            readAt: DateTime.now(),
            createdAt: n.createdAt,
            actor: n.actor,
          );
        }
        return n;
      }).toList();
      state = AsyncValue.data(updated);
    });

    ref.invalidate(unreadCountProvider);
  }

  Future<void> markAllAsRead() async {
    await _service.markAllAsRead(_userId);

    // Aktualizuj lokální stav
    state.whenData((notifications) {
      final updated = notifications.map((n) {
        return NotificationModel(
          id: n.id,
          userId: n.userId,
          type: n.type,
          title: n.title,
          body: n.body,
          actorId: n.actorId,
          postId: n.postId,
          commentId: n.commentId,
          data: n.data,
          isRead: true,
          readAt: DateTime.now(),
          createdAt: n.createdAt,
          actor: n.actor,
        );
      }).toList();
      state = AsyncValue.data(updated);
    });

    ref.invalidate(unreadCountProvider);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _service.deleteNotification(notificationId);

    state.whenData((notifications) {
      final updated = notifications.where((n) => n.id != notificationId).toList();
      state = AsyncValue.data(updated);
    });

    ref.invalidate(unreadCountProvider);
  }

  Future<void> deleteReadNotifications() async {
    await _service.deleteAllRead(_userId);

    state.whenData((notifications) {
      final updated = notifications.where((n) => !n.isRead).toList();
      state = AsyncValue.data(updated);
    });

    ref.invalidate(unreadCountProvider);
  }
}

final notificationNotifierProvider =
    NotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>(() {
  return NotificationNotifier();
});
