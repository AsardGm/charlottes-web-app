import 'push_notification_service_stub.dart'
    if (dart.library.js_interop) 'push_notification_service_web.dart';

/// Abstraktní rozhraní pro push notifikace
///
/// Implementace se liší podle platformy:
/// - Web/PWA: push_notification_service_web.dart
/// - Ostatní: push_notification_service_stub.dart (prázdná implementace)
abstract class WebPushService {
  /// Singleton instance
  static WebPushService? _instance;
  static WebPushService get instance =>
      _instance ??= createWebPushService();

  /// Stream pro příchozí notifikace
  Stream<Map<String, dynamic>> get onNotification;

  /// Aktuální FCM token
  String? get currentToken;

  /// Zda jsou push notifikace povoleny
  bool get isEnabled;

  /// Platforma (web, ios_pwa, android_pwa, etc.)
  String get platform;

  /// Zda je PWA nainstalovaná (standalone mode)
  bool get isStandalone;

  /// Zda platforma podporuje push notifikace
  bool get isPushSupported;

  /// Inicializace služby
  Future<void> initialize();

  /// Požádá o oprávnění pro notifikace
  Future<String> requestPermission();

  /// Registruje token po přihlášení
  Future<void> onUserLoggedIn();

  /// Odregistruje token při odhlášení
  Future<void> onUserLoggedOut();

  /// Odstraní FCM token
  Future<void> removeToken();

  /// Testovací notifikace
  Future<void> sendTestNotification();

  /// Uvolní prostředky
  void dispose();
}
