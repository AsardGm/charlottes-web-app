import 'package:flutter/material.dart';

/// Time-series aggregace kognitivních dat pro heatmap
class BrainHeatmapData {
  final DateTime weekStart;
  final double avgFocus;
  final double avgAnxiety;
  final double avgCreativity;
  final double avgMood;
  final int testCount;
  final TrendDirection focusTrend;
  final TrendDirection anxietyTrend;

  const BrainHeatmapData({
    required this.weekStart,
    required this.avgFocus,
    required this.avgAnxiety,
    required this.avgCreativity,
    required this.avgMood,
    required this.testCount,
    required this.focusTrend,
    required this.anxietyTrend,
  });

  /// Celkové brain health skóre (0-10)
  double get healthScore {
    // High focus + low anxiety + high creativity = healthy
    final focusWeight = avgFocus * 0.4;
    final anxietyPenalty = (10 - avgAnxiety) * 0.3; // inverted
    final creativityWeight = avgCreativity * 0.3;
    return (focusWeight + anxietyPenalty + creativityWeight).clamp(0, 10);
  }

  /// Barva pro heatmap tile
  Color get heatmapColor {
    if (healthScore >= 7.5) {
      return const Color(0xFF4CAF50); // Green - healthy
    } else if (healthScore >= 5.0) {
      return const Color(0xFFFFB74D); // Orange - warning
    } else {
      return const Color(0xFFEF5350); // Red - needs break
    }
  }

  /// Intenzita barvy (0.0 - 1.0)
  double get intensity {
    return (healthScore / 10).clamp(0.3, 1.0);
  }

  /// Potřebuje pauzu?
  bool get needsBreak {
    return healthScore < 5.0 ||
           avgAnxiety > 7.0 ||
           avgFocus < 4.0;
  }
}

/// Trend direction
enum TrendDirection {
  improving,
  stable,
  declining,
}

extension TrendDirectionExtension on TrendDirection {
  IconData get icon {
    switch (this) {
      case TrendDirection.improving:
        return Icons.trending_up;
      case TrendDirection.stable:
        return Icons.trending_flat;
      case TrendDirection.declining:
        return Icons.trending_down;
    }
  }

  Color get color {
    switch (this) {
      case TrendDirection.improving:
        return const Color(0xFF4CAF50);
      case TrendDirection.stable:
        return const Color(0xFFFFB74D);
      case TrendDirection.declining:
        return const Color(0xFFEF5350);
    }
  }

  String get label {
    switch (this) {
      case TrendDirection.improving:
        return 'Zlepšuje se';
      case TrendDirection.stable:
        return 'Stabilní';
      case TrendDirection.declining:
        return 'Klesá';
    }
  }
}

/// Insight o dlouhodobém trendu
class BrainHealthInsight {
  final InsightType type;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final InsightSeverity severity;

  const BrainHealthInsight({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.severity,
  });
}

enum InsightType {
  burnout,
  recovery,
  stable,
  needsBreak,
  improving,
}

enum InsightSeverity {
  critical, // Immediate action needed
  warning,  // Pay attention
  info,     // Good to know
  positive, // Positive feedback
}

extension InsightSeverityExtension on InsightSeverity {
  Color get color {
    switch (this) {
      case InsightSeverity.critical:
        return const Color(0xFFEF5350);
      case InsightSeverity.warning:
        return const Color(0xFFFFB74D);
      case InsightSeverity.info:
        return const Color(0xFF42A5F5);
      case InsightSeverity.positive:
        return const Color(0xFF4CAF50);
    }
  }
}
