import 'package:flutter/foundation.dart';

/// Weekly AI-generated insights from Charlotte
@immutable
class WeeklyInsight {
  final String id;
  final String userId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalSessions;
  final int uniqueStrains;
  final double? cognitiveAverage;
  final double? cognitiveChangePercent;
  final String? cognitiveTrend;
  final List<InsightPattern> patterns;
  final List<InsightFinding> insights;
  final List<InsightAchievement> achievements;
  final List<InsightRecommendation> recommendations;
  final WeeklyComparison? comparison;
  final List<GoalProgress> goalsProgress;
  final String? summary;
  final DateTime generatedAt;
  final DateTime? viewedAt;
  final bool isViewed;

  const WeeklyInsight({
    required this.id,
    required this.userId,
    required this.weekStart,
    required this.weekEnd,
    this.totalSessions = 0,
    this.uniqueStrains = 0,
    this.cognitiveAverage,
    this.cognitiveChangePercent,
    this.cognitiveTrend,
    this.patterns = const [],
    this.insights = const [],
    this.achievements = const [],
    this.recommendations = const [],
    this.comparison,
    this.goalsProgress = const [],
    this.summary,
    required this.generatedAt,
    this.viewedAt,
    this.isViewed = false,
  });

  factory WeeklyInsight.fromJson(Map<String, dynamic> json) {
    return WeeklyInsight(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weekStart: DateTime.parse(json['week_start'] as String),
      weekEnd: DateTime.parse(json['week_end'] as String),
      totalSessions: json['total_sessions'] as int? ?? 0,
      uniqueStrains: json['unique_strains'] as int? ?? 0,
      cognitiveAverage: json['cognitive_average'] as double?,
      cognitiveChangePercent: json['cognitive_change_percent'] as double?,
      cognitiveTrend: json['cognitive_trend'] as String?,
      patterns: (json['patterns'] as List?)
              ?.map((e) => InsightPattern.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      insights: (json['insights'] as List?)
              ?.map((e) => InsightFinding.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      achievements: (json['achievements'] as List?)
              ?.map((e) => InsightAchievement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List?)
              ?.map((e) => InsightRecommendation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      comparison: json['comparison'] != null
          ? WeeklyComparison.fromJson(json['comparison'] as Map<String, dynamic>)
          : null,
      goalsProgress: (json['goals_progress'] as List?)
              ?.map((e) => GoalProgress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summary: json['summary'] as String?,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      viewedAt: json['viewed_at'] != null
          ? DateTime.parse(json['viewed_at'] as String)
          : null,
      isViewed: json['is_viewed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'week_start': weekStart.toIso8601String(),
      'week_end': weekEnd.toIso8601String(),
      'total_sessions': totalSessions,
      'unique_strains': uniqueStrains,
      'cognitive_average': cognitiveAverage,
      'cognitive_change_percent': cognitiveChangePercent,
      'cognitive_trend': cognitiveTrend,
      'patterns': patterns.map((e) => e.toJson()).toList(),
      'insights': insights.map((e) => e.toJson()).toList(),
      'achievements': achievements.map((e) => e.toJson()).toList(),
      'recommendations': recommendations.map((e) => e.toJson()).toList(),
      'comparison': comparison?.toJson(),
      'goals_progress': goalsProgress.map((e) => e.toJson()).toList(),
      'summary': summary,
      'generated_at': generatedAt.toIso8601String(),
      'viewed_at': viewedAt?.toIso8601String(),
      'is_viewed': isViewed,
    };
  }

  /// Get week date range as string
  String get weekRangeString {
    final start = weekStart;
    final end = weekEnd;
    return '${start.day}.${start.month}. - ${end.day}.${end.month}. ${end.year}';
  }

  /// Get overall status based on patterns and cognitive trend
  WeekStatus get overallStatus {
    // Check for high-severity patterns
    final hasHighSeverityPattern = patterns.any((p) => p.severity == 'high');

    if (hasHighSeverityPattern) return WeekStatus.needsAttention;

    // Check cognitive trend
    if (cognitiveTrend == 'declining' &&
        cognitiveChangePercent != null &&
        cognitiveChangePercent! < -10) {
      return WeekStatus.needsAttention;
    }

    if (cognitiveTrend == 'improving') return WeekStatus.good;

    return WeekStatus.normal;
  }

  /// Get status emoji
  String get statusEmoji {
    switch (overallStatus) {
      case WeekStatus.good:
        return '✅';
      case WeekStatus.needsAttention:
        return '⚠️';
      case WeekStatus.normal:
        return '📊';
    }
  }

  /// Get status color hex
  String get statusColorHex {
    switch (overallStatus) {
      case WeekStatus.good:
        return '66BB6A';
      case WeekStatus.needsAttention:
        return 'FF9800';
      case WeekStatus.normal:
        return '2196F3';
    }
  }
}

enum WeekStatus {
  good,
  normal,
  needsAttention,
}

/// Pattern detected in user behavior
@immutable
class InsightPattern {
  final String type;
  final String severity; // 'low', 'medium', 'high'
  final String description;
  final String? recommendation;

  const InsightPattern({
    required this.type,
    required this.severity,
    required this.description,
    this.recommendation,
  });

  factory InsightPattern.fromJson(Map<String, dynamic> json) {
    return InsightPattern(
      type: json['type'] as String,
      severity: json['severity'] as String,
      description: json['description'] as String,
      recommendation: json['recommendation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'severity': severity,
      'description': description,
      'recommendation': recommendation,
    };
  }
}

/// AI-generated finding/correlation
@immutable
class InsightFinding {
  final String type;
  final String title;
  final String description;
  final double confidence; // 0-1
  final Map<String, dynamic>? data;

  const InsightFinding({
    required this.type,
    required this.title,
    required this.description,
    this.confidence = 0.0,
    this.data,
  });

  factory InsightFinding.fromJson(Map<String, dynamic> json) {
    return InsightFinding(
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      confidence: json['confidence'] as double? ?? 0.0,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'confidence': confidence,
      'data': data,
    };
  }
}

/// Achievement earned this week
@immutable
class InsightAchievement {
  final String type;
  final String title;
  final String? description;
  final String icon;

  const InsightAchievement({
    required this.type,
    required this.title,
    this.description,
    this.icon = '🏆',
  });

  factory InsightAchievement.fromJson(Map<String, dynamic> json) {
    return InsightAchievement(
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? '🏆',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'icon': icon,
    };
  }
}

/// AI recommendation
@immutable
class InsightRecommendation {
  final String type;
  final String priority; // 'low', 'medium', 'high'
  final String message;
  final String? actionLabel;
  final String? actionRoute;

  const InsightRecommendation({
    required this.type,
    required this.priority,
    required this.message,
    this.actionLabel,
    this.actionRoute,
  });

  factory InsightRecommendation.fromJson(Map<String, dynamic> json) {
    return InsightRecommendation(
      type: json['type'] as String,
      priority: json['priority'] as String,
      message: json['message'] as String,
      actionLabel: json['action_label'] as String?,
      actionRoute: json['action_route'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'priority': priority,
      'message': message,
      'action_label': actionLabel,
      'action_route': actionRoute,
    };
  }
}

/// Week-over-week comparison
@immutable
class WeeklyComparison {
  final MetricComparison? sessions;
  final MetricComparison? cognitive;
  final MetricComparison? checkIns;
  final MetricComparison? uniqueStrains;

  const WeeklyComparison({
    this.sessions,
    this.cognitive,
    this.checkIns,
    this.uniqueStrains,
  });

  factory WeeklyComparison.fromJson(Map<String, dynamic> json) {
    return WeeklyComparison(
      sessions: json['sessions'] != null
          ? MetricComparison.fromJson(json['sessions'] as Map<String, dynamic>)
          : null,
      cognitive: json['cognitive'] != null
          ? MetricComparison.fromJson(json['cognitive'] as Map<String, dynamic>)
          : null,
      checkIns: json['check_ins'] != null
          ? MetricComparison.fromJson(json['check_ins'] as Map<String, dynamic>)
          : null,
      uniqueStrains: json['unique_strains'] != null
          ? MetricComparison.fromJson(json['unique_strains'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessions': sessions?.toJson(),
      'cognitive': cognitive?.toJson(),
      'check_ins': checkIns?.toJson(),
      'unique_strains': uniqueStrains?.toJson(),
    };
  }
}

/// Individual metric comparison
@immutable
class MetricComparison {
  final double current;
  final double previous;
  final String change; // "+50%", "-10%"
  final String trend; // 'up', 'down', 'stable'

  const MetricComparison({
    required this.current,
    required this.previous,
    required this.change,
    required this.trend,
  });

  factory MetricComparison.fromJson(Map<String, dynamic> json) {
    return MetricComparison(
      current: (json['current'] as num).toDouble(),
      previous: (json['previous'] as num).toDouble(),
      change: json['change'] as String,
      trend: json['trend'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'previous': previous,
      'change': change,
      'trend': trend,
    };
  }
}

/// Goal progress tracking
@immutable
class GoalProgress {
  final String goal;
  final double progress; // 0-1
  final String status; // 'on_track', 'behind', 'completed'
  final String? message;

  const GoalProgress({
    required this.goal,
    this.progress = 0.0,
    required this.status,
    this.message,
  });

  factory GoalProgress.fromJson(Map<String, dynamic> json) {
    return GoalProgress(
      goal: json['goal'] as String,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal': goal,
      'progress': progress,
      'status': status,
      'message': message,
    };
  }
}
