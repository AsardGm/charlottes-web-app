import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Řádek se statistikami profilu
///
/// Zobrazuje počet příspěvků, sledujících a sledovaných
/// v horizontálním rozložení s oddělovači.
class ProfileStatsRow extends StatelessWidget {
  /// Počet příspěvků
  final int postCount;

  /// Počet sledujících
  final int followerCount;

  /// Počet sledovaných
  final int followingCount;

  const ProfileStatsRow({
    super.key,
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(8),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(count: postCount, label: 'Příspěvky'),
          _buildDivider(),
          _StatItem(count: followerCount, label: 'Sledující'),
          _buildDivider(),
          _StatItem(count: followingCount, label: 'Sleduje'),
        ],
      ),
    );
  }

  /// Sestaví vertikální oddělovač
  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withAlpha(10),
    );
  }
}

/// Položka statistiky (číslo + popisek)
class _StatItem extends StatelessWidget {
  /// Hodnota statistiky
  final int count;

  /// Popisek statistiky
  final String label;

  const _StatItem({
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hodnota
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        // Popisek
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
