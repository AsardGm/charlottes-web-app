import 'package:flutter/foundation.dart';

/// Cognitive performance trend
enum CognitiveTrend {
  improving,
  stable,
  declining,
  insufficient, // Not enough data
}

extension CognitiveTrendExtension on CognitiveTrend {
  String get displayName {
    switch (this) {
      case CognitiveTrend.improving:
        return 'Zlepšující se';
      case CognitiveTrend.stable:
        return 'Stabilní';
      case CognitiveTrend.declining:
        return 'Klesající';
      case CognitiveTrend.insufficient:
        return 'Nedostatek dat';
    }
  }

  String get emoji {
    switch (this) {
      case CognitiveTrend.improving:
        return '📈';
      case CognitiveTrend.stable:
        return '➡️';
      case CognitiveTrend.declining:
        return '📉';
      case CognitiveTrend.insufficient:
        return '❓';
    }
  }
}

/// Insights z cognitive test dat pro Charlotte AI
@immutable
class CognitiveInsights {
  // Základní metriky
  final int totalTests;
  final int last7DaysTests;
  final int last30DaysTests;

  // Aktuální stav
  final double? currentScore; // 0-100
  final double? baselineScore; // První nebo průměrná baseline
  final double? averageScore;

  // Trend analysis
  final CognitiveTrend trend;
  final double? trendPercentage; // +/- percentage change

  // Best/worst performance
  final double? bestScore;
  final double? worstScore;
  final DateTime? bestScoreDate;
  final DateTime? worstScoreDate;

  // Correlation s consumption
  final double? averageScoreAfterConsumption;
  final double? averageScoreWithoutConsumption;
  final bool hasConsumptionCorrelation;

  // Time patterns
  final Map<String, double> scoresByTimeOfDay; // morning, afternoon, evening, night
  final Map<String, double> scoresByDayOfWeek;

  // Last test info
  final DateTime? lastTestDate;
  final double? lastTestScore;
  final int? daysSinceLastTest;

  // Warnings
  final bool isSignificantDecline; // >20% drop from baseline
  final bool needsAttention; // Multiple declining tests in row
  final List<String> warnings;

  const CognitiveInsights({
    this.totalTests = 0,
    this.last7DaysTests = 0,
    this.last30DaysTests = 0,
    this.currentScore,
    this.baselineScore,
    this.averageScore,
    this.trend = CognitiveTrend.insufficient,
    this.trendPercentage,
    this.bestScore,
    this.worstScore,
    this.bestScoreDate,
    this.worstScoreDate,
    this.averageScoreAfterConsumption,
    this.averageScoreWithoutConsumption,
    this.hasConsumptionCorrelation = false,
    this.scoresByTimeOfDay = const {},
    this.scoresByDayOfWeek = const {},
    this.lastTestDate,
    this.lastTestScore,
    this.daysSinceLastTest,
    this.isSignificantDecline = false,
    this.needsAttention = false,
    this.warnings = const [],
  });

  static const CognitiveInsights empty = CognitiveInsights();

  /// Generuje textový summary pro Charlotte AI
  String generateSummary() {
    final buffer = StringBuffer();

    if (totalTests == 0) {
      return 'Uživatel zatím neprovedl žádné cognitive testy.';
    }

    buffer.writeln('Cognitive Performance Summary:');
    buffer.writeln('- Total tests: $totalTests');
    buffer.writeln('- Last 7 days: $last7DaysTests tests');
    buffer.writeln('- Last 30 days: $last30DaysTests tests');

    if (currentScore != null) {
      buffer.writeln('- Current score: ${currentScore!.toStringAsFixed(1)}/100');
    }

    if (averageScore != null) {
      buffer.writeln('- Average score: ${averageScore!.toStringAsFixed(1)}/100');
    }

    if (baselineScore != null && currentScore != null) {
      final diff = currentScore! - baselineScore!;
      final sign = diff >= 0 ? '+' : '';
      buffer.writeln('- vs Baseline: $sign${diff.toStringAsFixed(1)} points');
    }

    // Trend
    buffer.writeln('- Trend: ${trend.emoji} ${trend.displayName}');
    if (trendPercentage != null) {
      final sign = trendPercentage! >= 0 ? '+' : '';
      buffer.writeln('  - Change: $sign${trendPercentage!.toStringAsFixed(1)}%');
    }

    // Best/worst
    if (bestScore != null) {
      buffer.writeln('- Best score: ${bestScore!.toStringAsFixed(1)}');
    }
    if (worstScore != null) {
      buffer.writeln('- Worst score: ${worstScore!.toStringAsFixed(1)}');
    }

    // Consumption correlation
    if (hasConsumptionCorrelation) {
      buffer.writeln('- After consumption: ${averageScoreAfterConsumption!.toStringAsFixed(1)}/100');
      buffer.writeln('- Without consumption: ${averageScoreWithoutConsumption!.toStringAsFixed(1)}/100');
      final impact = averageScoreAfterConsumption! - averageScoreWithoutConsumption!;
      if (impact.abs() > 5) {
        final effect = impact > 0 ? 'positive' : 'negative';
        buffer.writeln('  - Consumption has $effect impact (${impact.toStringAsFixed(1)} points)');
      }
    }

    // Last test
    if (lastTestDate != null) {
      buffer.writeln('- Last test: $daysSinceLastTest days ago');
      if (lastTestScore != null) {
        buffer.writeln('  - Score: ${lastTestScore!.toStringAsFixed(1)}/100');
      }
    }

    // Warnings
    if (warnings.isNotEmpty) {
      buffer.writeln('- Warnings:');
      for (final warning in warnings) {
        buffer.writeln('  ⚠️ $warning');
      }
    }

    return buffer.toString();
  }

