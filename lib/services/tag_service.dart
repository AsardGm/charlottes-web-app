import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tag_model.dart';

class TagService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Získá populární tagy
  Future<List<TagModel>> getPopularTags({int limit = 20}) async {
    final response = await _supabase
        .from('tags')
        .select()
        .order('post_count', ascending: false)
        .limit(limit);

    return (response as List)
        .map((t) => TagModel.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  /// Vyhledá tagy podle názvu
  Future<List<TagModel>> searchTags(String query, {int limit = 10}) async {
    if (query.isEmpty) return [];

    final response = await _supabase
        .from('tags')
        .select()
        .ilike('name', '%$query%')
        .order('post_count', ascending: false)
        .limit(limit);

    return (response as List)
        .map((t) => TagModel.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  /// Získá tagy příspěvku
  Future<List<TagModel>> getPostTags(String postId) async {
    final response = await _supabase
        .from('post_tags')
        .select('*, tags(*)')
        .eq('post_id', postId);

    return (response as List)
        .where((pt) => pt['tags'] != null)
        .map((pt) => TagModel.fromJson(pt['tags'] as Map<String, dynamic>))
        .toList();
  }

  /// Přidá tag k příspěvku (vytvoří tag pokud neexistuje)
  Future<void> addTagToPost(String postId, String tagName) async {
    // Použij RPC funkci pro získání nebo vytvoření tagu
    final tagId = await _supabase.rpc(
      'get_or_create_tag',
      params: {'tag_name': tagName},
    );

    // Přidej vazbu
    await _supabase.from('post_tags').insert({
      'post_id': postId,
      'tag_id': tagId,
    });
  }

  /// Odebere tag z příspěvku
  Future<void> removeTagFromPost(String postId, String tagId) async {
    await _supabase
        .from('post_tags')
        .delete()
        .eq('post_id', postId)
        .eq('tag_id', tagId);
  }

  /// Získá příspěvky s daným tagem
  Future<List<String>> getPostIdsByTag(String tagId, {int limit = 50}) async {
    final response = await _supabase
        .from('post_tags')
        .select('post_id')
        .eq('tag_id', tagId)
        .limit(limit);

    return (response as List)
        .map((pt) => pt['post_id'] as String)
        .toList();
  }

  /// Získá tag podle slug
  Future<TagModel?> getTagBySlug(String slug) async {
    final response = await _supabase
        .from('tags')
        .select()
        .eq('slug', slug)
        .maybeSingle();

    if (response == null) return null;
    return TagModel.fromJson(response);
  }
}
