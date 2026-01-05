import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'web_push_service.dart';

/// Web implementace push notifikací pro PWA
///
/// Tato služba:
/// - Registruje FCM token pro web/PWA
/// - Zpracovává foreground notifikace
/// - Komunikuje se service workerem
/// - Podporuje iOS 16.4+ PWA push notifikace
class WebPushServiceImpl implements WebPushService {
  /// VAPID klíč pro FCM (veřejný klíč z Firebase Console)
  static const String _vapidKey =
      'BPjYAJHAQQN1aViQ23YQCP0_J57aMbVr5Y_FkDMlhpAR_HpjkDZl6uwyMuXjefOhAymxVgGMj9CoWsP92eHhoeI';

  final SupabaseClient _supabase = Supabase.instance.client;

  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get onNotification =>
      _notificationController.stream;

  String? _currentToken;
  @override
  String? get currentToken => _currentToken;

  bool _isEnabled = false;
  @override
  bool get isEnabled => _isEnabled;

  @override
  String get platform {
    final userAgent = web.window.navigator.userAgent;

    if (userAgent.contains('iPhone') ||
        userAgent.contains('iPad') ||
        userAgent.contains('iPod')) {
      return isStandalone ? 'ios_pwa' : 'ios_web';
    }

    if (userAgent.contains('Android')) {
      return isStandalone ? 'android_pwa' : 'android_web';
    }

    return 'web';
  }

  @override
  bool get isStandalone {
    // Kontrola display-mode: standalone
    final mediaQuery = web.window.matchMedia('(display-mode: standalone)');
    if (mediaQuery.matches) return true;

    // iOS Safari standalone check
    final navigator = web.window.navigator;
    final standalone = _getNavigatorStandalone(navigator);
    return standalone;
  }

  @override
  bool get isPushSupported {
    // iOS Safari nepodporuje push, ale iOS PWA ano (od 16.4)
    if (platform == 'ios_web') return false;

    return _hasNotificationSupport() && _hasPushManagerSupport();
  }

  @override
  Future<void> initialize() async {
    debugPrint('[WebPush] Initializing for platform: $platform');

    // Nastav listener pro foreground zprávy z FCM
    _setupForegroundListener();

    // Nastav listener pro kliknutí na notifikace
    _setupNotificationClickListener();

    // Zkontroluj existující oprávnění
    final permission = _getNotificationPermission();
    _isEnabled = permission == 'granted';

    if (_isEnabled) {
      await _refreshToken();
    }

    debugPrint('[WebPush] Initialized. Enabled: $_isEnabled');
  }

  void _setupForegroundListener() {
    web.window.addEventListener(
      'fcm-message',
      (web.Event event) {
        final customEvent = event as web.CustomEvent;
        final payload = customEvent.detail;

        debugPrint('[WebPush] Foreground message received');

        if (payload != null) {
          try {
            final data = _convertJsObject(payload);
            _notificationController.add(data);
            _showForegroundNotification(data);
          } catch (e) {
            debugPrint('[WebPush] Error processing foreground message: $e');
          }
        }
      }.toJS,
    );
  }

  void _setupNotificationClickListener() {
    final sw = web.window.navigator.serviceWorker;
    sw.addEventListener(
      'message',
      (web.Event event) {
        final messageEvent = event as web.MessageEvent;
        final data = messageEvent.data;

        if (data != null) {
          try {
            final map = _convertJsObject(data);
            if (map['type'] == 'NOTIFICATION_CLICK') {
              debugPrint('[WebPush] Notification click: ${map['url']}');

              _notificationController.add({
                'type': 'click',
                'url': map['url'],
                'data': map['data'],
              });
            }
          } catch (e) {
            debugPrint('[WebPush] Error processing SW message: $e');
          }
        }
      }.toJS,
    );
  }

