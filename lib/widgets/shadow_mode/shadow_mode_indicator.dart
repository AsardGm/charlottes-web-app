import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/shadow_mode_provider.dart';
import '../../theme/theme.dart';
import 'shadow_mode_toggle_dialog.dart';

/// Indikátor Shadow Mode v headeru
/// Zobrazí se pouze když je Shadow Mode aktivní
class ShadowModeIndicator extends ConsumerWidget {
  const ShadowModeIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(isShadowModeActiveProvider);

    if (!isActive) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        ShadowModeToggleDialog.show(context, isActive: true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.functionalSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🕶️',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              'Shadow Mode',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner zobrazující se v top části screenu
class ShadowModeBanner extends ConsumerWidget {
  const ShadowModeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(isShadowModeActiveProvider);

    if (!isActive) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Text('🕶️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Shadow Mode aktivní - Offline režim',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ShadowModeToggleDialog.show(context, isActive: true);
            },
            child: Text(
              'Deaktivovat',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
