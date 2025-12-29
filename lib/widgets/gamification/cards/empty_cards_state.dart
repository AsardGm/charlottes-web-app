import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../models/strain_card_model.dart';

/// Prazdny stav pro kolekci karet
class EmptyCardsState extends StatelessWidget {
  /// Volitelna rarita pro zobrazeni specificke zpravy
  final CardRarity? rarity;

  const EmptyCardsState({
    super.key,
    this.rarity,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.collections_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            rarity == null
                ? 'Zatim nemas zadne karty'
                : 'Nemas zadne ${rarity!.nameCz} karty',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pln ukoly a ziskej nove karty!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
