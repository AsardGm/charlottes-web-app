import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<UserModel>> getAllUsers() async {
    final response = await _supabase
        .from('profiles')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> blockUser(String userId) async {
    await _supabase
        .from('profiles')
        .update({'is_blocked': true})
        .eq('id', userId);
  }

  Future<void> unblockUser(String userId) async {
    await _supabase
        .from('profiles')
        .update({'is_blocked': false})
        .eq('id', userId);
  }

  Future<void> setUserRole(String userId, String role) async {
    await _supabase
        .from('profiles')
        .update({'role': role})
        .eq('id', userId);
  }

  Future<void> makeAdmin(String userId) async {
    await setUserRole(userId, 'admin');
  }

  Future<void> makeMember(String userId) async {
    await setUserRole(userId, 'member');
  }

  Future<List<PostModel>> getAllPosts({int limit = 50, int offset = 0}) async {
    final response = await _supabase
        .from('posts')
        .select('''
          *,
          profiles(*),
          comments(*, profiles(*)),
          reactions(*)
        ''')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> deletePost(String postId) async {
    // Delete related comments and reactions first
    await _supabase.from('comments').delete().eq('post_id', postId);
    await _supabase.from('reactions').delete().eq('post_id', postId);
    await _supabase.from('posts').delete().eq('id', postId);
  }

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
