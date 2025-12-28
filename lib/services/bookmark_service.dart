import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';

/// Služba pro správu záložek (bookmarků)
///
/// Umožňuje ukládat a odebírat příspěvky ze záložek.
class BookmarkService {
  /// Supabase klient
  final SupabaseClient _supabase = Supabase.instance.client;

  /// ID aktuálního uživatele
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Získá všechny záložky uživatele
  ///
  /// Vrací seznam uložených příspěvků seřazený od nejnovějších.
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

  /// Zkontroluje zda je příspěvek v záložkách
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

  /// Přidá příspěvek do záložek
  Future<void> addBookmark(String postId) async {
    if (currentUserId == null) return;

    await _supabase.from('bookmarks').insert({
      'user_id': currentUserId,
      'post_id': postId,
    });
  }

  /// Odebere příspěvek ze záložek
  Future<void> removeBookmark(String postId) async {
    if (currentUserId == null) return;

    await _supabase
        .from('bookmarks')
        .delete()
        .eq('user_id', currentUserId!)
        .eq('post_id', postId);
  }

  /// Přepne stav záložky (přidá/odebere)
  ///
  /// Vrací nový stav (true = přidáno, false = odebráno).
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

  /// Počet záložek uživatele
  Future<int> getBookmarkCount() async {
    if (currentUserId == null) return 0;

    final response = await _supabase
        .from('bookmarks')
        .select('id')
        .eq('user_id', currentUserId!);

    return (response as List).length;
  }
}
