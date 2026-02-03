import 'package:flutter/foundation.dart';

/// Strain effectiveness data for a specific user and strain
@immutable
class StrainEffect {
  final String id;
  final String userId;
  final String strainId;
  final String? strainName;

  // Session statistics
  final int totalSessions;
  final DateTime? firstUsedAt;
  final DateTime? lastUsedAt;

  // Mood metrics (1-10 scale)
  final double? avgMoodBefore;
  final double? avgMoodAfter;
  final double? avgEnergyBefore;
  final double? avgEnergyAfter;
  final double? avgFocusBefore;
  final double? avgFocusAfter;
  final double? avgAnxietyBefore;
  final double? avgAnxietyAfter;

  // Cognitive impact
  final double? avgCognitiveScore;
  final int cognitiveSessions;

  // Common effects
  final List<EffectTag> commonEffects;

  // User rating
  final double? userRating;

  const StrainEffect({
    required this.id,
    required this.userId,
    required this.strainId,
    this.strainName,
    required this.totalSessions,
    this.firstUsedAt,
    this.lastUsedAt,
    this.avgMoodBefore,
    this.avgMoodAfter,
    this.avgEnergyBefore,
    this.avgEnergyAfter,
    this.avgFocusBefore,
    this.avgFocusAfter,
    this.avgAnxietyBefore,
    this.avgAnxietyAfter,
    this.avgCognitiveScore,
    this.cognitiveSessions = 0,
    this.commonEffects = const [],
    this.userRating,
  });

  // Calculated properties
  double get moodBoost =>
      (avgMoodAfter ?? 0) - (avgMoodBefore ?? 0);

  double get energyChange =>
      (avgEnergyAfter ?? 0) - (avgEnergyBefore ?? 0);

  double get focusChange =>
      (avgFocusAfter ?? 0) - (avgFocusBefore ?? 0);

  double get anxietyChange =>
      (avgAnxietyAfter ?? 0) - (avgAnxietyBefore ?? 0);

  double get effectivenessScore {
    // Weighted score based on positive changes
    double score = 0;
    score += moodBoost * 0.3;
    score += focusChange * 0.3;
    score += energyChange * 0.2;
    score -= anxietyChange * 0.2; // Lower anxiety is better
    return score.clamp(0, 10);
  }

  factory StrainEffect.fromJson(Map<String, dynamic> json) {
    return StrainEffect(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      strainId: json['strain_id'] as String,
      strainName: json['strain_name'] as String?,
      totalSessions: json['total_sessions'] as int? ?? 0,
      firstUsedAt: json['first_used_at'] != null
          ? DateTime.parse(json['first_used_at'] as String)
          : null,
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      avgMoodBefore: (json['avg_mood_before'] as num?)?.toDouble(),
      avgMoodAfter: (json['avg_mood_after'] as num?)?.toDouble(),
      avgEnergyBefore: (json['avg_energy_before'] as num?)?.toDouble(),
      avgEnergyAfter: (json['avg_energy_after'] as num?)?.toDouble(),
      avgFocusBefore: (json['avg_focus_before'] as num?)?.toDouble(),
      avgFocusAfter: (json['avg_focus_after'] as num?)?.toDouble(),
      avgAnxietyBefore: (json['avg_anxiety_before'] as num?)?.toDouble(),
      avgAnxietyAfter: (json['avg_anxiety_after'] as num?)?.toDouble(),
      avgCognitiveScore: (json['avg_cognitive_score'] as num?)?.toDouble(),
      cognitiveSessions: json['cognitive_sessions'] as int? ?? 0,
      commonEffects: json['common_effects'] != null
          ? (json['common_effects'] as List)
              .map((e) => EffectTag.fromJson(e))
              .toList()
          : [],
      userRating: (json['user_rating'] as num?)?.toDouble(),
    );
  }
}

/// Effect tag with count
@immutable
class EffectTag {
  final String effect;
  final int count;

  const EffectTag({
    required this.effect,
    required this.count,
  });

