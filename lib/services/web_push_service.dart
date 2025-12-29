import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Služba pro Web Push notifikace v PWA
///
/// Používá Web Push API pro nativní push notifikace na mobilních zařízeních
/// i na desktopu (Chrome, Firefox, Safari 16.4+).
class WebPushService {
  static WebPushService? _instance;
  static WebPushService get instance => _instance ??= WebPushService._();

  WebPushService._();

  final _supabase = Supabase.instance.client;

  /// VAPID public key pro Web Push
  /// Vygeneruj pomocí: npx web-push generate-vapid-keys
  /// Toto je placeholder - nahraď vlastním klíčem!
  static const String vapidPublicKey =
      'YOUR_VAPID_PUBLIC_KEY_HERE';

  /// Inicializuje Web Push (pouze na webu)
  Future<void> initialize() async {
    if (!kIsWeb) return;

    try {
      // Registrace service workeru přes JS interop
      await _registerServiceWorker();
      debugPrint('[WebPush] Service worker registered');
    } catch (e) {
      debugPrint('[WebPush] Failed to initialize: $e');
    }
  }

  /// Požádá o povolení notifikací
  Future<bool> requestPermission() async {
    if (!kIsWeb) return false;

    try {
      final permission = await _requestNotificationPermission();
      return permission == 'granted';
    } catch (e) {
      debugPrint('[WebPush] Permission request failed: $e');
      return false;
    }
  }

  /// Zkontroluje stav povolení
  Future<String> checkPermission() async {
    if (!kIsWeb) return 'denied';

    try {
      return await _getNotificationPermission();
    } catch (e) {
      return 'denied';
    }
  }

  /// Přihlásí se k push notifikacím a uloží subscription do Supabase
  Future<bool> subscribe() async {
    if (!kIsWeb) return false;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final subscription = await _subscribeToPush();
      if (subscription == null) return false;

      // Ulož subscription do Supabase
      await _supabase.from('push_subscriptions').upsert({
        'user_id': userId,
        'endpoint': subscription['endpoint'],
        'p256dh': subscription['keys']['p256dh'],
        'auth': subscription['keys']['auth'],
        'platform': 'web',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,platform');

      debugPrint('[WebPush] Subscribed successfully');
      return true;
    } catch (e) {
      debugPrint('[WebPush] Subscribe failed: $e');
      return false;
    }
  }

  /// Odhlásí se od push notifikací
  Future<bool> unsubscribe() async {
    if (!kIsWeb) return false;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _unsubscribeFromPush();

      // Smaž subscription z Supabase
      await _supabase
          .from('push_subscriptions')
          .delete()
          .eq('user_id', userId)
          .eq('platform', 'web');

      debugPrint('[WebPush] Unsubscribed successfully');
      return true;
    } catch (e) {
      debugPrint('[WebPush] Unsubscribe failed: $e');
      return false;
    }
  }

  /// Zobrazí lokální notifikaci (když je app otevřená)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
    Map<String, dynamic>? data,
  }) async {
    if (!kIsWeb) return;

    try {
      await _showNotification(
        title: title,
        body: body,
        icon: icon ?? '/icons/Icon-192.png',
        tag: tag ?? 'local-${DateTime.now().millisecondsSinceEpoch}',
        data: data ?? {},
      );
    } catch (e) {
      debugPrint('[WebPush] Show notification failed: $e');
    }
  }

  // === JS Interop helpers (budou implementovány v index.html) ===

  Future<void> _registerServiceWorker() async {
    // Implementováno přes JS
  }

  Future<String> _requestNotificationPermission() async {
    // Implementováno přes JS
    return 'default';
  }

  Future<String> _getNotificationPermission() async {
    // Implementováno přes JS
    return 'default';
  }

  Future<Map<String, dynamic>?> _subscribeToPush() async {
    // Implementováno přes JS
    return null;
  }

  Future<void> _unsubscribeFromPush() async {
    // Implementováno přes JS
  }

  Future<void> _showNotification({
    required String title,
    required String body,
    required String icon,
    required String tag,
    required Map<String, dynamic> data,
  }) async {
    // Implementováno přes JS
  }
}
