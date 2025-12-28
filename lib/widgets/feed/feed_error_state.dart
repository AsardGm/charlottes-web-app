import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Widget pro zobrazení chybového stavu feedu
///
/// Zobrazuje se když dojde k chybě při načítání příspěvků.
/// Obsahuje ikonu, popis chyby a tlačítko pro opakování.
class FeedErrorState extends StatelessWidget {
  /// Chyba která nastala
  final Object error;

  /// Callback pro opakování načítání
  final VoidCallback onRetry;

  const FeedErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikona chyby
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),

            const SizedBox(height: 24),

            // Nadpis
            Text(
              'Něco se pokazilo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // Popis chyby
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),

            const SizedBox(height: 24),

            // Tlačítko pro opakování
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Zkusit znovu'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
