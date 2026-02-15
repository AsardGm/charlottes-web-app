import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/consumption_insights_model.dart';

/// Service pro generování insights z consumption dat
class ConsumptionInsightsService {
  final _supabase = Supabase.instance.client;

  /// Generuje insights z consumption logs pro daného uživatele
  Future<ConsumptionInsights> generateInsights(String userId) async {
    try {
      // Fetch all consumption logs for user
      final response = await _supabase
          .from('consumption_logs')
          .select()
          .eq('user_id', userId)
          .order('consumed_at', ascending: false);

      final logs = response as List<dynamic>;

      if (logs.isEmpty) {
        return ConsumptionInsights.empty;
      }

      // Analyze data
      final now = DateTime.now();
      final last7Days = now.subtract(const Duration(days: 7));
      final last30Days = now.subtract(const Duration(days: 30));

      // Count sessions
      final totalSessions = logs.length;
      final last7DaysSessions = logs.where((log) {
        final date = DateTime.parse(log['consumed_at']);
        return date.isAfter(last7Days);
      }).length;

      final last30DaysSessions = logs.where((log) {
        final date = DateTime.parse(log['consumed_at']);
        return date.isAfter(last30Days);
      }).length;

      // Find most common strain
      final strainCounts = <String, int>{};
      for (final log in logs) {
        final strain = log['strain_name'] as String?;
        if (strain != null) {
          strainCounts[strain] = (strainCounts[strain] ?? 0) + 1;
        }
      }

      String? mostCommonStrain;
      int mostCommonStrainCount = 0;
      if (strainCounts.isNotEmpty) {
        final mostCommon = strainCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b);
        mostCommonStrain = mostCommon.key;
        mostCommonStrainCount = mostCommon.value;
      }

      // Calculate average scores
      double? averageCognitiveScore;
      double? averageMoodScore;

      final cognitiveScores = logs
          .map((log) => log['cognitive_score_after'] as int?)
          .where((score) => score != null)
          .cast<int>()
          .toList();

      if (cognitiveScores.isNotEmpty) {
        averageCognitiveScore = cognitiveScores.reduce((a, b) => a + b) /
            cognitiveScores.length;
      }

      final moodScores = logs
          .map((log) => log['mood_after'] as int?)
          .where((score) => score != null)
          .cast<int>()
          .toList();

      if (moodScores.isNotEmpty) {
        averageMoodScore = moodScores.reduce((a, b) => a + b) /
            moodScores.length;
      }

      // Analyze time patterns
      final consumptionByTimeOfDay = <String, int>{};
      final consumptionByDayOfWeek = <String, int>{};

      for (final log in logs) {
        final date = DateTime.parse(log['consumed_at']);

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
        consumptionByTimeOfDay[timeOfDay] =
            (consumptionByTimeOfDay[timeOfDay] ?? 0) + 1;

        // Day of week
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final dayOfWeek = days[date.weekday - 1];
        consumptionByDayOfWeek[dayOfWeek] =
            (consumptionByDayOfWeek[dayOfWeek] ?? 0) + 1;
      }

      // Analyze methods
      final methodsUsed = <String, int>{};
      for (final log in logs) {
        final method = log['method'] as String?;
        if (method != null) {
          methodsUsed[method] = (methodsUsed[method] ?? 0) + 1;
        }
      }

      // Analyze trends (compare recent vs older)
      final last60Days = now.subtract(const Duration(days: 60));
      final prev30DaysSessions = logs.where((log) {
        final date = DateTime.parse(log['consumed_at']);
        return date.isBefore(last30Days) && date.isAfter(last60Days);
      }).length;

      bool isIncreasing = false;
      bool isDecreasing = false;
      bool isStable = true;

      if (prev30DaysSessions > 0) {
        final changePercent =
            ((last30DaysSessions - prev30DaysSessions) / prev30DaysSessions) *
                100;

        if (changePercent > 20) {
          isIncreasing = true;
          isStable = false;
        } else if (changePercent < -20) {
          isDecreasing = true;
          isStable = false;
        }
      }

      // Last consumption info
      final lastLog = logs.first;
      final lastConsumptionDate = DateTime.parse(lastLog['consumed_at']);
      final lastConsumptionStrain = lastLog['strain_name'] as String?;
      final lastConsumptionMethod = lastLog['method'] as String?;

      return ConsumptionInsights(
        totalSessions: totalSessions,
        last7DaysSessions: last7DaysSessions,
        last30DaysSessions: last30DaysSessions,
        mostCommonStrain: mostCommonStrain,
        mostCommonStrainCount: mostCommonStrainCount,
        averageCognitiveScore: averageCognitiveScore,
        averageMoodScore: averageMoodScore,
        consumptionByTimeOfDay: consumptionByTimeOfDay,
        consumptionByDayOfWeek: consumptionByDayOfWeek,
        methodsUsed: methodsUsed,
        preferredTerpenes: _analyzeTerpenes(logs),
        isIncreasing: isIncreasing,
        isDecreasing: isDecreasing,
        isStable: isStable,
        lastConsumptionDate: lastConsumptionDate,
        lastConsumptionStrain: lastConsumptionStrain,
        lastConsumptionMethod: lastConsumptionMethod,
      );
    } catch (e) {
      throw Exception('Failed to generate consumption insights: $e');
    }
  }

  /// Analyze terpene preferences from consumption logs
  Map<String, int> _analyzeTerpenes(List<dynamic> logs) {
    final terpeneCounts = <String, int>{};
    for (final log in logs) {
      final terpenes = log['terpenes'] as List<dynamic>?;
      if (terpenes != null) {
        for (final terpene in terpenes) {
          final name = terpene.toString();
          terpeneCounts[name] = (terpeneCounts[name] ?? 0) + 1;
        }
      }
      // Also check strain_terpenes if available
      final strainTerpenes = log['strain_terpenes'] as String?;
      if (strainTerpenes != null && strainTerpenes.isNotEmpty) {
        for (final t in strainTerpenes.split(',')) {
          final name = t.trim();
          if (name.isNotEmpty) {
            terpeneCounts[name] = (terpeneCounts[name] ?? 0) + 1;
          }
        }
      }
    }
    return terpeneCounts;
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

  /// Top 3 strainy pro uživatele
  Future<List<String>> getTopStrains(String userId, {int limit = 3}) async {
    try {
      final response = await _supabase
          .from('consumption_logs')
          .select('strain_name')
          .eq('user_id', userId)
          .not('strain_name', 'is', null)
          .order('consumed_at', ascending: false)
          .limit(100); // Look at last 100 sessions

      final logs = response as List<dynamic>;

      // Count occurrences
      final strainCounts = <String, int>{};
      for (final log in logs) {
        final strain = log['strain_name'] as String;
        strainCounts[strain] = (strainCounts[strain] ?? 0) + 1;
      }

      // Sort by count and return top N
      final sorted = strainCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.take(limit).map((e) => e.key).toList();
    } catch (e) {
      return [];
    }
  }

  /// Consumption frequency (sessions per week average)
  Future<double> getWeeklyFrequency(String userId) async {
    final insights = await generateInsights(userId);

    if (insights.totalSessions == 0) return 0;

    // Calculate based on 30 day average
    return (insights.last30DaysSessions / 30) * 7;
  }
}
