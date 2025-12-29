import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

/// Služba pro vyhledávání
///
/// Umožňuje vyhledávat příspěvky a uživatele v databázi.
class SearchService {
  /// Supabase klient
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Vyhledá příspěvky podle obsahu
  ///
  /// Hledá v textu příspěvků pomocí ILIKE (case-insensitive).
  Future<List<PostModel>> searchPosts(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (query.isEmpty) return [];

    final response = await _supabase
        .from('posts')
        .select('''
          *,
          profiles!posts_author_id_fkey(*),
          thread_types(*),
          categories(*),
          reactions(*)
        ''')
        .ilike('content', '%$query%')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((p) => PostModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// Vyhledá uživatele podle jména nebo bio
  ///
  /// Hledá v uživatelském jméně a popisu profilu.
  Future<List<UserModel>> searchUsers(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (query.isEmpty) return [];

    try {
      debugPrint('Searching users for: $query');

      // Hledani podle username
      final response = await _supabase
          .from('profiles')
          .select()
          .ilike('username', '%$query%')
          .order('created_at', ascending: false)
          .limit(limit);

      debugPrint('Search response: $response');
      debugPrint('Response type: ${response.runtimeType}');
      debugPrint('Response length: ${(response as List).length}');

      final users = response
          .map((u) => UserModel.fromJson(u))
          .toList();

      // Pokud nenajdeme podle username, zkus bio
      if (users.isEmpty) {
        final bioResponse = await _supabase
            .from('profiles')
            .select()
            .ilike('bio', '%$query%')
            .order('created_at', ascending: false)
            .limit(limit);

        return (bioResponse as List)
            .map((u) => UserModel.fromJson(u as Map<String, dynamic>))
            .toList();
      }

      return users;
    } catch (e) {
      debugPrint('Search users error: $e');
      return [];
    }
  }

  /// Kombinované vyhledávání příspěvků i uživatelů
  ///
  /// Spustí obě vyhledávání paralelně pro lepší výkon.
  Future<SearchResults> search(String query, {int limit = 10}) async {
    if (query.isEmpty) {
      return SearchResults(posts: [], users: []);
    }

    // Paralelní vyhledávání
    final results = await Future.wait([
      searchPosts(query, limit: limit),
      searchUsers(query, limit: limit),
    ]);

    return SearchResults(
      posts: results[0] as List<PostModel>,
      users: results[1] as List<UserModel>,
    );
  }
}

/// Výsledky vyhledávání
///
/// Obsahuje nalezené příspěvky a uživatele.
class SearchResults {
  /// Nalezené příspěvky
  final List<PostModel> posts;

  /// Nalezení uživatelé
  final List<UserModel> users;

  SearchResults({
    required this.posts,
    required this.users,
  });

  /// Jsou výsledky prázdné?
  bool get isEmpty => posts.isEmpty && users.isEmpty;

  /// Celkový počet výsledků
  int get totalCount => posts.length + users.length;
}
