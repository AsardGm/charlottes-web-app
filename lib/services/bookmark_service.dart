import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';

class BookmarkService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Získá všechny bookmarky uživatele
  Future<List<PostModel>> getBookmarks({
    int limit = 50,
    int offset = 0,
  }) async {
    if (currentUserId == null) return [];

    final response = await _supabase
        .from('bookmarks')
        .select('''
          *,
          posts(
            *,
            profiles(*),
            thread_types(*),
            categories(*)
          )
        ''')
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .where((b) => b['posts'] != null)
        .map((b) => PostModel.fromJson(b['posts'] as Map<String, dynamic>))
        .toList();
  }

  /// Zkontroluje zda je příspěvek v bookmarkách
  Future<bool> isBookmarked(String postId) async {
    if (currentUserId == null) return false;

    final response = await _supabase
        .from('bookmarks')
        .select('id')
        .eq('user_id', currentUserId!)
        .eq('post_id', postId)
        .maybeSingle();

    return response != null;
  }

  /// Přidá bookmark
  Future<void> addBookmark(String postId) async {
    if (currentUserId == null) return;

    await _supabase.from('bookmarks').insert({
      'user_id': currentUserId,
      'post_id': postId,
    });
  }

  /// Odebere bookmark
  Future<void> removeBookmark(String postId) async {
    if (currentUserId == null) return;

    await _supabase
        .from('bookmarks')
        .delete()
        .eq('user_id', currentUserId!)
        .eq('post_id', postId);
  }

  /// Toggle bookmark
  Future<bool> toggleBookmark(String postId) async {
    final isCurrentlyBookmarked = await isBookmarked(postId);

    if (isCurrentlyBookmarked) {
      await removeBookmark(postId);
      return false;
    } else {
      await addBookmark(postId);
      return true;
    }
  }

  /// Počet bookmarkovaných příspěvků
  Future<int> getBookmarkCount() async {
    if (currentUserId == null) return 0;

    final response = await _supabase
        .from('bookmarks')
        .select('id')
        .eq('user_id', currentUserId!);

    return (response as List).length;
  }
}
