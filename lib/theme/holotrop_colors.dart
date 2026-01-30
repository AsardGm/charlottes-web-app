import 'package:flutter/material.dart';

/// Uklidnujici barevna paleta pro Holotrop mod
/// Hluboky navy, teal a klidna modra nahrazuji agresivni cyberpunk barvy
class HolotropColors {
  HolotropColors._();

  // === POZADI ===
  static const Color background = Color(0xFF0A1628);
  static const Color surface = Color(0xFF0F2035);
  static const Color surfaceLight = Color(0xFF142A42);

  // === ACCENT - Uklidnujici teal ===
  static const Color accent = Color(0xFF00BFA5);
  static const Color accentGlow = Color(0x6000BFA5);
  static const Color accentSoft = Color(0xFF4DD0B8);

  // === BARVY FAZI DYCHANI ===
  static const Color inhale = Color(0xFF00BFA5);
  static const Color hold = Color(0xFF7C4DFF);
  static const Color exhale = Color(0xFF2979FF);

  // === TEXT ===
  static const Color textPrimary = Color(0xFFE0F2F1);
  static const Color textSecondary = Color(0xFF80CBC4);
  static const Color textMuted = Color(0xFF4DB6AC);

  // === TERMINAL (pro bio-hacky) ===
  static const Color terminalGreen = Color(0xFF00E676);
  static const Color terminalBg = Color(0xFF0A0E14);

  // === GRADIENTY ===
  static const LinearGradient calmGradient = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF0F2035), Color(0xFF0A1628)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const RadialGradient breatheGlow = RadialGradient(
    colors: [Color(0x4000BFA5), Color(0x0000BFA5)],
    radius: 0.8,
  );

  static const LinearGradient moduleGradient = LinearGradient(
    colors: [Color(0xFF0A3D3D), Color(0xFF0A1628)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
