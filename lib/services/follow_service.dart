import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/follow_request_model.dart';
import 'push_sender_service.dart';

/// Stav sledování uživatele
enum FollowStatus {
  /// Nesleduji
  notFollowing,
  /// Sleduji
  following,
  /// Žádost odeslaná (čeká na schválení)
  requested,
}

/// Služba pro správu sledování uživatelů
///
/// Umožňuje sledovat/přestat sledovat uživatele,
/// odesílat žádosti o sledování pro soukromé účty
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

  // ==================== FOLLOW REQUESTS ====================

  /// Získá stav sledování uživatele (following, requested, not_following)
  Future<FollowStatus> getFollowStatus(String userId) async {
    if (currentUserId == null) return FollowStatus.notFollowing;
    if (currentUserId == userId) return FollowStatus.notFollowing;

    // Nejdřív zkontroluj, jestli už sledujeme
    final isFollowingUser = await isFollowing(userId);
    if (isFollowingUser) return FollowStatus.following;

    // Zkontroluj, jestli existuje pending žádost
    try {
      final response = await _supabase
          .from('follow_requests')
          .select('id, status')
          .eq('requester_id', currentUserId!)
          .eq('target_id', userId)
          .eq('status', 'pending')
          .maybeSingle();

      if (response != null) return FollowStatus.requested;
    } catch (e) {
      debugPrint('getFollowStatus error: $e');
    }

    return FollowStatus.notFollowing;
  }

  /// Odešle žádost o sledování (pro soukromé účty)
  Future<void> sendFollowRequest(String userId) async {
    if (currentUserId == null) return;
    if (currentUserId == userId) return;

    try {
      debugPrint('Sending follow request to: $userId');

      // Smaž případnou starou rejected žádost
      await _supabase
          .from('follow_requests')
          .delete()
          .eq('requester_id', currentUserId!)
          .eq('target_id', userId)
          .eq('status', 'rejected');

      // Vytvoř novou žádost
      await _supabase.from('follow_requests').upsert({
        'requester_id': currentUserId,
        'target_id': userId,
        'status': 'pending',
      });

      debugPrint('Follow request sent');

      // Pošli notifikaci
      _pushSender.sendFollowRequestNotification(targetUserId: userId);
    } catch (e) {
      debugPrint('sendFollowRequest error: $e');
      rethrow;
    }
  }

  /// Zruší odeslanou žádost o sledování
  Future<void> cancelFollowRequest(String userId) async {
    if (currentUserId == null) return;

    await _supabase
        .from('follow_requests')
        .delete()
        .eq('requester_id', currentUserId!)
        .eq('target_id', userId);
  }

  /// Přijme žádost o sledování
  Future<void> acceptFollowRequest(String requesterId) async {
    if (currentUserId == null) return;

    await _supabase
        .from('follow_requests')
        .update({'status': 'accepted'})
        .eq('requester_id', requesterId)
        .eq('target_id', currentUserId!)
        .eq('status', 'pending');

    // Notifikace žadateli
    _pushSender.sendFollowRequestAcceptedNotification(requesterId: requesterId);
  }

  /// Odmítne žádost o sledování
  Future<void> rejectFollowRequest(String requesterId) async {
    if (currentUserId == null) return;

    await _supabase
        .from('follow_requests')
        .update({'status': 'rejected'})
        .eq('requester_id', requesterId)
        .eq('target_id', currentUserId!)
        .eq('status', 'pending');
  }

  /// Získá seznam čekajících žádostí (pro aktuálního uživatele)
  Future<List<FollowRequestModel>> getPendingRequests() async {
    if (currentUserId == null) return [];

    try {
      final response = await _supabase
          .from('follow_requests')
          .select('*, requester:profiles!follow_requests_requester_id_fkey(*)')
          .eq('target_id', currentUserId!)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((r) => FollowRequestModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getPendingRequests error: $e');
      return [];
    }
  }

  /// Počet čekajících žádostí
  Future<int> getPendingRequestsCount() async {
    if (currentUserId == null) return 0;

    try {
      final response = await _supabase
          .from('follow_requests')
          .select('id')
          .eq('target_id', currentUserId!)
          .eq('status', 'pending');

      return (response as List).length;
    } catch (e) {
      debugPrint('getPendingRequestsCount error: $e');
      return 0;
    }
  }

  /// Zkontroluje, jestli je uživatel soukromý
  Future<bool> isUserPrivate(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('is_private')
          .eq('id', userId)
          .maybeSingle();

      return response?['is_private'] as bool? ?? false;
    } catch (e) {
      debugPrint('isUserPrivate error: $e');
      return false;
    }
  }

  /// Sleduj nebo pošli žádost (podle toho, jestli je účet soukromý)
  Future<FollowStatus> followOrRequest(String userId) async {
    if (currentUserId == null) return FollowStatus.notFollowing;

    final isPrivate = await isUserPrivate(userId);

    if (isPrivate) {
      await sendFollowRequest(userId);
      return FollowStatus.requested;
    } else {
      await follow(userId);
      return FollowStatus.following;
    }
  }

  /// Přepne stav sledování s podporou soukromých účtů
  Future<FollowStatus> toggleFollowOrRequest(String userId) async {
    final currentStatus = await getFollowStatus(userId);

    switch (currentStatus) {
      case FollowStatus.following:
        await unfollow(userId);
        return FollowStatus.notFollowing;
      case FollowStatus.requested:
        await cancelFollowRequest(userId);
        return FollowStatus.notFollowing;
      case FollowStatus.notFollowing:
        return await followOrRequest(userId);
    }
  }
}
