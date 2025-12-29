import 'package:flutter/material.dart' hide Badge;
import '../../../models/badge_model.dart';
import '../../../theme/theme.dart';

/// Widget pro zobrazeni jednoho odznaku
class BadgeItem extends StatelessWidget {
  final Badge badge;
  final bool isEarned;
  final bool isNew;
  final bool isFeatured;
  final double size;
  final VoidCallback? onTap;

  const BadgeItem({
    super.key,
    required this.badge,
    this.isEarned = false,
    this.isNew = false,
    this.isFeatured = false,
    this.size = 60,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Hlavni odznak
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isEarned
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: badge.rarity.gradientColors,
                    )
                  : null,
              color: isEarned ? null : AppColors.surface,
              border: Border.all(
                color: isEarned
                    ? badge.rarity.color
                    : AppColors.textMuted.withAlpha(50),
                width: 2,
              ),
              boxShadow: isEarned
                  ? [
                      BoxShadow(
                        color: badge.rarity.color.withAlpha(60),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                badge.emoji,
                style: TextStyle(
                  fontSize: size * 0.45,
                  color: isEarned ? null : AppColors.textMuted.withAlpha(100),
                ),
              ),
            ),
          ),

          // New badge indicator
          if (isNew)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.background,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_awesome,
                    size: size * 0.15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Featured star
          if (isFeatured)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.background,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.star,
                    size: size * 0.15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Lock icon for unearned secret badges
          if (!isEarned && badge.isSecret)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background.withAlpha(180),
                ),
                child: Center(
                  child: Icon(
                    Icons.lock,
                    size: size * 0.35,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Maly badge chip pro zobrazeni v profilu
class BadgeChip extends StatelessWidget {
  final Badge badge;
  final bool showName;

  const BadgeChip({
    super.key,
    required this.badge,
    this.showName = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: badge.rarity.gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: badge.rarity.color.withAlpha(40),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badge.emoji,
            style: const TextStyle(fontSize: 14),
          ),
          if (showName) ...[
            const SizedBox(width: 6),
            Text(
              badge.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
