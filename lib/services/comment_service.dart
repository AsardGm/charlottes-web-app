import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';

class CommentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<CommentModel>> getComments(String postId) async {
    final response = await _supabase
        .from('comments')
        .select('*, profiles(*)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CommentModel> addComment({
    required String postId,
    required String content,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('comments')
        .insert({
          'post_id': postId,
          'author_id': userId,
          'content': content,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('*, profiles(*)')
        .single();

    return CommentModel.fromJson(response);
  }

  Future<void> deleteComment(String id) async {
    await _supabase.from('comments').delete().eq('id', id);
  }

  Stream<List<Map<String, dynamic>>> commentsStream(String postId) {
    return _supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at', ascending: true);
  }
}
