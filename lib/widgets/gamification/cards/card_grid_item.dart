import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../models/strain_card_model.dart';

/// Polozka karty v gridu
class CardGridItem extends StatelessWidget {
  /// Karta k zobrazeni
  final StrainCard card;

  /// Callback pri kliknuti
  final VoidCallback onTap;

  const CardGridItem({
    super.key,
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: card.rarity.color.withAlpha(100),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: card.rarity.color.withAlpha(30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header s raritou
            _CardHeader(card: card),

            // Obrazek
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: card.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          card.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => CardPlaceholder(
                            emoji: _getStrainEmoji(card.type),
                          ),
                        ),
                      )
                    : CardPlaceholder(
                        emoji: _getStrainEmoji(card.type),
                      ),
              ),
            ),

            // Nazev a statistiky
            _CardFooter(card: card),
          ],
        ),
      ),
    );
  }

  String _getStrainEmoji(StrainType type) {
    switch (type) {
      case StrainType.indica:
        return '🌙';
      case StrainType.sativa:
        return '☀️';
      case StrainType.hybrid:
        return '🌿';
    }
  }
}

/// Header karty s raritou a typem
class _CardHeader extends StatelessWidget {
  final StrainCard card;

  const _CardHeader({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: card.rarity.color.withAlpha(30),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            card.rarity.nameCz,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: card.rarity.color,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: card.type.color.withAlpha(50),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              card.type.displayName,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: card.type.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Footer karty s nazvem a statistikami
class _CardFooter extends StatelessWidget {
  final StrainCard card;

  const _CardFooter({required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          Text(
            card.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MiniStat(label: 'THC', value: '${card.thcPercent}%'),
              const SizedBox(width: 8),
              MiniStat(label: 'CBD', value: '${card.cbdPercent}%'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mala statistika (THC/CBD)
class MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const MiniStat({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder pro kartu bez obrazku
class CardPlaceholder extends StatelessWidget {
  final String emoji;

  const CardPlaceholder({
    super.key,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 48),
      ),
    );
  }
}
