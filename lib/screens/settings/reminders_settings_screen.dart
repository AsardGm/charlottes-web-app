import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';
import '../../widgets/common/animated_widgets.dart';

/// Daily Reminders Settings Screen
class RemindersSettingsScreen extends ConsumerStatefulWidget {
  const RemindersSettingsScreen({super.key});

  @override
  ConsumerState<RemindersSettingsScreen> createState() =>
      _RemindersSettingsScreenState();
}

class _RemindersSettingsScreenState
    extends ConsumerState<RemindersSettingsScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _dailyCheckinEnabled = false;
  TimeOfDay _dailyCheckinTime = const TimeOfDay(hour: 20, minute: 0);
  bool _weeklyInsightsEnabled = false;
  TimeOfDay _weeklyInsightsTime = const TimeOfDay(hour: 9, minute: 0);
  int _weeklyInsightsDay = 1; // 1 = Monday

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Load settings from user_settings or preferences table
      final response = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _dailyCheckinEnabled =
              response['daily_checkin_reminder_enabled'] ?? false;
          _weeklyInsightsEnabled =
              response['weekly_insights_reminder_enabled'] ?? false;

          // Parse time from HH:mm format
          if (response['daily_checkin_reminder_time'] != null) {
            final parts =
                (response['daily_checkin_reminder_time'] as String).split(':');
            _dailyCheckinTime =
                TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }

          if (response['weekly_insights_reminder_time'] != null) {
            final parts =
                (response['weekly_insights_reminder_time'] as String).split(':');
            _weeklyInsightsTime =
                TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }

          _weeklyInsightsDay =
              response['weekly_insights_reminder_day'] ?? 1;
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba načítání: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('user_settings').upsert({
        'user_id': userId,
        'daily_checkin_reminder_enabled': _dailyCheckinEnabled,
        'daily_checkin_reminder_time':
            '${_dailyCheckinTime.hour.toString().padLeft(2, '0')}:${_dailyCheckinTime.minute.toString().padLeft(2, '0')}',
        'weekly_insights_reminder_enabled': _weeklyInsightsEnabled,
        'weekly_insights_reminder_time':
            '${_weeklyInsightsTime.hour.toString().padLeft(2, '0')}:${_weeklyInsightsTime.minute.toString().padLeft(2, '0')}',
        'weekly_insights_reminder_day': _weeklyInsightsDay,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        HapticService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nastavení uloženo')),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: $e')),
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isDailyCheckin) async {
    final initialTime = isDailyCheckin ? _dailyCheckinTime : _weeklyInsightsTime;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isDailyCheckin) {
          _dailyCheckinTime = picked;
        } else {
          _weeklyInsightsTime = picked;
        }
      });
      await _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Připomínky'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RevealAnimation(
                  child: _buildDailyCheckinSection(),
                ),
                const SizedBox(height: 24),
                RevealAnimation(
                  delay: const Duration(milliseconds: 50),
                  child: _buildWeeklyInsightsSection(),
                ),
                const SizedBox(height: 24),
                RevealAnimation(
                  delay: const Duration(milliseconds: 100),
                  child: _buildInfoCard(),
                ),
              ],
            ),
    );
  }

  Widget _buildDailyCheckinSection() {
    return AnimatedCard(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF66BB6A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Check-in',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Denní připomínka check-inu',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _dailyCheckinEnabled,
                  onChanged: (value) {
                    HapticService.light();
                    setState(() => _dailyCheckinEnabled = value);
                    _saveSettings();
                  },
                  activeTrackColor: const Color(0xFF66BB6A),
                ),
              ],
            ),
            if (_dailyCheckinEnabled) ...[
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Čas připomínky',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      _selectTime(context, true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${_dailyCheckinTime.hour.toString().padLeft(2, '0')}:${_dailyCheckinTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyInsightsSection() {
    final days = [
      'Pondělí',
      'Úterý',
      'Středa',
      'Čtvrtek',
      'Pátek',
      'Sobota',
      'Neděle',
    ];

    return AnimatedCard(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAB47BC).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.insights,
                    color: Color(0xFFAB47BC),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Insights',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Týdenní přehled a statistiky',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _weeklyInsightsEnabled,
                  onChanged: (value) {
                    HapticService.light();
                    setState(() => _weeklyInsightsEnabled = value);
                    _saveSettings();
                  },
                  activeTrackColor: const Color(0xFFAB47BC),
                ),
              ],
            ),
            if (_weeklyInsightsEnabled) ...[
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Den',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<int>(
                    value: _weeklyInsightsDay,
                    dropdownColor: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    underline: const SizedBox(),
                    items: List.generate(7, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(days[index]),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        HapticService.light();
                        setState(() => _weeklyInsightsDay = value);
                        _saveSettings();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Čas připomínky',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      _selectTime(context, false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFAB47BC).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFAB47BC).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${_weeklyInsightsTime.hour.toString().padLeft(2, '0')}:${_weeklyInsightsTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Color(0xFFAB47BC),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Připomínky ti pomohou udržet pravidelný check-in a sledovat svůj pokrok',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
