import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';
import 'push_sender_service.dart';
import 'block_service.dart';
import 'content_moderation_service.dart';

/// Služba pro práci s komentáři
///
/// Zajišťuje CRUD operace pro komentáře k příspěvkům.
class CommentService {
  /// Supabase klient
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Push sender pro notifikace
  final PushSenderService _pushSender = PushSenderService.instance;

  /// Block service pro filtrování zablokovaných
  final BlockService _blockService = BlockService();

  /// Content moderation service pro kontrolu zakázaných slov
  final ContentModerationService _moderationService = ContentModerationService();

  /// Načte komentáře k příspěvku
  ///
  /// Vrací seznam komentářů seřazený od nejstaršího.
  /// Automaticky filtruje komentáře od zablokovaných uživatelů.
  Future<List<CommentModel>> getComments(String postId) async {
    final response = await _supabase
        .from('comments')
        .select('*, profiles!comments_author_id_fkey(*)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    // Získej seznam zablokovaných uživatelů
    final blockedIds = await _blockService.getAllBlockedIds();

    // Filtruj komentáře od zablokovaných uživatelů
    return (response as List)
        .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
        .where((comment) => !blockedIds.contains(comment.authorId))
        .toList();
  }

  /// Přidá nový komentář
  ///
  /// Před vytvořením zkontroluje obsah na zakázaná slova.
  /// Vyhodí [ContentBlockedException] pokud obsahuje zakázaný obsah.
  Future<CommentModel> addComment({
    required String postId,
    required String content,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    // Kontrola obsahu na zakázaná slova
    await _moderationService.validateContent(content);

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
