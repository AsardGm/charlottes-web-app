import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme.dart';
import '../../models/consumption_model.dart';
import '../../providers/consumption_provider.dart';

/// Quick post-consumption check (15s)
class PostCheckScreen extends ConsumerStatefulWidget {
  final String consumptionLogId;

  const PostCheckScreen({
    super.key,
    required this.consumptionLogId,
  });

  @override
  ConsumerState<PostCheckScreen> createState() => _PostCheckScreenState();
}

class _PostCheckScreenState extends ConsumerState<PostCheckScreen> {
  // Core metrics (required)
  double _focus = 5.0;
  double _mood = 5.0;
  double _energy = 5.0;
  double _anxiety = 0.0;

  // Body state
  BodyState _bodyState = BodyState.relaxed;

  // Optional metrics
  double? _creativity;
  double? _painRelief;
  AppetiteChange? _appetiteChange;

  bool _showOptional = false;
  bool _isSaving = false;

  Future<void> _saveCheck() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      // Create post-consumption check
      final check = PostConsumptionCheck(
        consumptionLogId: widget.consumptionLogId,
        userId: userId,
        checkTimestamp: DateTime.now(),
        focusScore: _focus.toInt(),
        moodScore: _mood.toInt(),
        energyScore: _energy.toInt(),
        anxietyLevel: _anxiety.toInt(),
        bodyState: _bodyState,
        creativityScore: _creativity?.toInt(),
        painRelief: _painRelief?.toInt(),
        appetiteChange: _appetiteChange,
      );

      // Save via provider (triggers correlation updates and insight generation)
      await ref
          .read(consumptionNotifierProvider.notifier)
          .savePostConsumptionCheck(check);

      if (mounted) {
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Post-check uložen! Data se zpracovávají...'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );

        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        title: const Text('Post-Check'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveCheck,
            child: Text(
              'Uložit',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timer info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withAlpha(20),
                    AppColors.accent.withAlpha(10),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent.withAlpha(60),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: AppColors.accent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Rychlý check (15s) — jak se teď cítíš?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Focus slider
            _buildSlider(
              label: 'FOCUS',
              value: _focus,
              emoji: '🎯',
              color: const Color(0xFF00ACC1),
              onChanged: (v) => setState(() => _focus = v),
            ),

            const SizedBox(height: 20),

            // Mood slider
            _buildSlider(
              label: 'MOOD',
              value: _mood,
              emoji: '😊',
              color: const Color(0xFF66BB6A),
              onChanged: (v) => setState(() => _mood = v),
            ),

            const SizedBox(height: 20),

            // Energy slider
            _buildSlider(
              label: 'ENERGY',
              value: _energy,
              emoji: '⚡',
              color: const Color(0xFFFFB74D),
              onChanged: (v) => setState(() => _energy = v),
            ),

            const SizedBox(height: 20),

            // Anxiety slider
            _buildSlider(
              label: 'ANXIETY',
              value: _anxiety,
              emoji: '😰',
              color: const Color(0xFFEF5350),
              onChanged: (v) => setState(() => _anxiety = v),
            ),

            const SizedBox(height: 24),

            // Body state selector
            Text(
              'BODY STATE',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BodyState.values.map((state) {
                final isSelected = _bodyState == state;
                return GestureDetector(
                  onTap: () => setState(() => _bodyState = state),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withAlpha(30)
                          : AppColors.functionalSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.functionalBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          state.label,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Optional metrics toggle
            TextButton.icon(
              onPressed: () => setState(() => _showOptional = !_showOptional),
              icon: Icon(
                _showOptional ? Icons.expand_less : Icons.expand_more,
                color: AppColors.accent,
              ),
              label: Text(
                _showOptional ? 'Skrýt extra metriky' : 'Přidat extra metriky',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            if (_showOptional) ...[
              const SizedBox(height: 16),

              // Creativity slider
              _buildSlider(
                label: 'CREATIVITY',
                value: _creativity ?? 5.0,
                emoji: '🎨',
                color: const Color(0xFF9C27B0),
                onChanged: (v) => setState(() => _creativity = v),
              ),

              const SizedBox(height: 20),

              // Pain relief slider
              _buildSlider(
                label: 'PAIN RELIEF',
                value: _painRelief ?? 5.0,
                emoji: '💊',
                color: const Color(0xFF26A69A),
                onChanged: (v) => setState(() => _painRelief = v),
              ),

              const SizedBox(height: 20),

              // Appetite change
              Text(
                'APPETITE',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppetiteChange.values.map((change) {
                  final isSelected = _appetiteChange == change;
                  return GestureDetector(
                    onTap: () => setState(() => _appetiteChange = change),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withAlpha(30)
                            : AppColors.functionalSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.functionalBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            change.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            change.label,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveCheck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Uložit Check',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Info text
            Text(
              'Tvoje data se použijí na kalkulaci personal ratingu pro tento strain',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required String emoji,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color,
                  width: 1.5,
                ),
              ),
              child: Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withAlpha(30),
            thumbColor: color,
            overlayColor: color.withAlpha(30),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: value,
            min: label == 'ANXIETY' ? 0 : 1,
            max: 10,
            divisions: label == 'ANXIETY' ? 10 : 9,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label == 'ANXIETY' ? '0 (none)' : '1 (low)',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            Text(
              '10 (high)',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
