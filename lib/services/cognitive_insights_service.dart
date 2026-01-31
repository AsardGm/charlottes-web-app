import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cognitive_insights_model.dart';

/// Service pro generování insights z cognitive test dat
class CognitiveInsightsService {
  final _supabase = Supabase.instance.client;

  /// Generuje insights z cognitive tests pro daného uživatele
  Future<CognitiveInsights> generateInsights(String userId) async {
    try {
      // Fetch all cognitive tests for user
      final response = await _supabase
          .from('cognitive_tests')
          .select()
          .eq('user_id', userId)
          .order('tested_at', ascending: false);

      final tests = response as List<dynamic>;

      if (tests.isEmpty) {
        return CognitiveInsights.empty;
      }

      // Analyze data
      final now = DateTime.now();
      final last7Days = now.subtract(const Duration(days: 7));
      final last30Days = now.subtract(const Duration(days: 30));

      // Count tests
      final totalTests = tests.length;
      final last7DaysTests = tests.where((test) {
        final date = DateTime.parse(test['tested_at']);
        return date.isAfter(last7Days);
      }).length;

      final last30DaysTests = tests.where((test) {
        final date = DateTime.parse(test['tested_at']);
        return date.isAfter(last30Days);
      }).length;

      // Calculate scores
      final scores = tests
          .map((test) => (test['total_score'] as num).toDouble())
          .toList();

      final currentScore = scores.first;
      final baselineScore = scores.last; // First test as baseline
      final averageScore = scores.reduce((a, b) => a + b) / scores.length;

      // Best/worst
      final bestScore = scores.reduce((a, b) => a > b ? a : b);
      final worstScore = scores.reduce((a, b) => a < b ? a : b);

      DateTime? bestScoreDate;
      DateTime? worstScoreDate;

      for (final test in tests) {
        final score = (test['total_score'] as num).toDouble();
        if (score == bestScore) {
          bestScoreDate = DateTime.parse(test['tested_at']);
        }
        if (score == worstScore) {
          worstScoreDate = DateTime.parse(test['tested_at']);
        }
      }

      // Trend analysis (compare recent vs older)
      CognitiveTrend trend = CognitiveTrend.insufficient;
      double? trendPercentage;

      if (totalTests >= 3) {
        final recentScores = scores.take(5).toList();
        final olderScores = totalTests > 5
            ? scores.skip(5).take(5).toList()
            : scores.skip(recentScores.length).toList();

        if (olderScores.isNotEmpty) {
          final recentAvg = recentScores.reduce((a, b) => a + b) / recentScores.length;
          final olderAvg = olderScores.reduce((a, b) => a + b) / olderScores.length;

          trendPercentage = ((recentAvg - olderAvg) / olderAvg) * 100;

          if (trendPercentage > 5) {
            trend = CognitiveTrend.improving;
          } else if (trendPercentage < -5) {
            trend = CognitiveTrend.declining;
          } else {
            trend = CognitiveTrend.stable;
          }
        }
      }

      // Consumption correlation
      double? averageScoreAfterConsumption;
      double? averageScoreWithoutConsumption;
      bool hasConsumptionCorrelation = false;

      final testsAfterConsumption = tests.where((test) {
        return test['was_after_consumption'] == true;
      }).toList();

      final testsWithoutConsumption = tests.where((test) {
        return test['was_after_consumption'] != true;
      }).toList();

      if (testsAfterConsumption.isNotEmpty && testsWithoutConsumption.isNotEmpty) {
        hasConsumptionCorrelation = true;

        final scoresAfter = testsAfterConsumption
            .map((t) => (t['total_score'] as num).toDouble())
            .toList();
        averageScoreAfterConsumption =
            scoresAfter.reduce((a, b) => a + b) / scoresAfter.length;

        final scoresWithout = testsWithoutConsumption
            .map((t) => (t['total_score'] as num).toDouble())
            .toList();
        averageScoreWithoutConsumption =
            scoresWithout.reduce((a, b) => a + b) / scoresWithout.length;
      }

      // Time patterns
      final scoresByTimeOfDay = <String, List<double>>{
        'morning': [],
        'afternoon': [],
        'evening': [],
        'night': [],
      };

      final scoresByDayOfWeek = <String, List<double>>{
        'Mon': [],
        'Tue': [],
        'Wed': [],
        'Thu': [],
        'Fri': [],
        'Sat': [],
        'Sun': [],
      };

      for (final test in tests) {
        final date = DateTime.parse(test['tested_at']);
        final score = (test['total_score'] as num).toDouble();

        // Time of day
        final hour = date.hour;
        String timeOfDay;
        if (hour >= 5 && hour < 12) {
          timeOfDay = 'morning';
        } else if (hour >= 12 && hour < 17) {
          timeOfDay = 'afternoon';
        } else if (hour >= 17 && hour < 21) {
          timeOfDay = 'evening';
        } else {
          timeOfDay = 'night';
        }
        scoresByTimeOfDay[timeOfDay]!.add(score);

        // Day of week
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final dayOfWeek = days[date.weekday - 1];
        scoresByDayOfWeek[dayOfWeek]!.add(score);
      }

      // Average by time/day
      final avgScoresByTimeOfDay = <String, double>{};
      for (final entry in scoresByTimeOfDay.entries) {
        if (entry.value.isNotEmpty) {
          avgScoresByTimeOfDay[entry.key] =
              entry.value.reduce((a, b) => a + b) / entry.value.length;
        }
      }

      final avgScoresByDayOfWeek = <String, double>{};
      for (final entry in scoresByDayOfWeek.entries) {
        if (entry.value.isNotEmpty) {
          avgScoresByDayOfWeek[entry.key] =
              entry.value.reduce((a, b) => a + b) / entry.value.length;
        }
      }

      // Last test info
      final lastTest = tests.first;
      final lastTestDate = DateTime.parse(lastTest['tested_at']);
      final lastTestScore = (lastTest['total_score'] as num).toDouble();
      final daysSinceLastTest = now.difference(lastTestDate).inDays;

      // Warnings
      final warnings = <String>[];
      bool isSignificantDecline = false;
      bool needsAttention = false;

      // Check for significant decline
      final declineFromBaseline = ((currentScore - baselineScore) / baselineScore) * 100;
      if (declineFromBaseline < -20) {
        isSignificantDecline = true;
        warnings.add('Cognitive score klesl o ${declineFromBaseline.abs().toStringAsFixed(1)}% oproti baseline');
      }

      // Check for consistent decline
      if (totalTests >= 3) {
        final last3Scores = scores.take(3).toList();
        bool isConsistentDecline = true;
        for (int i = 0; i < last3Scores.length - 1; i++) {
          if (last3Scores[i] >= last3Scores[i + 1]) {
            isConsistentDecline = false;
            break;
          }
        }
        if (isConsistentDecline) {
          needsAttention = true;
          warnings.add('Poslední 3 testy ukazují konzistentní pokles');
        }
      }

      // Check for very low score
      if (currentScore < 50) {
        warnings.add('Aktuální score je velmi nízký (${currentScore.toStringAsFixed(1)}/100)');
      }

      return CognitiveInsights(
        totalTests: totalTests,
        last7DaysTests: last7DaysTests,
        last30DaysTests: last30DaysTests,
        currentScore: currentScore,
        baselineScore: baselineScore,
        averageScore: averageScore,
        trend: trend,
        trendPercentage: trendPercentage,
        bestScore: bestScore,
        worstScore: worstScore,
        bestScoreDate: bestScoreDate,
        worstScoreDate: worstScoreDate,
        averageScoreAfterConsumption: averageScoreAfterConsumption,
        averageScoreWithoutConsumption: averageScoreWithoutConsumption,
        hasConsumptionCorrelation: hasConsumptionCorrelation,
        scoresByTimeOfDay: avgScoresByTimeOfDay,
        scoresByDayOfWeek: avgScoresByDayOfWeek,
        lastTestDate: lastTestDate,
        lastTestScore: lastTestScore,
        daysSinceLastTest: daysSinceLastTest,
        isSignificantDecline: isSignificantDecline,
        needsAttention: needsAttention,
        warnings: warnings,
      );
    } catch (e) {
      throw Exception('Failed to generate cognitive insights: $e');
    }
  }

  /// Rychlý summary pro Charlotte AI context
  Future<String> getQuickSummary(String userId) async {
    final insights = await generateInsights(userId);
    return insights.generateSummary();
  }

  /// Doporučení pro uživatele
  Future<List<String>> getRecommendations(String userId) async {
    final insights = await generateInsights(userId);
    return insights.generateRecommendations();
  }

  /// Test frequency (tests per week average)
  Future<double> getWeeklyFrequency(String userId) async {
    final insights = await generateInsights(userId);

    if (insights.totalTests == 0) return 0;

    // Calculate based on 30 day average
    return (insights.last30DaysTests / 30) * 7;
  }

  /// Consumption impact analysis
  Future<double?> getConsumptionImpact(String userId) async {
    final insights = await generateInsights(userId);

    if (!insights.hasConsumptionCorrelation) return null;

    return insights.averageScoreAfterConsumption! -
        insights.averageScoreWithoutConsumption!;
  }
}
