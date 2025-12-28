import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';

/// Služba pro práci s příspěvky
///
/// Zajišťuje CRUD operace pro příspěvky včetně filtrování,
/// řazení a správy stavu vláken.
class PostService {
  /// Supabase klient
  final SupabaseClient _supabase = Supabase.instance.client;

  /// SQL dotaz pro načtení příspěvku s relacemi
  static const String _selectQuery = '''
    *,
    profiles!posts_author_id_fkey(*),
    categories(*),
    thread_types(*),
    comments(*, profiles(*)),
    reactions(*)
  ''';

  /// Načte seznam příspěvků s možností filtrování
  ///
  /// [limit] - počet příspěvků na stránku
  /// [offset] - počet přeskočených příspěvků (pro stránkování)
  /// [categoryId] - filtr podle kategorie
  /// [threadTypeId] - filtr podle typu vlákna
  /// [status] - filtr podle stavu (open, resolved, locked)
  /// [hasDeadline] - pouze příspěvky s deadlinem
  /// [isOverdue] - pouze příspěvky po deadlinu
  /// [pinnedFirst] - připnuté příspěvky nahoře
  Future<List<PostModel>> getPosts({
    int limit = 20,
    int offset = 0,
    String? categoryId,
    String? threadTypeId,
    String? status,
    bool? hasDeadline,
    bool? isOverdue,
    bool pinnedFirst = true,
  }) async {
    var query = _supabase.from('posts').select(_selectQuery);

    // Aplikace filtrů
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    if (threadTypeId != null) {
      query = query.eq('thread_type_id', threadTypeId);
    }

    if (status != null) {
      query = query.eq('status', status);
    }

    if (hasDeadline == true) {
      query = query.not('deadline', 'is', null);
    }

    if (isOverdue == true) {
      query = query
          .not('deadline', 'is', null)
          .lt('deadline', DateTime.now().toIso8601String())
          .neq('status', 'resolved');
    }

    // Řazení - připnuté první, pak podle data
    final response = pinnedFirst
        ? await query
            .order('is_pinned', ascending: false)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1)
        : await query
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Načte jeden příspěvek podle ID
  ///
  /// Automaticky inkrementuje počet zobrazení.
  Future<PostModel?> getPost(String id) async {
    final response = await _supabase
        .from('posts')
        .select(_selectQuery)
        .eq('id', id)
        .single();

    // Inkrementovat počet zobrazení
    await incrementViewCount(id);

    return PostModel.fromJson(response);
  }

  /// Vytvoří nový příspěvek
  Future<PostModel> createPost({
    required String content,
    String? imageUrl,
    String? categoryId,
    String? threadTypeId,
    DateTime? deadline,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now().toIso8601String();

    final response = await _supabase
        .from('posts')
        .insert({
          'author_id': userId,
          'content': content,
          'image_url': imageUrl,
          'category_id': categoryId,
          'thread_type_id': threadTypeId,
          'deadline': deadline?.toIso8601String(),
          'created_at': now,
          'updated_at': now,
        })
        .select(_selectQuery)
        .single();

    return PostModel.fromJson(response);
  }

  /// Aktualizuje příspěvek
  Future<void> updatePost({
    required String id,
    required String content,
    String? imageUrl,
  }) async {
    await _supabase.from('posts').update({
      'content': content,
      'image_url': imageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Smaže příspěvek
  Future<void> deletePost(String id) async {
    await _supabase.from('posts').delete().eq('id', id);
  }

  /// Označí příspěvek jako vyřešený
  Future<void> resolvePost(String postId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('posts').update({
      'status': 'resolved',
      'resolved_at': DateTime.now().toIso8601String(),
      'resolved_by': userId,
    }).eq('id', postId);
  }

  /// Znovu otevře příspěvek
  Future<void> reopenPost(String postId) async {
    await _supabase.from('posts').update({
      'status': 'open',
      'resolved_at': null,
      'resolved_by': null,
    }).eq('id', postId);
  }

  /// Zamkne příspěvek (pouze admin)
  Future<void> lockPost(String postId) async {
    await _supabase.from('posts').update({
      'status': 'locked',
    }).eq('id', postId);
  }

  /// Připne/odepne příspěvek
  Future<void> togglePin(String postId, bool isPinned) async {
    await _supabase.from('posts').update({
      'is_pinned': isPinned,
    }).eq('id', postId);
  }

  /// Přijme komentář jako nejlepší odpověď
  Future<void> acceptAnswer(String postId, String commentId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('posts').update({
      'accepted_comment_id': commentId,
      'status': 'resolved',
      'resolved_at': DateTime.now().toIso8601String(),
      'resolved_by': userId,
    }).eq('id', postId);
  }

  /// Inkrementuje počet zobrazení příspěvku
  Future<void> incrementViewCount(String postId) async {
    await _supabase.rpc('increment_view_count', params: {'post_id': postId});
  }

  /// Real-time stream příspěvků
  Stream<List<Map<String, dynamic>>> postsStream() {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id']).order('created_at', ascending: false);
  }
}
