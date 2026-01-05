import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/posts_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/post_model.dart';
import '../../models/badge_model.dart';
import '../../widgets/profile/profile.dart';

/// Provider pro prispevky uzivatele
final userPostsProvider = FutureProvider.family<List<PostModel>, String>((ref, oderId) async {
  final service = ref.read(postServiceProvider);
  return service.getPostsByUser(oderId);
});

/// Obrazovka profilu uzivatele - Functional Dark design
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(
                'Neprihlaseny uzivatel',
                style: TextStyle(color: AppColors.functionalMuted),
              ),
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // App Bar
              SliverAppBar(
                backgroundColor: AppColors.functionalBg,
                pinned: true,
                title: Row(
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (user.isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.accent.withAlpha(100),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'ADMIN',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.add_box_outlined, color: AppColors.functionalMuted),
                    onPressed: () => context.go('/create-post'),
                  ),
                  IconButton(
                    icon: Icon(Icons.menu, color: AppColors.functionalMuted),
                    onPressed: () => _showProfileMenu(context),
                  ),
                ],
              ),

              // Banner s avatarem prekryvajicim
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Banner - Functional Dark gradient
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withAlpha(40),
                            AppColors.functionalSurface,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Avatar pozicovany dole
                    Positioned(
                      left: 16,
                      bottom: -43,
                      child: GlitchAvatar(
                        imageUrl: user.avatarUrl,
                        name: user.username,
                        size: 86,
                        glitchStyle: user.isAdmin ? GlitchStyle.neon : GlitchStyle.subtle,
                        showLevelBadge: false,
                        onTap: () => context.go('/edit-profile'),
                      ),
                    ),
                  ],
                ),
              ),

              // Profile Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistiky (vedle avataru)
                      Row(
                        children: [
                          // Mezera pro avatar
                          const SizedBox(width: 110),
                          // Statistiky - nactene z profileStatsProvider
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, _) {
                                final statsAsync = ref.watch(profileStatsProvider(user.id));
                                return statsAsync.when(
                                  data: (stats) => Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _StatColumn(
                                        count: stats.postCount,
                                        label: 'prispevku',
                                      ),
                                      _StatColumn(
                                        count: stats.followerCount,
                                        label: 'sledujicich',
                                        onTap: () => _showFollowers(context),
                                      ),
                                      _StatColumn(
                                        count: stats.followingCount,
                                        label: 'sleduje',
                                        onTap: () => _showFollowing(context),
                                      ),
                                    ],
                                  ),
                                  loading: () => Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _StatColumn(count: 0, label: 'prispevku'),
                                      _StatColumn(count: 0, label: 'sledujicich'),
                                      _StatColumn(count: 0, label: 'sleduje'),
                                    ],
                                  ),
                                  error: (_, _) => Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _StatColumn(count: 0, label: 'prispevku'),
                                      _StatColumn(count: 0, label: 'sledujicich'),
                                      _StatColumn(count: 0, label: 'sleduje'),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Bio s podporou tagu
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        ProfileBio(
                          bio: user.bio!,
                          onTagTap: (tag) {
                            context.push('/search?q=%23$tag');
                          },
                          onMentionTap: (username) {
                            context.push('/search?q=@$username');
                          },
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Lokace a web
                      if (user.location != null || user.website != null) ...[
                        ProfileInfoRow(
                          location: user.location,
                          website: user.website,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Tlacitko Upravit profil - Functional Dark
                      SizedBox(
                        width: double.infinity,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.go('/edit-profile'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.functionalSurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'Upravit profil',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Featured badges
                      const _FeaturedBadgesRow(),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Taby - Functional Dark
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.accent,
                    unselectedLabelColor: AppColors.functionalMuted,
                    indicatorColor: AppColors.accent,
                    indicatorWeight: 2,
                    dividerColor: AppColors.functionalBorder,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on, size: 24)),
                      Tab(icon: Icon(Icons.bookmark_border, size: 24)),
                      Tab(icon: Icon(Icons.person_pin_outlined, size: 24)),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // Grid prispevku
                _PostsGrid(userId: user.id),

                // Ulozene prispevky
                const _SavedPostsGrid(),

                // Oznacene prispevky (tagged)
                const _TaggedPostsGrid(),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (error, _) => Center(
          child: Text(
            'Chyba: ${error.toString()}',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.functionalSurface,
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
                color: AppColors.functionalMuted.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _MenuTile(
              icon: Icons.emoji_events,
              label: 'Gamifikace',
              onTap: () {
                Navigator.pop(context);
                context.go('/gamification');
              },
            ),
            _MenuTile(
              icon: Icons.workspace_premium,
              label: 'Odznaky',
              onTap: () {
                Navigator.pop(context);
                context.go('/badges');
              },
            ),
            _MenuTile(
              icon: Icons.collections,
              label: 'Sbirka karet',
              onTap: () {
                Navigator.pop(context);
                context.go('/cards');
              },
            ),
            _MenuTile(
              icon: Icons.leaderboard,
              label: 'Zebricek',
              onTap: () {
                Navigator.pop(context);
                context.go('/leaderboard');
              },
            ),
            Divider(height: 1, color: AppColors.functionalBorder),
            _MenuTile(
              icon: Icons.settings,
              label: 'Nastaveni',
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
            ),
            if (ref.read(isAdminProvider))
              _MenuTile(
                icon: Icons.admin_panel_settings,
                label: 'Administrace',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/admin');
                },
              ),
            _MenuTile(
              icon: Icons.logout,
              label: 'Odhlasit se',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                LogoutDialog.show(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFollowers(BuildContext context) {
    FollowersListModal.show(
      context,
      type: FollowListType.followers,
    );
  }

  void _showFollowing(BuildContext context) {
    FollowersListModal.show(
      context,
      type: FollowListType.following,
    );
  }
}

/// Sloupec statistiky - Functional Dark
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.functionalMuted,
              fontFamily: 'monospace',
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

/// Delegate pro tab bar - Functional Dark
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.functionalBg,
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

/// Polozka menu - Functional Dark
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.functionalMuted),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// Featured odznaky v radku - Functional Dark
class _FeaturedBadgesRow extends ConsumerWidget {
  const _FeaturedBadgesRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(featuredBadgesProvider);

    return badgesAsync.when(
      data: (badges) {
        if (badges.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length + 1, // +1 pro "Vse"
            itemBuilder: (context, index) {
              if (index == badges.length) {
                // Tlacitko "Vse"
                return GestureDetector(
                  onTap: () => context.go('/badges'),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.functionalSurface,
                          border: Border.all(
                            color: AppColors.functionalBorder,
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          color: AppColors.functionalMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vse',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.functionalMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final badge = badges[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => context.go('/badges'),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: badge.badge.rarity.gradientColors,
                          ),
                          border: Border.all(
                            color: badge.badge.rarity.color,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            badge.badge.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 64,
                        child: Text(
                          badge.badge.name,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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

/// Grid prispevku uzivatele - Functional Dark
class _PostsGrid extends ConsumerWidget {
  final String userId;

  const _PostsGrid({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userPostsProvider(userId));

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
                  color: AppColors.functionalMuted.withAlpha(80),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Zatim zadne prispevky',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sdilej sve fotky a prispevky',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.functionalMuted,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _PostGridItem(post: post);
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (error, _) => Center(
        child: Text('Chyba: $error', style: TextStyle(color: AppColors.error)),
      ),
    );
  }
}

/// Polozka gridu prispevku - Functional Dark
class _PostGridItem extends StatelessWidget {
  final PostModel post;

  const _PostGridItem({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/post/${post.id}'),
      child: Container(
        color: AppColors.functionalSurface,
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
      color: AppColors.functionalSurface,
      child: Center(
        child: Icon(
          Icons.image,
          color: AppColors.functionalMuted,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildTextPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: AppColors.functionalSurface,
      child: Center(
        child: Text(
          post.content,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.functionalMuted,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Grid ulozenych prispevku - Functional Dark
class _SavedPostsGrid extends ConsumerWidget {
  const _SavedPostsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider);

    return bookmarksAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 64,
                  color: AppColors.functionalMuted.withAlpha(80),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Zadne ulozene prispevky',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uloz si zajimave prispevky',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.functionalMuted,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _PostGridItem(post: post);
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (error, _) => Center(
        child: Text('Chyba: $error', style: TextStyle(color: AppColors.error)),
      ),
    );
  }
}

/// Grid oznacenych prispevku - Functional Dark
class _TaggedPostsGrid extends StatelessWidget {
  const _TaggedPostsGrid();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_pin_outlined,
            size: 64,
            color: AppColors.functionalMuted.withAlpha(80),
          ),
          const SizedBox(height: 16),
          const Text(
            'Zadne oznaceni',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prispevky kde jsi oznacen',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.functionalMuted,
            ),
          ),
        ],
      ),
    );
  }
}
