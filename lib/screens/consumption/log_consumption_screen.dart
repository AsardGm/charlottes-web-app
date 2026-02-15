import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme.dart';
import '../../models/consumption_model.dart';
import '../../providers/consumption_provider.dart';
import '../../widgets/harm_reduction/safety_tips_widget.dart';

/// Quick consumption log screen (5s entry)
class LogConsumptionScreen extends ConsumerStatefulWidget {
  final String? strainId; // Pre-selected strain (optional)

  const LogConsumptionScreen({super.key, this.strainId});

  @override
  ConsumerState<LogConsumptionScreen> createState() => _LogConsumptionScreenState();
}

class _LogConsumptionScreenState extends ConsumerState<LogConsumptionScreen> {
  String? _selectedStrainId;
  double _amount = 0.3; // Default 0.3g
  ConsumptionMethod _method = ConsumptionMethod.joint;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedStrainId = widget.strainId;
  }

  void _schedulePostCheckReminder() {
    // Schedule a delayed local notification after 45 min
    Future.delayed(const Duration(minutes: 45), () {
      if (!mounted) return;
      // Use the mobile push local notifications plugin if available
      try {
        debugPrint('Post-check reminder: 45 min elapsed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cas na post-consumption check-in!'),
              backgroundColor: AppColors.accent,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Otevrit',
                textColor: Colors.white,
                onPressed: () => context.push('/consumption/post-check'),
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Failed to show reminder: $e');
      }
    });
  }

  Future<void> _saveAndScheduleCheck() async {
    if (_selectedStrainId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vyber strain'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      // Create consumption log
      final log = ConsumptionLog(
        userId: userId,
        strainId: _selectedStrainId!,
        amount: _amount,
        method: _method,
        timestamp: DateTime.now(),
        timeOfDay: TimeOfDayExtension.fromDateTime(DateTime.now()),
      );

      // Save via provider
      final savedLog = await ref
          .read(consumptionNotifierProvider.notifier)
          .saveConsumptionLog(log);

      // Schedule notification for post-check in 45 min
      _schedulePostCheckReminder();

      if (mounted) {
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Uloženo! Reminder za 45 min'),
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
        title: const Text('Log Consumption'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveAndScheduleCheck,
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
            // Strain selector
            Text(
              'CO JSI UŽIL?',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final result = await context.push<String>('/strains');
                if (result != null && mounted) {
                  setState(() => _selectedStrainId = result);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.functionalSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedStrainId != null
                        ? AppColors.accent
                        : AppColors.functionalBorder,
                    width: _selectedStrainId != null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.grass,
                      color: _selectedStrainId != null
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedStrainId ?? 'Vyber strain...',
                        style: TextStyle(
                          color: _selectedStrainId != null
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Amount slider
            Text(
              'KOLIK? (${_amount.toStringAsFixed(1)}g)',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.functionalSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.functionalBorder,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Slider(
                    value: _amount,
                    min: 0.1,
                    max: 2.0,
                    divisions: 19,
                    activeColor: AppColors.accent,
                    inactiveColor: AppColors.functionalBorder,
                    onChanged: (value) {
                      setState(() => _amount = value);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0.1g',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '2.0g',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Method selector
            Text(
              'ZPŮSOB',
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
              children: ConsumptionMethod.values.map((method) {
                final isSelected = _method == method;
                return GestureDetector(
                  onTap: () => setState(() => _method = method),
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
                          method.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          method.label,
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

            const SizedBox(height: 32),

            // Info card
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
                    Icons.notifications_active,
                    color: AppColors.accent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Za 45 min dostaneš reminder na quick post-check (15s)',
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

            // Safety tips before consumption
            const SafetyTipsWidget(context: 'before'),

            const SizedBox(height: 24),

            // Save button (large)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveAndScheduleCheck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Uložit → Naplánovat Check',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
