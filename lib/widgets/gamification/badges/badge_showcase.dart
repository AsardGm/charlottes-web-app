import 'package:flutter/material.dart' hide Badge;
import '../../../models/badge_model.dart';
import '../../../theme/theme.dart';
import 'badge_item.dart';

/// Widget pro zobrazeni featured odznaku v profilu
class BadgeShowcase extends StatelessWidget {
  final List<UserBadge> badges;
  final VoidCallback? onViewAll;

  const BadgeShowcase({
    super.key,
    required this.badges,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Odznaky',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: Text(
                    'Zobrazit vse',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Badges row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: badges.take(3).map((userBadge) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    BadgeItem(
                      badge: userBadge.badge,
                      isEarned: true,
                      isFeatured: true,
                      size: 50,
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 70,
                      child: Text(
                        userBadge.badge.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Horizontal scroll list odznaku
class BadgeHorizontalList extends StatelessWidget {
  final List<UserBadge> badges;
  final Function(UserBadge)? onBadgeTap;

  const BadgeHorizontalList({
    super.key,
    required this.badges,
    this.onBadgeTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final userBadge = badges[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                BadgeItem(
                  badge: userBadge.badge,
                  isEarned: true,
                  isNew: userBadge.isNew,
                  isFeatured: userBadge.isFeatured,
                  size: 56,
                  onTap: onBadgeTap != null
                      ? () => onBadgeTap!(userBadge)
                      : null,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 60,
                  child: Text(
                    userBadge.badge.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
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
  }
}

/// Stats bar pro odznaky
class BadgeStatsBar extends StatelessWidget {
  final int total;
  final int earned;
  final Map<BadgeRarity, int> byRarity;

  const BadgeStatsBar({
    super.key,
    required this.total,
    required this.earned,
    this.byRarity = const {},
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? earned / total : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withAlpha(20),
            AppColors.primaryLight.withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withAlpha(30),
        ),
      ),
      child: Column(
        children: [
          // Main progress
          Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Kolekce odznaku',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$earned / $total',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.textMuted.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Rarity breakdown
          if (byRarity.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: BadgeRarity.values.map((rarity) {
                final count = byRarity[rarity] ?? 0;
                return _RarityCounter(
                  rarity: rarity,
                  count: count,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _RarityCounter extends StatelessWidget {
  final BadgeRarity rarity;
  final int count;

  const _RarityCounter({
    required this.rarity,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: rarity.gradientColors,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          rarity.name,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
