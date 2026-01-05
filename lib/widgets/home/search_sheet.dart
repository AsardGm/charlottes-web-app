import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../providers/search_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../user_avatar.dart';
import '../profile/follow_button.dart';

/// Moderní search sheet (bottom sheet nebo fullscreen)
class SearchSheet extends ConsumerStatefulWidget {
  /// Zobrazit jako fullscreen
  final bool fullscreen;

  const SearchSheet({
    super.key,
    this.fullscreen = false,
  });

  /// Zobrazí search sheet jako modal bottom sheet
  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SearchSheet(),
    );
  }

  /// Zobrazí search sheet jako fullscreen overlay
  static Future<void> showFullscreen(BuildContext context) {
    HapticFeedback.lightImpact();
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SearchSheet(fullscreen: true);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  @override
  ConsumerState<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends ConsumerState<SearchSheet>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  bool _showResults = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Historie vyhledávání (mock data - později z SharedPreferences)
  final List<String> _recentSearches = [
    'flutter',
    'dart',
    'supabase',
  ];

  // Trending témata (mock data - později z API)
  final List<String> _trendingTopics = [
    'CBD oleje',
    'Terpeny',
    'Extrakce',
    'Vaporizer',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();

    // Auto focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.isNotEmpty) {
        ref.read(searchNotifierProvider.notifier).search(query);
        setState(() => _showResults = true);
      } else {
        ref.read(searchNotifierProvider.notifier).clear();
        setState(() => _showResults = false);
      }
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      // Přidat do historie
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches.removeLast();
        }
      }
      ref.read(searchNotifierProvider.notifier).search(query);
      setState(() => _showResults = true);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchNotifierProvider.notifier).clear();
    setState(() => _showResults = false);
    HapticFeedback.lightImpact();
  }

  void _close() {
    _animController.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fullscreen) {
      return _buildFullscreen();
    }
    return _buildBottomSheet();
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              _buildHandle(),
              // Search bar
              _buildSearchBar(),
              // Content
              Expanded(
                child: _showResults
                    ? _buildResults(scrollController)
                    : _buildSuggestions(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFullscreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Search bar s back button
              _buildSearchBar(showBack: true),
              // Content
              Expanded(
                child: _showResults
                    ? _buildResults(null)
                    : _buildSuggestions(null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return GestureDetector(
      onTap: _close,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textMuted.withAlpha(60),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar({bool showBack = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          if (showBack)
            GestureDetector(
              onTap: _close,
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surface,
                    AppColors.surfaceLight.withAlpha(200),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? AppColors.primary.withAlpha(100)
                      : Colors.white.withAlpha(8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  if (_focusNode.hasFocus)
                    BoxShadow(
                      color: AppColors.primary.withAlpha(20),
                      blurRadius: 16,
                      spreadRadius: -4,
                    ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    Icons.search_rounded,
                    color: _focusNode.hasFocus
                        ? AppColors.primary
                        : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: 'Hledat příspěvky, uživatele...',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: _onSearchChanged,
                      onSubmitted: _onSearchSubmitted,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.textPrimary,
                          size: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(ScrollController? scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Recent searches
        if (_recentSearches.isNotEmpty) ...[
          _buildSectionHeader(
            'Nedávné',
            trailing: GestureDetector(
              onTap: () {
                setState(() => _recentSearches.clear());
                HapticFeedback.lightImpact();
              },
              child: Text(
                'Vymazat',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((query) {
              return _SearchChip(
                label: query,
                icon: Icons.history_rounded,
                onTap: () {
                  _searchController.text = query;
                  _onSearchSubmitted(query);
                },
                onDelete: () {
                  setState(() => _recentSearches.remove(query));
                  HapticFeedback.lightImpact();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Trending
        _buildSectionHeader('Trendy'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trendingTopics.map((topic) {
            return _SearchChip(
              label: topic,
              icon: Icons.trending_up_rounded,
              gradient: true,
              onTap: () {
                _searchController.text = topic;
                _onSearchSubmitted(topic);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Quick actions
        _buildSectionHeader('Rychlé akce'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.people_rounded,
                label: 'Uživatelé',
                color: AppColors.primary,
                onTap: () {
                  // Přepnout na tab uživatelé ve výsledcích
                  _searchController.text = ' ';
                  _onSearchSubmitted(' ');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.tag_rounded,
                label: 'Tagy',
                color: AppColors.info,
                onTap: () {
                  // Vyhledat hashtag
                  _searchController.text = '#';
                  _focusNode.requestFocus();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.category_rounded,
                label: 'Kategorie',
                color: AppColors.success,
                onTap: () {
                  // Zavřít search a otevřít feed s filtry
                  Navigator.pop(context);
                  // Feed screen má vlastní filtry pro kategorie
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildResults(ScrollController? scrollController) {
    final searchState = ref.watch(searchNotifierProvider);

    if (searchState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (searchState.isEmpty && _searchController.text.isNotEmpty) {
      return _buildEmptyState();
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.article_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Příspěvky (${searchState.posts.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Uživatelé (${searchState.users.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tab content
          Expanded(
            child: TabBarView(
              children: [
                _buildPostsResults(searchState.posts, scrollController),
                _buildUsersResults(searchState.users, scrollController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Žádné výsledky',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Zkuste jiný hledaný výraz',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsResults(List<PostModel> posts, ScrollController? scrollController) {
    if (posts.isEmpty) {
      return Center(
        child: Text(
          'Žádné příspěvky',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _PostResultCard(
          post: post,
          searchQuery: _searchController.text,
          onTap: () {
            Navigator.pop(context);
            context.push('/post/${post.id}');
          },
        );
      },
    );
  }

  Widget _buildUsersResults(List<UserModel> users, ScrollController? scrollController) {
    final currentUser = ref.watch(currentUserProvider).value;

    if (users.isEmpty) {
      return Center(
        child: Text(
          'Žádní uživatelé',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isCurrentUser = currentUser?.id == user.id;

        return _UserResultCard(
          user: user,
          isCurrentUser: isCurrentUser,
          onTap: () {
            Navigator.pop(context);
            context.push('/profile/${user.id}');
          },
        );
      },
    );
  }
}

/// Chip pro vyhledávání
class _SearchChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool gradient;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _SearchChip({
    required this.label,
    required this.icon,
    this.gradient = false,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_SearchChip> createState() => _SearchChipState();
}

class _SearchChipState extends State<_SearchChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: widget.gradient
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha(30),
                      AppColors.primaryLight.withAlpha(20),
                    ],
                  )
                : null,
            color: widget.gradient ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.gradient
                  ? AppColors.primary.withAlpha(50)
                  : Colors.white.withAlpha(8),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.gradient
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.onDelete != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick action karta
class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.color.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withAlpha(30),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                widget.icon,
                size: 28,
                color: widget.color,
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Karta výsledku příspěvku
class _PostResultCard extends StatelessWidget {
  final PostModel post;
  final String searchQuery;
  final VoidCallback onTap;

  const _PostResultCard({
    required this.post,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withAlpha(5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                UserAvatar(
                  imageUrl: post.author?.avatarUrl,
                  name: post.author?.username ?? 'User',
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author?.username ?? 'Unknown',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.threadType != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      post.threadType!.name,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Content
            Text(
              post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            // Image preview
            if (post.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Právě teď';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}.${date.month}.${date.year}';
  }
}

/// Karta výsledku uživatele
class _UserResultCard extends StatelessWidget {
  final UserModel user;
  final bool isCurrentUser;
  final VoidCallback onTap;

  const _UserResultCard({
    required this.user,
    required this.isCurrentUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withAlpha(5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            UserAvatar(
              imageUrl: user.avatarUrl,
              name: user.username,
              size: 52,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.username,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isAdmin) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${user.followerCount} sledujících',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!isCurrentUser)
              FollowButton(
                userId: user.id,
                compact: true,
              ),
          ],
        ),
      ),
    );
  }
}
