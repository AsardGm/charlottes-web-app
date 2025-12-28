import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
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
                  _ThemeTile(
                    currentTheme: settings.theme,
                    onChanged: (theme) {
                      ref.read(settingsNotifierProvider.notifier).setTheme(theme);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Notifikace
              _SectionHeader(title: 'Notifikace'),
              _SettingsCard(
                children: [
                  SwitchListTile(
                    title: const Text('Push notifikace'),
                    subtitle: const Text('Dostávat upozornění na novou aktivitu'),
                    value: settings.notificationsEnabled,
                    onChanged: (value) {
                      ref.read(settingsNotifierProvider.notifier)
                          .setNotificationsEnabled(value);
                    },
                    activeColor: AppColors.primary,
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
                    activeColor: AppColors.primary,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Soukromi
              _SectionHeader(title: 'Soukromi'),
              _SettingsCard(
                children: [
                  SwitchListTile(
                    title: const Text('Zobrazovat online status'),
                    subtitle: const Text('Ostatní uvidí, kdy jsi online'),
                    value: settings.showOnlineStatus,
                    onChanged: (value) {
                      ref.read(settingsNotifierProvider.notifier)
                          .setShowOnlineStatus(value);
                    },
                    activeColor: AppColors.primary,
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

              // Ucet
              _SectionHeader(title: 'Ucet'),
              _SettingsCard(
                children: [
                  ListTile(
                    leading: Icon(Icons.logout, color: AppColors.error),
                    title: Text(
                      'Odhlasit se',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () => _showLogoutDialog(context, ref),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Verze
              Center(
                child: Text(
                  "Charlotte's Web v1.0.0",
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
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Kdokoliv'),
              value: 'everyone',
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsNotifierProvider.notifier)
                    .setAllowMessagesFrom(value!);
                Navigator.pop(context);
              },
              activeColor: AppColors.primary,
            ),
            RadioListTile<String>(
              title: const Text('Pouze sledující'),
              value: 'followers',
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsNotifierProvider.notifier)
                    .setAllowMessagesFrom(value!);
                Navigator.pop(context);
              },
              activeColor: AppColors.primary,
            ),
            RadioListTile<String>(
              title: const Text('Nikdo'),
              value: 'nobody',
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsNotifierProvider.notifier)
                    .setAllowMessagesFrom(value!);
                Navigator.pop(context);
              },
              activeColor: AppColors.primary,
            ),
          ],
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(8),
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String currentTheme;
  final ValueChanged<String> onChanged;

  const _ThemeTile({
    required this.currentTheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Tema'),
      subtitle: Text(_getThemeLabel(currentTheme)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context),
    );
  }

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'dark':
        return 'Tmave';
      case 'light':
        return 'Svetle';
      case 'system':
        return 'Podle systemu';
      default:
        return theme;
    }
  }

  void _showThemeDialog(BuildContext context) {
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
              isSelected: currentTheme == 'dark',
              onTap: () {
                onChanged('dark');
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              icon: Icons.light_mode,
              title: 'Svetle',
              value: 'light',
              isSelected: currentTheme == 'light',
              onTap: () {
                onChanged('light');
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              icon: Icons.settings_brightness,
              title: 'Podle systemu',
              value: 'system',
              isSelected: currentTheme == 'system',
              onTap: () {
                onChanged('system');
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
      leading: Icon(icon, color: isSelected ? AppColors.primary : null),
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
