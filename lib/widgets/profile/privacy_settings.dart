import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme.dart';

/// Model pro nastaveni soukromi
class PrivacySettings {
  /// Anonymni mod - skryti profilu z vyhledavani
  final bool anonymousMode;

  /// Ghost mode - skryti polohy u fotek
  final bool ghostMode;

  /// Skryt pocet sledujicich
  final bool hideFollowerCount;

  /// Skryt aktivitu (posledni online)
  final bool hideActivity;

  /// Kdo muze videt profil
  final ProfileVisibility profileVisibility;

  /// Kdo muze posilat zpravy
  final MessagePermission messagePermission;

  const PrivacySettings({
    this.anonymousMode = false,
    this.ghostMode = false,
    this.hideFollowerCount = false,
    this.hideActivity = false,
    this.profileVisibility = ProfileVisibility.everyone,
    this.messagePermission = MessagePermission.everyone,
  });

  PrivacySettings copyWith({
    bool? anonymousMode,
    bool? ghostMode,
    bool? hideFollowerCount,
    bool? hideActivity,
    ProfileVisibility? profileVisibility,
    MessagePermission? messagePermission,
  }) {
    return PrivacySettings(
      anonymousMode: anonymousMode ?? this.anonymousMode,
      ghostMode: ghostMode ?? this.ghostMode,
      hideFollowerCount: hideFollowerCount ?? this.hideFollowerCount,
      hideActivity: hideActivity ?? this.hideActivity,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      messagePermission: messagePermission ?? this.messagePermission,
    );
  }

  Map<String, dynamic> toJson() => {
        'anonymous_mode': anonymousMode,
        'ghost_mode': ghostMode,
        'hide_follower_count': hideFollowerCount,
        'hide_activity': hideActivity,
        'profile_visibility': profileVisibility.name,
        'message_permission': messagePermission.name,
      };

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      anonymousMode: json['anonymous_mode'] as bool? ?? false,
      ghostMode: json['ghost_mode'] as bool? ?? false,
      hideFollowerCount: json['hide_follower_count'] as bool? ?? false,
      hideActivity: json['hide_activity'] as bool? ?? false,
      profileVisibility: ProfileVisibility.values.firstWhere(
        (v) => v.name == json['profile_visibility'],
        orElse: () => ProfileVisibility.everyone,
      ),
      messagePermission: MessagePermission.values.firstWhere(
        (v) => v.name == json['message_permission'],
        orElse: () => MessagePermission.everyone,
      ),
    );
  }
}

enum ProfileVisibility {
  everyone,
  followers,
  nobody,
}

enum MessagePermission {
  everyone,
  followers,
  nobody,
}

/// Widget pro nastaveni soukromi
class PrivacySettingsWidget extends StatelessWidget {
  final PrivacySettings settings;
  final ValueChanged<PrivacySettings> onSettingsChanged;
  final VoidCallback? onBurnerAccountTap;

  const PrivacySettingsWidget({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.onBurnerAccountTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Anonymni mod
        _PrivacyToggle(
          icon: Icons.visibility_off,
          title: 'Anonymni mod',
          subtitle: 'Skryj svuj profil z vyhledavani',
          value: settings.anonymousMode,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            onSettingsChanged(settings.copyWith(anonymousMode: value));
          },
          color: Colors.purple,
        ),

        const SizedBox(height: 12),

        // Ghost mode
        _PrivacyToggle(
          icon: Icons.location_off,
          title: 'Ghost Mode',
          subtitle: 'Skryj polohu u vsech fotek',
          value: settings.ghostMode,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            onSettingsChanged(settings.copyWith(ghostMode: value));
          },
          color: Colors.indigo,
        ),

        const SizedBox(height: 12),

