import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';
import 'push_sender_service.dart';

/// Služba pro práci s komentáři
///
/// Zajišťuje CRUD operace pro komentáře k příspěvkům.
class CommentService {
  /// Supabase klient
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Push sender pro notifikace
  final PushSenderService _pushSender = PushSenderService.instance;

  /// Načte komentáře k příspěvku
  ///
  /// Vrací seznam komentářů seřazený od nejstaršího.
  Future<List<CommentModel>> getComments(String postId) async {
    final response = await _supabase
        .from('comments')
        .select('*, profiles!comments_author_id_fkey(*)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Přidá nový komentář
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
        .select('*, profiles!comments_author_id_fkey(*)')
        .single();

    final comment = CommentModel.fromJson(response);

    // Posli push notifikaci autorovi prispevku
    _sendCommentNotification(postId, comment.id, content);

    return comment;
  }

  /// Odesle push notifikaci autorovi prispevku o novem komentari
  Future<void> _sendCommentNotification(
    String postId,
    String commentId,
    String commentContent,
  ) async {
    try {
      final post = await _supabase
          .from('posts')
          .select('author_id, content')
          .eq('id', postId)
          .single();

      final authorId = post['author_id'] as String?;
      final postContent = post['content'] as String? ?? '';

      if (authorId != null) {
        await _pushSender.sendCommentNotification(
          postAuthorId: authorId,
          postId: postId,
          postContent: postContent,
          commentContent: commentContent,
          commentId: commentId,
        );
      }
    } catch (e) {
      // Ignoruj chyby - push neni kriticky
    }
  }

  /// Smaže komentář
  Future<void> deleteComment(String id) async {
    await _supabase.from('comments').delete().eq('id', id);
  }

  /// Real-time stream komentářů pro příspěvek
  Stream<List<Map<String, dynamic>>> commentsStream(String postId) {
    return _supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at', ascending: true);
  }
}
