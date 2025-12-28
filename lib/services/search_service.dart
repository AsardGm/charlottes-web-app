import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class SearchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Vyhledá příspěvky
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
          profiles(*),
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

  /// Vyhledá uživatele
  Future<List<UserModel>> searchUsers(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (query.isEmpty) return [];

    final response = await _supabase
        .from('profiles')
        .select()
        .or('username.ilike.%$query%,bio.ilike.%$query%')
        .order('username')
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((u) => UserModel.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  /// Kombinované vyhledávání
  Future<SearchResults> search(String query, {int limit = 10}) async {
    if (query.isEmpty) {
      return SearchResults(posts: [], users: []);
    }

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

class SearchResults {
  final List<PostModel> posts;
  final List<UserModel> users;

  SearchResults({
    required this.posts,
    required this.users,
  });

  bool get isEmpty => posts.isEmpty && users.isEmpty;
  int get totalCount => posts.length + users.length;
}
