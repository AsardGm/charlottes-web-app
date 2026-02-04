import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../services/haptic_service.dart';
import '../../widgets/common/animated_widgets.dart';
import '../../providers/theme_provider.dart';

/// App Settings Screen - Main settings hub
class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _hapticFeedbackEnabled = true;
  bool _celebrationAnimationsEnabled = true;
  bool _autoPlayVideos = false;
  bool _dataAnalyticsEnabled = true;

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

      final response = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _hapticFeedbackEnabled =
              response['haptic_feedback_enabled'] ?? true;
          _celebrationAnimationsEnabled =
              response['celebration_animations_enabled'] ?? true;
          _autoPlayVideos = response['auto_play_videos'] ?? false;
          _dataAnalyticsEnabled = response['data_analytics_enabled'] ?? true;
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('user_settings').upsert({
        'user_id': userId,
        'haptic_feedback_enabled': _hapticFeedbackEnabled,
        'celebration_animations_enabled': _celebrationAnimationsEnabled,
        'auto_play_videos': _autoPlayVideos,
        'data_analytics_enabled': _dataAnalyticsEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (_hapticFeedbackEnabled) {
        HapticService.success();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Nastavení'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RevealAnimation(
                  child: _buildAppearanceSection(themeMode),
                ),
                const SizedBox(height: 24),
                RevealAnimation(
                  delay: const Duration(milliseconds: 50),
                  child: _buildExperienceSection(),
                ),
                const SizedBox(height: 24),
                RevealAnimation(
                  delay: const Duration(milliseconds: 100),
                  child: _buildPrivacySection(),
                ),
                const SizedBox(height: 24),
                RevealAnimation(
                  delay: const Duration(milliseconds: 150),
                  child: _buildAccountSection(),
                ),
              ],
            ),
    );
  }

  Widget _buildAppearanceSection(ThemeMode themeMode) {
    return _SettingsSection(
      title: 'Vzhled',
      icon: Icons.palette_outlined,
      iconColor: const Color(0xFFAB47BC),
      children: [
        _SettingsTile(
          icon: Icons.brightness_6,
          title: 'Téma',
          subtitle: _getThemeModeName(themeMode),
          trailing: DropdownButton<ThemeMode>(
            value: themeMode,
            dropdownColor: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('Systém'),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Světlé'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Tmavé'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                HapticService.light();
                final notifier = ref.read(themeModeProvider.notifier);
                switch (value) {
                  case ThemeMode.system:
                    notifier.setSystem();
                    break;
                  case ThemeMode.light:
                    notifier.setLight();
                    break;
                  case ThemeMode.dark:
                    notifier.setDark();
                    break;
                }
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceSection() {
    return _SettingsSection(
      title: 'Zážitek',
      icon: Icons.auto_awesome,
      iconColor: const Color(0xFFFFB74D),
      children: [
        _SettingsTile(
          icon: Icons.vibration,
          title: 'Haptická odezva',
          subtitle: 'Vibrační feedback při akcích',
          trailing: Switch(
            value: _hapticFeedbackEnabled,
            onChanged: (value) {
              if (value) {
                HapticService.medium();
              }
              setState(() => _hapticFeedbackEnabled = value);
              _saveSettings();
            },
            activeTrackColor: AppColors.primary,
          ),
        ),
        _SettingsTile(
          icon: Icons.celebration,
          title: 'Oslavné animace',
          subtitle: 'Animace při dosažení úspěchů',
          trailing: Switch(
            value: _celebrationAnimationsEnabled,
            onChanged: (value) {
              HapticService.light();
              setState(() => _celebrationAnimationsEnabled = value);
              _saveSettings();
            },
            activeTrackColor: AppColors.primary,
          ),
        ),
        _SettingsTile(
          icon: Icons.notifications_outlined,
          title: 'Připomínky',
          subtitle: 'Denní a týdenní připomínky',
          onTap: () {
            HapticService.light();
            context.push('/settings/reminders');
          },
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return _SettingsSection(
      title: 'Soukromí & Data',
      icon: Icons.privacy_tip_outlined,
      iconColor: const Color(0xFF66BB6A),
      children: [
        _SettingsTile(
          icon: Icons.analytics_outlined,
          title: 'Analytika',
          subtitle: 'Pomoz nám zlepšit app',
          trailing: Switch(
            value: _dataAnalyticsEnabled,
            onChanged: (value) {
              HapticService.light();
              setState(() => _dataAnalyticsEnabled = value);
              _saveSettings();
            },
            activeTrackColor: const Color(0xFF66BB6A),
          ),
        ),
        _SettingsTile(
          icon: Icons.play_circle_outline,
          title: 'Auto-play videa',
          subtitle: 'Automatické přehrávání',
          trailing: Switch(
            value: _autoPlayVideos,
            onChanged: (value) {
              HapticService.light();
              setState(() => _autoPlayVideos = value);
              _saveSettings();
            },
            activeTrackColor: AppColors.primary,
          ),
        ),
        _SettingsTile(
          icon: Icons.security,
          title: 'Soukromí účtu',
          subtitle: 'Kdo může vidět tvůj profil',
          onTap: () {
            HapticService.light();
            // Navigate to privacy settings
          },
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _SettingsSection(
      title: 'Účet',
      icon: Icons.person_outline,
      iconColor: const Color(0xFF2196F3),
      children: [
        _SettingsTile(
          icon: Icons.email_outlined,
          title: 'Email',
          subtitle: _supabase.auth.currentUser?.email ?? 'Není přihlášen',
        ),
        _SettingsTile(
          icon: Icons.help_outline,
          title: 'Pomoc & Podpora',
          subtitle: 'Časté dotazy a kontakt',
          onTap: () {
            HapticService.light();
            // Navigate to help
          },
        ),
        _SettingsTile(
          icon: Icons.info_outline,
          title: 'O aplikaci',
          subtitle: 'Verze 1.0.0',
          onTap: () {
            HapticService.light();
            _showAboutDialog();
          },
        ),
        _SettingsTile(
          icon: Icons.logout,
          title: 'Odhlásit se',
          subtitle: '',
          iconColor: Colors.red,
          onTap: () {
            HapticService.medium();
            _showLogoutDialog();
          },
        ),
      ],
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Podle systému';
      case ThemeMode.light:
        return 'Světlé';
      case ThemeMode.dark:
        return 'Tmavé';
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'O aplikaci',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Charlotte\'s Web',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verze 1.0.0',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              'Tvůj osobní průvodce zodpovědnou konzumací cannabis.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Zavřít'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Odhlásit se',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Opravdu se chceš odhlásit?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () async {
              // Close dialog first
              if (context.mounted) {
                context.pop();
              }
              // Then sign out
              await _supabase.auth.signOut();
              // Navigate to auth
              if (mounted && context.mounted) {
                context.go('/auth');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Odhlásit'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        AnimatedCard(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: tile,
        ),
      );
    }

    return tile;
  }
}
