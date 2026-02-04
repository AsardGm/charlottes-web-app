import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/weekly_insight_model.dart';
import 'tbreak_service.dart';
import 'cache_service.dart';

/// Service for generating and managing weekly AI insights
class WeeklyInsightsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CacheService _cache = CacheService();

  /// Get all weekly insights for user (sorted by week_start desc)
  Future<List<WeeklyInsight>> getUserWeeklyInsights(String userId) async {
    final response = await _supabase
        .from('weekly_insights')
        .select()
        .eq('user_id', userId)
        .order('week_start', ascending: false);

    return (response as List)
        .map((json) => WeeklyInsight.fromJson(json))
        .toList();
  }

  /// Get latest unviewed insight
  Future<WeeklyInsight?> getLatestUnviewedInsight(
    String userId, {
    bool forceRefresh = false,
  }) async {
    return await _cache.getOrFetch(
      'weekly_insight_unviewed_$userId',
      () async {
        final response = await _supabase
            .from('weekly_insights')
            .select()
            .eq('user_id', userId)
            .eq('is_viewed', false)
            .order('week_start', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response == null) return null;
        return WeeklyInsight.fromJson(response);
      },
      expiry: const Duration(minutes: 15),
      forceRefresh: forceRefresh,
    );
  }

  /// Mark insight as viewed
  Future<void> markAsViewed(String insightId, String userId) async {
    await _supabase.from('weekly_insights').update({
      'viewed_at': DateTime.now().toIso8601String(),
      'is_viewed': true,
    }).eq('id', insightId);

    // Invalidate cache
    _cache.clear('weekly_insight_unviewed_$userId');
  }

  /// Generate weekly insight for user
  /// This is the main intelligence function
  Future<WeeklyInsight> generateWeeklyInsight(String userId) async {
    // Define week range (previous week: Sunday to Saturday)
    final now = DateTime.now();
    final weekEnd = now.subtract(Duration(days: now.weekday % 7));
    final weekStart = weekEnd.subtract(const Duration(days: 6));

    // Check if already generated
    final existing = await _supabase
        .from('weekly_insights')
        .select()
        .eq('user_id', userId)
        .eq('week_start', weekStart.toIso8601String().split('T')[0])
        .maybeSingle();

    if (existing != null) {
      return WeeklyInsight.fromJson(existing);
    }

    // Gather all data for analysis
    final consumptionData = await _getConsumptionData(userId, weekStart, weekEnd);
    final cognitiveData = await _getCognitiveData(userId, weekStart, weekEnd);
    final previousWeekData = await _getPreviousWeekData(
      userId,
      weekStart.subtract(const Duration(days: 7)),
      weekStart.subtract(const Duration(days: 1)),
    );

    // Run all analysis
    final patterns = await _detectPatterns(
      userId,
      consumptionData,
      cognitiveData,
    );

    final insights = await _generateInsights(
      consumptionData,
      cognitiveData,
      previousWeekData,
    );

    final achievements = await _detectAchievements(
      userId,
      consumptionData,
      cognitiveData,
    );

    final recommendations = await _generateRecommendations(
      userId,
      patterns,
      consumptionData,
      cognitiveData,
    );

    final comparison = _generateComparison(
      consumptionData,
      cognitiveData,
      previousWeekData,
    );

    final goalsProgress = await _calculateGoalsProgress(
      userId,
      consumptionData,
      cognitiveData,
    );

    // Generate AI summary
    final summary = _generateSummary(
      patterns,
      insights,
      achievements,
      recommendations,
    );

    // Calculate cognitive trends
    final cognitiveAverage = cognitiveData['average_score'] as double?;
    final cognitiveChangePercent = comparison?.cognitive?.change;
    String? cognitiveTrend;
    if (cognitiveChangePercent != null) {
      final change = double.tryParse(
            cognitiveChangePercent.replaceAll('%', '').replaceAll('+', ''),
          ) ??
          0;
      if (change > 5) {
        cognitiveTrend = 'improving';
      } else if (change < -5) {
        cognitiveTrend = 'declining';
      } else {
        cognitiveTrend = 'stable';
      }
    }

    // Create and save insight
    final insight = WeeklyInsight(
      id: '', // Will be set by DB
      userId: userId,
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalSessions: consumptionData['total_sessions'] as int? ?? 0,
      uniqueStrains: consumptionData['unique_strains'] as int? ?? 0,
      cognitiveAverage: cognitiveAverage,
      cognitiveChangePercent: cognitiveChangePercent != null
          ? double.tryParse(
              cognitiveChangePercent.replaceAll('%', '').replaceAll('+', ''),
            )
          : null,
      cognitiveTrend: cognitiveTrend,
      patterns: patterns,
      insights: insights,
      achievements: achievements,
      recommendations: recommendations,
      comparison: comparison,
      goalsProgress: goalsProgress,
      summary: summary,
      generatedAt: DateTime.now(),
    );

    final response = await _supabase
        .from('weekly_insights')
        .insert(insight.toJson())
        .select()
        .single();

    // Invalidate cache
    _cache.clear('weekly_insight_unviewed_$userId');

    return WeeklyInsight.fromJson(response);
  }

  // ========== DATA GATHERING ==========

  Future<Map<String, dynamic>> _getConsumptionData(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final logs = await _supabase
        .from('consumption_logs')
        .select()
        .eq('user_id', userId)
        .gte('timestamp', start.toIso8601String())
        .lte('timestamp', end.toIso8601String());

    final logsList = logs as List;

    final uniqueStrains = <String>{};
    for (final log in logsList) {
      if (log['strain_id'] != null) {
        uniqueStrains.add(log['strain_id'] as String);
      }
    }

    return {
      'total_sessions': logsList.length,
      'unique_strains': uniqueStrains.length,
      'logs': logsList,
    };
  }

  Future<Map<String, dynamic>> _getCognitiveData(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final tests = await _supabase
        .from('cognitive_test_results')
        .select()
        .eq('user_id', userId)
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String());

    final testsList = tests as List;

    if (testsList.isEmpty) {
      return {'average_score': null, 'tests': []};
    }

    final scores =
        testsList.map((t) => t['total_score'] as int).toList();
    final average = scores.reduce((a, b) => a + b) / scores.length;

    return {
      'average_score': average,
      'tests': testsList,
    };
  }

  Future<Map<String, dynamic>> _getPreviousWeekData(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final consumption = await _getConsumptionData(userId, start, end);
    final cognitive = await _getCognitiveData(userId, start, end);

    return {
      'consumption': consumption,
      'cognitive': cognitive,
    };
  }

  // ========== PATTERN DETECTION ==========

  Future<List<InsightPattern>> _detectPatterns(
    String userId,
    Map<String, dynamic> consumptionData,
    Map<String, dynamic> cognitiveData,
  ) async {
    final patterns = <InsightPattern>[];

    final totalSessions = consumptionData['total_sessions'] as int;

    // Pattern 1: Daily use
    if (totalSessions >= 6) {
      patterns.add(const InsightPattern(
        type: 'consumption_frequency',
        severity: 'high',
        description: 'Denní užívání detekováno 6+ dní v týdnu',
        recommendation: 'Zvažuj T-break pro reset tolerance',
      ));
    } else if (totalSessions >= 4) {
      patterns.add(const InsightPattern(
        type: 'consumption_frequency',
        severity: 'medium',
        description: 'Častá konzumace - 4-5 dní v týdnu',
        recommendation: 'Monitoruj svou toleranci',
      ));
    }

    // Pattern 2: Cognitive decline
    final cognitiveAvg = cognitiveData['average_score'] as double?;
    if (cognitiveAvg != null && cognitiveAvg < 70) {
      patterns.add(const InsightPattern(
        type: 'cognitive_performance',
        severity: 'high',
        description: 'Cognitive performance pod 70%',
        recommendation: 'T-break nebo snížení frekvence doporučeno',
      ));
    }

    // Pattern 3: No T-break in 90+ days
    final tbreakService = TBreakService();
    final history = await tbreakService.getToleranceBreakHistory(userId);
    final completedBreaks = history.where((b) => b.completedDate != null).toList()
      ..sort((a, b) => b.completedDate!.compareTo(a.completedDate!));

    if (completedBreaks.isEmpty && totalSessions > 0) {
      patterns.add(const InsightPattern(
        type: 'no_tbreak',
        severity: 'medium',
        description: 'Nikdy jsi neudělal T-break',
        recommendation: 'Zkus alespoň týdenní pauzu',
      ));
    } else if (completedBreaks.isNotEmpty) {
      final lastBreak = completedBreaks.first.completedDate!;
      final daysSince = DateTime.now().difference(lastBreak).inDays;
      if (daysSince > 90) {
        patterns.add(InsightPattern(
          type: 'no_tbreak',
          severity: 'medium',
          description: 'Poslední T-break byl před $daysSince dny',
          recommendation: 'Čas na další break',
        ));
      }
    }

    return patterns;
  }

  // ========== INSIGHTS GENERATION ==========

  Future<List<InsightFinding>> _generateInsights(
    Map<String, dynamic> consumptionData,
    Map<String, dynamic> cognitiveData,
    Map<String, dynamic> previousWeekData,
  ) async {
    final insights = <InsightFinding>[];

    // Insight 1: Consumption trend
    final currentSessions = consumptionData['total_sessions'] as int;
    final previousSessions =
        previousWeekData['consumption']['total_sessions'] as int;

    if (previousSessions > 0) {
      final change = ((currentSessions - previousSessions) / previousSessions * 100).round();
      if (change.abs() > 20) {
        insights.add(InsightFinding(
          type: 'consumption_trend',
          title: change > 0 ? 'Rostoucí konzumace' : 'Klesající konzumace',
          description:
              'Tento týden jsi měl $currentSessions sezení, což je ${change > 0 ? '+' : ''}$change% oproti minulému týdnu ($previousSessions).',
          confidence: 0.9,
        ));
      }
    }

    // Insight 2: Cognitive performance correlation
    final cognitiveAvg = cognitiveData['average_score'] as double?;
    final previousCognitiveAvg =
        previousWeekData['cognitive']['average_score'] as double?;

    if (cognitiveAvg != null && previousCognitiveAvg != null) {
      final change = ((cognitiveAvg - previousCognitiveAvg) / previousCognitiveAvg * 100);
      if (change.abs() > 10) {
        insights.add(InsightFinding(
          type: 'cognitive_correlation',
          title: change > 0
              ? 'Cognitive performance roste'
              : 'Cognitive performance klesá',
          description:
              'Tvoje průměrné skóre je ${cognitiveAvg.toStringAsFixed(1)}%, což je ${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}% oproti minulému týdnu.',
          confidence: 0.85,
        ));
      }
    }

    return insights;
  }

  // ========== ACHIEVEMENTS ==========

  Future<List<InsightAchievement>> _detectAchievements(
    String userId,
    Map<String, dynamic> consumptionData,
    Map<String, dynamic> cognitiveData,
  ) async {
    final achievements = <InsightAchievement>[];

    final totalSessions = consumptionData['total_sessions'] as int;

    // Achievement: Zero consumption week
    if (totalSessions == 0) {
      achievements.add(const InsightAchievement(
        type: 'zero_week',
        title: 'Clean Week! 🎉',
        description: 'Celý týden bez konzumace - skvělá práce!',
        icon: '🎉',
      ));
    }

    // Achievement: Consistent tracking
    final logs = consumptionData['logs'] as List;
    if (logs.isNotEmpty && logs.length == totalSessions) {
      achievements.add(const InsightAchievement(
        type: 'tracking_streak',
        title: 'Tracking Master',
        description: 'Zaznamenal jsi všechny své sessions!',
        icon: '📊',
      ));
    }

    // Achievement: Cognitive improvement
    final cognitiveTests = cognitiveData['tests'] as List;
    if (cognitiveTests.length >= 3) {
      achievements.add(const InsightAchievement(
        type: 'cognitive_testing',
        title: 'Data Scientist',
        description: 'Udělal jsi 3+ cognitive testy tento týden!',
        icon: '🧪',
      ));
    }

    return achievements;
  }

  // ========== RECOMMENDATIONS ==========

  Future<List<InsightRecommendation>> _generateRecommendations(
    String userId,
    List<InsightPattern> patterns,
    Map<String, dynamic> consumptionData,
    Map<String, dynamic> cognitiveData,
  ) async {
    final recommendations = <InsightRecommendation>[];

    // High-priority recs from patterns
    for (final pattern in patterns) {
      if (pattern.severity == 'high' && pattern.recommendation != null) {
        recommendations.add(InsightRecommendation(
          type: pattern.type,
          priority: 'high',
          message: pattern.recommendation!,
          actionLabel: pattern.type == 'no_tbreak' ? 'Začít T-Break' : null,
          actionRoute: pattern.type == 'no_tbreak' ? '/tbreak' : null,
        ));
      }
    }

    // General recommendations
    final totalSessions = consumptionData['total_sessions'] as int;
    if (totalSessions > 0) {
      final logs = consumptionData['logs'] as List;
      final trackedSessions = logs.where((l) => l['notes'] != null).length;
      if (trackedSessions < totalSessions * 0.5) {
        recommendations.add(const InsightRecommendation(
          type: 'tracking',
          priority: 'medium',
          message: 'Zkus přidávat poznámky k sessions pro lepší insights',
          actionLabel: 'Začít trackovat',
          actionRoute: '/consumption/log',
        ));
      }
    }

    return recommendations;
  }

  // ========== COMPARISON ==========

  WeeklyComparison? _generateComparison(
    Map<String, dynamic> consumptionData,
    Map<String, dynamic> cognitiveData,
    Map<String, dynamic> previousWeekData,
  ) {
    final currentSessions = consumptionData['total_sessions'] as int;
    final previousSessions =
        previousWeekData['consumption']['total_sessions'] as int;

    final cognitiveAvg = cognitiveData['average_score'] as double?;
    final previousCognitiveAvg =
        previousWeekData['cognitive']['average_score'] as double?;

    MetricComparison? sessionsComparison;
    if (previousSessions > 0) {
      final change = ((currentSessions - previousSessions) / previousSessions * 100);
      sessionsComparison = MetricComparison(
        current: currentSessions.toDouble(),
        previous: previousSessions.toDouble(),
        change: '${change > 0 ? '+' : ''}${change.toStringAsFixed(0)}%',
        trend: change > 0 ? 'up' : (change < 0 ? 'down' : 'stable'),
      );
    }

    MetricComparison? cognitiveComparison;
    if (cognitiveAvg != null && previousCognitiveAvg != null) {
      final change = ((cognitiveAvg - previousCognitiveAvg) / previousCognitiveAvg * 100);
      cognitiveComparison = MetricComparison(
        current: cognitiveAvg,
        previous: previousCognitiveAvg,
        change: '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
        trend: change > 0 ? 'up' : (change < 0 ? 'down' : 'stable'),
      );
    }

    return WeeklyComparison(
      sessions: sessionsComparison,
      cognitive: cognitiveComparison,
    );
  }

  // ========== GOALS PROGRESS ==========

  Future<List<GoalProgress>> _calculateGoalsProgress(
    String userId,
    Map<String, dynamic> consumptionData,
    Map<String, dynamic> cognitiveData,
  ) async {
    final progress = <GoalProgress>[];

    final totalSessions = consumptionData['total_sessions'] as int;
    final logs = consumptionData['logs'] as List;

    // Goal: Track all sessions
    if (totalSessions > 0) {
      final trackedCount = logs.where((l) => l['notes'] != null).length;
      final trackingProgress = trackedCount / totalSessions;
      progress.add(GoalProgress(
        goal: 'Track all sessions',
        progress: trackingProgress,
        status:
            trackingProgress >= 0.8 ? 'on_track' : (trackingProgress >= 0.5 ? 'behind' : 'behind'),
      ));
    }

    // Goal: Take cognitive tests
    final cognitiveTests = cognitiveData['tests'] as List;
    progress.add(GoalProgress(
      goal: 'Weekly cognitive test',
      progress: cognitiveTests.isEmpty ? 0.0 : 1.0,
      status: cognitiveTests.isNotEmpty ? 'completed' : 'behind',
    ));

    return progress;
  }

  // ========== SUMMARY ==========

  String _generateSummary(
    List<InsightPattern> patterns,
    List<InsightFinding> insights,
    List<InsightAchievement> achievements,
    List<InsightRecommendation> recommendations,
  ) {
    final summary = StringBuffer();

    // Opening
    if (achievements.isNotEmpty) {
      summary.writeln('🎉 Skvělý týden! ${achievements.first.title}');
    } else if (patterns.any((p) => p.severity == 'high')) {
      summary.writeln('⚠️ Tento týden vyžaduje tvou pozornost.');
    } else {
      summary.writeln('📊 Tvůj týdenní přehled je připraven.');
    }

    summary.writeln();

    // Key insights
    if (insights.isNotEmpty) {
      summary.writeln('**Klíčové zjištění:**');
      for (final insight in insights.take(2)) {
        summary.writeln('• ${insight.description}');
      }
      summary.writeln();
    }

    // High-priority recommendations
    final highPriorityRecs =
        recommendations.where((r) => r.priority == 'high').toList();
    if (highPriorityRecs.isNotEmpty) {
      summary.writeln('**Doporučení:**');
      for (final rec in highPriorityRecs) {
        summary.writeln('• ${rec.message}');
      }
    }

    return summary.toString();
  }
}
