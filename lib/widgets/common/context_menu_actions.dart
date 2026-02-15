import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ios_context_menu.dart';
import '../../theme/theme.dart';

/// Helper class for building common context menu actions
class ContextMenuActions {
  ContextMenuActions._();

  /// Reply action
  static ContextMenuAction reply(VoidCallback onTap) {
    return ContextMenuAction(
      label: 'Odpovědět',
      icon: Icons.reply_rounded,
      onTap: onTap,
    );
  }

  /// Edit action
  static ContextMenuAction edit(VoidCallback onTap) {
    return ContextMenuAction(
      label: 'Upravit',
      icon: Icons.edit_rounded,
      onTap: onTap,
    );
  }

  /// Pin action
  static ContextMenuAction pin(VoidCallback onTap, {bool isPinned = false}) {
    return ContextMenuAction(
      label: isPinned ? 'Odepnout' : 'Připnout',
      icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
      onTap: onTap,
    );
  }

  /// Global key for showing snackbars without context
  static GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  static void _showCopySnackbar(String message) {
    scaffoldMessengerKey?.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Copy link action
  static ContextMenuAction copyLink(String link) {
    return ContextMenuAction(
      label: 'Zkopírovat odkaz',
      icon: Icons.link_rounded,
      onTap: () {
        Clipboard.setData(ClipboardData(text: link));
        _showCopySnackbar('Odkaz zkopirovan');
      },
    );
  }

  /// Copy text action
  static ContextMenuAction copyText(String text) {
    return ContextMenuAction(
      label: 'Kopírovat',
      icon: Icons.copy_rounded,
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        _showCopySnackbar('Text zkopirovan');
      },
    );
  }

  /// Delete action
  static ContextMenuAction delete(VoidCallback onTap) {
    return ContextMenuAction(
      label: 'Smazat',
      icon: Icons.delete_rounded,
      onTap: onTap,
      isDestructive: true,
    );
  }

  /// Select action (for multi-select mode)
  static ContextMenuAction select(VoidCallback onTap) {
    return ContextMenuAction(
      label: 'Vybrat',
      icon: Icons.check_circle_outline_rounded,
      onTap: onTap,
    );
  }

  /// React action (with submenu indicator)
  static ContextMenuAction react(VoidCallback onTap) {
    return ContextMenuAction(
      label: 'Reagovat',
      icon: Icons.add_reaction_outlined,
      onTap: onTap,
      trailingIcon: Icons.chevron_right_rounded,
    );
  }

  /// Forward action
  static ContextMenuAction forward(VoidCallback onTap) {
    return ContextMenuAction(
      label: 'Přeposlat',
      icon: Icons.forward_rounded,
      onTap: onTap,
    );
  }

  /// Report action
  static ContextMenuAction report(VoidCallback onTap) {
    return ContextMenuAction(
      label: 'Nahlásit',
      icon: Icons.flag_outlined,
      onTap: onTap,
      color: Colors.orange,
    );
  }

  /// Block user action
  static ContextMenuAction blockUser(VoidCallback onTap) {
    return ContextMenuAction(
      label: 'Zablokovat uživatele',
      icon: Icons.block_rounded,
      onTap: onTap,
      isDestructive: true,
    );
  }

  /// Share action
  static ContextMenuAction share(VoidCallback onTap) {
    return ContextMenuAction(
      label: 'Sdílet',
      icon: Icons.share_rounded,
      onTap: onTap,
    );
  }

  /// Save/Bookmark action
  static ContextMenuAction save(VoidCallback onTap, {bool isSaved = false}) {
    return ContextMenuAction(
      label: isSaved ? 'Odebrat ze záložek' : 'Uložit',
      icon: isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
      onTap: onTap,
    );
  }

  /// Hide action
  static ContextMenuAction hide(VoidCallback onTap) {
    return ContextMenuAction(
      label: 'Skrýt',
      icon: Icons.visibility_off_rounded,
      onTap: onTap,
    );
  }

  /// Info/Details action
  static ContextMenuAction info(VoidCallback onTap) {
    return ContextMenuAction(
      label: 'Info',
      icon: Icons.info_outline_rounded,
      onTap: onTap,
      trailingIcon: Icons.chevron_right_rounded,
    );
  }

  /// Cancel action (for bottom of destructive menus)
  static ContextMenuAction cancel(VoidCallback onTap) {
    return ContextMenuAction(
      label: 'Zrušit',
      icon: Icons.close_rounded,
      onTap: onTap,
      color: AppColors.textSecondary,
    );
  }
}
