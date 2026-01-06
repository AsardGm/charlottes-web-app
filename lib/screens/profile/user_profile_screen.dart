import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/posts_provider.dart';
import '../../providers/follow_provider.dart';
import '../../providers/block_provider.dart';
import '../../services/profile_service.dart';
import '../../services/chat_service.dart';
import '../../services/follow_service.dart';
import '../../services/report_service.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/badge_model.dart';
import '../../widgets/profile/profile.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/report_dialog.dart';

/// Provider pro ProfileService
final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService());

/// Provider pro nacteni profilu uzivatele
final userProfileProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final service = ref.read(profileServiceProvider);
  return service.getProfile(userId);
});

/// Provider pro prispevky uzivatele
final otherUserPostsProvider = FutureProvider.family<List<PostModel>, String>((ref, userId) async {
  final service = ref.read(postServiceProvider);
  return service.getPostsByUser(userId);
});

/// Provider pro odznaky uzivatele
final userBadgesProvider = FutureProvider.family<List<UserBadge>, String>((ref, userId) async {
  final service = ref.read(badgeServiceProvider);
  return service.getUserBadges(userId);
});

/// Obrazovka profilu jineho uzivatele
class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Otevře nebo vytvoří chat s uživatelem
  Future<void> _openChat(String userId) async {
    try {
      final chatService = ChatService();
      final conversationId =
          await chatService.getOrCreateDirectConversation(userId);
      if (mounted) {
        context.push('/chat/$conversationId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nepodařilo se otevřít chat: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider(widget.userId));
    final currentUser = ref.watch(currentUserProvider).value;
    final isOwnProfile = currentUser?.id == widget.userId;

    // Pokud je to vlastni profil, presmeruj
    if (isOwnProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/profile');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return _buildNotFound();
          }
          return _buildProfile(user);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Chyba: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userProfileProvider(widget.userId)),
                child: const Text('Zkusit znovu'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Uzivatel nenalezen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tento profil neexistuje nebo byl smazan',
            style: TextStyle(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            child: const Text('Zpet'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(UserModel user) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        // App Bar
        SliverAppBar(
          backgroundColor: AppColors.background,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: Row(
            children: [
              Text(
                user.username,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (user.isAdmin)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.verified,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showUserOptions(context, user),
            ),
          ],
        ),

        // Profile Info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Avatar a statistiky
                Row(
                  children: [
                    UserAvatar(
                      imageUrl: user.avatarUrl,
                      name: user.username,
                      size: 86,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatColumn(
                            count: user.postCount,
                            label: 'prispevku',
                          ),
                          _StatColumn(
                            count: user.followerCount,
                            label: 'sledujicich',
                            onTap: () => FollowersListModal.show(
                              context,
                              userId: user.id,
                              type: FollowListType.followers,
                            ),
                          ),
                          _StatColumn(
                            count: user.followingCount,
                            label: 'sleduje',
                            onTap: () => FollowersListModal.show(
                              context,
                              userId: user.id,
                              type: FollowListType.following,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bio
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  Text(
                    user.bio!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Location & Website
                if (user.location != null || user.website != null) ...[
                  Wrap(
                    spacing: 16,
                    children: [
                      if (user.location != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              user.location!,
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      if (user.website != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              user.website!,
                              style: TextStyle(fontSize: 13, color: AppColors.primary),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 8),

                // Follow / Message buttons
                Row(
                  children: [
                    Expanded(
                      child: FollowButton(userId: user.id),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _openChat(user.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: AppColors.textMuted.withAlpha(50)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'Zprava',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Badges
                _UserBadgesRow(userId: user.id),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Tabs
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              controller: _tabController,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.textPrimary,
              indicatorWeight: 1,
              tabs: const [
                Tab(icon: Icon(Icons.grid_on, size: 24)),
                Tab(icon: Icon(Icons.workspace_premium, size: 24)),
              ],
            ),
          ),
        ),
      ],
      body: _ProfileContentOrPrivate(
        userId: widget.userId,
        isPrivate: user.isPrivate,
        tabController: _tabController,
      ),
    );
  }

  void _showUserOptions(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Sdilet profil'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sdileni - pripravujeme')),
                );
              },
            ),
            // Blokování
            Consumer(
              builder: (context, ref, _) {
                final isBlockedAsync = ref.watch(isBlockedProvider(user.id));
                return isBlockedAsync.when(
                  data: (isBlocked) => ListTile(
                    leading: Icon(
                      isBlocked ? Icons.check_circle : Icons.block,
                      color: isBlocked ? AppColors.success : null,
                    ),
                    title: Text(isBlocked ? 'Odblokovat' : 'Zablokovat'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _toggleBlock(user.id, isBlocked);
                    },
                  ),
                  loading: () => const ListTile(
                    leading: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    title: Text('Zablokovat'),
                  ),
                  error: (_, _) => ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text('Zablokovat'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _toggleBlock(user.id, false);
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.flag, color: AppColors.error),
              title: Text('Nahlasit', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                ReportDialog.show(
                  context: context,
                  contentType: ReportContentType.user,
                  contentId: user.id,
                  contentPreview: '@${user.username}',
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBlock(String userId, bool isCurrentlyBlocked) async {
    try {
      await ref.read(blockNotifierProvider.notifier).toggleBlock(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyBlocked
                  ? 'Uzivatel byl odblokovany'
                  : 'Uzivatel byl zablokovany',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Pokud jsme zablokovali, vrat se zpet
        if (!isCurrentlyBlocked) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// Sloupec statistiky
class _StatColumn extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback? onTap;

  const _StatColumn({
    required this.count,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatCount(count),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 10000) {
      return '${(count / 1000).toStringAsFixed(0)}K';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Delegate pro tab bar
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

/// Radek s odznaky uzivatele
class _UserBadgesRow extends ConsumerWidget {
  final String userId;

  const _UserBadgesRow({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(userBadgesProvider(userId));

    return badgesAsync.when(
      data: (badges) {
        final featured = badges.where((b) => b.isFeatured).toList();
        if (featured.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: featured.length,
            itemBuilder: (context, index) {
              final userBadge = featured[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: userBadge.badge.rarity.gradientColors,
                        ),
                        border: Border.all(
                          color: userBadge.badge.rarity.color,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          userBadge.badge.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 64,
                      child: Text(
                        userBadge.badge.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Widget pro zobrazeni obsahu nebo zpravy o soukromem profilu
class _ProfileContentOrPrivate extends ConsumerWidget {
  final String userId;
  final bool isPrivate;
  final TabController tabController;

  const _ProfileContentOrPrivate({
    required this.userId,
    required this.isPrivate,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pokud profil neni soukromy, zobraz obsah
    if (!isPrivate) {
      return TabBarView(
        controller: tabController,
        children: [
          _UserPostsGrid(userId: userId),
          _UserBadgesGrid(userId: userId),
        ],
      );
    }

    // Pro soukrome profily zkontroluj follow status
    final followStatusAsync = ref.watch(followStatusProvider(userId));

    return followStatusAsync.when(
      data: (status) {
        // Pokud uzivatel sleduje, zobraz obsah
        if (status == FollowStatus.following) {
          return TabBarView(
            controller: tabController,
            children: [
              _UserPostsGrid(userId: userId),
              _UserBadgesGrid(userId: userId),
            ],
          );
        }

        // Jinak zobraz zpravu o soukromem profilu
        return _PrivateProfileMessage(
          isRequested: status == FollowStatus.requested,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => TabBarView(
        controller: tabController,
        children: [
          _UserPostsGrid(userId: userId),
          _UserBadgesGrid(userId: userId),
        ],
      ),
    );
  }
}

/// Zprava o soukromem profilu
class _PrivateProfileMessage extends StatelessWidget {
  final bool isRequested;

  const _PrivateProfileMessage({
    this.isRequested = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Soukromy ucet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isRequested
                  ? 'Pozadali jste o sledovani tohoto uctu.\nPockejte na schvaleni.'
                  : 'Sledujte tento ucet, abyste videli\njeho prispevky a odznaky.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (isRequested) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ceka na schvaleni',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Grid prispevku uzivatele
class _UserPostsGrid extends ConsumerWidget {
  final String userId;

  const _UserPostsGrid({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(otherUserPostsProvider(userId));

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 64,
                  color: AppColors.textMuted.withAlpha(80),
                ),
                const SizedBox(height: 16),
                Text(
                  'Zatim zadne prispevky',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(1),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _PostGridItem(post: post);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Chyba: $error', style: TextStyle(color: AppColors.error)),
      ),
    );
  }
}

/// Polozka gridu
class _PostGridItem extends StatelessWidget {
  final PostModel post;

  const _PostGridItem({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/post/${post.id}'),
      child: Container(
        color: AppColors.surface,
        child: post.imageUrl != null
            ? Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildPlaceholder(),
              )
            : _buildTextPreview(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Center(
        child: Icon(
          Icons.image,
          color: AppColors.textMuted,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildTextPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: AppColors.surfaceLight,
      child: Center(
        child: Text(
          post.content,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Grid odznaku uzivatele
class _UserBadgesGrid extends ConsumerWidget {
  final String userId;

  const _UserBadgesGrid({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(userBadgesProvider(userId));

    return badgesAsync.when(
      data: (badges) {
        if (badges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.workspace_premium,
                  size: 64,
                  color: AppColors.textMuted.withAlpha(80),
                ),
                const SizedBox(height: 16),
                Text(
                  'Zatim zadne odznaky',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final userBadge = badges[index];
            return _BadgeGridItem(userBadge: userBadge);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Chyba: $error', style: TextStyle(color: AppColors.error)),
      ),
    );
  }
}

/// Polozka gridu odznaku
class _BadgeGridItem extends StatelessWidget {
  final UserBadge userBadge;

  const _BadgeGridItem({required this.userBadge});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: userBadge.badge.rarity.gradientColors,
            ),
            border: Border.all(
              color: userBadge.badge.rarity.color,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              userBadge.badge.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          userBadge.badge.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
