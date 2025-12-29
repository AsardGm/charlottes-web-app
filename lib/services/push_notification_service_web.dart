import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

/// Web implementace push notifikací pomocí FCM
/// Podporuje iOS 16.4+ PWA Push Notifications
class PushNotificationServiceImpl {
  static PushNotificationServiceImpl? _instance;
  static PushNotificationServiceImpl get instance =>
      _instance ??= PushNotificationServiceImpl._();

  PushNotificationServiceImpl._();

  final _supabase = Supabase.instance.client;

  static const String vapidKey =
      'BL7gIwdMNx4w-GwOYnFBPNDtJ1J93qvncLHoyyuWnAby1nvqz6ll6RfrPYF8SApGU-qFQiTVco_2KDiaH0ijUsA';

  StreamController<Map<String, dynamic>>? _messageController;

  Stream<Map<String, dynamic>> get onMessage {
    _messageController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _messageController!.stream;
  }

  /// Zkontroluje, zda je to iOS PWA
  bool get isIOSPWA {
    final userAgent = web.window.navigator.userAgent.toLowerCase();
    final isIOS = userAgent.contains('iphone') ||
                  userAgent.contains('ipad') ||
                  userAgent.contains('ipod');
    final isStandalone = web.window.matchMedia('(display-mode: standalone)').matches;
    return isIOS && isStandalone;
  }

  /// Zkontroluje, zda je to iOS (bez ohledu na PWA)
  bool get isIOS {
    final userAgent = web.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('iphone') ||
           userAgent.contains('ipad') ||
           userAgent.contains('ipod');
  }

  /// Zkontroluje, zda prohlížeč podporuje push notifikace
  bool get isPushSupported {
    try {
      return web.window.navigator.serviceWorker != null &&
             _hasNotificationAPI();
    } catch (e) {
      return false;
    }
  }

  bool _hasNotificationAPI() {
    try {
      // ignore: unnecessary_null_comparison
      return web.Notification != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> initialize() async {
    if (!isPushSupported) {
      debugPrint('[PushNotification] Push not supported on this browser');
      return;
    }

    _listenToForegroundMessages();
    _listenToServiceWorkerMessages();
    debugPrint('[PushNotification] Web initialized (iOS PWA: $isIOSPWA)');
  }

  Future<String> checkPermission() async {
    if (!isPushSupported) return 'unsupported';

    try {
      return web.Notification.permission;
    } catch (e) {
      return 'unsupported';
    }
  }

  Future<bool> requestPermission() async {
    if (!isPushSupported) {
      debugPrint('[PushNotification] Push not supported');
      return false;
    }

    try {
      // Pro iOS PWA musí být uživatel přidal na Home Screen
      if (isIOS && !isIOSPWA) {
        debugPrint('[PushNotification] iOS requires PWA (Add to Home Screen)');
        return false;
      }

      final jsResult = web.Notification.requestPermission();
      final result = await jsResult.toDart;
      final granted = result.toDart == 'granted';

      debugPrint('[PushNotification] Permission result: ${result.toDart}');
      return granted;
    } catch (e) {
      debugPrint('[PushNotification] Permission error: $e');
      return false;
    }
  }

  Future<bool> subscribe() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    if (!isPushSupported) return false;

    try {
      final token = await _getFCMToken();
      if (token == null || token.isEmpty) {
        debugPrint('[PushNotification] Failed to get FCM token');
        return false;
      }

      // Určení platformy pro analytics
      String platform = 'web';
      if (isIOSPWA) {
        platform = 'ios_pwa';
      } else if (isIOS) {
        platform = 'ios_web';
      }

      await _supabase.from('push_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,platform');

      debugPrint('[PushNotification] Subscribed with platform: $platform');
      return true;
    } catch (e) {
      debugPrint('[PushNotification] Subscribe error: $e');
      return false;
    }
  }

  Future<void> unsubscribe() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Smaž všechny web tokeny pro tohoto uživatele
      await _supabase
          .from('push_tokens')
          .delete()
          .eq('user_id', userId)
          .inFilter('platform', ['web', 'ios_pwa', 'ios_web']);
    } catch (e) {
      debugPrint('[PushNotification] Unsubscribe error: $e');
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? tag,
    Map<String, dynamic>? data,
  }) async {
    if (!isPushSupported) return;
    if (web.Notification.permission != 'granted') return;

    try {
      web.Notification(
        title,
        web.NotificationOptions(
          body: body,
          icon: '/icons/Icon-192.png',
          badge: '/icons/Icon-192.png',
          tag: tag ?? 'local-${DateTime.now().millisecondsSinceEpoch}',
          requireInteraction: false,
          silent: false,
        ),
      );
    } catch (e) {
      debugPrint('[PushNotification] Local notification error: $e');
    }
  }

  void _listenToForegroundMessages() {
    web.window.addEventListener(
      'fcm-message',
      _onFcmMessage.toJS,
    );
  }

  void _listenToServiceWorkerMessages() {
    // Poslouchej zprávy od service workeru (např. kliknutí na notifikaci)
    web.window.navigator.serviceWorker?.addEventListener(
      'message',
      _onServiceWorkerMessage.toJS,
    );
  }

  void _onFcmMessage(web.Event event) {
    try {
      final customEvent = event as web.CustomEvent;
      final detail = customEvent.detail;
      if (detail != null) {
        debugPrint('[PushNotification] Foreground message received');
        _messageController?.add({
          'title': '',
          'body': '',
          'data': {},
          'foreground': true,
        });
      }
    } catch (e) {
      debugPrint('[PushNotification] Message error: $e');
    }
  }

  void _onServiceWorkerMessage(web.Event event) {
    try {
      final messageEvent = event as web.MessageEvent;
      final data = messageEvent.data;
      debugPrint('[PushNotification] SW message: $data');

      // Zpracuj zprávy od SW (např. NOTIFICATION_CLICK)
      _messageController?.add({
        'type': 'sw_message',
        'data': data,
      });
    } catch (e) {
      debugPrint('[PushNotification] SW message error: $e');
    }
  }

  Future<String?> _getFCMToken() async {
    try {
      final result = await _jsGetFCMToken(vapidKey.toJS).toDart;
      final token = result?.toDart;
      if (token != null) {
        debugPrint('[PushNotification] Got FCM token: ${token.substring(0, 20)}...');
      }
      return token;
    } catch (e) {
      debugPrint('[PushNotification] Token error: $e');
      return null;
    }
  }

  /// Vrátí info o podpoře push notifikací pro UI
  Map<String, dynamic> getPushSupportInfo() {
    return {
      'supported': isPushSupported,
      'isIOS': isIOS,
      'isIOSPWA': isIOSPWA,
      'requiresPWA': isIOS && !isIOSPWA,
      'permission': isPushSupported ? web.Notification.permission : 'unsupported',
    };
  }

  void dispose() {
    _messageController?.close();
  }
}

@JS('getFCMToken')
external JSPromise<JSString?> _jsGetFCMToken(JSString vapidKey);
