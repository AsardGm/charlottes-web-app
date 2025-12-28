import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/comment_service.dart';
import '../services/reaction_service.dart';

final postServiceProvider = Provider<PostService>((ref) => PostService());
final commentServiceProvider = Provider<CommentService>((ref) => CommentService());
final reactionServiceProvider = Provider<ReactionService>((ref) => ReactionService());

/// Filtrační stav pro příspěvky
class PostsFilter {
  final String? categoryId;
  final String? threadTypeId;
  final String? status;
  final bool? hasDeadline;
  final bool? isOverdue;

  const PostsFilter({
    this.categoryId,
    this.threadTypeId,
    this.status,
    this.hasDeadline,
    this.isOverdue,
  });

  PostsFilter copyWith({
    String? categoryId,
    String? threadTypeId,
    String? status,
    bool? hasDeadline,
    bool? isOverdue,
    bool clearCategoryId = false,
    bool clearThreadTypeId = false,
    bool clearStatus = false,
    bool clearHasDeadline = false,
    bool clearIsOverdue = false,
  }) {
    return PostsFilter(
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      threadTypeId: clearThreadTypeId ? null : (threadTypeId ?? this.threadTypeId),
      status: clearStatus ? null : (status ?? this.status),
      hasDeadline: clearHasDeadline ? null : (hasDeadline ?? this.hasDeadline),
      isOverdue: clearIsOverdue ? null : (isOverdue ?? this.isOverdue),
    );
  }

  bool get hasActiveFilters =>
      categoryId != null ||
      threadTypeId != null ||
      status != null ||
      hasDeadline == true ||
      isOverdue == true;
}

class PostsNotifier extends Notifier<AsyncValue<List<PostModel>>> {
  late PostService _postService;
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;
  PostsFilter _filter = const PostsFilter();

  @override
  AsyncValue<List<PostModel>> build() {
    _postService = ref.read(postServiceProvider);
    _loadInitial();
    return const AsyncValue.loading();
  }

  bool get hasMore => _hasMore;
  PostsFilter get currentFilter => _filter;

  Future<void> _loadInitial() async {
    await loadPosts(refresh: true);
  }

