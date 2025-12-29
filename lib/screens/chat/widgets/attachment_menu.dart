import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

/// Widget pro menu priloh v chatu
class AttachmentMenu extends StatelessWidget {
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final VoidCallback onSendLocation;
  final VoidCallback onCreatePoll;

  const AttachmentMenu({
    super.key,
    required this.onPickImage,
    required this.onPickFile,
    required this.onSendLocation,
    required this.onCreatePoll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          top: BorderSide(color: AppColors.surface, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _AttachmentOption(
            icon: Icons.image,
            label: 'Obrazek',
            color: Colors.purple,
            onTap: onPickImage,
          ),
          _AttachmentOption(
            icon: Icons.insert_drive_file,
            label: 'Soubor',
            color: Colors.blue,
            onTap: onPickFile,
          ),
          _AttachmentOption(
            icon: Icons.location_on,
            label: 'Poloha',
            color: Colors.green,
            onTap: onSendLocation,
          ),
          _AttachmentOption(
            icon: Icons.poll,
            label: 'Anketa',
            color: Colors.orange,
            onTap: onCreatePoll,
          ),
        ],
      ),
    );
  }
}

/// Widget pro tlacitko v menu priloh
class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
