import 'package:flutter/foundation.dart';

/// Insights z consumption dat pro Charlotte AI
@immutable
class ConsumptionInsights {
  // Základní statistiky
  final int totalSessions;
  final int last7DaysSessions;
  final int last30DaysSessions;

  // Nejčastější strain
  final String? mostCommonStrain;
  final int mostCommonStrainCount;

  // Průměrné skóre
  final double? averageCognitiveScore;
  final double? averageMoodScore;

  // Časové vzory
  final Map<String, int> consumptionByTimeOfDay; // morning, afternoon, evening, night
  final Map<String, int> consumptionByDayOfWeek;

  // Metody konzumace
  final Map<String, int> methodsUsed; // smoking, vaping, edibles, etc.

  // Terpene preferences
  final Map<String, int> preferredTerpenes;

  // Trendy
  final bool isIncreasing; // Je konzumace rostoucí?
  final bool isDecreasing;
  final bool isStable;

  // Last consumption info
  final DateTime? lastConsumptionDate;
  final String? lastConsumptionStrain;
  final String? lastConsumptionMethod;

  const ConsumptionInsights({
    this.totalSessions = 0,
    this.last7DaysSessions = 0,
    this.last30DaysSessions = 0,
    this.mostCommonStrain,
    this.mostCommonStrainCount = 0,
    this.averageCognitiveScore,
    this.averageMoodScore,
    this.consumptionByTimeOfDay = const {},
    this.consumptionByDayOfWeek = const {},
    this.methodsUsed = const {},
    this.preferredTerpenes = const {},
    this.isIncreasing = false,
    this.isDecreasing = false,
    this.isStable = true,
    this.lastConsumptionDate,
    this.lastConsumptionStrain,
    this.lastConsumptionMethod,
  });

  static const ConsumptionInsights empty = ConsumptionInsights();

  /// Generuje textový summary pro Charlotte AI
  String generateSummary() {
    final buffer = StringBuffer();

    if (totalSessions == 0) {
      return 'Uživatel zatím nemá zaznamenané žádné konzumační sessions.';
    }

    buffer.writeln('Consumption Summary:');
    buffer.writeln('- Total sessions: $totalSessions');
    buffer.writeln('- Last 7 days: $last7DaysSessions sessions');
    buffer.writeln('- Last 30 days: $last30DaysSessions sessions');

    if (mostCommonStrain != null) {
      buffer.writeln('- Most common strain: $mostCommonStrain ($mostCommonStrainCount times)');
    }

    if (lastConsumptionDate != null) {
      final daysSince = DateTime.now().difference(lastConsumptionDate!).inDays;
      buffer.writeln('- Last consumption: $daysSince days ago');
      if (lastConsumptionStrain != null) {
        buffer.writeln('  - Strain: $lastConsumptionStrain');
      }
      if (lastConsumptionMethod != null) {
        buffer.writeln('  - Method: $lastConsumptionMethod');
      }
    }

    if (averageCognitiveScore != null) {
      buffer.writeln('- Average cognitive score: ${averageCognitiveScore!.toStringAsFixed(1)}/10');
    }

    if (averageMoodScore != null) {
      buffer.writeln('- Average mood score: ${averageMoodScore!.toStringAsFixed(1)}/10');
    }

    // Trend analysis
    if (isIncreasing) {
      buffer.writeln('- Trend: Increasing consumption (consider harm reduction)');
    } else if (isDecreasing) {
      buffer.writeln('- Trend: Decreasing consumption');
    } else {
      buffer.writeln('- Trend: Stable consumption');
    }

    // Time patterns
    if (consumptionByTimeOfDay.isNotEmpty) {
      final mostCommonTime = consumptionByTimeOfDay.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      buffer.writeln('- Most common time: $mostCommonTime');
    }

    // Method preferences
    if (methodsUsed.isNotEmpty) {
      final mostCommonMethod = methodsUsed.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      buffer.writeln('- Preferred method: $mostCommonMethod');
    }

    return buffer.toString();
  }

