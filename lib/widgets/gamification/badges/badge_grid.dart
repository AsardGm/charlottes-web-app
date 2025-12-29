import 'package:flutter/material.dart' hide Badge;
import '../../../models/badge_model.dart';
import '../../../theme/theme.dart';
import 'badge_item.dart';

/// Grid pro zobrazeni kolekce odznaku
class BadgeGrid extends StatelessWidget {
  final List<Badge> badges;
  final Set<String> earnedBadgeIds;
  final Set<String> newBadgeIds;
  final Set<String> featuredBadgeIds;
  final Function(Badge)? onBadgeTap;
  final int crossAxisCount;

  const BadgeGrid({
    super.key,
    required this.badges,
    this.earnedBadgeIds = const {},
    this.newBadgeIds = const {},
    this.featuredBadgeIds = const {},
    this.onBadgeTap,
    this.crossAxisCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final isEarned = earnedBadgeIds.contains(badge.id);
        final isNew = newBadgeIds.contains(badge.id);
        final isFeatured = featuredBadgeIds.contains(badge.id);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BadgeItem(
              badge: badge,
              isEarned: isEarned,
              isNew: isNew,
              isFeatured: isFeatured,
              size: 56,
              onTap: onBadgeTap != null ? () => onBadgeTap!(badge) : null,
            ),
            const SizedBox(height: 6),
            Text(
              isEarned || !badge.isSecret ? badge.name : '???',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isEarned ? AppColors.textPrimary : AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }
}

/// Sekce odznaku podle kategorie
class BadgeCategorySection extends StatelessWidget {
  final BadgeCategory category;
  final List<Badge> badges;
  final Set<String> earnedBadgeIds;
  final Set<String> newBadgeIds;
  final Set<String> featuredBadgeIds;
  final Function(Badge)? onBadgeTap;

  const BadgeCategorySection({
    super.key,
    required this.category,
    required this.badges,
    this.earnedBadgeIds = const {},
    this.newBadgeIds = const {},
    this.featuredBadgeIds = const {},
    this.onBadgeTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryBadges = badges.where((b) => b.category == category).toList();
    if (categoryBadges.isEmpty) return const SizedBox.shrink();

    final earnedCount = categoryBadges.where((b) => earnedBadgeIds.contains(b.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                category.icon,
                color: category.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: category.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$earnedCount/${categoryBadges.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: category.color,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grid
        BadgeGrid(
          badges: categoryBadges,
          earnedBadgeIds: earnedBadgeIds,
          newBadgeIds: newBadgeIds,
          featuredBadgeIds: featuredBadgeIds,
          onBadgeTap: onBadgeTap,
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}
