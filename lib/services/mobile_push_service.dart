import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.notification?.title}');
}

/// Mobile push notification service for iOS and Android
class MobilePushService {
  static MobilePushService? _instance;
  static MobilePushService get instance => _instance ??= MobilePushService._();

  MobilePushService._();

  FirebaseMessaging? _messaging;
  String? _fcmToken;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Navigation callback - set by app to handle deep links
  static void Function(String route)? onNavigate;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      _messaging = FirebaseMessaging.instance;

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Initialize local notifications for foreground display
      await _initLocalNotifications();

      // Handle foreground messages
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check for initial message (app opened from terminated state)
      final initialMessage = await _messaging?.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      debugPrint('MobilePushService initialized');
    } catch (e) {
      debugPrint('Failed to initialize MobilePushService: $e');
    }
  }

  /// Initialize flutter_local_notifications for foreground display
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          _navigateToRoute(payload);
        }
      },
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'default_channel',
              'Notifikace',
              description: 'Hlavni kanal notifikaci',
              importance: Importance.high,
            ),
          );
    }
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    if (_messaging == null) return false;

    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                      settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint('Push permission: ${settings.authorizationStatus}');
      return granted;
    } catch (e) {
      debugPrint('Failed to request push permission: $e');
      return false;
    }
  }

  /// Get FCM token
  Future<String?> getToken() async {
    if (_messaging == null) return null;

    try {
      _fcmToken = await _messaging!.getToken();
      debugPrint('FCM Token: $_fcmToken');
      return _fcmToken;
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Called when user logs in - request permission and save token
  Future<void> onUserLoggedIn(String userId) async {
    final granted = await requestPermission();
    if (!granted) {
      debugPrint('Push notifications not granted');
      return;
    }

    final token = await getToken();
    if (token != null) {
      await _saveTokenToSupabase(userId, token);
    }

    // Listen for token refresh
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging?.onTokenRefresh.listen((newToken) {
      _saveTokenToSupabase(userId, newToken);
    });
  }

  /// Called when user logs out - remove token
  Future<void> onUserLoggedOut(String userId) async {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _removeTokenFromSupabase(userId);
  }

  /// Save FCM token to Supabase
  Future<void> _saveTokenToSupabase(String userId, String token) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';

      await Supabase.instance.client
          .from('push_tokens')
          .upsert({
            'user_id': userId,
            'token': token,
            'platform': platform,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,platform');

      debugPrint('FCM token saved to Supabase');
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  /// Remove FCM token from Supabase
  Future<void> _removeTokenFromSupabase(String userId) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';

      await Supabase.instance.client
          .from('push_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('platform', platform);

      debugPrint('FCM token removed from Supabase');
    } catch (e) {
      debugPrint('Failed to remove FCM token: $e');
    }
  }

  /// Handle foreground message - show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Build navigation route from message data
    final route = _buildRouteFromData(message.data);

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'default_channel',
          'Notifikace',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: route,
    );
  }

  /// Handle notification tap - navigate to appropriate screen
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    final route = _buildRouteFromData(message.data);
    _navigateToRoute(route);
  }

  /// Build route from notification data payload
  String _buildRouteFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final id = data['id'] as String?;

    switch (type) {
      case 'chat':
      case 'message':
        return '/chat/$id';
      case 'post':
        return '/post/$id';
      case 'profile':
        return '/user/$id';
      case 'challenge':
        return '/challenge/$id';
      default:
        return '/notifications';
    }
  }

  /// Navigate to a route
  void _navigateToRoute(String route) {
    if (onNavigate != null) {
      onNavigate!(route);
    } else {
      debugPrint('Navigation callback not set, route: $route');
    }
  }

  /// Dispose resources
  void dispose() {
    _foregroundSubscription?.cancel();
    _messageOpenedSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
  }
}
