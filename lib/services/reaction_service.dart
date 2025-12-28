import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reaction_model.dart';

/// Služba pro správu reakcí na příspěvky
///
/// Umožňuje přidávat, odebírat a přepínat reakce (like, love, atd.).
class ReactionService {
  /// Supabase klient
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Získá všechny reakce na příspěvek
  Future<List<ReactionModel>> getReactions(String postId) async {
    final response = await _supabase
        .from('reactions')
        .select()
        .eq('post_id', postId);

    return (response as List)
        .map((json) => ReactionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Získá reakci aktuálního uživatele na příspěvek
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

  /// Přidá reakci na příspěvek
  ///
  /// Nejprve odstraní existující reakci (pokud existuje).
  Future<ReactionModel> addReaction({
    required String postId,
    required String type,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    // Nejprve odstraň existující reakci
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

  /// Odstraní reakci z příspěvku
  Future<void> removeReaction(String postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('reactions')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);
  }

  /// Přepne reakci na příspěvku
  ///
  /// Pokud stejná reakce existuje, odstraní ji.
  /// Pokud ne, přidá novou.
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
