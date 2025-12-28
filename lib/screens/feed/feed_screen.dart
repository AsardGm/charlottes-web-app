import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/theme.dart';
import '../../providers/posts_provider.dart';
import '../../providers/thread_type_provider.dart';
import '../../models/post_model.dart';
import '../../widgets/feed/feed.dart';
import '../../widgets/filter_sidebar.dart';

/// Hlavní obrazovka feedu s příspěvky
///
/// Zobrazuje seznam příspěvků s možností filtrování podle typu vlákna,
/// kategorie a stavu. Podporuje nekonečné scrollování a pull-to-refresh.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  /// Controller pro scrollování seznamu
  final ScrollController _scrollController = ScrollController();

  /// Klíč pro přístup ke Scaffold (pro otevření draweru)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Callback volaný při scrollování - načte další příspěvky
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(postsProvider.notifier).loadMore();
    }
  }

  /// Obnoví seznam příspěvků (pull-to-refresh)
  Future<void> _onRefresh() async {
    await ref.read(postsProvider.notifier).refresh();
  }

  /// Zobrazí snackbar se zprávou o úspěšném smazání
  void _showDeleteSuccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Příspěvek smazán'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Zobrazí snackbar s chybou
  void _showDeleteError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chyba: ${error.toString()}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sledované stavy
    final postsState = ref.watch(postsProvider);
    final threadTypesAsync = ref.watch(threadTypesProvider);
    final currentFilter = ref.watch(postsProvider.notifier).currentFilter;

    // Responzivita
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      key: _scaffoldKey,
      // Boční panel jako drawer na mobilech
      endDrawer: isWideScreen ? null : const FilterSidebar(),
      body: Row(
        children: [
          // === Hlavní obsah ===
          Expanded(
            child: Column(
              children: [
                // Taby pro typy vláken
                ThreadTypeTabs(
                  threadTypesAsync: threadTypesAsync,
                  currentFilter: currentFilter,
                ),

                // Lišta aktivních filtrů
                if (currentFilter.hasActiveFilters)
                  ActiveFiltersBar(filter: currentFilter),

                // Seznam příspěvků
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: postsState.when(
                      data: (posts) => PostsListView(
                        posts: posts.cast<PostModel>(),
                        scrollController: _scrollController,
                        hasMore: ref.read(postsProvider.notifier).hasMore,
                        onDeletePost: (postId) =>
                            ref.read(postsProvider.notifier).deletePost(postId),
                        onDeleteSuccess: _showDeleteSuccess,
                        onDeleteError: _showDeleteError,
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, _) => FeedErrorState(
                        error: error,
                        onRetry: _onRefresh,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // === Boční panel (desktop) ===
          if (isWideScreen)
            const SizedBox(
              width: 280,
              child: FilterSidebar(isDrawer: false),
            ),
        ],
      ),

      // Plovoucí akční tlačítka
      floatingActionButton: FeedFab(
        isWideScreen: isWideScreen,
        hasActiveFilters: currentFilter.hasActiveFilters,
        onOpenFilters: () => _scaffoldKey.currentState?.openEndDrawer(),
      ),
    );
  }
}
