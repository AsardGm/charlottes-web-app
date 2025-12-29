import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

/// Web implementace push notifikací pomocí FCM
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

  Future<void> initialize() async {
    _listenToForegroundMessages();
    debugPrint('[PushNotification] Web initialized');
  }

  Future<String> checkPermission() async {
    return web.Notification.permission;
  }

  Future<bool> requestPermission() async {
    try {
      final jsResult = web.Notification.requestPermission();
      final result = await jsResult.toDart;
      return result.toDart == 'granted';
    } catch (e) {
      debugPrint('[PushNotification] Permission error: $e');
      return false;
    }
  }

  Future<bool> subscribe() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final token = await _getFCMToken();
      if (token == null || token.isEmpty) return false;

      await _supabase.from('push_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': 'web',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,platform');

      debugPrint('[PushNotification] Subscribed');
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
      await _supabase
          .from('push_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('platform', 'web');
    } catch (e) {
      debugPrint('[PushNotification] Unsubscribe error: $e');
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? tag,
  }) async {
    if (web.Notification.permission != 'granted') return;

    web.Notification(
      title,
      web.NotificationOptions(
        body: body,
        icon: '/icons/Icon-192.png',
        tag: tag ?? 'local',
      ),
    );
  }

  void _listenToForegroundMessages() {
    web.window.addEventListener(
      'fcm-message',
      _onFcmMessage.toJS,
    );
  }

  void _onFcmMessage(web.Event event) {
    try {
      final customEvent = event as web.CustomEvent;
      final detail = customEvent.detail;
      if (detail != null) {
        _messageController?.add({
          'title': '',
          'body': '',
          'data': {},
        });
      }
    } catch (e) {
      debugPrint('[PushNotification] Message error: $e');
    }
  }

  Future<String?> _getFCMToken() async {
    try {
      final result = await _jsGetFCMToken(vapidKey.toJS).toDart;
      return result?.toDart;
    } catch (e) {
      debugPrint('[PushNotification] Token error: $e');
      return null;
    }
  }

  void dispose() {
    _messageController?.close();
  }
}

@JS('getFCMToken')
external JSPromise<JSString?> _jsGetFCMToken(JSString vapidKey);
