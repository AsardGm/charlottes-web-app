import 'package:flutter/material.dart';
import '../../models/strain_card_model.dart';
import '../../theme/theme.dart';

/// Widget pro zobrazeni sberatelske karty strainu
class StrainCardWidget extends StatelessWidget {
  final StrainCard card;
  final bool isCollected;
  final VoidCallback? onTap;
  final bool showDetails;

  const StrainCardWidget({
    super.key,
    required this.card,
    this.isCollected = false,
    this.onTap,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isCollected
                ? card.rarity.gradientColors
                : [AppColors.surface, AppColors.surfaceLight],
          ),
          boxShadow: isCollected
              ? [
                  BoxShadow(
                    color: card.rarity.glowColor,
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : null,
          border: Border.all(
            color: isCollected
                ? card.rarity.color
                : AppColors.surfaceLight,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Card content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rarity badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: card.rarity.color.withAlpha(isCollected ? 50 : 30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          card.rarity.nameCz,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCollected
                                ? Colors.white
                                : card.rarity.color,
                          ),
                        ),
                      ),
                      // Strain type
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: card.type.color.withAlpha(50),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          card.type.displayName,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isCollected
                                ? Colors.white
                                : card.type.color,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Card image or placeholder
                  Center(
                    child: card.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              card.imageUrl!,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              color: isCollected ? null : Colors.grey,
                              colorBlendMode: isCollected ? null : BlendMode.saturation,
                            ),
                          )
                        : Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: isCollected
                                  ? Colors.white.withAlpha(30)
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.local_florist,
                              size: 40,
                              color: isCollected
                                  ? Colors.white.withAlpha(150)
                                  : AppColors.textMuted,
                            ),
                          ),
                  ),

                  const Spacer(),

                  // Name
                  Text(
                    card.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCollected ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // THC/CBD
                  Row(
                    children: [
                      _StatChip(
                        label: 'THC',
                        value: '${card.thcPercent}%',
                        isCollected: isCollected,
                      ),
                      const SizedBox(width: 6),
                      _StatChip(
                        label: 'CBD',
                        value: '${card.cbdPercent}%',
                        isCollected: isCollected,
                      ),
                    ],
                  ),

                  if (showDetails && card.cardNumber != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '#${card.cardNumber}/${card.totalCards}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isCollected
                            ? Colors.white.withAlpha(180)
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Lock overlay if not collected
            if (!isCollected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.black.withAlpha(100),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lock_outline,
                      color: Colors.white.withAlpha(100),
                      size: 32,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isCollected;

  const _StatChip({
    required this.label,
    required this.value,
    required this.isCollected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isCollected
            ? Colors.white.withAlpha(30)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isCollected
                  ? Colors.white.withAlpha(150)
                  : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isCollected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail karty v dialogu
class StrainCardDetailDialog extends StatelessWidget {
  final StrainCard card;
  final bool isCollected;
  final VoidCallback? onCollect;

  const StrainCardDetailDialog({
    super.key,
    required this.card,
    this.isCollected = false,
    this.onCollect,
  });

  static Future<void> show(
    BuildContext context,
    StrainCard card, {
    bool isCollected = false,
    VoidCallback? onCollect,
  }) {
    return showDialog(
      context: context,
      builder: (context) => StrainCardDetailDialog(
        card: card,
        isCollected: isCollected,
        onCollect: onCollect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: card.rarity.gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: card.rarity.glowColor,
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rarity & Type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    card.rarity.nameCz.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: card.type.color.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    card.type.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Image
            Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: card.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        card.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.local_florist,
                      size: 80,
                      color: Colors.white54,
                    ),
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              card.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              card.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withAlpha(200),
              ),
            ),

            const SizedBox(height: 16),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DetailStat(label: 'THC', value: '${card.thcPercent}%'),
                const SizedBox(width: 24),
                _DetailStat(label: 'CBD', value: '${card.cbdPercent}%'),
              ],
            ),

            const SizedBox(height: 16),

            // Effects
            if (card.effects.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: card.effects.map((effect) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      effect,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Card number
            if (card.cardNumber != null)
              Text(
                '#${card.cardNumber} z ${card.totalCards}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withAlpha(150),
                ),
              ),

            const SizedBox(height: 20),

            // Close / Collect button
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Zavrit',
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                      ),
                    ),
                  ),
                ),
                if (!isCollected && onCollect != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onCollect!();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: card.rarity.color,
                      ),
                      child: const Text('Sebrat'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;

  const _DetailStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withAlpha(150),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
