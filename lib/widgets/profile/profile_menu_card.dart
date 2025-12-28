import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Karta menu v profilu
///
/// Kontejner s zaoblenými rohy pro seskupení položek menu.
/// Automaticky přidává oddělovače mezi položky.
class ProfileMenuCard extends StatelessWidget {
  /// Seznam položek menu
  final List<Widget> children;

  const ProfileMenuCard({
    super.key,
    required this.children,
  });

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
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            // Oddělovač mezi položkami
            if (i < children.length - 1)
              Divider(height: 1, color: Colors.white.withAlpha(5)),
          ],
        ],
      ),
    );
  }
}

/// Položka menu v profilu
///
/// Zobrazuje ikonu, název a volitelně podnázev.
/// Podporuje vlastní barvy pro ikonu a text.
class ProfileMenuItem extends StatelessWidget {
  /// Ikona položky
  final IconData icon;

  /// Název položky
  final String title;

  /// Volitelný podnázev
  final String? subtitle;

  /// Callback při kliknutí
  final VoidCallback onTap;

  /// Volitelná barva ikony
  final Color? iconColor;

  /// Volitelná barva názvu
  final Color? titleColor;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // Ikona
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.textSecondary,
      ),
      // Název
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      // Podnázev
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            )
          : null,
      // Šipka vpravo
      trailing: Icon(
        Icons.chevron_right,
        color: iconColor ?? AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}