  /// Generuje doporučení pro Charlotte AI
  List<String> generateRecommendations() {
    final recommendations = <String>[];

    // Significant decline
    if (isSignificantDecline) {
      recommendations.add(
        '⚠️ Tvoje cognitive score významně klesl. '
        'Doporuču udělat tolerance break nebo změnit konzumační vzory.',
      );
    }

    // Needs attention
    if (needsAttention) {
      recommendations.add(
        'Vidím konzistentní pokles v cognitive performance. '
        'Měl/a bys zvážit harm reduction strategie.',
      );
    }

    // Improving trend
    if (trend == CognitiveTrend.improving) {
      recommendations.add(
        '${trend.emoji} Skvělá práce! Tvoje cognitive performance se zlepšuje. Pokračuj v tom, co děláš!',
      );
    }

    // Infrequent testing
    if (daysSinceLastTest != null && daysSinceLastTest! > 14 && totalTests > 3) {
      recommendations.add(
        'Poslední test byl před $daysSinceLastTest dny. '
        'Pravidelné testování pomáhá sledovat cognitive drift.',
      );
    }

    // Consumption correlation
    if (hasConsumptionCorrelation) {
      final impact = averageScoreAfterConsumption! - averageScoreWithoutConsumption!;
      if (impact < -10) {
        recommendations.add(
          'Konzumace má negativní vliv na tvoje cognitive score (-${impact.abs().toStringAsFixed(1)} bodů). '
          'Zkus experimentovat s nižšími dávkami nebo jinými strainy.',
        );
      } else if (impact > 5) {
        recommendations.add(
          'Zajímavé - tvoje cognitive score je lepší po konzumaci! '
          'Může to být díky anxiety reduction nebo specific strain effects.',
        );
      }
    }

    // Low average
    if (averageScore != null && averageScore! < 60 && totalTests > 5) {
      recommendations.add(
        'Tvůj průměrný cognitive score je poměrně nízký (${averageScore!.toStringAsFixed(1)}/100). '
        'Můžu ti pomoct s technikami pro zlepšení kognitivních funkcí?',
      );
    }

    // Stable performance
    if (trend == CognitiveTrend.stable && averageScore != null && averageScore! > 70) {
      recommendations.add(
        'Udržuješ stabilní a zdravý cognitive score. Výborná práce! 🧠',
      );
    }

    return recommendations;
  }

  /// Performance level category
  String get performanceLevel {
    if (currentScore == null) return 'Unknown';
    if (currentScore! >= 80) return 'Excellent';
    if (currentScore! >= 70) return 'Good';
    if (currentScore! >= 60) return 'Average';
    if (currentScore! >= 50) return 'Below Average';
    return 'Poor';
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTests': totalTests,
      'last7DaysTests': last7DaysTests,
      'last30DaysTests': last30DaysTests,
      'currentScore': currentScore,
      'baselineScore': baselineScore,
      'averageScore': averageScore,
      'trend': trend.name,
      'trendPercentage': trendPercentage,
      'bestScore': bestScore,
      'worstScore': worstScore,
      'bestScoreDate': bestScoreDate?.toIso8601String(),
      'worstScoreDate': worstScoreDate?.toIso8601String(),
      'averageScoreAfterConsumption': averageScoreAfterConsumption,
      'averageScoreWithoutConsumption': averageScoreWithoutConsumption,
      'hasConsumptionCorrelation': hasConsumptionCorrelation,
      'scoresByTimeOfDay': scoresByTimeOfDay,
      'scoresByDayOfWeek': scoresByDayOfWeek,
      'lastTestDate': lastTestDate?.toIso8601String(),
      'lastTestScore': lastTestScore,
      'daysSinceLastTest': daysSinceLastTest,
      'isSignificantDecline': isSignificantDecline,
      'needsAttention': needsAttention,
      'warnings': warnings,
    };
  }
}

/// Extended cognitive test result with context
class CognitiveTestResult {
  final String id;
  final String userId;
  final DateTime testedAt;

  // Test scores (0-100)
  final double totalScore;
  final double? reactionTimeScore;
  final double? memoryScore;
  final double? focusScore;

  // Raw metrics
  final int? reactionTimeMs;
  final int? memoryCorrect;
  final int? memoryTotal;

  // Context
  final bool wasAfterConsumption;
  final int? hoursAfterConsumption;
  final String? strainUsed;

  // Metadata
  final String? notes;
  final Map<String, dynamic>? additionalData;

  const CognitiveTestResult({
    required this.id,
    required this.userId,
    required this.testedAt,
    required this.totalScore,
    this.reactionTimeScore,
    this.memoryScore,
    this.focusScore,
    this.reactionTimeMs,
    this.memoryCorrect,
    this.memoryTotal,
    this.wasAfterConsumption = false,
    this.hoursAfterConsumption,
    this.strainUsed,
    this.notes,
    this.additionalData,
  });

  /// Time of day category
  String get timeOfDay {
    final hour = testedAt.hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  /// Day of week
  String get dayOfWeek {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[testedAt.weekday - 1];
  }
}
