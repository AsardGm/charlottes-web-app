import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reaction_model.dart';

class ReactionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ReactionModel>> getReactions(String postId) async {
    final response = await _supabase
        .from('reactions')
        .select()
        .eq('post_id', postId);

    return (response as List)
        .map((json) => ReactionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ReactionModel?> getUserReaction(String postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('reactions')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .single();

      return ReactionModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<ReactionModel> addReaction({
    required String postId,
    required String type,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    // Remove existing reaction first
    await removeReaction(postId);

    final response = await _supabase
        .from('reactions')
        .insert({
          'post_id': postId,
          'user_id': userId,
          'type': type,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return ReactionModel.fromJson(response);
  }

  Future<void> removeReaction(String postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('reactions')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);
  }

  Future<void> toggleReaction({
    required String postId,
    required String type,
  }) async {
    final existing = await getUserReaction(postId);

    if (existing != null && existing.type == type) {
      await removeReaction(postId);
    } else {
      await addReaction(postId: postId, type: type);
    }
  }
}
