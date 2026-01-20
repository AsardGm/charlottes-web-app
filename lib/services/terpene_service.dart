import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/terpene_model.dart';

/// Služba pro práci s terpeny a komunitními zkušenostmi
class TerpeneService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Načte všechny terpeny
  Future<List<TerpeneModel>> getTerpenes() async {
    final response = await _supabase
        .from('terpenes')
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((json) => TerpeneModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Načte terpen podle slug
  Future<TerpeneModel?> getTerpeneBySlug(String slug) async {
    try {
      final response = await _supabase
          .from('terpenes')
          .select()
          .eq('slug', slug)
          .maybeSingle();

      if (response == null) return null;
      return TerpeneModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Načte zkušenosti pro terpen
  Future<List<TerpeneExperienceModel>> getExperiences(
    String terpeneId, {
    int limit = 20,
    String orderBy = 'helpful_count',
  }) async {
    final response = await _supabase
        .from('terpene_experiences')
        .select('*, profiles(username, avatar_url)')
        .eq('terpene_id', terpeneId)
        .order(orderBy, ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) =>
            TerpeneExperienceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Přidá zkušenost
  Future<TerpeneExperienceModel> addExperience({
    required String terpeneId,
    required String content,
    required int rating,
    List<String> tags = const [],
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Pro přidání zkušenosti musíte být přihlášeni');
    }

    final response = await _supabase
        .from('terpene_experiences')
        .insert({
          'terpene_id': terpeneId,
          'user_id': userId,
          'content': content,
          'rating': rating,
          'tags': tags,
        })
        .select('*, profiles(username, avatar_url)')
        .single();

    return TerpeneExperienceModel.fromJson(response);
  }

  /// Smaže zkušenost
  Future<void> deleteExperience(String experienceId) async {
    await _supabase
        .from('terpene_experiences')
        .delete()
        .eq('id', experienceId);
  }

  /// Hlasuje pro užitečnost zkušenosti
  Future<bool> voteHelpful(String experienceId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // Zkus přidat hlas
      await _supabase.from('terpene_experience_votes').insert({
        'experience_id': experienceId,
        'user_id': userId,
      });

      // Zvyš počítadlo
      await _supabase.rpc('increment_helpful_count', params: {
        'exp_id': experienceId,
      });

      return true;
    } catch (_) {
      // Už hlasoval - odeber hlas
      await _supabase
          .from('terpene_experience_votes')
          .delete()
          .eq('experience_id', experienceId)
          .eq('user_id', userId);

      // Sniž počítadlo
      await _supabase.rpc('decrement_helpful_count', params: {
        'exp_id': experienceId,
      });

      return false;
    }
  }

  /// Zkontroluje zda uživatel už hlasoval
  Future<bool> hasVoted(String experienceId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _supabase
        .from('terpene_experience_votes')
        .select('id')
        .eq('experience_id', experienceId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }

  /// Průměrné hodnocení terpenu
  Future<double> getAverageRating(String terpeneId) async {
    final response = await _supabase
        .from('terpene_experiences')
        .select('rating')
        .eq('terpene_id', terpeneId);

    if ((response as List).isEmpty) return 0;

    final ratings = response.map((e) => e['rating'] as int).toList();
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  /// Počet zkušeností pro terpen
  Future<int> getExperienceCount(String terpeneId) async {
    final response = await _supabase
        .from('terpene_experiences')
        .select('id')
        .eq('terpene_id', terpeneId);

    return (response as List).length;
  }
}
