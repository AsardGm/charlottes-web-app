import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../services/bookmark_service.dart';

final bookmarkServiceProvider = Provider<BookmarkService>((ref) {
  return BookmarkService();
});

final bookmarksProvider = FutureProvider<List<PostModel>>((ref) async {
  return ref.read(bookmarkServiceProvider).getBookmarks();
});

final isBookmarkedProvider = FutureProvider.family<bool, String>((ref, postId) async {
  return ref.read(bookmarkServiceProvider).isBookmarked(postId);
});

class BookmarkNotifier extends Notifier<AsyncValue<List<PostModel>>> {
  late BookmarkService _service;

  @override
  AsyncValue<List<PostModel>> build() {
    _service = ref.read(bookmarkServiceProvider);
    _loadBookmarks();
    return const AsyncValue.loading();
  }

  Future<void> _loadBookmarks() async {
    try {
      final bookmarks = await _service.getBookmarks();
      state = AsyncValue.data(bookmarks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadBookmarks();
  }

  Future<bool> toggleBookmark(String postId) async {
    final isNowBookmarked = await _service.toggleBookmark(postId);

    // Refresh bookmarks list
    await _loadBookmarks();

    // Invalidate specific bookmark check
    ref.invalidate(isBookmarkedProvider(postId));

    return isNowBookmarked;
  }

  Future<void> removeBookmark(String postId) async {
    await _service.removeBookmark(postId);

    state.whenData((bookmarks) {
      final updated = bookmarks.where((p) => p.id != postId).toList();
      state = AsyncValue.data(updated);
    });

    ref.invalidate(isBookmarkedProvider(postId));
  }
}

final bookmarkNotifierProvider =
    NotifierProvider<BookmarkNotifier, AsyncValue<List<PostModel>>>(() {
  return BookmarkNotifier();
});
