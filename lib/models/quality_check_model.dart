import 'package:flutter/material.dart';

/// Quality Check kategorie
enum QualityCheckCategory {
  visual('Visual Check', 'Vizuální kontrola', Icons.visibility),
  smell('Smell Test', 'Test zápachu', Icons.air),
  synthetic('Synthetic Warning', 'Syntetické látky', Icons.warning),
  sprays('Chemical Sprays', 'Chemické postřiky', Icons.science),
  extracts('Extract Types', 'Typy extraktů', Icons.opacity),
  organic('Organic vs Chemical', 'Bio vs Chemie', Icons.eco);

  const QualityCheckCategory(this.label, this.labelCs, this.icon);
  final String label;
  final String labelCs;
  final IconData icon;
}

/// Quality check item - jednotlivý kontrolní bod
class QualityCheckItem {
  final String id;
  final QualityCheckCategory category;
  final String title;
  final String description;
  final CheckType type; // good_sign, red_flag, neutral_info
  final List<String> bulletPoints;
  final String? imageHint; // Popis co hledat

  const QualityCheckItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.type,
    required this.bulletPoints,
    this.imageHint,
  });
}

enum CheckType {
  goodSign('✅ Good Sign', Color(0xFF4CAF50)),
  redFlag('🚩 Red Flag', Color(0xFFEF5350)),
  neutralInfo('ℹ️ Info', Color(0xFF42A5F5));

  const CheckType(this.label, this.color);
  final String label;
  final Color color;
}

/// Synthetic cannabinoid warning
class SyntheticWarning {
  final String substance;
  final String commonNames;
  final String danger;
  final List<String> howToSpot;
  final SeverityLevel severity;

  const SyntheticWarning({
    required this.substance,
    required this.commonNames,
    required this.danger,
    required this.howToSpot,
    required this.severity,
  });
}

enum SeverityLevel {
  extreme('EXTREME', Color(0xFFD32F2F)),
  high('HIGH', Color(0xFFEF5350)),
  medium('MEDIUM', Color(0xFFFFB74D)),
  low('LOW', Color(0xFFFFEE58));

  const SeverityLevel(this.label, this.color);
  final String label;
  final Color color;
}

/// Extract type info
class ExtractInfo {
  final String name;
  final String method;
  final String safety;
  final List<String> characteristics;
  final bool isSolventless;
  final String qualityRating; // "Premium", "Good", "Risky"

  const ExtractInfo({
    required this.name,
    required this.method,
    required this.safety,
    required this.characteristics,
    required this.isSolventless,
    required this.qualityRating,
  });
}

/// Quick reference card
class QuickRefCard {
  final String title;
  final String question;
  final Map<String, String> answers; // option -> explanation

  const QuickRefCard({
    required this.title,
    required this.question,
    required this.answers,
  });
}
