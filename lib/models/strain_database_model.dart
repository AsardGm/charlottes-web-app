import 'package:flutter/material.dart';

enum StrainType { indica, sativa, hybrid }
enum DifficultyLevel { beginner, intermediate, advanced }
enum RiskFactor { anxietyProne, paranoiaProne, drymouth, hunger, sleepy, energetic }

class StrainDatabaseModel {
  final String id;
  final String name;
  final String? aka;
  final StrainType type;
  final DifficultyLevel difficulty;
  final String? breeder;
  final List<String> genetics;
  final List<String> phenotypes;
  final Map<String, double> terpeneProfile;
  final Map<String, int> effects;
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
  final Map<String, int>? awards;
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
      case StrainType.indica: return '🌙';
      case StrainType.sativa: return '☀️';
      case StrainType.hybrid: return '🌗';
    }
  }

  String get typeLabel {
    switch (type) {
      case StrainType.indica: return 'Indica';
      case StrainType.sativa: return 'Sativa';
      case StrainType.hybrid: return 'Hybrid';
    }
  }

  String get difficultyLabel {
    switch (difficulty) {
      case DifficultyLevel.beginner: return '🟢 Beginner';
      case DifficultyLevel.intermediate: return '🟡 Intermediate';
      case DifficultyLevel.advanced: return '🔴 Advanced';
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case DifficultyLevel.beginner: return Colors.green;
      case DifficultyLevel.intermediate: return Colors.orange;
      case DifficultyLevel.advanced: return Colors.red;
    }
  }

  String get thcRange {
    if (thcMin == null && thcMax == null) return 'N/A';
    if (thcMin == thcMax) return '${thcMin?.toStringAsFixed(1)}%';
    return '${thcMin?.toStringAsFixed(1)}-${thcMax?.toStringAsFixed(1)}%';
  }
}

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
      case AwardCategory.bestMedical: return '🏥 Best Medical';
      case AwardCategory.bestFlavor: return '👅 Best Flavor';
      case AwardCategory.bestFocus: return '🎯 Best Focus';
      case AwardCategory.bestSleep: return '😴 Best Sleep';
      case AwardCategory.bestCreativity: return '🎨 Best Creativity';
      case AwardCategory.bestSocial: return '🎉 Best Social';
      case AwardCategory.beginnerChoice: return '🌱 Beginner Choice';
      case AwardCategory.communityFavorite: return '❤️ Community Favorite';
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