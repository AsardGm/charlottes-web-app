import 'package:flutter/material.dart';
import '../../theme/holotrop_colors.dart';

/// Karta jednoho kroku uzemneni s cyberpunk stylem
class GroundingStepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onDone;

  const GroundingStepCard({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    this.isActive = false,
    this.isCompleted = false,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? HolotropColors.accent
        : isActive
            ? HolotropColors.accentSoft
            : HolotropColors.textMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? HolotropColors.surface
            : HolotropColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? HolotropColors.accent.withAlpha(100)
              : isCompleted
                  ? HolotropColors.accent.withAlpha(60)
                  : HolotropColors.surface.withAlpha(80),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: HolotropColors.accentGlow.withAlpha(40),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cislo kroku
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(isActive ? 40 : 20),
              border: Border.all(
                color: color.withAlpha(isActive ? 120 : 60),
                width: 1.5,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? Icon(Icons.check, color: color, size: 18)
                  : Text(
                      '$stepNumber',
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Obsah
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isActive || isCompleted
                              ? HolotropColors.textPrimary
                              : HolotropColors.textMuted,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: isActive
                        ? HolotropColors.textSecondary
                        : HolotropColors.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (isActive && onDone != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onDone,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: HolotropColors.accent,
                        side: BorderSide(
                          color: HolotropColors.accent.withAlpha(120),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'HOTOVO',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
