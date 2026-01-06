import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// Service pro spravu blokovani uzivatelu
class BlockService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Aktualni ID uzivatele
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Zablokuje uzivatele
  Future<void> blockUser(String userId) async {
    if (currentUserId == null) return;
    if (currentUserId == userId) return;

    try {
      await _supabase.from('blocked_users').insert({
        'blocker_id': currentUserId,
        'blocked_id': userId,
      });
      debugPrint('User $userId blocked');
    } catch (e) {
      debugPrint('blockUser error: $e');
      rethrow;
    }
  }

  /// Odblokuje uzivatele
  Future<void> unblockUser(String userId) async {
    if (currentUserId == null) return;

    try {
      await _supabase
          .from('blocked_users')
          .delete()
          .eq('blocker_id', currentUserId!)
          .eq('blocked_id', userId);
      debugPrint('User $userId unblocked');
    } catch (e) {
      debugPrint('unblockUser error: $e');
      rethrow;
    }
  }

  /// Zkontroluje, jestli je uzivatel zablokovany mnou
  Future<bool> isBlocked(String userId) async {
    if (currentUserId == null) return false;
    if (currentUserId == userId) return false;

    try {
      final response = await _supabase
          .from('blocked_users')
          .select('id')
          .eq('blocker_id', currentUserId!)
          .eq('blocked_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('isBlocked error: $e');
      return false;
    }
  }

  /// Zkontroluje, jestli me uzivatel zablokoval
  Future<bool> isBlockedByUser(String userId) async {
    if (currentUserId == null) return false;
    if (currentUserId == userId) return false;

    try {
      final response = await _supabase
          .from('blocked_users')
          .select('id')
          .eq('blocker_id', userId)
          .eq('blocked_id', currentUserId!)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('isBlockedByUser error: $e');
      return false;
    }
  }

  /// Zkontroluje vzajemne blokovani (at uz on me nebo ja jeho)
  Future<bool> isMutuallyBlocked(String userId) async {
    if (currentUserId == null) return false;
    if (currentUserId == userId) return false;

    final blocked = await isBlocked(userId);
    if (blocked) return true;

    final blockedBy = await isBlockedByUser(userId);
    return blockedBy;
  }

  /// Prepne stav blokovani
  Future<bool> toggleBlock(String userId) async {
    final blocked = await isBlocked(userId);

    if (blocked) {
      await unblockUser(userId);
      return false;
    } else {
      await blockUser(userId);
      return true;
    }
  }

  /// Ziska seznam zablokovaných uzivatelu
  Future<List<UserModel>> getBlockedUsers() async {
    if (currentUserId == null) return [];

    try {
      final response = await _supabase
          .from('blocked_users')
          .select('blocked:profiles!blocked_users_blocked_id_fkey(*)')
          .eq('blocker_id', currentUserId!)
          .order('created_at', ascending: false);

      return (response as List).map((r) {
        final blocked = r['blocked'] as Map<String, dynamic>;
        return UserModel.fromJson(blocked);
      }).toList();
    } catch (e) {
      debugPrint('getBlockedUsers error: $e');
      return [];
    }
  }

  /// Ziska pocet zablokovaných uzivatelu
  Future<int> getBlockedUsersCount() async {
    if (currentUserId == null) return 0;

    try {
      final response = await _supabase
          .from('blocked_users')
          .select('id')
          .eq('blocker_id', currentUserId!);

      return (response as List).length;
    } catch (e) {
      debugPrint('getBlockedUsersCount error: $e');
      return 0;
    }
  }

  /// Ziska seznam ID zablokovaných uzivatelu (pro filtrovani)
  Future<List<String>> getBlockedUserIds() async {
    if (currentUserId == null) return [];

    try {
      final response = await _supabase
          .from('blocked_users')
          .select('blocked_id')
          .eq('blocker_id', currentUserId!);

      return (response as List)
          .map((r) => r['blocked_id'] as String)
          .toList();
    } catch (e) {
      debugPrint('getBlockedUserIds error: $e');
      return [];
    }
  }

  /// Ziska seznam ID uzivatelu, kteri me zablokovali (pro filtrovani)
  Future<List<String>> getBlockedByUserIds() async {
    if (currentUserId == null) return [];

    try {
      final response = await _supabase
          .from('blocked_users')
          .select('blocker_id')
          .eq('blocked_id', currentUserId!);

      return (response as List)
          .map((r) => r['blocker_id'] as String)
          .toList();
    } catch (e) {
      debugPrint('getBlockedByUserIds error: $e');
      return [];
    }
  }

  /// Ziska vsechna blokovana ID (obousmerne) pro filtrovani
  Future<Set<String>> getAllBlockedIds() async {
    final blocked = await getBlockedUserIds();
    final blockedBy = await getBlockedByUserIds();

    return {...blocked, ...blockedBy};
  }
}
