import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

/// Služba pro správu notifikací
///
/// Zajišťuje načítání, označování jako přečtené a mazání notifikací.
/// Podporuje real-time aktualizace.
class NotificationService {
  /// Supabase klient
  final SupabaseClient _supabase = Supabase.instance.client;

  /// ID aktuálního uživatele
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Získá všechny notifikace uživatele
  ///
  /// [limit] - počet notifikací na stránku
  /// [offset] - počet přeskočených (pro stránkování)
  /// [unreadOnly] - pouze nepřečtené
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    if (currentUserId == null) return [];

    final baseQuery = _supabase
        .from('notifications')
        .select('*, profiles!notifications_actor_id_fkey(*)');

    final filteredQuery = unreadOnly
        ? baseQuery.eq('user_id', currentUserId!).eq('is_read', false)
        : baseQuery.eq('user_id', currentUserId!);

    final response = await filteredQuery
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  /// Počet nepřečtených notifikací
  Future<int> getUnreadCount() async {
    if (currentUserId == null) return 0;

    final response = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', currentUserId!)
        .eq('is_read', false);

    return (response as List).length;
  }

  /// Označí notifikaci jako přečtenou
  Future<void> markAsRead(String notificationId) async {
    await _supabase.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', notificationId);
  }

  /// Označí všechny notifikace jako přečtené
  Future<void> markAllAsRead() async {
    if (currentUserId == null) return;

    await _supabase.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('user_id', currentUserId!).eq('is_read', false);
  }

  /// Smaže notifikaci
  Future<void> deleteNotification(String notificationId) async {
    await _supabase.from('notifications').delete().eq('id', notificationId);
  }

  /// Smaže všechny přečtené notifikace
  Future<void> deleteReadNotifications() async {
    if (currentUserId == null) return;

    await _supabase
        .from('notifications')
        .delete()
        .eq('user_id', currentUserId!)
        .eq('is_read', true);
  }

  /// Real-time stream notifikací
  Stream<List<Map<String, dynamic>>> notificationsStream() {
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false)
        .limit(20);
  }
}
