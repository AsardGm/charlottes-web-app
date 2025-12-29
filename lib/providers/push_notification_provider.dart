import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/push_notification_service.dart';

/// Provider pro PushNotificationService singleton
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService.instance;
});

/// Stav povolení notifikací
final notificationPermissionProvider = FutureProvider<String>((ref) async {
  if (!kIsWeb) return 'unsupported';
  return ref.read(pushNotificationServiceProvider).checkPermission();
});

/// Provider pro přihlášení k push notifikacím
final pushSubscriptionProvider = FutureProvider.autoDispose<bool>((ref) async {
  if (!kIsWeb) return false;

  final service = ref.read(pushNotificationServiceProvider);

  // Nejdřív zkontroluj povolení
  final permission = await service.checkPermission();
  if (permission != 'granted') {
    return false;
  }

  // Přihlas se k notifikacím
  return service.subscribe();
});

/// Notifier pro správu push notifikací
class PushNotificationNotifier extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() {
    return const AsyncValue.data(false);
  }

  /// Požádá o povolení a přihlásí se k notifikacím
  Future<bool> enableNotifications() async {
    if (!kIsWeb) return false;

    state = const AsyncValue.loading();

    try {
      final service = ref.read(pushNotificationServiceProvider);

      // Požádej o povolení
      final granted = await service.requestPermission();
      if (!granted) {
        state = const AsyncValue.data(false);
        return false;
      }

      // Přihlas se
      final subscribed = await service.subscribe();
      state = AsyncValue.data(subscribed);
      return subscribed;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Odhlásí se od notifikací
  Future<void> disableNotifications() async {
    if (!kIsWeb) return;

    try {
      final service = ref.read(pushNotificationServiceProvider);
      await service.unsubscribe();
      state = const AsyncValue.data(false);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Zobrazí lokální notifikaci
  Future<void> showNotification({
    required String title,
    required String body,
    String? tag,
  }) async {
    if (!kIsWeb) return;

    final service = ref.read(pushNotificationServiceProvider);
    await service.showLocalNotification(
      title: title,
      body: body,
      tag: tag,
    );
  }
}

final pushNotificationNotifierProvider =
    NotifierProvider<PushNotificationNotifier, AsyncValue<bool>>(() {
  return PushNotificationNotifier();
});
