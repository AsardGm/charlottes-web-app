import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_settings/app_settings.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart' as theme;
import '../../providers/shadow_mode_provider.dart';
import '../../models/shadow_mode_model.dart';
import '../../services/web_push_service.dart';
import '../../widgets/shadow_mode/shadow_mode_toggle_dialog.dart';
import '../onboarding/onboarding_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text('Nastaveni'),
      ),
      body: settingsAsync.when(
        data: (settings) {
          if (settings == null) {
            return const Center(child: Text('Nelze nacist nastaveni'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Vzhled
              _SectionHeader(title: 'Vzhled'),
              _SettingsCard(
                children: [
                  _ThemeTileNew(ref: ref),
                ],
              ),

              const SizedBox(height: 24),

              // Shadow Mode - Wellness
              _SectionHeader(title: 'Pohoda'),
              _SettingsCard(
                children: [
                  _ShadowModeTile(ref: ref),
                ],
              ),

              const SizedBox(height: 24),

              // Notifikace
              _SectionHeader(title: 'Notifikace'),
              _SettingsCard(
                children: [
                  // Web/PWA - push notifikace
                  if (kIsWeb) ...[
                    const _WebPushTile(),
                    const Divider(height: 1),
                  ],
                  // Mobile - odkaz do systémových nastavení
                  if (!kIsWeb) ...[
                    ListTile(
                      title: const Text('Push notifikace'),
                      subtitle: const Text('Spravovat v nastaveni systemu'),
                      trailing: const Icon(Icons.open_in_new, size: 20),
                      onTap: () {
                        AppSettings.openAppSettings(type: AppSettingsType.notification);
                      },
                    ),
                    const Divider(height: 1),
                  ],
                  SwitchListTile(
                    title: const Text('In-app notifikace'),
                    subtitle: const Text('Zobrazovat upozornění v aplikaci'),
                    value: settings.notificationsEnabled,
                    onChanged: (value) {
                      ref.read(settingsNotifierProvider.notifier)
                          .setNotificationsEnabled(value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('E-mailové notifikace'),
                    subtitle: const Text('Dostávat upozornění na e-mail'),
                    value: settings.emailNotifications,
                    onChanged: (value) {
                      ref.read(settingsNotifierProvider.notifier)
                          .updateSettings({'email_notifications': value});
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Soukromi
              _SectionHeader(title: 'Soukromi'),
              _SettingsCard(
                children: [
                  ListTile(
                    leading: Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Soukromi a bezpecnost'),
                    subtitle: const Text('Soukromy ucet, heslo, prihlaseni'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/privacy-security'),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Zobrazovat online status'),
                    subtitle: const Text('Ostatní uvidí, kdy jsi online'),
                    value: settings.showOnlineStatus,
                    onChanged: (value) {
                      ref.read(settingsNotifierProvider.notifier)
                          .setShowOnlineStatus(value);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Kdo mi může psát'),
                    subtitle: Text(_getMessagesFromLabel(settings.allowMessagesFrom)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showMessagesFromDialog(context, ref, settings.allowMessagesFrom),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Buddy - pruvodce
              _SectionHeader(title: 'Pruvodce'),
              _SettingsCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: const Text('Wiki / Encyklopedie'),
                    subtitle: const Text('Kanabinoidy, terpeny, harm reduction'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/wiki'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: const Text('Spustit pruvodce'),
                    subtitle: const Text('Znovu zobrazit uvitani od Buddyho'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await OnboardingHelper.reset();
                      if (context.mounted) {
                        context.go('/onboarding');
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Ucet
              _SectionHeader(title: 'Ucet'),
              _SettingsCard(
                children: [
                  ListTile(
                    leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                    title: Text(
                      'Odhlasit se',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    onTap: () => _showLogoutDialog(context, ref),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Verze
              Center(
                child: Text(
                  "Buds and Buddies v1.0.0",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Chyba: ${error.toString()}'),
            ],
          ),
        ),
      ),
    );
  }

  String _getMessagesFromLabel(String value) {
    switch (value) {
      case 'everyone':
        return 'Kdokoliv';
      case 'followers':
        return 'Pouze sledující';
      case 'nobody':
        return 'Nikdo';
      default:
        return value;
    }
  }

  void _showMessagesFromDialog(BuildContext context, WidgetRef ref, String current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kdo mi může psát'),
        content: RadioGroup<String>(
          onChanged: (value) {
            if (value != null) {
              ref.read(settingsNotifierProvider.notifier)
                  .setAllowMessagesFrom(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Kdokoliv'),
                leading: Radio<String>(value: 'everyone'),
                onTap: () {
                  ref.read(settingsNotifierProvider.notifier)
                      .setAllowMessagesFrom('everyone');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Pouze sledující'),
                leading: Radio<String>(value: 'followers'),
                onTap: () {
                  ref.read(settingsNotifierProvider.notifier)
                      .setAllowMessagesFrom('followers');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Nikdo'),
                leading: Radio<String>(value: 'nobody'),
                onTap: () {
                  ref.read(settingsNotifierProvider.notifier)
                      .setAllowMessagesFrom('nobody');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odhlasit se?'),
        content: const Text('Opravdu se chcete odhlasit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zrusit'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Odhlasit'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).textTheme.labelSmall?.color ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: mutedColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(8)
              : Theme.of(context).colorScheme.outline.withAlpha(30),
          width: 1,
        ),
        boxShadow: !isDark ? [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

/// Widget pro přepínání tématu - používá theme_provider
class _ThemeTileNew extends StatelessWidget {
  final WidgetRef ref;

  const _ThemeTileNew({required this.ref});

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(theme.themeModeProvider);

    return ListTile(
      title: const Text('Tema'),
      subtitle: Text(_getThemeLabel(themeMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Tmave';
      case ThemeMode.light:
        return 'Svetle';
      case ThemeMode.system:
        return 'Podle systemu';
    }
  }

  void _showThemeDialog(BuildContext context) {
    final themeMode = ref.read(theme.themeModeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vybrat tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(
              icon: Icons.dark_mode,
              title: 'Tmave',
              value: 'dark',
              isSelected: themeMode == ThemeMode.dark,
              onTap: () {
                ref.read(theme.themeModeProvider.notifier).setDark();
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              icon: Icons.light_mode,
              title: 'Svetle',
              value: 'light',
              isSelected: themeMode == ThemeMode.light,
              onTap: () {
                ref.read(theme.themeModeProvider.notifier).setLight();
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              icon: Icons.settings_brightness,
              title: 'Podle systemu',
              value: 'system',
              isSelected: themeMode == ThemeMode.system,
              onTap: () {
                ref.read(theme.themeModeProvider.notifier).setSystem();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

/// Widget pro Shadow Mode toggle
class _ShadowModeTile extends ConsumerWidget {
  final WidgetRef ref;

  const _ShadowModeTile({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shadowModeState = ref.watch(shadowModeStateProvider);
    final isActive = shadowModeState.isActive;

    return ListTile(
      leading: const Text('🕶️', style: TextStyle(fontSize: 24)),
      title: const Text('Shadow Mode™'),
      subtitle: Text(
        isActive
            ? '${shadowModeState.reason?.emoji ?? ''} ${shadowModeState.reason?.displayName ?? 'Aktivní'}'
            : 'Offline. Bez lidí. Bez tlaku.',
      ),
      trailing: Switch(
        value: isActive,
        onChanged: (value) async {
          await ShadowModeToggleDialog.show(context, isActive: isActive);
        },
      ),
      onTap: () async {
        await ShadowModeToggleDialog.show(context, isActive: isActive);
      },
    );
  }
}

/// Widget pro nastavení web push notifikací
class _WebPushTile extends StatefulWidget {
  const _WebPushTile();

  @override
  State<_WebPushTile> createState() => _WebPushTileState();
}

class _WebPushTileState extends State<_WebPushTile> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final pushService = WebPushService.instance;
    final isEnabled = pushService.isEnabled;
    final isPushSupported = pushService.isPushSupported;
    final isStandalone = pushService.isStandalone;
    final platform = pushService.platform;

    // iOS Safari nepodporuje push
    if (platform == 'ios_web') {
      return ListTile(
        title: const Text('Push notifikace'),
        subtitle: const Text('Nainstaluj aplikaci pro push notifikace'),
        trailing: const Icon(
          Icons.info_outline,
          size: 20,
        ),
        onTap: () => _showIOSInstallDialog(context),
      );
    }

    // Platforma nepodporuje push
    if (!isPushSupported) {
      return ListTile(
        title: const Text('Push notifikace'),
        subtitle: const Text('Tvuj prohlizec nepodporuje push notifikace'),
        trailing: const Icon(
          Icons.warning_amber,
          color: Colors.orange,
          size: 20,
        ),
      );
    }

    return ListTile(
      title: const Text('Push notifikace'),
      subtitle: Text(
        isEnabled
            ? 'Povoleno${isStandalone ? ' (PWA)' : ''}'
            : 'Klikni pro povoleni',
      ),
      trailing: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              isEnabled ? Icons.notifications_active : Icons.notifications_off,
              color: isEnabled ? Colors.green : null,
            ),
      onTap: isEnabled ? null : _requestPermission,
    );
  }

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);

    try {
      final result = await WebPushService.instance.requestPermission();

      if (mounted) {
        setState(() => _isLoading = false);

        if (result == 'granted') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Push notifikace povoleny!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (result == 'denied') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Push notifikace byly zamitnuty'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showIOSInstallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nainstaluj aplikaci'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pro push notifikace na iOS je potreba nainstalovat aplikaci na plochu:',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.ios_share, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('1. Klikni na tlacitko Sdilet'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_box_outlined, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('2. Vyber "Pridat na plochu"'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle_outline, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('3. Otevri aplikaci z plochy'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Rozumim'),
          ),
        ],
      ),
    );
  }
}
