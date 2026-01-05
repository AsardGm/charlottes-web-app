import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

/// Služba pro administraci aplikace
///
/// Poskytuje funkce pro správu uživatelů a příspěvků,
/// přístupné pouze administrátorům.
class AdminService {
  /// Supabase klient
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Získá seznam všech uživatelů
  Future<List<UserModel>> getAllUsers() async {
    final response = await _supabase
        .from('profiles')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Vyhledá uživatele podle username (pro @mentions)
  Future<List<UserModel>> searchUsers(String query, {int limit = 10}) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .ilike('username', '%$query%')
        .eq('is_blocked', false)
        .limit(limit)
        .order('username');

    return (response as List)
        .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Zablokuje uživatele
  Future<void> blockUser(String userId) async {
    await _supabase
        .from('profiles')
        .update({'is_blocked': true})
        .eq('id', userId);
  }

  /// Odblokuje uživatele
  Future<void> unblockUser(String userId) async {
    await _supabase
        .from('profiles')
        .update({'is_blocked': false})
        .eq('id', userId);
  }

  /// Nastaví roli uživatele
  Future<void> setUserRole(String userId, String role) async {
    await _supabase
        .from('profiles')
        .update({'role': role})
        .eq('id', userId);
  }

  /// Povýší uživatele na admina
  Future<void> makeAdmin(String userId) async {
    await setUserRole(userId, 'admin');
  }

  /// Degraduje uživatele na člena
  Future<void> makeMember(String userId) async {
    await setUserRole(userId, 'member');
  }

  /// Získá seznam všech příspěvků (pro administraci)
  Future<List<PostModel>> getAllPosts({int limit = 50, int offset = 0}) async {
    final response = await _supabase
        .from('posts')
        .select('''
          *,
          profiles!posts_author_id_fkey(*),
          comments(*, profiles!comments_author_id_fkey(*)),
          reactions(*)
        ''')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Smaže příspěvek včetně souvisejících dat
  Future<void> deletePost(String postId) async {
    // Nejprve smaž komentáře a reakce
    await _supabase.from('comments').delete().eq('post_id', postId);
    await _supabase.from('reactions').delete().eq('post_id', postId);
    // Pak smaž samotný příspěvek
    await _supabase.from('posts').delete().eq('id', postId);
  }

  /// Získá statistiky aplikace
  ///
  /// Vrací počty uživatelů, příspěvků, komentářů a reakcí.
  Future<Map<String, int>> getStats() async {
    final usersResponse = await _supabase.from('profiles').select('id');
    final postsResponse = await _supabase.from('posts').select('id');
    final commentsResponse = await _supabase.from('comments').select('id');
    final reactionsResponse = await _supabase.from('reactions').select('id');

    return {
      'users': (usersResponse as List).length,
      'posts': (postsResponse as List).length,
      'comments': (commentsResponse as List).length,
      'reactions': (reactionsResponse as List).length,
    };
  }
}
