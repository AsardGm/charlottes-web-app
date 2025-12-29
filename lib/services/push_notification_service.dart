import 'dart:async';

// Podmíněný import - web vs stub
import 'push_notification_service_stub.dart'
    if (dart.library.html) 'push_notification_service_web.dart';

/// Služba pro push notifikace
///
/// Na webu používá FCM Web Push API.
/// Na mobilních platformách je to stub - pro plnou podporu
/// přidejte firebase_messaging package.
class PushNotificationService {
  static PushNotificationService? _instance;
  static PushNotificationService get instance =>
      _instance ??= PushNotificationService._();

  PushNotificationService._();

  final _impl = PushNotificationServiceImpl.instance;

  /// VAPID klíč pro reference
  static const String vapidKey =
      'BL7gIwdMNx4w-GwOYnFBPNDtJ1J93qvncLHoyyuWnAby1nvqz6ll6RfrPYF8SApGU-qFQiTVco_2KDiaH0ijUsA';

  /// Stream příchozích zpráv
  Stream<Map<String, dynamic>> get onMessage => _impl.onMessage;

  /// Inicializace
  Future<void> initialize() => _impl.initialize();

  /// Kontrola povolení
  Future<String> checkPermission() => _impl.checkPermission();

  /// Žádost o povolení
  Future<bool> requestPermission() => _impl.requestPermission();

  /// Přihlášení k notifikacím
  Future<bool> subscribe() => _impl.subscribe();

  /// Odhlášení
  Future<void> unsubscribe() => _impl.unsubscribe();

  /// Zobrazení lokální notifikace
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? tag,
    Map<String, dynamic>? data,
  }) =>
      _impl.showLocalNotification(title: title, body: body, tag: tag);

  void dispose() => _impl.dispose();
}
