import 'package:flutter/material.dart';

/// Kategorie wiki clanku
enum WikiCategory {
  cannabinoids('Kanabinoidy', Icons.science, Color(0xFF00D4FF)),
  terpenes('Terpeny', Icons.eco, Color(0xFF22C55E)),
  synthetic('Syntetika', Icons.warning_amber_rounded, Color(0xFFE62429)),
  interactions('Interakce', Icons.compare_arrows, Color(0xFFC4A35A)),
  harmReduction('Harm Reduction', Icons.shield_outlined, Color(0xFF8B5CF6)),
  purchasing('N\u00e1kup', Icons.storefront_outlined, Color(0xFFFF9800)),
  legal('Legislativa', Icons.gavel, Color(0xFF2D6A8F));

  final String label;
  final IconData icon;
  final Color color;
  const WikiCategory(this.label, this.icon, this.color);
}

/// Uroven rizika
enum RiskLevel {
  low('Nizke', Color(0xFF22C55E)),
  medium('Stredni', Color(0xFFC4A35A)),
  high('Vysoke', Color(0xFFE62429)),
  unknown('Nezname', Color(0xFF8A929C));

  final String label;
  final Color color;
  const RiskLevel(this.label, this.color);
}

/// Model wiki clanku
class WikiArticleModel {
  final String id;
  final String slug;
  final String title;
  final String subtitle;
  final WikiCategory category;
  final String summary;
  final String description;
  final List<String> effects;
  final List<String> risks;
  final List<String> harmReductionTips;
  final String? legalStatus;
  final RiskLevel riskLevel;
  final List<String> tags;
  final List<String> relatedSlugs;
  final Map<String, String> technicalData;

  const WikiArticleModel({
    required this.id,
    required this.slug,
    required this.title,
    this.subtitle = '',
    required this.category,
    required this.summary,
    required this.description,
    this.effects = const [],
    this.risks = const [],
    this.harmReductionTips = const [],
    this.legalStatus,
    this.riskLevel = RiskLevel.unknown,
    this.tags = const [],
    this.relatedSlugs = const [],
    this.technicalData = const {},
  });

  factory WikiArticleModel.fromJson(Map<String, dynamic> json) {
    return WikiArticleModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      category: WikiCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => WikiCategory.cannabinoids,
      ),
      summary: json['summary'] as String,
      description: json['description'] as String,
      effects: List<String>.from(json['effects'] ?? []),
      risks: List<String>.from(json['risks'] ?? []),
      harmReductionTips: List<String>.from(json['harm_reduction_tips'] ?? []),
      legalStatus: json['legal_status'] as String?,
      riskLevel: RiskLevel.values.firstWhere(
        (r) => r.name == json['risk_level'],
        orElse: () => RiskLevel.unknown,
      ),
      tags: List<String>.from(json['tags'] ?? []),
      relatedSlugs: List<String>.from(json['related_slugs'] ?? []),
      technicalData: Map<String, String>.from(json['technical_data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'title': title,
    'subtitle': subtitle,
    'category': category.name,
    'summary': summary,
    'description': description,
    'effects': effects,
    'risks': risks,
    'harm_reduction_tips': harmReductionTips,
    'legal_status': legalStatus,
    'risk_level': riskLevel.name,
    'tags': tags,
    'related_slugs': relatedSlugs,
    'technical_data': technicalData,
  };
}
