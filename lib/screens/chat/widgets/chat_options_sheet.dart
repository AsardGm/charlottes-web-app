import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

/// Widget pro zobrazeni moznosti chatu (bottom sheet)
class ChatOptionsSheet extends StatelessWidget {
  final VoidCallback onDisappearingMessages;
  final VoidCallback onSearch;
  final VoidCallback onMute;
  final VoidCallback onBlock;

  const ChatOptionsSheet({
    super.key,
    required this.onDisappearingMessages,
    required this.onSearch,
    required this.onMute,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Mizici zpravy'),
            subtitle: const Text('Vypnuto'),
            onTap: onDisappearingMessages,
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Hledat ve zpravach'),
            onTap: onSearch,
          ),
          ListTile(
            leading: const Icon(Icons.volume_off),
            title: const Text('Ztlumit'),
            onTap: onMute,
          ),
          ListTile(
            leading: Icon(Icons.block, color: AppColors.error),
            title: Text('Blokovat', style: TextStyle(color: AppColors.error)),
            onTap: onBlock,
          ),
        ],
      ),
    );
  }
}

/// Dialog pro volbu mizicich zprav
class DisappearingMessagesSheet extends StatelessWidget {
  final int currentTtl;
  final Function(int) onSelect;

  const DisappearingMessagesSheet({
    super.key,
    required this.currentTtl,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Mizici zpravy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          _DisappearingOption(
            title: 'Vypnuto',
            isSelected: currentTtl == 0,
            onTap: () => onSelect(0),
          ),
          _DisappearingOption(
            title: '24 hodin',
            isSelected: currentTtl == 86400,
            onTap: () => onSelect(86400),
          ),
          _DisappearingOption(
            title: '7 dni',
            isSelected: currentTtl == 604800,
            onTap: () => onSelect(604800),
          ),
          _DisappearingOption(
            title: '90 dni',
            isSelected: currentTtl == 7776000,
            onTap: () => onSelect(7776000),
          ),
        ],
      ),
    );
  }
}

class _DisappearingOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DisappearingOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