  Future<void> loadPosts({bool refresh = false}) async {
    if (refresh) {
      _offset = 0;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    try {
      final posts = await _postService.getPosts(
        limit: _limit,
        offset: _offset,
        categoryId: _filter.categoryId,
        threadTypeId: _filter.threadTypeId,
        status: _filter.status,
        hasDeadline: _filter.hasDeadline,
        isOverdue: _filter.isOverdue,
      );

      if (posts.length < _limit) {
        _hasMore = false;
      }

      if (refresh || _offset == 0) {
        state = AsyncValue.data(posts);
      } else {
        final currentPosts = state.value ?? [];
        state = AsyncValue.data([...currentPosts, ...posts]);
      }

      _offset += posts.length;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Nastaví nový filtr a znovu načte příspěvky
  Future<void> setFilter(PostsFilter filter) async {
    _filter = filter;
    await loadPosts(refresh: true);
  }

  /// Filtruje podle kategorie
  Future<void> filterByCategory(String? categoryId) async {
    _filter = _filter.copyWith(
      categoryId: categoryId,
      clearCategoryId: categoryId == null,
    );
    await loadPosts(refresh: true);
  }

  /// Filtruje podle typu vlákna
  Future<void> filterByThreadType(String? threadTypeId) async {
    _filter = _filter.copyWith(
      threadTypeId: threadTypeId,
      clearThreadTypeId: threadTypeId == null,
    );
    await loadPosts(refresh: true);
  }

  /// Filtruje podle stavu
  Future<void> filterByStatus(String? status) async {
    _filter = _filter.copyWith(
      status: status,
      clearStatus: status == null,
    );
    await loadPosts(refresh: true);
  }

  /// Filtruje příspěvky s deadline
  Future<void> filterByDeadline(bool hasDeadline) async {
    _filter = _filter.copyWith(
      hasDeadline: hasDeadline,
      clearHasDeadline: !hasDeadline,
    );
    await loadPosts(refresh: true);
  }

  /// Filtruje prošlé příspěvky
  Future<void> filterOverdue(bool isOverdue) async {
    _filter = _filter.copyWith(
      isOverdue: isOverdue,
      clearIsOverdue: !isOverdue,
    );
    await loadPosts(refresh: true);
  }

  /// Vymaže všechny filtry
  Future<void> clearFilters() async {
    _filter = const PostsFilter();
    await loadPosts(refresh: true);
  }

  Future<void> loadByCategory(String? categoryId) async {
    await filterByCategory(categoryId);
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    await loadPosts();
  }

  Future<void> refresh() async {
    await loadPosts(refresh: true);
  }

  Future<void> createPost(
    String content, {
    String? imageUrl,
    String? categoryId,
    String? threadTypeId,
    DateTime? deadline,
  }) async {
    try {
      final newPost = await _postService.createPost(
        content: content,
        imageUrl: imageUrl,
        categoryId: categoryId,
        threadTypeId: threadTypeId,
        deadline: deadline,
      );

      final currentPosts = state.value ?? [];
      // Přidat do seznamu pouze pokud odpovídá aktuálnímu filtru
      final matchesFilter = _matchesFilter(newPost);
      if (matchesFilter) {
        state = AsyncValue.data([newPost, ...currentPosts]);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  bool _matchesFilter(PostModel post) {
    if (_filter.categoryId != null && post.categoryId != _filter.categoryId) {
      return false;
    }
    if (_filter.threadTypeId != null && post.threadTypeId != _filter.threadTypeId) {
      return false;
    }
    if (_filter.status != null && post.status != _filter.status) {
      return false;
    }
    return true;
  }

  Future<void> deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);

      final currentPosts = state.value ?? [];
      state = AsyncValue.data(
        currentPosts.where((p) => p.id != postId).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> resolvePost(String postId) async {
    try {
      await _postService.resolvePost(postId);
      _updatePostStatus(postId, 'resolved');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> reopenPost(String postId) async {
    try {
      await _postService.reopenPost(postId);
      _updatePostStatus(postId, 'open');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> lockPost(String postId) async {
    try {
      await _postService.lockPost(postId);
      _updatePostStatus(postId, 'locked');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> togglePin(String postId, bool isPinned) async {
    try {
      await _postService.togglePin(postId, isPinned);
      final currentPosts = state.value ?? [];
      final index = currentPosts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final newList = [...currentPosts];
        newList[index] = newList[index].copyWith(isPinned: isPinned);
        state = AsyncValue.data(newList);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> acceptAnswer(String postId, String commentId) async {
    try {
      await _postService.acceptAnswer(postId, commentId);
      final currentPosts = state.value ?? [];
      final index = currentPosts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final newList = [...currentPosts];
        newList[index] = newList[index].copyWith(
          acceptedCommentId: commentId,
          status: 'resolved',
        );
        state = AsyncValue.data(newList);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void _updatePostStatus(String postId, String status) {
    final currentPosts = state.value ?? [];
    final index = currentPosts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final newList = [...currentPosts];
      newList[index] = newList[index].copyWith(status: status);
      state = AsyncValue.data(newList);
    }
  }

  void updatePostLocally(PostModel updatedPost) {
    final currentPosts = state.value ?? [];
    final index = currentPosts.indexWhere((p) => p.id == updatedPost.id);
    if (index != -1) {
      final newList = [...currentPosts];
      newList[index] = updatedPost;
      state = AsyncValue.data(newList);
    }
  }
}

final postsProvider =
    NotifierProvider<PostsNotifier, AsyncValue<List<PostModel>>>(() {
  return PostsNotifier();
});

final singlePostProvider = FutureProvider.family<PostModel?, String>((ref, id) async {
  return await ref.read(postServiceProvider).getPost(id);
});