  Map<String, dynamic> _convertJsObject(JSAny? jsObject) {
    if (jsObject == null) return {};

    try {
      final jsonString = _jsonStringify(jsObject);
      if (jsonString != null) {
        return json.decode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[WebPush] Error converting JS object: $e');
    }
    return {};
  }

  void _showForegroundNotification(Map<String, dynamic> data) {
    debugPrint('[WebPush] Foreground notification: $data');
  }

  @override
  Future<String> requestPermission() async {
    try {
      final permission = await _requestNotificationPermissionJS();
      final result = permission ?? 'denied';

      debugPrint('[WebPush] Permission result: $result');

      _isEnabled = result == 'granted';

      if (_isEnabled) {
        await _refreshToken();
      }

      return result;
    } catch (e) {
      debugPrint('[WebPush] Permission error: $e');
      return 'denied';
    }
  }

  String _getNotificationPermission() {
    try {
      return _getNotificationPermissionJS() ?? 'default';
    } catch (e) {
      return 'default';
    }
  }

  Future<String?> _refreshToken() async {
    try {
      final token = await _getFCMTokenJS(_vapidKey);
      _currentToken = token;

      if (_currentToken != null) {
        debugPrint(
            '[WebPush] Token: ${_currentToken!.substring(0, 20)}...');
        await _saveTokenToDatabase(_currentToken!);
      }

      return _currentToken;
    } catch (e) {
      debugPrint('[WebPush] Token error: $e');
      return null;
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[WebPush] Cannot save token - user not logged in');
      return;
    }

    try {
      await _supabase.from('push_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': platform,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id, platform',
      );

      debugPrint('[WebPush] Token saved to database');
    } catch (e) {
      debugPrint('[WebPush] Error saving token: $e');
    }
  }

  @override
  Future<void> removeToken() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || _currentToken == null) return;

    try {
      await _supabase
          .from('push_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('token', _currentToken!);

      debugPrint('[WebPush] Token removed from database');
    } catch (e) {
      debugPrint('[WebPush] Error removing token: $e');
    }

    _currentToken = null;
    _isEnabled = false;
  }

  @override
  Future<void> onUserLoggedIn() async {
    if (_isEnabled && _currentToken != null) {
      await _saveTokenToDatabase(_currentToken!);
    } else if (_getNotificationPermission() == 'granted') {
      await _refreshToken();
    }
  }

  @override
  Future<void> onUserLoggedOut() async {
    await removeToken();
  }

  @override
  Future<void> sendTestNotification() async {
    try {
      final registration = await web.window.navigator.serviceWorker.ready.toDart;
      final active = registration.active;
      if (active != null) {
        active.postMessage({'type': 'TEST_NOTIFICATION'}.jsify());
        debugPrint('[WebPush] Test notification sent to SW');
      }
    } catch (e) {
      debugPrint('[WebPush] Error sending test notification: $e');
    }
  }

  @override
  void dispose() {
    _notificationController.close();
  }
}

/// Factory funkce pro vytvoření instance
WebPushService createWebPushService() => WebPushServiceImpl();

// =============================================================================
// JS Interop pomocné funkce
// =============================================================================

@JS('JSON.stringify')
external String? _jsonStringifyJS(JSAny? obj);

String? _jsonStringify(JSAny? obj) {
  try {
    return _jsonStringifyJS(obj);
  } catch (e) {
    return null;
  }
}

@JS('Notification.permission')
external String? get _notificationPermissionJS;

String? _getNotificationPermissionJS() => _notificationPermissionJS;

@JS('requestNotificationPermission')
external JSPromise<JSString?> _requestNotificationPermissionJSRaw();

Future<String?> _requestNotificationPermissionJS() async {
  try {
    final result = await _requestNotificationPermissionJSRaw().toDart;
    return result?.toDart;
  } catch (e) {
    return null;
  }
}

@JS('getFCMToken')
external JSPromise<JSString?> _getFCMTokenJSRaw(String vapidKey);

Future<String?> _getFCMTokenJS(String vapidKey) async {
  try {
    final result = await _getFCMTokenJSRaw(vapidKey).toDart;
    return result?.toDart;
  } catch (e) {
    return null;
  }
}

@JS('Notification')
external JSAny? get _notificationClass;

bool _hasNotificationSupport() => _notificationClass != null;

@JS('PushManager')
external JSAny? get _pushManagerClass;

bool _hasPushManagerSupport() => _pushManagerClass != null;

@JS('navigator.standalone')
external JSBoolean? get _navigatorStandalone;

bool _getNavigatorStandalone(web.Navigator navigator) {
  // Pokus získat navigator.standalone pro iOS
  try {
    final standalone = _navigatorStandalone;
    if (standalone != null) {
      return standalone.toDart;
    }
  } catch (e) {
    // Ignoruj - property neexistuje
  }
  return false;
}
