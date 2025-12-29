import 'package:flutter/material.dart';
import '../../models/rank_model.dart';
import '../../theme/theme.dart';

/// Widget pro zobrazeni Spider Rank badge
class RankBadgeWidget extends StatelessWidget {
  final SpiderRank rank;
  final bool showName;
  final bool showProgress;
  final int? currentXp;
  final double size;

  const RankBadgeWidget({
    super.key,
    required this.rank,
    this.showName = true,
    this.showProgress = false,
    this.currentXp,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: rank.color.withAlpha(30),
            border: Border.all(
              color: rank.color,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: rank.color.withAlpha(50),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              rank.emoji,
              style: TextStyle(fontSize: size * 0.5),
            ),
          ),
        ),

        if (showName) ...[
          const SizedBox(height: 4),
          Text(
            rank.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: rank.color,
            ),
          ),
        ],

        if (showProgress && currentXp != null) ...[
          const SizedBox(height: 8),
          _XpProgressBar(rank: rank, currentXp: currentXp!),
        ],
      ],
    );
  }
}

/// XP progress bar
class _XpProgressBar extends StatelessWidget {
  final SpiderRank rank;
  final int currentXp;

  const _XpProgressBar({
    required this.rank,
    required this.currentXp,
  });

  @override
  Widget build(BuildContext context) {
    final progress = rank.getProgress(currentXp);
    final xpToNext = rank.xpToNextRank(currentXp);
    final nextRank = SpiderRanks.getNextRank(rank);

    return Column(
      children: [
        // Progress bar
        Container(
          height: 8,
          width: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: AppColors.surfaceLight,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    rank.color,
                    nextRank?.color ?? rank.color,
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // XP text
        Text(
          nextRank != null
              ? '$currentXp / ${rank.maxXp} XP'
              : 'MAX LEVEL',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),

        if (xpToNext > 0 && nextRank != null)
          Text(
            '$xpToNext XP do ${nextRank.name}',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }
}

/// Kompaktni rank indicator pro profil
class CompactRankIndicator extends StatelessWidget {
  final SpiderRank rank;
  final int currentXp;

  const CompactRankIndicator({
    super.key,
    required this.rank,
    required this.currentXp,
  });

  @override
  Widget build(BuildContext context) {
    final progress = rank.getProgress(currentXp);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: rank.color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: rank.color.withAlpha(50),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rank.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rank.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: rank.color,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation(rank.color),
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            '$currentXp XP',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Level up celebration dialog
class LevelUpDialog extends StatelessWidget {
  final SpiderRank newRank;

  const LevelUpDialog({
    super.key,
    required this.newRank,
  });

  static Future<void> show(BuildContext context, SpiderRank newRank) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LevelUpDialog(newRank: newRank),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: newRank.color.withAlpha(100),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: newRank.color.withAlpha(50),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Confetti / celebration icon
            Text(
              '🎉',
              style: const TextStyle(fontSize: 48),
            ),

            const SizedBox(height: 16),

            Text(
              'LEVEL UP!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: newRank.color,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 24),

            // New rank badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    newRank.color.withAlpha(50),
                    newRank.color.withAlpha(100),
                  ],
                ),
                border: Border.all(
                  color: newRank.color,
                  width: 3,
                ),
              ),
              child: Text(
                newRank.emoji,
                style: const TextStyle(fontSize: 64),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              newRank.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              newRank.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            // New permissions
            if (newRank.permissions.isNotEmpty) ...[
              Text(
                'Nove schopnosti:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: _getNewPermissions().map((p) {
                  return Chip(
                    label: Text(
                      _getPermissionName(p),
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: newRank.color.withAlpha(30),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // Close button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: newRank.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Super!'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getNewPermissions() {
    // Porovnej s predchozim rankem
    final currentIndex = SpiderRanks.all.indexOf(newRank);
    if (currentIndex <= 0) return newRank.permissions;

    final previousRank = SpiderRanks.all[currentIndex - 1];
    return newRank.permissions
        .where((p) => !previousRank.permissions.contains(p))
        .toList();
  }

  String _getPermissionName(String permission) {
    switch (permission) {
      case RankPermissions.view:
        return 'Prohlizeni';
      case RankPermissions.like:
        return 'Lajkovani';
      case RankPermissions.comment:
        return 'Komentovani';
      case RankPermissions.uploadPhoto:
        return 'Nahravani fotek';
      case RankPermissions.createThread:
        return 'Tvorba vlaken';
      case RankPermissions.accessSecretDrops:
        return 'Tajne dropy';
      case RankPermissions.moderate:
        return 'Moderovani';
      case RankPermissions.veto:
        return 'Pravo veta';
      default:
        return permission;
    }
  }
}
