import 'package:flutter/material.dart';

enum StrainType { indica, sativa, hybrid }
enum DifficultyLevel { beginner, intermediate, advanced }
enum RiskFactor { anxietyProne, paranoiaProne, drymouth, hunger, sleepy, energetic }

class StrainDatabaseModel {
  final String id;
  final String name;
  final String? aka; // Also known as
  final StrainType type;
  final DifficultyLevel difficulty;
  final String? breeder;
  final List<String> genetics; // Parent strains
  final List<String> phenotypes;
  final Map<String, double> terpeneProfile; // e.g., {'Myrcene': 0.45, 'Limonene': 0.23}
  final Map<String, int> effects; // e.g., {'Relaxed': 85, 'Happy': 72}
  final List<RiskFactor> riskFactors;
  final List<String> medicalUses;
  final List<String> flavors;
  final String? description;
  final String? imageUrl;
  final double? thcMin;
  final double? thcMax;
  final double? cbdMin;
  final double? cbdMax;
  final int totalVotes;
  final double averageRating;
  final Map<String, int>? awards; // e.g., {'2024_best_medical': 1, '2023_best_flavor': 2}
  final DateTime? createdAt;

  StrainDatabaseModel({
    required this.id,
    required this.name,
    this.aka,
    required this.type,
    required this.difficulty,
    this.breeder,
    this.genetics = const [],
    this.phenotypes = const [],
    this.terpeneProfile = const {},
    this.effects = const {},
    this.riskFactors = const [],
    this.medicalUses = const [],
    this.flavors = const [],
    this.description,
    this.imageUrl,
    this.thcMin,
    this.thcMax,
    this.cbdMin,
    this.cbdMax,
    this.totalVotes = 0,
    this.averageRating = 0.0,
    this.awards,
    this.createdAt,
  });

  String get typeEmoji {
    switch (type) {
      case StrainType.indica:
        return '🌙';
      case StrainType.sativa:
        return '☀️';
      case StrainType.hybrid:
        return '🌗';
    }
  }

  String get typeLabel {
    switch (type) {
      case StrainType.indica:
        return 'Indica';
      case StrainType.sativa:
        return 'Sativa';
      case StrainType.hybrid:
        return 'Hybrid';
    }
  }

  String get difficultyLabel {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return '🟢 Beginner Friendly';
      case DifficultyLevel.intermediate:
        return '🟡 Intermediate';
      case DifficultyLevel.advanced:
        return '🔴 Advanced';
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.orange;
      case DifficultyLevel.advanced:
        return Colors.red;
    }
  }

  String get thcRange {
    if (thcMin == null && thcMax == null) return 'N/A';
    if (thcMin == thcMax) return '${thcMin?.toStringAsFixed(1)}%';
    return '${thcMin?.toStringAsFixed(1)}-${thcMax?.toStringAsFixed(1)}%';
  }

  factory StrainDatabaseModel.fromJson(Map<String, dynamic> json) {
    return StrainDatabaseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      aka: json['aka'] as String?,
      type: StrainType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StrainType.hybrid,
      ),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => DifficultyLevel.intermediate,
      ),
      breeder: json['breeder'] as String?,
      genetics: List<String>.from(json['genetics'] ?? []),
      phenotypes: List<String>.from(json['phenotypes'] ?? []),
      terpeneProfile: Map<String, double>.from(json['terpene_profile'] ?? {}),
      effects: Map<String, int>.from(json['effects'] ?? {}),
      riskFactors: (json['risk_factors'] as List<dynamic>?)
              ?.map((e) => RiskFactor.values.firstWhere((r) => r.name == e))
              .toList() ??
          [],
      medicalUses: List<String>.from(json['medical_uses'] ?? []),
      flavors: List<String>.from(json['flavors'] ?? []),
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      thcMin: (json['thc_min'] as num?)?.toDouble(),
      thcMax: (json['thc_max'] as num?)?.toDouble(),
      cbdMin: (json['cbd_min'] as num?)?.toDouble(),
      cbdMax: (json['cbd_max'] as num?)?.toDouble(),
      totalVotes: json['total_votes'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      awards: json['awards'] != null ? Map<String, int>.from(json['awards']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'aka': aka,
      'type': type.name,
      'difficulty': difficulty.name,
      'breeder': breeder,
      'genetics': genetics,
      'phenotypes': phenotypes,
      'terpene_profile': terpeneProfile,
      'effects': effects,
      'risk_factors': riskFactors.map((e) => e.name).toList(),
      'medical_uses': medicalUses,
      'flavors': flavors,
      'description': description,
      'image_url': imageUrl,
      'thc_min': thcMin,
      'thc_max': thcMax,
      'cbd_min': cbdMin,
      'cbd_max': cbdMax,
      'total_votes': totalVotes,
      'average_rating': averageRating,
      'awards': awards,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

// Model of the Year kategorie
enum AwardCategory {
  bestMedical,
  bestFlavor,
  bestFocus,
  bestSleep,
  bestCreativity,
  bestSocial,
  beginnerChoice,
  communityFavorite,
}

extension AwardCategoryExt on AwardCategory {
  String get label {
    switch (this) {
      case AwardCategory.bestMedical:
        return '🏥 Best Medical';
      case AwardCategory.bestFlavor:
        return '👅 Best Flavor';
      case AwardCategory.bestFocus:
        return '🎯 Best Focus';
      case AwardCategory.bestSleep:
        return '😴 Best Sleep';
      case AwardCategory.bestCreativity:
        return '🎨 Best Creativity';
      case AwardCategory.bestSocial:
        return '🎉 Best Social';
      case AwardCategory.beginnerChoice:
        return '🌱 Beginner Choice';
      case AwardCategory.communityFavorite:
        return '❤️ Community Favorite';
    }
  }

  String get emoji {
    switch (this) {
      case AwardCategory.bestMedical:
        return '🏥';
      case AwardCategory.bestFlavor:
        return '👅';
      case AwardCategory.bestFocus:
        return '🎯';
      case AwardCategory.bestSleep:
        return '😴';
      case AwardCategory.bestCreativity:
        return '🎨';
      case AwardCategory.bestSocial:
        return '🎉';
      case AwardCategory.beginnerChoice:
        return '🌱';
      case AwardCategory.communityFavorite:
        return '❤️';
    }
  }
}

class StrainVote {
  final String userId;
  final String strainId;
  final AwardCategory category;
  final int year;
  final DateTime votedAt;

  StrainVote({
    required this.userId, 
    required this.strainId,
    required this.category,
    required this.year,
    required this.votedAt,
  });
}