import 'package:flutter/foundation.dart';

/// Comprehensive strain journal entry with detailed effect tracking
@immutable
class StrainJournalEntry {
  final String id;
  final String userId;
  final String strainId;
  final String? strainName;
  final String? consumptionLogId;

  // Basic info
  final DateTime consumedAt;
  final String? method;
  final double? amount;
  final String? amountUnit;

  // Setting & Context
  final List<String> setting;
  final List<String> activities;
  final int? moodBefore;
  final String? intention;

  // Effects
  final PhysicalEffects physicalEffects;
  final MentalEffects mentalEffects;
  final EmotionalEffects emotionalEffects;

  // Duration
  final int? onsetTime;
  final int? peakTime;
  final int? totalDuration;

  // Overall
  final double? overallRating;
  final bool? wouldUseAgain;

  // User content
  final String? title;
  final String? notes;
  final List<String> highlights;
  final List<String> drawbacks;
  final List<String> tags;
  final List<String> photos;

  // AI Analysis
  final String? aiSummary;
  final List<AIRecommendation> aiRecommendations;
  final DateTime? aiAnalyzedAt;

  // Metadata
  final bool isFavorite;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StrainJournalEntry({
    required this.id,
    required this.userId,
    required this.strainId,
    this.strainName,
    this.consumptionLogId,
    required this.consumedAt,
    this.method,
    this.amount,
    this.amountUnit,
    this.setting = const [],
    this.activities = const [],
    this.moodBefore,
    this.intention,
    required this.physicalEffects,
    required this.mentalEffects,
    required this.emotionalEffects,
    this.onsetTime,
    this.peakTime,
    this.totalDuration,
    this.overallRating,
    this.wouldUseAgain,
    this.title,
    this.notes,
    this.highlights = const [],
    this.drawbacks = const [],
    this.tags = const [],
    this.photos = const [],
    this.aiSummary,
    this.aiRecommendations = const [],
    this.aiAnalyzedAt,
    this.isFavorite = false,
    this.isPrivate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasAIAnalysis => aiSummary != null;

  bool get isComplete {
    return overallRating != null &&
        (physicalEffects.hasAnyRating ||
            mentalEffects.hasAnyRating ||
            emotionalEffects.hasAnyRating);
  }

  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    if (strainName != null) return strainName!;
    return 'Journal Entry';
  }

  factory StrainJournalEntry.fromJson(Map<String, dynamic> json) {
    return StrainJournalEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      strainId: json['strain_id'] as String,
      strainName: json['strain_name'] as String?,
      consumptionLogId: json['consumption_log_id'] as String?,
      consumedAt: DateTime.parse(json['consumed_at'] as String),
      method: json['method'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      amountUnit: json['amount_unit'] as String?,
      setting: json['setting'] != null
          ? List<String>.from(json['setting'] as List)
          : [],
      activities: json['activities'] != null
          ? List<String>.from(json['activities'] as List)
          : [],
      moodBefore: json['mood_before'] as int?,
      intention: json['intention'] as String?,
      physicalEffects: PhysicalEffects.fromJson(json),
      mentalEffects: MentalEffects.fromJson(json),
      emotionalEffects: EmotionalEffects.fromJson(json),
      onsetTime: json['onset_time'] as int?,
      peakTime: json['peak_time'] as int?,
      totalDuration: json['total_duration'] as int?,
      overallRating: (json['overall_rating'] as num?)?.toDouble(),
      wouldUseAgain: json['would_use_again'] as bool?,
      title: json['title'] as String?,
      notes: json['notes'] as String?,
      highlights: json['highlights'] != null
          ? List<String>.from(json['highlights'] as List)
          : [],
      drawbacks: json['drawbacks'] != null
          ? List<String>.from(json['drawbacks'] as List)
          : [],
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : [],
      photos: json['photos'] != null
          ? List<String>.from(json['photos'] as List)
          : [],
      aiSummary: json['ai_summary'] as String?,
      aiRecommendations: json['ai_recommendations'] != null
          ? (json['ai_recommendations'] as List)
              .map((r) => AIRecommendation.fromJson(r))
              .toList()
          : [],
      aiAnalyzedAt: json['ai_analyzed_at'] != null
          ? DateTime.parse(json['ai_analyzed_at'] as String)
          : null,
      isFavorite: json['is_favorite'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'strain_id': strainId,
      'consumption_log_id': consumptionLogId,
      'consumed_at': consumedAt.toIso8601String(),
      'method': method,
      'amount': amount,
      'amount_unit': amountUnit,
      'setting': setting,
      'activities': activities,
      'mood_before': moodBefore,
      'intention': intention,
      ...physicalEffects.toJson(),
      ...mentalEffects.toJson(),
      ...emotionalEffects.toJson(),
      'onset_time': onsetTime,
      'peak_time': peakTime,
      'total_duration': totalDuration,
      'overall_rating': overallRating,
      'would_use_again': wouldUseAgain,
      'title': title,
      'notes': notes,
      'highlights': highlights,
      'drawbacks': drawbacks,
      'tags': tags,
      'photos': photos,
      'ai_summary': aiSummary,
      'ai_recommendations': aiRecommendations.map((r) => r.toJson()).toList(),
      'ai_analyzed_at': aiAnalyzedAt?.toIso8601String(),
      'is_favorite': isFavorite,
      'is_private': isPrivate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Physical effects (0-10 scale)
@immutable
class PhysicalEffects {
  final int? bodyHigh;
  final int? energyLevel;
  final int? appetite;
  final int? dryMouth;
  final int? redEyes;
  final int? physicalRelaxation;
  final int? painRelief;
  final int? sleepiness;

  const PhysicalEffects({
    this.bodyHigh,
    this.energyLevel,
    this.appetite,
    this.dryMouth,
    this.redEyes,
    this.physicalRelaxation,
    this.painRelief,
    this.sleepiness,
  });

  bool get hasAnyRating {
    return bodyHigh != null ||
        energyLevel != null ||
        appetite != null ||
        physicalRelaxation != null ||
        painRelief != null ||
        sleepiness != null;
  }

  factory PhysicalEffects.fromJson(Map<String, dynamic> json) {
    return PhysicalEffects(
      bodyHigh: json['body_high'] as int?,
      energyLevel: json['energy_level'] as int?,
      appetite: json['appetite'] as int?,
      dryMouth: json['dry_mouth'] as int?,
      redEyes: json['red_eyes'] as int?,
      physicalRelaxation: json['physical_relaxation'] as int?,
      painRelief: json['pain_relief'] as int?,
      sleepiness: json['sleepiness'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'body_high': bodyHigh,
      'energy_level': energyLevel,
      'appetite': appetite,
      'dry_mouth': dryMouth,
      'red_eyes': redEyes,
      'physical_relaxation': physicalRelaxation,
      'pain_relief': painRelief,
      'sleepiness': sleepiness,
    };
  }
}

/// Mental effects (0-10 scale)
@immutable
class MentalEffects {
  final int? headHigh;
  final int? focus;
  final int? creativity;
  final int? euphoria;
  final int? mentalClarity;
  final int? memoryImpact;
  final int? paranoia;

  const MentalEffects({
    this.headHigh,
    this.focus,
    this.creativity,
    this.euphoria,
    this.mentalClarity,
    this.memoryImpact,
    this.paranoia,
  });

  bool get hasAnyRating {
    return headHigh != null ||
        focus != null ||
        creativity != null ||
        euphoria != null ||
        mentalClarity != null;
  }

  factory MentalEffects.fromJson(Map<String, dynamic> json) {
    return MentalEffects(
      headHigh: json['head_high'] as int?,
      focus: json['focus'] as int?,
      creativity: json['creativity'] as int?,
      euphoria: json['euphoria'] as int?,
      mentalClarity: json['mental_clarity'] as int?,
      memoryImpact: json['memory_impact'] as int?,
      paranoia: json['paranoia'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'head_high': headHigh,
      'focus': focus,
      'creativity': creativity,
      'euphoria': euphoria,
      'mental_clarity': mentalClarity,
      'memory_impact': memoryImpact,
      'paranoia': paranoia,
    };
  }
}

/// Emotional effects (0-10 scale)
@immutable
class EmotionalEffects {
  final int? happiness;
  final int? anxietyRelief;
  final int? stressRelief;
  final int? sociability;
  final int? introspection;

  const EmotionalEffects({
    this.happiness,
    this.anxietyRelief,
    this.stressRelief,
    this.sociability,
    this.introspection,
  });

  bool get hasAnyRating {
    return happiness != null ||
        anxietyRelief != null ||
        stressRelief != null ||
        sociability != null ||
        introspection != null;
  }

  factory EmotionalEffects.fromJson(Map<String, dynamic> json) {
    return EmotionalEffects(
      happiness: json['happiness'] as int?,
      anxietyRelief: json['anxiety_relief'] as int?,
      stressRelief: json['stress_relief'] as int?,
      sociability: json['sociability'] as int?,
      introspection: json['introspection'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'happiness': happiness,
      'anxiety_relief': anxietyRelief,
      'stress_relief': stressRelief,
      'sociability': sociability,
      'introspection': introspection,
    };
  }
}

/// AI-generated recommendation
@immutable
class AIRecommendation {
  final String type;
  final String message;
  final String? actionRoute;

  const AIRecommendation({
    required this.type,
    required this.message,
    this.actionRoute,
  });

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      type: json['type'] as String,
      message: json['message'] as String,
      actionRoute: json['action_route'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
      'action_route': actionRoute,
    };
  }
}

/// Quick rating (star-only)
@immutable
class StrainQuickRating {
  final String id;
  final String userId;
  final String strainId;
  final double rating;
  final String? quickNotes;
  final DateTime createdAt;

  const StrainQuickRating({
    required this.id,
    required this.userId,
    required this.strainId,
    required this.rating,
    this.quickNotes,
    required this.createdAt,
  });

  factory StrainQuickRating.fromJson(Map<String, dynamic> json) {
    return StrainQuickRating(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      strainId: json['strain_id'] as String,
      rating: (json['rating'] as num).toDouble(),
      quickNotes: json['quick_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'strain_id': strainId,
      'rating': rating,
      'quick_notes': quickNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
