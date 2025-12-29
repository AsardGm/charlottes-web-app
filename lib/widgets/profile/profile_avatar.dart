import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../models/rank_model.dart';
import 'glitch_avatar.dart';

/// Widget pro zobrazení avataru uživatele s tlačítkem pro editaci
///
/// Zobrazuje kruhový avatar s glitch efektem a neonovym okrajem podle ranku.
/// Obsahuje tlačítko pro přechod na editaci profilu.
class ProfileAvatar extends StatelessWidget {
  /// URL obrázku avataru
  final String? imageUrl;

  /// Jméno uživatele (pro fallback avatar)
  final String username;

  /// Je uživatel admin?
  final bool isAdmin;

  /// Velikost avataru
  final double size;

  /// Rank uzivatele (pro efekty)
  final SpiderRank? rank;

  /// Styl glitch efektu
  final GlitchStyle glitchStyle;

  /// Zobrazit tlacitko editace?
  final bool showEditButton;

  /// Web level pro hustotu pavuciny
  final int webLevel;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.username,
    required this.isAdmin,
    this.size = 100,
    this.rank,
    this.glitchStyle = GlitchStyle.subtle,
    this.showEditButton = true,
    this.webLevel = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Urceni stylu podle ranku pokud neni explicitne nastaven
    final effectiveStyle = _getEffectiveStyle();
    final effectiveRank = rank ?? (isAdmin ? SpiderRanks.master : null);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Glitch Avatar
        GlitchAvatar(
          imageUrl: imageUrl,
          name: username,
          size: size,
          rank: effectiveRank,
          glitchStyle: effectiveStyle,
          intensity: _getIntensity(),
          webLevel: webLevel,
          showLevelBadge: rank != null,
        ),

        // Tlačítko editace
        if (showEditButton)
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

  GlitchStyle _getEffectiveStyle() {
    if (glitchStyle != GlitchStyle.subtle) return glitchStyle;

    // Automaticky styl podle ranku
    switch (rank?.id) {
      case 'master':
        return GlitchStyle.fire;
      case 'widow':
        return GlitchStyle.neon;
      case 'weaver':
        return GlitchStyle.web;
      case 'hunter':
        return GlitchStyle.pulse;
      case 'spiderling':
        return GlitchStyle.subtle;
      default:
        return isAdmin ? GlitchStyle.neon : GlitchStyle.none;
    }
  }

  double _getIntensity() {
    switch (rank?.id) {
      case 'master':
        return 0.8;
      case 'widow':
        return 0.7;
      case 'weaver':
        return 0.6;
      case 'hunter':
        return 0.5;
      default:
        return 0.4;
    }
  }
}