  factory EffectTag.fromJson(Map<String, dynamic> json) {
    return EffectTag(
      effect: json['effect'] as String,
      count: json['count'] as int,
    );
  }
}

/// Correlation insight between two factors
@immutable
class CorrelationInsight {
  final String id;
  final String userId;
  final String type;
  final String factorA;
  final String factorB;

  // Statistical measures
  final double? correlationCoefficient;
  final double? pValue;
  final int sampleSize;
  final ConfidenceLevel confidenceLevel;

  // Insight content
  final Map<String, dynamic> insightData;
  final String summary;
  final String? recommendation;

  final DateTime calculatedAt;
  final DateTime? expiresAt;

  const CorrelationInsight({
    required this.id,
    required this.userId,
    required this.type,
    required this.factorA,
    required this.factorB,
    this.correlationCoefficient,
    this.pValue,
    required this.sampleSize,
    required this.confidenceLevel,
    required this.insightData,
    required this.summary,
    this.recommendation,
    required this.calculatedAt,
    this.expiresAt,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isSignificant =>
      correlationCoefficient != null &&
      correlationCoefficient!.abs() > 0.3 &&
      pValue != null &&
      pValue! < 0.05;

  String get strengthLabel {
    if (correlationCoefficient == null) return 'Unknown';
    final abs = correlationCoefficient!.abs();
    if (abs < 0.3) return 'Weak';
    if (abs < 0.7) return 'Moderate';
    return 'Strong';
  }

  factory CorrelationInsight.fromJson(Map<String, dynamic> json) {
    return CorrelationInsight(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      factorA: json['factor_a'] as String,
      factorB: json['factor_b'] as String,
      correlationCoefficient:
          (json['correlation_coefficient'] as num?)?.toDouble(),
      pValue: (json['p_value'] as num?)?.toDouble(),
      sampleSize: json['sample_size'] as int? ?? 0,
      confidenceLevel: _parseConfidenceLevel(json['confidence_level'] as String?),
      insightData: json['insight_data'] as Map<String, dynamic>? ?? {},
      summary: json['summary'] as String? ?? '',
      recommendation: json['recommendation'] as String?,
      calculatedAt: DateTime.parse(json['calculated_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  static ConfidenceLevel _parseConfidenceLevel(String? level) {
    switch (level) {
      case 'high':
        return ConfidenceLevel.high;
      case 'medium':
        return ConfidenceLevel.medium;
      case 'low':
        return ConfidenceLevel.low;
      default:
        return ConfidenceLevel.low;
    }
  }
}

enum ConfidenceLevel {
  high,
  medium,
  low,
}

/// Consumption patterns analysis
@immutable
class ConsumptionPattern {
  final String id;
  final String userId;

  // Time-based patterns
  final List<String> bestTimeOfDay;
  final List<String> worstTimeOfDay;
  final List<String> bestDayOfWeek;
  final List<String> worstDayOfWeek;

  // Dosage patterns
  final Map<String, dynamic>? optimalDosageRange;

  // Frequency patterns
  final String? optimalFrequency;
  final int? breakRecommendation;

  // Method patterns
  final List<String> bestMethods;

  // Activities
  final List<ActivityBoost> bestActivities;

  // Confidence and metadata
  final double confidence;
  final int basedOnSessions;
  final DateTime calculatedAt;

  const ConsumptionPattern({
    required this.id,
    required this.userId,
    this.bestTimeOfDay = const [],
    this.worstTimeOfDay = const [],
    this.bestDayOfWeek = const [],
    this.worstDayOfWeek = const [],
    this.optimalDosageRange,
    this.optimalFrequency,
    this.breakRecommendation,
    this.bestMethods = const [],
    this.bestActivities = const [],
    required this.confidence,
    required this.basedOnSessions,
    required this.calculatedAt,
  });

  bool get hasEnoughData => basedOnSessions >= 10;

  bool get isHighConfidence => confidence >= 0.7;

  factory ConsumptionPattern.fromJson(Map<String, dynamic> json) {
    return ConsumptionPattern(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bestTimeOfDay: json['best_time_of_day'] != null
          ? List<String>.from(json['best_time_of_day'] as List)
          : [],
      worstTimeOfDay: json['worst_time_of_day'] != null
          ? List<String>.from(json['worst_time_of_day'] as List)
          : [],
      bestDayOfWeek: json['best_day_of_week'] != null
          ? List<String>.from(json['best_day_of_week'] as List)
          : [],
      worstDayOfWeek: json['worst_day_of_week'] != null
          ? List<String>.from(json['worst_day_of_week'] as List)
          : [],
      optimalDosageRange: json['optimal_dosage_range'] as Map<String, dynamic>?,
      optimalFrequency: json['optimal_frequency'] as String?,
      breakRecommendation: json['break_recommendation'] as int?,
      bestMethods: json['best_methods'] != null
          ? List<String>.from(json['best_methods'] as List)
          : [],
      bestActivities: json['best_activities'] != null
          ? (json['best_activities'] as List)
              .map((e) => ActivityBoost.fromJson(e))
              .toList()
          : [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      basedOnSessions: json['based_on_sessions'] as int? ?? 0,
      calculatedAt: DateTime.parse(json['calculated_at'] as String),
    );
  }
}

@immutable
class ActivityBoost {
  final String activity;
  final double boost;

  const ActivityBoost({
    required this.activity,
    required this.boost,
  });

  factory ActivityBoost.fromJson(Map<String, dynamic> json) {
    return ActivityBoost(
      activity: json['activity'] as String,
      boost: (json['boost'] as num).toDouble(),
    );
  }
}

/// Strain recommendation
@immutable
class StrainRecommendation {
  final String id;
  final String userId;
  final String strainId;
  final String? strainName;

  // Recommendation score
  final double score;

  // Reasoning
  final List<RecommendationReason> reasons;

  // Context
  final List<String> recommendedFor;
  final List<String> recommendedTimes;

  // Expected outcomes
  final double? expectedMoodBoost;
  final double? expectedEnergyChange;
  final double? expectedFocusChange;

  // Status
  final bool isTried;
  final double? actualRating;

  final DateTime generatedAt;
  final DateTime? expiresAt;
  final DateTime? triedAt;

  const StrainRecommendation({
    required this.id,
    required this.userId,
    required this.strainId,
    this.strainName,
    required this.score,
    this.reasons = const [],
    this.recommendedFor = const [],
    this.recommendedTimes = const [],
    this.expectedMoodBoost,
    this.expectedEnergyChange,
    this.expectedFocusChange,
    this.isTried = false,
    this.actualRating,
    required this.generatedAt,
    this.expiresAt,
    this.triedAt,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory StrainRecommendation.fromJson(Map<String, dynamic> json) {
    return StrainRecommendation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      strainId: json['strain_id'] as String,
      strainName: json['strain_name'] as String?,
      score: (json['score'] as num).toDouble(),
      reasons: json['reasons'] != null
          ? (json['reasons'] as List)
              .map((e) => RecommendationReason.fromJson(e))
              .toList()
          : [],
      recommendedFor: json['recommended_for'] != null
          ? List<String>.from(json['recommended_for'] as List)
          : [],
      recommendedTimes: json['recommended_times'] != null
          ? List<String>.from(json['recommended_times'] as List)
          : [],
      expectedMoodBoost: (json['expected_mood_boost'] as num?)?.toDouble(),
      expectedEnergyChange: (json['expected_energy_change'] as num?)?.toDouble(),
      expectedFocusChange: (json['expected_focus_change'] as num?)?.toDouble(),
      isTried: json['is_tried'] as bool? ?? false,
      actualRating: (json['actual_rating'] as num?)?.toDouble(),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      triedAt: json['tried_at'] != null
          ? DateTime.parse(json['tried_at'] as String)
          : null,
    );
  }
}

@immutable
class RecommendationReason {
  final String type;
  final String description;

  const RecommendationReason({
    required this.type,
    required this.description,
  });

  factory RecommendationReason.fromJson(Map<String, dynamic> json) {
    return RecommendationReason(
      type: json['type'] as String,
      description: json['description'] as String,
    );
  }
}
