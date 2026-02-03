import 'package:flutter/foundation.dart';

/// Status of tolerance break
enum TBreakStatus {
  active,
  completed,
  failed,
}

extension TBreakStatusExtension on TBreakStatus {
  String get displayName {
    switch (this) {
      case TBreakStatus.active:
        return 'Aktivní';
      case TBreakStatus.completed:
        return 'Dokončeno';
      case TBreakStatus.failed:
        return 'Ukončeno předčasně';
    }
  }

  String get emoji {
    switch (this) {
      case TBreakStatus.active:
        return '💪';
      case TBreakStatus.completed:
        return '🎉';
      case TBreakStatus.failed:
        return '🔄';
    }
  }
}

/// Motivation for taking a tolerance break
enum TBreakMotivation {
  lowerTolerance,
  health,
  saveMoney,
  resetReceptors,
  proveMyself,
  other,
}

extension TBreakMotivationExtension on TBreakMotivation {
  String get displayName {
    switch (this) {
      case TBreakMotivation.lowerTolerance:
        return 'Snížit toleranci';
      case TBreakMotivation.health:
        return 'Zdravotní důvody';
      case TBreakMotivation.saveMoney:
        return 'Ušetřit peníze';
      case TBreakMotivation.resetReceptors:
        return 'Reset receptorů';
      case TBreakMotivation.proveMyself:
        return 'Dokázat si to';
      case TBreakMotivation.other:
        return 'Jiné';
    }
  }

  String get emoji {
    switch (this) {
      case TBreakMotivation.lowerTolerance:
        return '📉';
      case TBreakMotivation.health:
        return '🏥';
      case TBreakMotivation.saveMoney:
        return '💰';
      case TBreakMotivation.resetReceptors:
        return '🧠';
      case TBreakMotivation.proveMyself:
        return '💪';
      case TBreakMotivation.other:
        return '✨';
    }
  }
}

/// Tolerance Break model
@immutable
class ToleranceBreak {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime targetEndDate;
  final int targetDays;
  final TBreakStatus status;
  final TBreakMotivation motivation;
  final String? customMotivation;

  // Progress
  final int daysCompleted;
  final DateTime? completedDate;
  final DateTime? failedDate;

