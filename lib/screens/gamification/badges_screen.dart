import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../models/badge_model.dart';
import '../../providers/badge_provider.dart';
import '../../widgets/gamification/gamification.dart';

/// Obrazovka kolekce odznaku
class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: BadgeCategory.values.length + 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badgesAsync = ref.watch(userBadgesProvider);
    final statsAsync = ref.watch(badgeStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
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
        title: Text(
          'Odznaky',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: [
            const Tab(text: 'Vse'),
            ...BadgeCategory.values.map((cat) => Tab(text: cat.name)),
          ],
        ),
      ),
      body: badgesAsync.when(
        data: (userBadges) {
          final earnedIds = userBadges.map((b) => b.badgeId).toSet();
          final newIds = userBadges.where((b) => b.isNew).map((b) => b.badgeId).toSet();
          final featuredIds = userBadges.where((b) => b.isFeatured).map((b) => b.badgeId).toSet();

          return Column(
            children: [
              // Stats bar
              statsAsync.when(
                data: (stats) => BadgeStatsBar(
                  total: stats.total,
                  earned: stats.earned,
                  byRarity: stats.byRarity,
                ),
                loading: () => const SizedBox(height: 100),
                error: (_, _) => const SizedBox(height: 100),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Vsechny odznaky
                    _AllBadgesTab(
                      earnedIds: earnedIds,
                      newIds: newIds,
                      featuredIds: featuredIds,
                      userBadges: userBadges,
                    ),
                    // Odznaky podle kategorie
                    ...BadgeCategory.values.map((category) => _CategoryBadgesTab(
                      category: category,
                      earnedIds: earnedIds,
                      newIds: newIds,
                      featuredIds: featuredIds,
                      userBadges: userBadges,
                    )),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Chyba: $error',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

/// Tab se vsemi odznaky
class _AllBadgesTab extends ConsumerWidget {
  final Set<String> earnedIds;
  final Set<String> newIds;
  final Set<String> featuredIds;
  final List<UserBadge> userBadges;

  const _AllBadgesTab({
    required this.earnedIds,
    required this.newIds,
    required this.featuredIds,
    required this.userBadges,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: BadgeCategory.values.map((category) {
        return BadgeCategorySection(
          category: category,
          badges: Badges.all,
          earnedBadgeIds: earnedIds,
          newBadgeIds: newIds,
          featuredBadgeIds: featuredIds,
          onBadgeTap: (badge) => _showBadgeDetail(context, ref, badge),
        );
      }).toList(),
    );
  }

  void _showBadgeDetail(BuildContext context, WidgetRef ref, Badge badge) {
    final userBadge = userBadges.where((ub) => ub.badgeId == badge.id).firstOrNull;
    final isEarned = userBadge != null;

    BadgeDetailDialog.show(
      context,
      badge,
      isEarned: isEarned,
      earnedAt: userBadge?.earnedAt,
      isFeatured: userBadge?.isFeatured ?? false,
      onToggleFeatured: isEarned
          ? () => ref.read(badgeProvider.notifier).toggleFeaturedBadge(
                badge.id,
                !userBadge.isFeatured,
              )
          : null,
    );
  }
}

/// Tab s odznaky podle kategorie
class _CategoryBadgesTab extends ConsumerWidget {
  final BadgeCategory category;
  final Set<String> earnedIds;
  final Set<String> newIds;
  final Set<String> featuredIds;
  final List<UserBadge> userBadges;

  const _CategoryBadgesTab({
    required this.category,
    required this.earnedIds,
    required this.newIds,
    required this.featuredIds,
    required this.userBadges,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryBadges = Badges.getByCategory(category);

    if (categoryBadges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 64,
              color: AppColors.textMuted.withAlpha(50),
            ),
            const SizedBox(height: 16),
            Text(
              'Zadne odznaky v teto kategorii',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: BadgeGrid(
        badges: categoryBadges,
        earnedBadgeIds: earnedIds,
        newBadgeIds: newIds,
        featuredBadgeIds: featuredIds,
        onBadgeTap: (badge) => _showBadgeDetail(context, ref, badge),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, WidgetRef ref, Badge badge) {
    final userBadge = userBadges.where((ub) => ub.badgeId == badge.id).firstOrNull;
    final isEarned = userBadge != null;

    BadgeDetailDialog.show(
      context,
      badge,
      isEarned: isEarned,
      earnedAt: userBadge?.earnedAt,
      isFeatured: userBadge?.isFeatured ?? false,
      onToggleFeatured: isEarned
          ? () => ref.read(badgeProvider.notifier).toggleFeaturedBadge(
                badge.id,
                !userBadge.isFeatured,
              )
          : null,
    );
  }
}
