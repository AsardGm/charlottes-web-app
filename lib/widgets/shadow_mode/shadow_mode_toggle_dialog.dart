import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/shadow_mode_model.dart';
import '../../providers/shadow_mode_provider.dart';
import '../../theme/theme.dart';
import '../common/ripple_button.dart';

/// Dialog pro aktivaci/deaktivaci Shadow Mode
class ShadowModeToggleDialog extends ConsumerStatefulWidget {
  final bool isCurrentlyActive;

  const ShadowModeToggleDialog({
    super.key,
    required this.isCurrentlyActive,
  });

  @override
  ConsumerState<ShadowModeToggleDialog> createState() =>
      _ShadowModeToggleDialogState();

  /// Show dialog
  static Future<void> show(BuildContext context, {required bool isActive}) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => ShadowModeToggleDialog(isCurrentlyActive: isActive),
    );
  }
}

class _ShadowModeToggleDialogState
    extends ConsumerState<ShadowModeToggleDialog> {
  ShadowModeReason? _selectedReason;

  @override
  Widget build(BuildContext context) {
    if (widget.isCurrentlyActive) {
      return _buildDeactivateDialog();
    } else {
      return _buildActivateDialog();
    }
  }

  Widget _buildDeactivateDialog() {
    final state = ref.watch(shadowModeStateProvider);

    return Dialog(
      backgroundColor: AppColors.functionalSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🕶️', style: TextStyle(fontSize: 32)),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            const Text(
              'Shadow Mode Aktivní',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            // Duration
            if (state.currentSessionDuration != null)
              Text(
                'Aktivní: ${_formatDuration(state.currentSessionDuration!)}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

            const SizedBox(height: 8),

            // Reason
            if (state.reason != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.reason!.emoji} ${state.reason!.displayName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.accent,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            Text(
              'Chceš se vrátit do normálního režimu?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Zůstat',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: 'Deaktivovat',
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await ref
                          .read(shadowModeStateProvider.notifier)
                          .deactivate();
                      if (context.mounted) {
                        navigator.pop();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivateDialog() {
    final service = ref.read(shadowModeServiceProvider);

    return Dialog(
      backgroundColor: AppColors.functionalSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🕶️', style: TextStyle(fontSize: 32)),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            const Text(
              'Shadow Mode™',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Offline. Bez lidí. Bez tlaku.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 8),

            // Recommended time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                service.getRecommendedTime(),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.accent,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Reason selection
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Proč aktivuješ Shadow Mode?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Reason buttons
            ...ShadowModeReason.values.map((reason) {
              final isSelected = _selectedReason == reason;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedReason = reason;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.functionalBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.functionalBorder.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          reason.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          reason.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(Icons.check_circle, color: AppColors.accent, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Zrušit',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: 'Aktivovat',
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await ref.read(shadowModeStateProvider.notifier).activate(
                            reason: _selectedReason,
                          );
                      if (context.mounted) {
                        navigator.pop();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