  /// Generuje personalizované rady pro Charlotte AI
  List<String> generateRecommendations() {
    final recommendations = <String>[];

    // High frequency warning
    if (last7DaysSessions > 21) {
      // 3+ times daily
      recommendations.add(
        'Konzumuješ velmi často (${(last7DaysSessions / 7).toStringAsFixed(1)}× denně). '
        'Zvažuji tolerance break pro obnovení účinku.',
      );
    }

    // Increasing trend
    if (isIncreasing && last30DaysSessions > 30) {
      recommendations.add(
        'Tvoje konzumace roste. Můžu ti pomoct s harm reduction strategiemi?',
      );
    }

    // Low variety
    if (mostCommonStrainCount > totalSessions * 0.7) {
      recommendations.add(
        'Používáš hlavně jeden strain ($mostCommonStrain). '
        'Zkus experimentovat s jinými pro různé efekty!',
      );
    }

    // Cognitive score trend
    if (averageCognitiveScore != null && averageCognitiveScore! < 6) {
      recommendations.add(
        'Tvoje průměrné cognitive score je nízké. '
        'Zkus konzumovat méně nebo změnit metodu.',
      );
    }

    // Positive reinforcement
    if (last30DaysSessions < 30 && totalSessions > 30) {
      recommendations.add(
        'Skvělá práce! Udržuješ zdravou frekvenci konzumace. 🌿',
      );
    }

    return recommendations;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'last7DaysSessions': last7DaysSessions,
      'last30DaysSessions': last30DaysSessions,
      'mostCommonStrain': mostCommonStrain,
      'mostCommonStrainCount': mostCommonStrainCount,
      'averageCognitiveScore': averageCognitiveScore,
      'averageMoodScore': averageMoodScore,
      'consumptionByTimeOfDay': consumptionByTimeOfDay,
      'consumptionByDayOfWeek': consumptionByDayOfWeek,
      'methodsUsed': methodsUsed,
      'preferredTerpenes': preferredTerpenes,
      'isIncreasing': isIncreasing,
      'isDecreasing': isDecreasing,
      'isStable': isStable,
      'lastConsumptionDate': lastConsumptionDate?.toIso8601String(),
      'lastConsumptionStrain': lastConsumptionStrain,
      'lastConsumptionMethod': lastConsumptionMethod,
    };
  }

  factory ConsumptionInsights.fromJson(Map<String, dynamic> json) {
    return ConsumptionInsights(
      totalSessions: json['totalSessions'] ?? 0,
      last7DaysSessions: json['last7DaysSessions'] ?? 0,
      last30DaysSessions: json['last30DaysSessions'] ?? 0,
      mostCommonStrain: json['mostCommonStrain'],
      mostCommonStrainCount: json['mostCommonStrainCount'] ?? 0,
      averageCognitiveScore: json['averageCognitiveScore']?.toDouble(),
      averageMoodScore: json['averageMoodScore']?.toDouble(),
      consumptionByTimeOfDay: Map<String, int>.from(json['consumptionByTimeOfDay'] ?? {}),
      consumptionByDayOfWeek: Map<String, int>.from(json['consumptionByDayOfWeek'] ?? {}),
      methodsUsed: Map<String, int>.from(json['methodsUsed'] ?? {}),
      preferredTerpenes: Map<String, int>.from(json['preferredTerpenes'] ?? {}),
      isIncreasing: json['isIncreasing'] ?? false,
      isDecreasing: json['isDecreasing'] ?? false,
      isStable: json['isStable'] ?? true,
      lastConsumptionDate: json['lastConsumptionDate'] != null
          ? DateTime.parse(json['lastConsumptionDate'])
          : null,
      lastConsumptionStrain: json['lastConsumptionStrain'],
      lastConsumptionMethod: json['lastConsumptionMethod'],
    );
  }
}

/// Extended consumption log model s dodatečnými insights fields
class ConsumptionLogExtended {
  final String id;
  final String userId;
  final DateTime consumedAt;

  // Basic info
  final String? strainName;
  final String? strainId;
  final String method; // smoking, vaping, edibles, tincture, etc.
  final double? amountGrams;

  // Effects tracking
  final int? moodBefore; // 1-10
  final int? moodAfter; // 1-10
  final int? cognitiveScoreBefore; // 1-10
  final int? cognitiveScoreAfter; // 1-10

  // Terpenes (if known)
  final List<String>? dominantTerpenes;

  // Notes
  final String? notes;
  final List<String>? tags; // relaxing, creative, energetic, etc.

  // Location/context
  final String? location; // home, outdoors, social, etc.
  final bool isAlone;

  // Post-consumption check
  final bool hasPostCheck;
  final DateTime? postCheckAt;
  final int? postCheckScore; // Overall experience 1-10

  const ConsumptionLogExtended({
    required this.id,
    required this.userId,
    required this.consumedAt,
    this.strainName,
    this.strainId,
    required this.method,
    this.amountGrams,
    this.moodBefore,
    this.moodAfter,
    this.cognitiveScoreBefore,
    this.cognitiveScoreAfter,
    this.dominantTerpenes,
    this.notes,
    this.tags,
    this.location,
    this.isAlone = true,
    this.hasPostCheck = false,
    this.postCheckAt,
    this.postCheckScore,
  });

  /// Time of day category
  String get timeOfDay {
    final hour = consumedAt.hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  /// Day of week
  String get dayOfWeek {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[consumedAt.weekday - 1];
  }

  /// Mood improvement
  int? get moodImprovement {
    if (moodBefore == null || moodAfter == null) return null;
    return moodAfter! - moodBefore!;
  }

  /// Cognitive impact
  int? get cognitiveImpact {
    if (cognitiveScoreBefore == null || cognitiveScoreAfter == null) return null;
    return cognitiveScoreAfter! - cognitiveScoreBefore!;
  }
}
