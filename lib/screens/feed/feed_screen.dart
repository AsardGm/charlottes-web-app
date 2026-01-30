import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/posts_provider.dart';
import '../../providers/thread_type_provider.dart';
import '../../providers/follow_provider.dart';
import '../../models/post_model.dart';
import '../../models/thread_type_model.dart';
import '../../theme/theme.dart';
import '../../widgets/feed/feed.dart';
import '../../widgets/filter_sidebar.dart';
import '../../widgets/common/skeleton_loading.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../utils/haptic_utils.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(postsProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    HapticUtils.lightImpact();
    await ref.read(postsProvider.notifier).refresh();
  }

  void _showDeleteSuccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Prispevek smazan'),
        backgroundColor: AppColors.functionalSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showDeleteError(Object error) {
    if (!mounted) return;
    ErrorSnackbar.show(context, error, action: 'delete');
  }

  void _onSearch(String query) {
    if (query.isNotEmpty) {
      context.push('/search?q=$query');
    }
  }

  void _showGamesMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.functionalSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎮 Mini Games & Tools',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('🌿', style: TextStyle(fontSize: 28)),
              title: const Text('Terpene Match', style: TextStyle(color: Colors.white)),
              subtitle: Text('Spoj terpeny s efekty', style: TextStyle(color: AppColors.functionalMuted)),
              onTap: () {
                Navigator.pop(context);
                context.push('/terpene-match');
              },
            ),
            ListTile(
              leading: const Text('🕷️', style: TextStyle(fontSize: 28)),
              title: const Text('Spider Focus', style: TextStyle(color: Colors.white)),
              subtitle: Text('Dechová hra pro fokus', style: TextStyle(color: AppColors.functionalMuted)),
              onTap: () {
                Navigator.pop(context);
                context.push('/spider-focus');
              },
            ),
            ListTile(
              leading: const Text('⏱️', style: TextStyle(fontSize: 28)),
              title: const Text('Pass Timer', style: TextStyle(color: Colors.white)),
              subtitle: Text('Férové předávání v kruhu', style: TextStyle(color: AppColors.functionalMuted)),
              onTap: () {
                Navigator.pop(context);
                context.push('/pass-timer');
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Text('📚', style: TextStyle(fontSize: 28)),
              title: const Text('Strain Database', style: TextStyle(color: Colors.white)),
              subtitle: Text('Encyclopedia všech strainů', style: TextStyle(color: AppColors.functionalMuted)),
              onTap: () {
                Navigator.pop(context);
                context.push('/strains');
              },
            ),
            ListTile(
              leading: const Text('🏆', style: TextStyle(fontSize: 28)),
              title: const Text('Model of the Year', style: TextStyle(color: Colors.white)),
              subtitle: Text('Hlasuj pro nejlepší strain', style: TextStyle(color: AppColors.functionalMuted)),
              onTap: () {
                Navigator.pop(context);
                context.push('/model-of-year');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
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
      backgroundColor: AppColors.functionalBg,
      endDrawer: isWideScreen ? null : const FilterSidebar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(threadTypesAsync, currentFilter, ref),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: AppColors.accent,
                      backgroundColor: AppColors.functionalSurface,
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
                        loading: () => const SkeletonFeed(),
                        error: (error, _) => FeedErrorState(
                          error: error,
                          onRetry: _onRefresh,
                        ),
                      ),
                    ),
                  ),
                  if (isWideScreen)
                    const SizedBox(
                      width: 280,
                      child: FilterSidebar(isDrawer: false),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FeedFab(
        isWideScreen: isWideScreen,
        hasActiveFilters: currentFilter.hasActiveFilters,
        onOpenFilters: () => _scaffoldKey.currentState?.openEndDrawer(),
      ),
    );
  }

  Widget _buildHeader(
    AsyncValue<List<ThreadTypeModel>> threadTypesAsync,
    PostsFilter currentFilter,
    WidgetRef ref,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.functionalBg.withAlpha(242),
        border: Border(
          bottom: BorderSide(
            color: AppColors.functionalBorder.withAlpha(128),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                // SOS Button
                GestureDetector(
                  onTap: () {
                    HapticUtils.heavyImpact();
                    context.push('/calm');
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withAlpha(100)),
                    ),
                    child: const Center(
                      child: Text('🆘', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.functionalSurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Hledat...',
                        hintStyle: TextStyle(
                          color: AppColors.functionalMuted,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: _onSearch,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Consumer(
                  builder: (context, ref, _) {
                    final countAsync = ref.watch(pendingRequestsCountProvider);
                    final count = countAsync.maybeWhen(
                      data: (c) => c,
                      orElse: () => 0,
                    );
                    return _buildIconButton(
                      icon: Icons.person_add_outlined,
                      onTap: () {
                        HapticUtils.lightImpact();
                        context.push('/follow-requests');
                      },
                      badgeCount: count,
                    );
                  },
                ),
                const SizedBox(width: 6),
                _buildIconButton(
                  icon: Icons.sports_esports_outlined,
                  onTap: () {
                    HapticUtils.lightImpact();
                    _showGamesMenu(context);
                  },
                ),
                const SizedBox(width: 6),
                _buildIconButton(
                  icon: Icons.notifications_outlined,
                  onTap: () {
                    HapticUtils.lightImpact();
                    context.push('/notifications');
                  },
                  hasNotification: true,
                ),
              ],
            ),
          ),
          _buildFilterChips(threadTypesAsync, currentFilter, ref),
          if (currentFilter.hasActiveFilters)
            _buildActiveFiltersBar(currentFilter),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool hasNotification = false,
    int badgeCount = 0,
  }) {
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.functionalSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: AppColors.functionalMuted,
                size: 22,
              ),
            ),
          ),
        ),
        if (hasNotification)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        if (badgeCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChips(
    AsyncValue<List<ThreadTypeModel>> threadTypesAsync,
    PostsFilter currentFilter,
    WidgetRef ref,
  ) {
    return threadTypesAsync.when(
      data: (threadTypes) => SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: [
            _FilterChip(
              label: 'Vse',
              icon: Icons.dashboard_outlined,
              isActive: currentFilter.threadTypeId == null,
              onTap: () {
                HapticUtils.selectionClick();
                ref.read(postsProvider.notifier).filterByThreadType(null);
              },
            ),
            const SizedBox(width: 8),
            ...threadTypes.map((type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: type.name,
                    emoji: type.emoji,
                    isActive: currentFilter.threadTypeId == type.id,
                    onTap: () {
                      HapticUtils.selectionClick();
                      ref.read(postsProvider.notifier).filterByThreadType(type.id);
                    },
                  ),
                )),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 44),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildActiveFiltersBar(PostsFilter filter) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 16,
            color: AppColors.accent,
          ),
          const SizedBox(width: 8),
          Text(
            'Aktivni filtry',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              HapticUtils.lightImpact();
              ref.read(postsProvider.notifier).clearFilters();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Zrusit',
              style: TextStyle(
                color: AppColors.functionalMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? emoji;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    this.emoji,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent.withAlpha(30) : AppColors.functionalSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive ? AppColors.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isActive ? AppColors.accent : AppColors.functionalMuted,
                ),
                const SizedBox(width: 6),
              ],
              if (emoji != null) ...[
                Text(
                  emoji!,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.accent : Colors.white,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}