import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/search_service.dart';

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService();
});

final searchResultsProvider = FutureProvider.family<SearchResults, String>((ref, query) async {
  if (query.isEmpty) {
    return SearchResults(posts: [], users: []);
  }
  return ref.read(searchServiceProvider).search(query);
});

final searchPostsProvider = FutureProvider.family<List<PostModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return ref.read(searchServiceProvider).searchPosts(query);
});

final searchUsersProvider = FutureProvider.family<List<UserModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return ref.read(searchServiceProvider).searchUsers(query);
});

class SearchNotifier extends Notifier<SearchState> {
  late SearchService _service;

  @override
  SearchState build() {
    _service = ref.read(searchServiceProvider);
    return SearchState.initial();
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = SearchState.initial();
      return;
    }

    state = state.copyWith(isLoading: true, query: query);

    try {
      final results = await _service.search(query);
      state = state.copyWith(
        isLoading: false,
        posts: results.posts,
        users: results.users,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clear() {
    state = SearchState.initial();
  }
}

final searchNotifierProvider = NotifierProvider<SearchNotifier, SearchState>(() {
  return SearchNotifier();
});

class SearchState {
  final String query;
  final bool isLoading;
  final List<PostModel> posts;
  final List<UserModel> users;
  final String? error;

  SearchState({
    required this.query,
    required this.isLoading,
    required this.posts,
    required this.users,
    this.error,
  });

  factory SearchState.initial() {
    return SearchState(
      query: '',
      isLoading: false,
      posts: [],
      users: [],
    );
  }

  SearchState copyWith({
    String? query,
    bool? isLoading,
    List<PostModel>? posts,
    List<UserModel>? users,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      posts: posts ?? this.posts,
      users: users ?? this.users,
      error: error,
    );
  }

  bool get isEmpty => posts.isEmpty && users.isEmpty;
  bool get hasResults => !isEmpty;
}
