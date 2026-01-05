import 'dart:async';

import 'web_push_service.dart';

/// Stub implementace pro non-web platformy
///
/// Tato třída se používá na iOS/Android, kde push notifikace
/// řeší nativní Firebase SDK (firebase_messaging).
class WebPushServiceImpl implements WebPushService {
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get onNotification =>
      _notificationController.stream;

  @override
  String? get currentToken => null;

  @override
  bool get isEnabled => false;

  @override
  String get platform => 'native';

  @override
  bool get isStandalone => false;

  @override
  bool get isPushSupported => false;

  @override
  Future<void> initialize() async {
    // Nic - na nativních platformách používáme firebase_messaging
  }

  @override
  Future<String> requestPermission() async {
    return 'denied';
  }

  @override
  Future<void> onUserLoggedIn() async {}

  @override
  Future<void> onUserLoggedOut() async {}

  @override
  Future<void> removeToken() async {}

  @override
  Future<void> sendTestNotification() async {}

  @override
  void dispose() {
    _notificationController.close();
  }
}

/// Factory funkce pro vytvoření instance
WebPushService createWebPushService() => WebPushServiceImpl();
