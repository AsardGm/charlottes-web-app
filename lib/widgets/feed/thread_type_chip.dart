import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Chip pro výběr typu vlákna v hlavičce feedu
///
/// Zobrazuje emoji a název typu vlákna s animovaným
/// zvýrazněním při výběru.
class ThreadTypeChip extends StatelessWidget {
  /// Textový popisek (název typu)
  final String label;

  /// Emoji ikona typu
  final String emoji;

  /// Barva typu (použitá pro zvýraznění)
  final Color color;

  /// Je tento typ aktuálně vybrán?
  final bool isSelected;

  /// Callback při kliknutí
  final VoidCallback onTap;

  const ThreadTypeChip({
    super.key,
    required this.label,
    required this.emoji,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          // Gradient pozadí pro vybraný stav
          gradient: isSelected
              ? LinearGradient(
                  colors: [color.withAlpha(40), color.withAlpha(20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color.withAlpha(150) : Colors.white.withAlpha(8),
            width: isSelected ? 1.5 : 1,
          ),
          // Stín pro vybraný stav
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji ikona
            Text(
              emoji,
              style: TextStyle(
                fontSize: 16,
                shadows: isSelected
                    ? [Shadow(color: color.withAlpha(100), blurRadius: 8)]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            // Název typu
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : AppColors.textSecondary,
                letterSpacing: isSelected ? 0.3 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
