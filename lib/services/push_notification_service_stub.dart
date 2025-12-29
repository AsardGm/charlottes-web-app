import 'dart:async';
import 'package:flutter/foundation.dart';

/// Stub implementace pro non-web platformy (iOS, Android)
/// Tyto platformy používají firebase_messaging package
class PushNotificationServiceImpl {
  static PushNotificationServiceImpl? _instance;
  static PushNotificationServiceImpl get instance =>
      _instance ??= PushNotificationServiceImpl._();

  PushNotificationServiceImpl._();

  StreamController<Map<String, dynamic>>? _messageController;

  Stream<Map<String, dynamic>> get onMessage {
    _messageController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _messageController!.stream;
  }

  Future<void> initialize() async {
    debugPrint('[PushNotification] Stub - use firebase_messaging for mobile');
  }

  Future<String> checkPermission() async {
    return 'unsupported';
  }

  Future<bool> requestPermission() async {
    return false;
  }

  Future<bool> subscribe() async {
    return false;
  }

  Future<void> unsubscribe() async {}

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? tag,
  }) async {}

  void dispose() {
    _messageController?.close();
  }
}
