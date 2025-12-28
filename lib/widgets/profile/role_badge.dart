import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Badge zobrazující roli uživatele
///
/// Zobrazuje "Admin" s gradientem nebo "Člen" s neutrálním pozadím.
class RoleBadge extends StatelessWidget {
  /// Je uživatel admin?
  final bool isAdmin;

  const RoleBadge({
    super.key,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        gradient: isAdmin ? AppColors.primaryGradient : null,
        color: isAdmin ? null : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'Člen',
        style: TextStyle(
          color: isAdmin ? Colors.white : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
