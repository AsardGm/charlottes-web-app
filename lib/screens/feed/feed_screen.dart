import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../providers/posts_provider.dart';
import '../../providers/thread_type_provider.dart';
import '../../models/thread_type_model.dart';
import '../../widgets/post_card.dart';
import '../../widgets/filter_sidebar.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
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

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(postsProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(postsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final postsState = ref.watch(postsProvider);
    final threadTypesAsync = ref.watch(threadTypesProvider);
    final currentFilter = ref.watch(postsProvider.notifier).currentFilter;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: isWideScreen ? null : const FilterSidebar(),
      body: Row(
        children: [
          // Hlavní obsah
          Expanded(
            child: Column(
              children: [
                // Thread type tabs
                _buildThreadTypeTabs(threadTypesAsync, currentFilter),

                // Active filters indicator
                if (currentFilter.hasActiveFilters)
                  _buildActiveFiltersBar(currentFilter),

                // Posts list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: postsState.when(
                      data: (posts) => _buildPostsList(posts),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => _buildErrorState(error),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Boční panel (pouze na širokých obrazovkách)
          if (isWideScreen)
            const SizedBox(
              width: 280,
              child: FilterSidebar(isDrawer: false),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tlačítko pro filtr na mobilech
          if (!isWideScreen)
            FloatingActionButton.small(
              heroTag: 'filter',
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              backgroundColor: AppColors.surfaceLight,
              child: Badge(
                isLabelVisible: currentFilter.hasActiveFilters,
                child: const Icon(Icons.filter_list),
              ),
            ),
          if (!isWideScreen) const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: () => context.go('/create-post'),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadTypeTabs(
    AsyncValue<List<ThreadTypeModel>> threadTypesAsync,
    PostsFilter currentFilter,
  ) {
    return threadTypesAsync.when(
      data: (threadTypes) => Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withAlpha(10),
              width: 1,
            ),
          ),
        ),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            // "Vse" tab
            _ThreadTypeChip(
              label: 'Vse',
              emoji: '🏠',
              color: AppColors.primary,
              isSelected: currentFilter.threadTypeId == null,
              onTap: () {
                ref.read(postsProvider.notifier).filterByThreadType(null);
              },
            ),
            const SizedBox(width: 8),
            // Thread type tabs
            ...threadTypes.map((type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ThreadTypeChip(
                    label: type.name,
                    emoji: type.emoji,
                    color: type.colorValue,
                    isSelected: currentFilter.threadTypeId == type.id,
                    onTap: () {
                      ref
                          .read(postsProvider.notifier)
                          .filterByThreadType(type.id);
                    },
                  ),
                )),
          ],
        ),
      ),
      loading: () => const SizedBox(
        height: 56,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildActiveFiltersBar(PostsFilter filter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withAlpha(50),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Aktivni filtry',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => ref.read(postsProvider.notifier).clearFilters(),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Zrusit'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList(List<dynamic> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withAlpha(20),
                    AppColors.primary.withAlpha(5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withAlpha(30),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.edit_note_rounded,
                size: 48,
                color: AppColors.primary.withAlpha(180),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Zatim zadne prispevky',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bud prvni, kdo neco napise!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/create-post'),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Vytvorit prispevek'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: posts.length + (ref.read(postsProvider.notifier).hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= posts.length) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }

        final post = posts[index];
        return PostCard(
          post: post,
          onTap: () => context.go('/post/${post.id}'),
          onDelete: () async {
            try {
              await ref.read(postsProvider.notifier).deletePost(post.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Prispevek smazan'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Chyba: ${e.toString()}'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Chyba: ${error.toString()}'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _onRefresh,
            child: const Text('Zkusit znovu'),
          ),
        ],
      ),
    );
  }
}

class _ThreadTypeChip extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThreadTypeChip({
    required this.label,
    required this.emoji,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color.withAlpha(40), color.withAlpha(20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color.withAlpha(150) : Colors.white.withAlpha(8),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: 16,
                shadows: isSelected
                    ? [Shadow(color: color.withAlpha(100), blurRadius: 8)]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : AppColors.textSecondary,
                letterSpacing: isSelected ? 0.3 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