        // Skryt pocet sledujicich
        _PrivacyToggle(
          icon: Icons.people_outline,
          title: 'Skryt sledujici',
          subtitle: 'Ostatni neuvidi pocet tvi sledujicich',
          value: settings.hideFollowerCount,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            onSettingsChanged(settings.copyWith(hideFollowerCount: value));
          },
          color: Colors.teal,
        ),

        const SizedBox(height: 12),

        // Skryt aktivitu
        _PrivacyToggle(
          icon: Icons.access_time,
          title: 'Skryt aktivitu',
          subtitle: 'Ostatni neuvidi kdy jsi byl online',
          value: settings.hideActivity,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            onSettingsChanged(settings.copyWith(hideActivity: value));
          },
          color: Colors.orange,
        ),

        const SizedBox(height: 24),

        // Kdo vidi profil
        _PrivacyDropdown<ProfileVisibility>(
          icon: Icons.person,
          title: 'Kdo vidi muj profil',
          value: settings.profileVisibility,
          items: const [
            DropdownMenuItem(
              value: ProfileVisibility.everyone,
              child: Text('Vsichni'),
            ),
            DropdownMenuItem(
              value: ProfileVisibility.followers,
              child: Text('Jen sledujici'),
            ),
            DropdownMenuItem(
              value: ProfileVisibility.nobody,
              child: Text('Nikdo'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.lightImpact();
              onSettingsChanged(settings.copyWith(profileVisibility: value));
            }
          },
        ),

        const SizedBox(height: 12),

        // Kdo muze psat
        _PrivacyDropdown<MessagePermission>(
          icon: Icons.message,
          title: 'Kdo mi muze psat',
          value: settings.messagePermission,
          items: const [
            DropdownMenuItem(
              value: MessagePermission.everyone,
              child: Text('Vsichni'),
            ),
            DropdownMenuItem(
              value: MessagePermission.followers,
              child: Text('Jen sledujici'),
            ),
            DropdownMenuItem(
              value: MessagePermission.nobody,
              child: Text('Nikdo'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.lightImpact();
              onSettingsChanged(settings.copyWith(messagePermission: value));
            }
          },
        ),

        const SizedBox(height: 32),

        // Burner Account
        if (onBurnerAccountTap != null) _BurnerAccountButton(onTap: onBurnerAccountTap!),
      ],
    );
  }
}

class _PrivacyToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  const _PrivacyToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? color.withAlpha(100) : AppColors.surfaceLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (value ? color : AppColors.textMuted).withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: value ? color : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: color.withAlpha(150),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return color;
              }
              return null;
            }),
          ),
        ],
      ),
    );
  }
}

class _PrivacyDropdown<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _PrivacyDropdown({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            underline: const SizedBox(),
            dropdownColor: AppColors.surface,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BurnerAccountButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BurnerAccountButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.local_fire_department,
                size: 22,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Burner Account',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rychle smaz vsechna data z profilu',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog pro potvrzeni Burner Account
class BurnerAccountDialog extends StatefulWidget {
  final VoidCallback onConfirm;

  const BurnerAccountDialog({
    super.key,
    required this.onConfirm,
  });

  static Future<bool?> show(BuildContext context, {required VoidCallback onConfirm}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BurnerAccountDialog(onConfirm: onConfirm),
    );
  }

  @override
  State<BurnerAccountDialog> createState() => _BurnerAccountDialogState();
}

class _BurnerAccountDialogState extends State<BurnerAccountDialog> {
  final _controller = TextEditingController();
  bool _canConfirm = false;
  bool _isLoading = false;

  static const _confirmText = 'SMAZAT';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
          const SizedBox(width: 12),
          Text(
            'Burner Account',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tato akce je NEVRATNA!',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Budou smazany:',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          _buildDeleteItem('Vsechny tvoje prispevky'),
          _buildDeleteItem('Vsechny komentare'),
          _buildDeleteItem('Historie chatu'),
          _buildDeleteItem('Profilove informace'),
          _buildDeleteItem('Nastaveni'),
          const SizedBox(height: 16),
          Text(
            'Pro potvrzeni napis "$_confirmText":',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: _confirmText,
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _canConfirm = value.toUpperCase() == _confirmText;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Zrusit',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: _canConfirm && !_isLoading
              ? () async {
                  setState(() => _isLoading = true);
                  HapticFeedback.heavyImpact();
                  widget.onConfirm();
                  Navigator.pop(context, true);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            disabledBackgroundColor: AppColors.error.withAlpha(50),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Smazat vse',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          Icon(Icons.remove, size: 14, color: AppColors.error),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rychly prepinac anonymniho modu
class AnonymousModeToggle extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const AnonymousModeToggle({
    super.key,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!isEnabled);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.purple.withAlpha(30) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnabled ? Colors.purple : AppColors.surfaceLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEnabled ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: isEnabled ? Colors.purple : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              isEnabled ? 'Anonymni' : 'Viditelny',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isEnabled ? Colors.purple : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
