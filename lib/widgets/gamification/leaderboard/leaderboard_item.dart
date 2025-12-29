import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../models/rank_model.dart';
import '../rank_badge_widget.dart';
import 'position_badge.dart';

/// Polozka v zebricku
class LeaderboardItem extends StatelessWidget {
  /// Data polozky (Map z API)
  final Map<String, dynamic> entry;

  /// Pozice v zebricku
  final int position;

  const LeaderboardItem({
    super.key,
    required this.entry,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final totalXp = entry['total_xp'] as int? ?? 0;
    final username = entry['username'] as String? ?? 'Anonym';
    final avatarUrl = entry['avatar_url'] as String?;
    final rank = SpiderRanks.getRankByXp(totalXp);
    final isTopThree = position <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTopThree
            ? _getPositionColor(position).withAlpha(20)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopThree
              ? _getPositionColor(position).withAlpha(100)
              : Colors.white.withAlpha(10),
          width: isTopThree ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Pozice
          PositionBadge(position: position),
          const SizedBox(width: 12),

          // Avatar s rankem
          _AvatarWithRank(
            avatarUrl: avatarUrl,
            username: username,
            rank: rank,
          ),
          const SizedBox(width: 12),

          // Jmeno a rank
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rank.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: rank.color,
                  ),
                ),
              ],
            ),
          ),

          // XP
          XpDisplay(xp: totalXp),
        ],
      ),
    );
  }

  Color _getPositionColor(int pos) {
    switch (pos) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textMuted;
    }
  }
}

/// Avatar s rank badge
class _AvatarWithRank extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final SpiderRank rank;

  const _AvatarWithRank({
    this.avatarUrl,
    required this.username,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.surfaceLight,
          backgroundImage: avatarUrl != null
              ? NetworkImage(avatarUrl!)
              : null,
          child: avatarUrl == null
              ? Text(
                  username[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: RankBadgeWidget(
              rank: rank,
              size: 20,
              showName: false,
            ),
          ),
        ),
      ],
    );
  }
}

/// Zobrazeni XP
class XpDisplay extends StatelessWidget {
  final int xp;

  const XpDisplay({
    super.key,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Icon(
              Icons.star,
              size: 16,
              color: AppColors.warning,
            ),
            const SizedBox(width: 4),
            Text(
              _formatXp(xp),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Text(
          'XP',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000000) {
      return '${(xp / 1000000).toStringAsFixed(1)}M';
    } else if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}K';
    }
    return xp.toString();
  }
}
