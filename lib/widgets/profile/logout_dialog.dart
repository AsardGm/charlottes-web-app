import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/theme.dart';
import '../../providers/auth_provider.dart';

/// Dialog pro potvrzení odhlášení
///
/// Zobrazuje potvrzovací dialog s možností zrušit nebo potvrdit odhlášení.
class LogoutDialog extends ConsumerWidget {
  const LogoutDialog({super.key});

  /// Zobrazí dialog pro odhlášení
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LogoutDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Odhlásit se?'),
      content: const Text('Opravdu se chcete odhlásit?'),
      actions: [
        // Tlačítko zrušit
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zrušit'),
        ),
        // Tlačítko odhlásit
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await ref.read(authNotifierProvider.notifier).signOut();
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Odhlásit'),
        ),
      ],
    );
  }
}
