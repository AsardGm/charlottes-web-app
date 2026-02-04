/// Example usage of skeleton loading states
///
/// This file demonstrates how to use the skeleton widgets and LoadingStateBuilder
/// for consistent and beautiful loading states throughout the app.

/*
// ==================== EXAMPLE 1: Simple List with Skeleton ====================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/loading_state_builder.dart';
import '../../widgets/common/skeleton_widgets.dart';

class ChallengesListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(challengesProvider);

    return ListLoadingStateBuilder(
      state: challengesAsync,
      itemSkeleton: const ListItemSkeleton(),
      skeletonItemCount: 5,
      emptyMessage: 'Žádné challenges k dispozici',
      builder: (challenges) {
        return ListView.builder(
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return ChallengeCard(challenge: challenge);
          },
        );
      },
    );
  }
}

// ==================== EXAMPLE 2: Dashboard Stats with Skeleton ====================

class DashboardStatsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);

    return LoadingStateBuilder(
      state: statsAsync,
      loadingSkeleton: Row(
        children: [
          Expanded(child: StatCardSkeleton()),
          SizedBox(width: 12),
          Expanded(child: StatCardSkeleton()),
        ],
      ),
      builder: (stats) {
        return Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.local_fire_department,
                title: 'Streak',
                value: '${stats.currentStreak} days',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.emoji_events,
                title: 'Level',
                value: '${stats.level}',
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==================== EXAMPLE 3: Single Item with Skeleton ====================

class ProfileScreen extends ConsumerWidget {
  final String userId;

  const ProfileScreen({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));

    return DataLoadingStateBuilder(
      state: profileAsync,
      skeleton: const ProfileCardSkeleton(),
      notFoundMessage: 'Uživatel nenalezen',
      builder: (profile) {
        return ProfileCard(profile: profile);
      },
    );
  }
}

// ==================== EXAMPLE 4: Pull to Refresh with Skeleton ====================

class JournalEntriesScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalEntriesProvider);

    return RefreshableLoadingState(
      state: entriesAsync,
      onRefresh: () => ref.refresh(journalEntriesProvider.future),
      loadingSkeleton: SkeletonList(
        skeletonItem: const JournalEntrySkeleton(),
        itemCount: 5,
      ),
      emptyMessage: 'Zatím žádné záznamy',
      builder: (entries) {
        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            return JournalEntryCard(entry: entries[index]);
          },
        );
      },
    );
  }
}

// ==================== EXAMPLE 5: Grid with Skeleton ====================

class StrainBrowserScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strainsAsync = ref.watch(strainsProvider);

    return LoadingStateBuilder(
      state: strainsAsync,
      loadingSkeleton: SkeletonGrid(
        skeletonItem: const GridItemSkeleton(),
        itemCount: 6,
        crossAxisCount: 2,
      ),
      emptyMessage: 'Žádné strains k zobrazení',
      builder: (strains) {
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: strains.length,
          itemBuilder: (context, index) {
            return StrainCard(strain: strains[index]);
          },
        );
      },
    );
  }
}

// ==================== EXAMPLE 6: Custom Empty State ====================

class NotificationsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return ListLoadingStateBuilder(
      state: notificationsAsync,
      itemSkeleton: const ListItemSkeleton(showTrailing: false),
      emptyWidget: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              'Žádné notifikace',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Zde se budou objevovat důležité zprávy',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
      builder: (notifications) {
        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return NotificationTile(notification: notifications[index]);
          },
        );
      },
    );
  }
}

// ==================== EXAMPLE 7: Complex Dashboard Layout ====================

class ComplexDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Stats section with skeleton
        Consumer(
          builder: (context, ref, child) {
            final statsAsync = ref.watch(dashboardStatsProvider);
            return LoadingStateBuilder(
              state: statsAsync,
              loadingSkeleton: Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: i > 0 ? 12 : 0),
                      child: StatCardSkeleton(),
                    ),
                  ),
                ),
              ),
              builder: (stats) => DashboardStatsRow(stats: stats),
            );
          },
        ),

        SizedBox(height: 24),

        // Challenges section with skeleton
        Text(
          'Active Challenges',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Consumer(
          builder: (context, ref, child) {
            final challengesAsync = ref.watch(activeChallengesProvider);
            return LoadingStateBuilder(
              state: challengesAsync,
              loadingSkeleton: SkeletonList(
                skeletonItem: const ProgressCardSkeleton(),
                itemCount: 3,
              ),
              builder: (challenges) {
                return Column(
                  children: challenges
                      .map((c) => ChallengeProgressCard(challenge: c))
                      .toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// ==================== BEST PRACTICES ====================

/*
✅ DO:
- Use skeleton widgets that match the actual content layout
- Provide meaningful empty messages
- Handle error states gracefully
- Use pull-to-refresh for list screens
- Keep skeleton item count reasonable (3-5 items)

❌ DON'T:
- Show generic CircularProgressIndicator for lists
- Ignore empty states
- Skip error handling
- Use too many skeleton items (causes UI jank)
- Mix skeleton styles (be consistent)

💡 TIPS:
- Skeleton duration matches data fetch time (~1-2 seconds)
- Use lighter skeletons for secondary content
- Test with slow network to verify UX
- Combine with haptic feedback for better feel
*/
*/
