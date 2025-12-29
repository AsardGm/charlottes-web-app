import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../models/strain_card_model.dart';

/// Bar se statistikami kolekce karet
class CollectionStatsBar extends StatelessWidget {
  /// Celkovy pocet karet v systemu
  final int total;

  /// Pocet sebranych karet
  final int collected;

  /// Pocet karet podle rarity
  final Map<CardRarity, int> byRarity;

  const CollectionStatsBar({
    super.key,
    required this.total,
    required this.collected,
    required this.byRarity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(30),
            AppColors.primary.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withAlpha(50),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatColumn(
            label: 'Celkem',
            value: '$collected/$total',
            icon: Icons.collections,
          ),
          _StatColumn(
            label: 'Common',
            value: (byRarity[CardRarity.common] ?? 0).toString(),
            color: CardRarity.common.color,
          ),
          _StatColumn(
            label: 'Rare',
            value: (byRarity[CardRarity.rare] ?? 0).toString(),
            color: CardRarity.rare.color,
          ),
          _StatColumn(
            label: 'Exotic',
            value: (byRarity[CardRarity.exotic] ?? 0).toString(),
            color: CardRarity.exotic.color,
          ),
          _StatColumn(
            label: 'Legend',
            value: (byRarity[CardRarity.legend] ?? 0).toString(),
            color: CardRarity.legend.color,
          ),
        ],
      ),
    );
  }
}

/// Sloupec statistiky
class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  const _StatColumn({
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (icon != null)
          Icon(icon, color: AppColors.primary, size: 20)
        else
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(height: 4),
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
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
