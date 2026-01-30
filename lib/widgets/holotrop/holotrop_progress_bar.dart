import 'package:flutter/material.dart';
import '../../models/holotrop_state_model.dart';
import '../../theme/holotrop_colors.dart';

/// Indikator prubehu sekci Holotrop
class HolotropProgressBar extends StatelessWidget {
  final HolotropSection currentSection;

  const HolotropProgressBar({
    super.key,
    required this.currentSection,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: HolotropSection.values.map((section) {
        final isActive = section == currentSection;
        final isPast = section.index < currentSection.index;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive
                  ? HolotropColors.accent
                  : isPast
                      ? HolotropColors.accent.withAlpha(120)
                      : HolotropColors.surface,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: HolotropColors.accentGlow,
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
