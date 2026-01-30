import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cognitive_test_model.dart';

/// Service pro práci s cognitive testy v Supabase
class CognitiveService {
  final SupabaseClient _supabase;

  CognitiveService(this._supabase);

  /// Uloží výsledek testu do databáze
  /// Automaticky se přepočítá baseline pomocí DB triggeru
  Future<void> saveTestResult(CognitiveTestResult result) async {
    await _supabase.from('cognitive_test_results').insert(result.toJson());
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
