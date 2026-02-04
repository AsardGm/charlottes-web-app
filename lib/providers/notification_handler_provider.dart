import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_handler_service.dart';

/// Global notification handler provider
final notificationHandlerProvider = Provider<NotificationHandlerService>((ref) {
  return NotificationHandlerService();
});
