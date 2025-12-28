import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../user_avatar.dart';

/// Widget pro zobrazení avataru uživatele s tlačítkem pro editaci
///
/// Zobrazuje kruhový avatar s gradientním okrajem pro adminy
/// a tlačítko pro přechod na editaci profilu.
class ProfileAvatar extends StatelessWidget {
  /// URL obrázku avataru
  final String? imageUrl;

  /// Jméno uživatele (pro fallback avatar)
  final String username;

  /// Je uživatel admin?
  final bool isAdmin;

  /// Velikost avataru
  final double size;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.username,
    required this.isAdmin,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Avatar s okrajem
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Gradient okraj pro adminy
            gradient: isAdmin ? AppColors.primaryGradient : null,
            border: isAdmin
                ? null
                : Border.all(color: AppColors.surfaceLight, width: 3),
          ),
          child: UserAvatar(
            imageUrl: imageUrl,
            name: username,
            size: size,
          ),
        ),

        // Tlačítko editace
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => context.go('/edit-profile'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.background,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.edit,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
