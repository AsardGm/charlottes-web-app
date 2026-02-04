import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cognitive_test_model.dart';
import '../models/brain_heatmap_model.dart';
import 'challenge_service.dart';

/// Service pro práci s cognitive testy v Supabase
class CognitiveService {
  final SupabaseClient _supabase;
  final ChallengeService _challengeService = ChallengeService();

  CognitiveService(this._supabase);

  /// Uloží výsledek testu do databáze
  /// Automaticky se přepočítá baseline pomocí DB triggeru
  Future<void> saveTestResult(CognitiveTestResult result) async {
    await _supabase.from('cognitive_test_results').insert(result.toJson());

    // Update challenge progress for cognitive tests
    _challengeService.updateChallengeProgress(result.userId, 'cognitive');
  }

  /// Získá baseline uživatele
  Future<CognitiveBaseline?> getBaseline(String userId) async {
    final response = await _supabase
        .from('cognitive_baselines')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return CognitiveBaseline.fromJson(response);
  }

  /// Získá historii testů uživatele
  Future<List<CognitiveTestResult>> getTestHistory({
    required String userId,
    int limit = 30,
  }) async {
    final response = await _supabase
        .from('cognitive_test_results')
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => CognitiveTestResult.fromJson(json))
        .toList();
  }

  /// Získá testy za poslední N dní
  Future<List<CognitiveTestResult>> getRecentTests({
    required String userId,
    int days = 7,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    final response = await _supabase
        .from('cognitive_test_results')
        .select()
        .eq('user_id', userId)
        .gte('timestamp', cutoffDate.toIso8601String())
        .order('timestamp', ascending: false);

    return (response as List)
        .map((json) => CognitiveTestResult.fromJson(json))
        .toList();
  }

  /// Získá statistiky streaku
  Future<CognitiveStreakStats> getStreakStats(String userId) async {
    final baseline = await getBaseline(userId);

    if (baseline == null) {
      return CognitiveStreakStats(
        currentStreak: 0,
        longestStreak: 0,
        totalTests: 0,
        lastTestDate: null,
      );
    }

    return CognitiveStreakStats(
      currentStreak: baseline.totalTests > 0
          ? await _calculateCurrentStreak(userId)
          : 0,
      longestStreak: await _calculateLongestStreak(userId),
      totalTests: baseline.totalTests,
      lastTestDate: await _getLastTestDate(userId),
    );
  }

  Future<int> _calculateCurrentStreak(String userId) async {
    final tests = await _supabase
        .from('cognitive_daily_tests')
        .select('test_date')
        .eq('user_id', userId)
        .order('test_date', ascending: false)
        .limit(100); // Safety limit

    if (tests.isEmpty) return 0;

    int streak = 0;
    DateTime? previousDate;

    for (final test in tests) {
      final testDate = DateTime.parse(test['test_date']);

      if (previousDate == null) {
        // First test
        final today = DateTime.now();
        final daysDiff = today.difference(testDate).inDays;

        // Must be today or yesterday to count as active streak
        if (daysDiff > 1) return 0;

        streak = 1;
        previousDate = testDate;
      } else {
        final daysDiff = previousDate.difference(testDate).inDays;

        if (daysDiff == 1) {
          // Consecutive day
          streak++;
          previousDate = testDate;
        } else {
          // Gap in streak
          break;
        }
      }
    }

    return streak;
  }

  Future<int> _calculateLongestStreak(String userId) async {
    final tests = await _supabase
        .from('cognitive_daily_tests')
        .select('test_date')
        .eq('user_id', userId)
        .order('test_date', ascending: false);

    if (tests.isEmpty) return 0;

    int longestStreak = 1;
    int currentStreak = 1;
    DateTime? previousDate;

    for (final test in tests) {
      final testDate = DateTime.parse(test['test_date']);

      if (previousDate != null) {
        final daysDiff = previousDate.difference(testDate).inDays;

        if (daysDiff == 1) {
          currentStreak++;
          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
          }
        } else {
          currentStreak = 1;
        }
      }

      previousDate = testDate;
    }

    return longestStreak;
  }

  Future<DateTime?> _getLastTestDate(String userId) async {
    final response = await _supabase
        .from('cognitive_test_results')
        .select('timestamp')
        .eq('user_id', userId)
        .order('timestamp', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return DateTime.parse(response['timestamp']);
  }

  /// Získá denní statistiku (pro grafy)
  Future<List<DailyScore>> getDailyScores({
    required String userId,
    int days = 30,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    final response = await _supabase
        .from('cognitive_test_results')
        .select('timestamp, total_score')
        .eq('user_id', userId)
        .gte('timestamp', cutoffDate.toIso8601String())
        .order('timestamp', ascending: true);

    // Group by date and average scores for that day
    final Map<String, List<int>> scoresByDate = {};

    for (final test in response) {
      final date = DateTime.parse(test['timestamp']);
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      if (!scoresByDate.containsKey(dateKey)) {
        scoresByDate[dateKey] = [];
      }
      scoresByDate[dateKey]!.add(test['total_score'] as int);
    }

    return scoresByDate.entries.map((entry) {
      final avgScore = entry.value.reduce((a, b) => a + b) ~/ entry.value.length;
      return DailyScore(
        date: DateTime.parse(entry.key),
        averageScore: avgScore,
        testCount: entry.value.length,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Zkontroluje, zda byl test dnes již proveden
  Future<bool> hasTestToday(String userId) async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final response = await _supabase
        .from('cognitive_daily_tests')
        .select('test_count')
        .eq('user_id', userId)
        .eq('test_date', todayStr)
        .maybeSingle();

    return response != null;
  }

  /// Získá týdenní agregaci cognitive dat pro heatmap
  Future<List<BrainHeatmapData>> getWeeklyHeatmapData({
    required String userId,
    int weeks = 12,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: weeks * 7));

    final response = await _supabase
        .from('cognitive_test_results')
        .select()
        .eq('user_id', userId)
        .gte('timestamp', cutoffDate.toIso8601String())
        .order('timestamp', ascending: true);

    final tests = (response as List)
        .map((json) => CognitiveTestResult.fromJson(json))
        .toList();

    if (tests.isEmpty) return [];

    // Group tests by week
    final Map<DateTime, List<CognitiveTestResult>> testsByWeek = {};

    for (final test in tests) {
      final weekStart = _getWeekStart(test.timestamp);
      if (!testsByWeek.containsKey(weekStart)) {
        testsByWeek[weekStart] = [];
      }
      testsByWeek[weekStart]!.add(test);
    }

    // Calculate weekly aggregates
    final List<BrainHeatmapData> heatmapData = [];
    final sortedWeeks = testsByWeek.keys.toList()..sort();

    for (int i = 0; i < sortedWeeks.length; i++) {
      final weekStart = sortedWeeks[i];
      final weekTests = testsByWeek[weekStart]!;

      // Calculate averages for the week
      final avgFocus = _calculateAverageFocus(weekTests);
      final avgAnxiety = _calculateAverageAnxiety(weekTests);
      final avgCreativity = _calculateAverageCreativity(weekTests);
      final avgMood = _calculateAverageMood(weekTests);

      // Calculate trends (compare with previous week)
      TrendDirection focusTrend = TrendDirection.stable;
      TrendDirection anxietyTrend = TrendDirection.stable;

      if (i > 0) {
        final prevWeekTests = testsByWeek[sortedWeeks[i - 1]]!;
        final prevFocus = _calculateAverageFocus(prevWeekTests);
        final prevAnxiety = _calculateAverageAnxiety(prevWeekTests);

        focusTrend = _calculateTrend(avgFocus, prevFocus);
        anxietyTrend = _calculateTrend(avgAnxiety, prevAnxiety);
      }

      heatmapData.add(BrainHeatmapData(
        weekStart: weekStart,
        avgFocus: avgFocus,
        avgAnxiety: avgAnxiety,
        avgCreativity: avgCreativity,
        avgMood: avgMood,
        testCount: weekTests.length,
        focusTrend: focusTrend,
        anxietyTrend: anxietyTrend,
      ));
    }

    return heatmapData;
  }

  /// Generuje health insights z heatmap dat
  List<BrainHealthInsight> generateInsights(List<BrainHeatmapData> heatmapData) {
    final insights = <BrainHealthInsight>[];

    if (heatmapData.isEmpty) return insights;

    final recentData = heatmapData.length >= 3
        ? heatmapData.sublist(heatmapData.length - 3)
        : heatmapData;

    // Check for burnout pattern
    final highAnxietyWeeks = recentData.where((d) => d.avgAnxiety > 7.0).length;
    final lowFocusWeeks = recentData.where((d) => d.avgFocus < 4.0).length;

    if (highAnxietyWeeks >= 2 || lowFocusWeeks >= 2) {
      insights.add(BrainHealthInsight(
        type: InsightType.burnout,
        title: 'Možný burnout',
        message:
            'Tvoje anxiety je vysoká a focus klesá. Čas na pauzu a regeneraci.',
        icon: Icons.warning,
        color: const Color(0xFFEF5350),
        severity: InsightSeverity.critical,
      ));
    }

    // Check for improvement
    if (recentData.length >= 2) {
      final lastWeek = recentData.last;
      final prevWeek = recentData[recentData.length - 2];

      if (lastWeek.avgFocus > prevWeek.avgFocus &&
          lastWeek.avgAnxiety < prevWeek.avgAnxiety) {
        insights.add(BrainHealthInsight(
          type: InsightType.improving,
          title: 'Skvělý progres!',
          message: 'Tvůj focus roste a anxiety klesá. Pokračuj v tom!',
          icon: Icons.trending_up,
          color: const Color(0xFF4CAF50),
          severity: InsightSeverity.positive,
        ));
      }
    }

    // Check if needs break
    final latestData = heatmapData.last;
    if (latestData.needsBreak) {
      insights.add(BrainHealthInsight(
        type: InsightType.needsBreak,
        title: 'Potřebuješ pauzu',
        message:
            'Data ukazují, že tvůj mozek potřebuje odpočinek. Dej si T-break.',
        icon: Icons.self_improvement,
        color: const Color(0xFFFFB74D),
        severity: InsightSeverity.warning,
      ));
    }

    // Check for stable period
    final avgHealthScore =
        recentData.map((d) => d.healthScore).reduce((a, b) => a + b) /
            recentData.length;
    if (avgHealthScore >= 6.0 && avgHealthScore <= 7.5 && insights.isEmpty) {
      insights.add(BrainHealthInsight(
        type: InsightType.stable,
        title: 'Stabilní stav',
        message: 'Tvoje cognitive funkce jsou v dobrém stavu. Udržuj to!',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF42A5F5),
        severity: InsightSeverity.info,
      ));
    }

    return insights;
  }

  /// Helper: Get start of week (Monday)
  DateTime _getWeekStart(DateTime date) {
    final dayOfWeek = date.weekday; // 1 = Monday, 7 = Sunday
    final daysToSubtract = dayOfWeek - 1;
    final weekStart = date.subtract(Duration(days: daysToSubtract));
    return DateTime(weekStart.year, weekStart.month, weekStart.day);
  }

  /// Helper: Calculate average focus (reaction time score)
  double _calculateAverageFocus(List<CognitiveTestResult> tests) {
    if (tests.isEmpty) return 0.0;
    final sum = tests.map((t) => t.reactionTime.score).reduce((a, b) => a + b);
    return (sum / tests.length) / 10.0; // Scale to 0-10
  }

  /// Helper: Calculate average anxiety (inverse of consistency)
  double _calculateAverageAnxiety(List<CognitiveTestResult> tests) {
    if (tests.isEmpty) return 0.0;

    // Anxiety = high variability in scores + low overall performance
    final scores = tests.map((t) => t.totalScore).toList();
    final avg = scores.reduce((a, b) => a + b) / scores.length;

    // Calculate variance
    final variance = scores.map((s) => (s - avg) * (s - avg)).reduce((a, b) => a + b) / scores.length;
    final stdDev = variance.abs().clamp(0.0, 100.0);

    // High variance = higher anxiety
    // Low scores = higher anxiety
    final anxietyFromVariance = (stdDev / 10).clamp(0.0, 5.0);
    final anxietyFromPerformance = ((100 - avg) / 20).clamp(0.0, 5.0);

    return (anxietyFromVariance + anxietyFromPerformance).clamp(0.0, 10.0).toDouble();
  }

  /// Helper: Calculate average creativity (pattern recognition)
  double _calculateAverageCreativity(List<CognitiveTestResult> tests) {
    if (tests.isEmpty) return 0.0;
    final sum = tests.map((t) => t.patternRecognition.score).reduce((a, b) => a + b);
    return (sum / tests.length) / 10.0; // Scale to 0-10
  }

  /// Helper: Calculate average mood (total score)
  double _calculateAverageMood(List<CognitiveTestResult> tests) {
    if (tests.isEmpty) return 0.0;
    final sum = tests.map((t) => t.totalScore).reduce((a, b) => a + b);
    return (sum / tests.length) / 10.0; // Scale to 0-10
  }

  /// Helper: Calculate trend direction
  TrendDirection _calculateTrend(double current, double previous) {
    final diff = current - previous;
    if (diff > 0.5) return TrendDirection.improving;
    if (diff < -0.5) return TrendDirection.declining;
    return TrendDirection.stable;
  }
}

/// Statistiky streaku
class CognitiveStreakStats {
  final int currentStreak;
  final int longestStreak;
  final int totalTests;
  final DateTime? lastTestDate;

  CognitiveStreakStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalTests,
    this.lastTestDate,
  });
}

/// Denní score pro graf
class DailyScore {
  final DateTime date;
  final int averageScore;
  final int testCount;

  DailyScore({
    required this.date,
    required this.averageScore,
    required this.testCount,
  });
}
