import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../providers/gamification_provider.dart';
import '../../models/rank_model.dart';
import '../../widgets/gamification/gamification.dart';

/// Hlavni obrazovka gamifikace
class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xpAsync = ref.watch(userXpProvider);
    final rankAsync = ref.watch(userRankProvider);
    final questsAsync = ref.watch(dailyQuestsProvider);
    final websAsync = ref.watch(userWebsProvider);
    final positionAsync = ref.watch(leaderboardPositionProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header s rankem
          SliverToBoxAdapter(
            child: _GamificationHeader(
              xpAsync: xpAsync,
              rankAsync: rankAsync,
              websAsync: websAsync,
              positionAsync: positionAsync,
            ),
          ),

          // Obsah
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Denni ukoly
                questsAsync.when(
                  data: (quests) => DailyQuestsSection(
                    quests: quests,
                    onQuestTap: (quest) {
                      // Navigace na relevantni cast aplikace
                      _navigateToQuest(context, quest.type);
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Chyba: $e'),
                ),

                const SizedBox(height: 24),

                // Sekce pro navigaci
                _QuickActionsSection(),

                const SizedBox(height: 24),

                // Leaderboard preview
                _LeaderboardPreview(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToQuest(BuildContext context, questType) {
    // Navigace podle typu questu
    switch (questType.toString()) {
      case 'QuestType.like':
      case 'QuestType.comment':
        context.go('/');
        break;
      case 'QuestType.uploadPhoto':
        context.go('/create-post');
        break;
      case 'QuestType.visitProfile':
        context.go('/search');
        break;
      case 'QuestType.collectCard':
        context.go('/cards');
        break;
      default:
        break;
    }
  }
}

/// Header s XP a rankem
class _GamificationHeader extends StatelessWidget {
  final AsyncValue<int> xpAsync;
  final AsyncValue<SpiderRank> rankAsync;
  final AsyncValue<int> websAsync;
  final AsyncValue<int> positionAsync;

  const _GamificationHeader({
    required this.xpAsync,
    required this.rankAsync,
    required this.websAsync,
    required this.positionAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withAlpha(40),
            AppColors.background,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            context.go('/');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                      Text(
                        'Spider Hub',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  // Leaderboard position
                  positionAsync.when(
                    data: (position) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(50),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.leaderboard,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '#$position',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Rank card
              rankAsync.when(
                data: (rank) => xpAsync.when(
                  data: (xp) => _RankCard(rank: rank, xp: xp),
                  loading: () => _RankCard(rank: rank, xp: 0),
                  error: (_, _) => _RankCard(rank: rank, xp: 0),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, _) => const Text('Chyba'),
              ),

              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.star,
                      label: 'XP',
                      value: xpAsync.when(
                        data: (xp) => _formatNumber(xp),
                        loading: () => '...',
                        error: (_, _) => '0',
                      ),
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.hub,
                      label: 'Vlakna',
                      value: websAsync.when(
                        data: (webs) => _formatNumber(webs),
                        loading: () => '...',
                        error: (_, _) => '0',
                      ),
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toString();
  }
}

/// Karta s aktualni hodnosti
class _RankCard extends StatelessWidget {
  final SpiderRank rank;
  final int xp;

  const _RankCard({
    required this.rank,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    final nextRank = SpiderRanks.getNextRank(rank);
    final progress = rank.getProgress(xp);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: rank.color.withAlpha(50),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: rank.color.withAlpha(20),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rank.color.withAlpha(30),
              border: Border.all(
                color: rank.color,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                rank.emoji,
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: rank.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rank.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation(rank.color),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$xp XP',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (nextRank != null)
                      Text(
                        '${rank.xpToNextRank(xp)} XP do ${nextRank.name}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat karta
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(30),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sekce s rychlymi akcemi
class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prozkoumej',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.style,
                title: 'Karty',
                subtitle: 'Sbirka strainu',
                color: Colors.purple,
                onTap: () => context.go('/cards'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.leaderboard,
                title: 'Zebricek',
                subtitle: 'Top uzivatele',
                color: Colors.orange,
                onTap: () => context.go('/leaderboard'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.emoji_events,
                title: 'Hodnosti',
                subtitle: 'Vsechny ranky',
                color: Colors.amber,
                onTap: () => _showRanksDialog(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.shopping_bag,
                title: 'Merch Drop',
                subtitle: 'Exkluzivni',
                color: Colors.red,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pripravujeme...')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showRanksDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spider Ranks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...SpiderRanks.all.map((rank) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rank.color.withAlpha(30),
                          border: Border.all(color: rank.color, width: 2),
                        ),
                        child: Center(
                          child: Text(rank.emoji, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rank.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: rank.color,
                              ),
                            ),
                            Text(
                              '${rank.minXp}+ XP',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withAlpha(50),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview leaderboardu
class _LeaderboardPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top hráči',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/leaderboard'),
              child: const Text('Zobrazit vse'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        leaderboardAsync.when(
          data: (users) => Column(
            children: users.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              final rank = user['rank'] as SpiderRank;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: index == 0
                      ? Colors.amber.withAlpha(20)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: index == 0
                        ? Colors.amber.withAlpha(50)
                        : AppColors.surfaceLight,
                  ),
                ),
                child: Row(
                  children: [
                    // Position
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getPositionColor(index),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Avatar
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: user['avatar_url'] != null
                          ? NetworkImage(user['avatar_url'])
                          : null,
                      child: user['avatar_url'] == null
                          ? Text(
                              (user['username'] as String)[0].toUpperCase(),
                              style: const TextStyle(fontSize: 14),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['username'] ?? 'Uzivatel',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              Text(
                                rank.emoji,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rank.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: rank.color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // XP
                    Text(
                      '${user['xp']} XP',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Text('Chyba pri nacitani'),
        ),
      ],
    );
  }

  Color _getPositionColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return AppColors.textMuted;
    }
  }
}
