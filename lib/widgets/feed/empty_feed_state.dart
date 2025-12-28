import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';

/// Prázdný stav feedu
///
/// Zobrazuje se když nejsou žádné příspěvky.
/// Obsahuje ilustraci, text a tlačítko pro vytvoření příspěvku.
class EmptyFeedState extends StatelessWidget {
  const EmptyFeedState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animovaný kontejner s ikonou
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withAlpha(20),
                  AppColors.primary.withAlpha(5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withAlpha(30),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.edit_note_rounded,
              size: 48,
              color: AppColors.primary.withAlpha(180),
            ),
          ),

          const SizedBox(height: 24),

          // Nadpis
          Text(
            'Zatím žádné příspěvky',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          // Podtext
          Text(
            'Buď první, kdo něco napíše!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),

          const SizedBox(height: 24),

          // Tlačítko pro vytvoření příspěvku
          FilledButton.icon(
            onPressed: () => context.go('/create-post'),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Vytvořit příspěvek'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
