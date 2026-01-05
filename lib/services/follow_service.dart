import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'push_sender_service.dart';

/// Služba pro správu sledování uživatelů
///
/// Umožňuje sledovat/přestat sledovat uživatele
/// a získat seznamy sledujících/sledovaných.
class FollowService {
  /// Supabase klient
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Push sender pro notifikace
  final PushSenderService _pushSender = PushSenderService.instance;

  /// ID aktuálního uživatele
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Získá seznam sledovaných uživatelů
  ///
  /// [userId] - ID uživatele (výchozí je aktuální uživatel)
  Future<List<UserModel>> getFollowing({
    String? userId,
    int limit = 50,
    int offset = 0,
  }) async {
    final targetUserId = userId ?? currentUserId;
    if (targetUserId == null) return [];

    final response = await _supabase
        .from('follows')
        .select('*, profiles!follows_following_id_fkey(*)')
        .eq('follower_id', targetUserId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .where((f) => f['profiles'] != null)
        .map((f) => UserModel.fromJson(f['profiles'] as Map<String, dynamic>))
        .toList();
  }

  /// Získá seznam sledujících (followers)
  ///
  /// [userId] - ID uživatele (výchozí je aktuální uživatel)
  Future<List<UserModel>> getFollowers({
    String? userId,
    int limit = 50,
    int offset = 0,
  }) async {
    final targetUserId = userId ?? currentUserId;
    if (targetUserId == null) return [];

    final response = await _supabase
        .from('follows')
        .select('*, profiles!follows_follower_id_fkey(*)')
        .eq('following_id', targetUserId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .where((f) => f['profiles'] != null)
        .map((f) => UserModel.fromJson(f['profiles'] as Map<String, dynamic>))
        .toList();
  }

  /// Zkontroluje zda sledujeme uživatele
  Future<bool> isFollowing(String userId) async {
    if (currentUserId == null) return false;

    try {
      final response = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', currentUserId!)
          .eq('following_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('isFollowing error: $e');
      return false;
    }
  }

  /// Začne sledovat uživatele
  Future<void> follow(String userId) async {
    if (currentUserId == null) return;
    if (currentUserId == userId) return; // Nemůžeme sledovat sami sebe

    try {
      debugPrint('Following user: $userId');
      await _supabase.from('follows').insert({
        'follower_id': currentUserId,
        'following_id': userId,
      });
      debugPrint('Follow successful');

      // Posli push notifikaci sledovanemu uzivateli
      _pushSender.sendFollowNotification(followedUserId: userId);
    } catch (e) {
      debugPrint('Follow error: $e');
      rethrow;
    }
  }

  /// Přestane sledovat uživatele
  Future<void> unfollow(String userId) async {
    if (currentUserId == null) return;

    await _supabase
        .from('follows')
        .delete()
        .eq('follower_id', currentUserId!)
        .eq('following_id', userId);
  }

  /// Přepne stav sledování (sleduje/nesleduje)
  ///
  /// Vrací nový stav (true = sleduje, false = nesleduje).
  Future<bool> toggleFollow(String userId) async {
    final isCurrentlyFollowing = await isFollowing(userId);

    if (isCurrentlyFollowing) {
      await unfollow(userId);
      return false;
    } else {
      await follow(userId);
      return true;
    }
  }

  /// Počet sledovaných uživatelů
  Future<int> getFollowingCount({String? userId}) async {
    final targetUserId = userId ?? currentUserId;
    if (targetUserId == null) return 0;

    final response = await _supabase
        .from('follows')
        .select('id')
        .eq('follower_id', targetUserId);

    return (response as List).length;
  }

  /// Počet sledujících (followers)
  Future<int> getFollowersCount({String? userId}) async {
    final targetUserId = userId ?? currentUserId;
    if (targetUserId == null) return 0;

    final response = await _supabase
        .from('follows')
        .select('id')
        .eq('following_id', targetUserId);

    return (response as List).length;
  }
}