  // Daily check-ins
  final List<TBreakCheckIn> checkIns;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const ToleranceBreak({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.targetEndDate,
    required this.targetDays,
    required this.status,
    required this.motivation,
    this.customMotivation,
    this.daysCompleted = 0,
    this.completedDate,
    this.failedDate,
    this.checkIns = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate progress percentage
  double get progressPercentage {
    return (daysCompleted / targetDays * 100).clamp(0, 100);
  }

  /// Get days remaining
  int get daysRemaining {
    return (targetDays - daysCompleted).clamp(0, targetDays);
  }

  /// Check if T-break is currently active
  bool get isActive => status == TBreakStatus.active;

  /// Get encouragement message based on progress
  String getEncouragementMessage() {
    if (daysCompleted == 0) {
      return 'První den je nejtěžší - jsi silnější než si myslíš! 💪';
    } else if (daysCompleted == 3) {
      return 'Peak withdrawal - drž se! Za pár dní bude lepší. 🌟';
    } else if (daysCompleted == 7) {
      return 'Týden za tebou! Tvoje receptory ti děkují. 🧠';
    } else if (daysCompleted == 14) {
      return 'Polovka! Tolerance je významně nižší. 🎯';
    } else if (daysCompleted >= targetDays) {
      return 'DOKÁZAL JSI TO! 🎉';
    } else if (daysCompleted > targetDays / 2) {
      return 'Víc než polovina - držíš se skvěle! ⭐';
    } else {
      return 'Pokračuj! Každý den se počítá. 💚';
    }
  }

  /// Get milestone badge for current progress
  String? getMilestoneBadge() {
    if (daysCompleted >= 30) return 'Master of Willpower';
    if (daysCompleted >= 14) return 'Tolerance Slayer';
    if (daysCompleted >= 7) return 'Week Champion';
    if (daysCompleted >= 3) return 'Warrior';
    if (daysCompleted >= 1) return 'First Day Hero';
    return null;
  }

  factory ToleranceBreak.fromJson(Map<String, dynamic> json) {
    return ToleranceBreak(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      targetEndDate: DateTime.parse(json['target_end_date'] as String),
      targetDays: json['target_days'] as int,
      status: TBreakStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TBreakStatus.active,
      ),
      motivation: TBreakMotivation.values.firstWhere(
        (e) => e.name == json['motivation'],
        orElse: () => TBreakMotivation.other,
      ),
      customMotivation: json['custom_motivation'] as String?,
      daysCompleted: json['days_completed'] as int? ?? 0,
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date'] as String)
          : null,
      failedDate: json['failed_date'] != null
          ? DateTime.parse(json['failed_date'] as String)
          : null,
      checkIns: const [], // Load separately if needed
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_date': startDate.toIso8601String(),
      'target_end_date': targetEndDate.toIso8601String(),
      'target_days': targetDays,
      'status': status.name,
      'motivation': motivation.name,
      'custom_motivation': customMotivation,
      'days_completed': daysCompleted,
      'completed_date': completedDate?.toIso8601String(),
      'failed_date': failedDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Daily check-in for tolerance break
@immutable
class TBreakCheckIn {
  final String id;
  final String tBreakId;
  final DateTime date;
  final int dayNumber;

  // Mood & feelings (1-10)
  final int moodScore;
  final bool hadCravings;
  final int sleepQuality;
  final int anxietyLevel;

  // Symptoms
  final List<String> symptoms;
  final String? notes;

  final DateTime createdAt;

  const TBreakCheckIn({
    required this.id,
    required this.tBreakId,
    required this.date,
    required this.dayNumber,
    required this.moodScore,
    required this.hadCravings,
    required this.sleepQuality,
    required this.anxietyLevel,
    this.symptoms = const [],
    this.notes,
    required this.createdAt,
  });

  factory TBreakCheckIn.fromJson(Map<String, dynamic> json) {
    return TBreakCheckIn(
      id: json['id'] as String,
      tBreakId: json['tbreak_id'] as String,
      date: DateTime.parse(json['date'] as String),
      dayNumber: json['day_number'] as int,
      moodScore: json['mood_score'] as int,
      hadCravings: json['had_cravings'] as bool,
      sleepQuality: json['sleep_quality'] as int,
      anxietyLevel: json['anxiety_level'] as int,
      symptoms: json['symptoms'] != null
          ? List<String>.from(json['symptoms'] as List)
          : [],
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tbreak_id': tBreakId,
      'date': date.toIso8601String(),
      'day_number': dayNumber,
      'mood_score': moodScore,
      'had_cravings': hadCravings,
      'sleep_quality': sleepQuality,
      'anxiety_level': anxietyLevel,
      'symptoms': symptoms,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Common withdrawal symptoms
class TBreakSymptoms {
  static const List<String> common = [
    'Irritability',
    'Insomnia',
    'Vivid dreams',
    'Appetite changes',
    'Headache',
    'Sweating',
    'Restlessness',
    'Anxiety',
    'Depression',
    'Concentration issues',
  ];

  static String getCzechName(String symptom) {
    switch (symptom) {
      case 'Irritability':
        return 'Podrážděnost';
      case 'Insomnia':
        return 'Nespavost';
      case 'Vivid dreams':
        return 'Živé sny';
      case 'Appetite changes':
        return 'Změny chuti k jídlu';
      case 'Headache':
        return 'Bolest hlavy';
      case 'Sweating':
        return 'Pocení';
      case 'Restlessness':
        return 'Neklid';
      case 'Anxiety':
        return 'Úzkost';
      case 'Depression':
        return 'Deprese';
      case 'Concentration issues':
        return 'Problémy s koncentrací';
      default:
        return symptom;
    }
  }
}
