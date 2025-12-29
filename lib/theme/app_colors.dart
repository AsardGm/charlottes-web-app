import 'package:flutter/material.dart';

/// Barevna paleta aplikace Charlotte's Web / SpiderBagzz
/// Design podle loga - tmava nocni atmosfera s neonovou cervenou
class AppColors {
  AppColors._();

  // === PRIMARY - SpiderBagzz cervena (z loga) ===
  static const Color primary = Color(0xFFC41E24);        // Tmavsi Spider cervena z loga
  static const Color primaryLight = Color(0xFFE62429);   // Svetlejsi cervena
  static const Color primaryDark = Color(0xFF8B1419);    // Tmava cervena

  // === SECONDARY - Nocni modra (z pozadi loga) ===
  static const Color secondary = Color(0xFF1A4B6E);      // Tmava modra z loga
  static const Color secondaryLight = Color(0xFF2D6A8F); // Svetlejsi modra
  static const Color secondaryDark = Color(0xFF0D1B2A);  // Velmi tmava modra

  // === ACCENT - Neonove cyan (oci z loga) ===
  static const Color accent = Color(0xFF00D4FF);         // Neonove cyan z oci
  static const Color accentGlow = Color(0x6000D4FF);     // Cyan zare

  // === BACKGROUND - Nocni obloha z loga ===
  static const Color background = Color(0xFF0D1B2A);     // Tmava nocni modra
  static const Color surface = Color(0xFF132238);        // O neco svetlejsi
  static const Color surfaceLight = Color(0xFF1C3148);   // Svetlejsi plocha
  static const Color surfaceElevated = Color(0xFF254158); // Elevated karty

  // === TEXT ===
  static const Color textPrimary = Color(0xFFF5F0E6);    // Kremova bila z loga
  static const Color textSecondary = Color(0xFFB8C4D0);  // Svetle seda s modrim
  static const Color textMuted = Color(0xFF6B7B8A);      // Utlumena modro-seda

  // === ACCENT - Zluta/Hneda (z krabic UPS/DHL) ===
  static const Color gold = Color(0xFFC4A35A);           // Zlata/hneda z krabic
  static const Color goldLight = Color(0xFFD4B86A);      // Svetlejsi zlata
  static const Color goldDark = Color(0xFFA08040);       // Tmavsi zlata

  // === WEB/Pavoici vlakna ===
  static const Color web = Color(0xFFF5F0E6);            // Kremova bila
  static const Color webGlow = Color(0x40F5F0E6);        // Zare pavuciny

  // === STATUS ===
  static const Color success = Color(0xFF22C55E);        // Zelena
  static const Color error = Color(0xFFC41E24);          // Cervena (stejna jako primary)
  static const Color warning = Color(0xFFC4A35A);        // Zlata (z loga)
  static const Color info = Color(0xFF00D4FF);           // Cyan (z oci)

  // === RARITY COLORS (pro karty a odznaky) ===
  static const Color rarityCommon = Color(0xFF6B7B8A);   // Seda
  static const Color rarityRare = Color(0xFF1A4B6E);     // Modra
  static const Color rarityExotic = Color(0xFF8B5CF6);   // Fialova
  static const Color rarityLegend = Color(0xFFC4A35A);   // Zlata (legendary)

  // === RANK COLORS ===
  static const Color rankEgg = Color(0xFF6B7B8A);        // Seda - Vajicko
  static const Color rankHatchling = Color(0xFF22C55E);  // Zelena - Maly krizak
  static const Color rankHunter = Color(0xFF1A4B6E);     // Modra - Lovec
  static const Color rankWeaver = Color(0xFF00D4FF);     // Cyan - Tkadlec
  static const Color rankWidow = Color(0xFFC41E24);      // Cervena - Vdova
  static const Color rankMaster = Color(0xFFC4A35A);     // Zlata - Spider Master

  // === GRADIENTS ===

  /// Hlavni gradient (cervena -> tmave cervena)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFC41E24), Color(0xFF8B1419)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Sekundarni gradient (nocni modra)
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF2D6A8F), Color(0xFF0D1B2A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// SpiderBagzz gradient (cervena -> tmava modra) - z loga
  static const LinearGradient spiderGradient = LinearGradient(
    colors: [Color(0xFFC41E24), Color(0xFF1A4B6E), Color(0xFF0D1B2A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Neon cyan gradient (z oci)
  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF0088AA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Nocni obloha gradient (z pozadi loga)
  static const LinearGradient nightSkyGradient = LinearGradient(
    colors: [Color(0xFF0D1B2A), Color(0xFF1C3148), Color(0xFF0D1B2A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Web glow gradient (kremova s prusvitnosti)
  static const LinearGradient webGradient = LinearGradient(
    colors: [Color(0x80F5F0E6), Color(0x20F5F0E6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Gold/Legendary gradient (z krabic)
  static const LinearGradient legendGradient = LinearGradient(
    colors: [Color(0xFFD4B86A), Color(0xFFC4A35A), Color(0xFFA08040)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Text s cervenym obrysem gradient (z loga)
  static const LinearGradient titleGradient = LinearGradient(
    colors: [Color(0xFFF5F0E6), Color(0xFFD4C4B0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Card shimmer gradient
  static const LinearGradient cardShimmer = LinearGradient(
    colors: [
      Color(0x00FFFFFF),
      Color(0x20FFFFFF),
      Color(0x00FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
