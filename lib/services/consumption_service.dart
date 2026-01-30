import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/consumption_model.dart';

/// Service pro tracking consumption a efektů
class ConsumptionService {
  final SupabaseClient _supabase;

  ConsumptionService(this._supabase);

  // ========== CONSUMPTION LOGS ==========

  /// Uloží consumption log
  Future<ConsumptionLog> saveConsumptionLog(ConsumptionLog log) async {
    final response = await _supabase
        .from('consumption_logs')
        .insert(log.toJson())
        .select()
        .single();

    return ConsumptionLog.fromJson(response);
  }

  /// Získá consumption logs uživatele
  Future<List<ConsumptionLog>> getConsumptionLogs({
    required String userId,
    int limit = 50,
  }) async {
    final response = await _supabase
        .from('consumption_logs')
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => ConsumptionLog.fromJson(json))
        .toList();
  }

  /// Získá logy za poslední N dní
  Future<List<ConsumptionLog>> getRecentConsumptionLogs({
    required String userId,
    int days = 30,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    final response = await _supabase
        .from('consumption_logs')
        .select()
        .eq('user_id', userId)
        .gte('timestamp', cutoffDate.toIso8601String())
        .order('timestamp', ascending: false);

    return (response as List)
        .map((json) => ConsumptionLog.fromJson(json))
        .toList();
  }

  /// Získá consumption log s post-check
  Future<(ConsumptionLog, PostConsumptionCheck?)?> getConsumptionWithCheck(
      String logId) async {
    final logResponse = await _supabase
        .from('consumption_logs')
        .select()
        .eq('id', logId)
        .maybeSingle();

    if (logResponse == null) return null;

    final log = ConsumptionLog.fromJson(logResponse);

    final checkResponse = await _supabase
        .from('post_consumption_checks')
        .select()
        .eq('consumption_log_id', logId)
        .maybeSingle();

    final check = checkResponse != null
        ? PostConsumptionCheck.fromJson(checkResponse)
        : null;

    return (log, check);
  }

  // ========== POST-CONSUMPTION CHECKS ==========

  /// Uloží post-consumption check
  Future<PostConsumptionCheck> savePostConsumptionCheck(
      PostConsumptionCheck check) async {
    final response = await _supabase
        .from('post_consumption_checks')
        .insert(check.toJson())
        .select()
        .single();

    return PostConsumptionCheck.fromJson(response);
  }

  /// Zjistí, zda má consumption log již post-check
  Future<bool> hasPostCheck(String consumptionLogId) async {
    final response = await _supabase
        .from('post_consumption_checks')
        .select('id')
        .eq('consumption_log_id', consumptionLogId)
        .maybeSingle();

    return response != null;
  }

  /// Získá consumption logs bez post-checku (pro reminder)
  Future<List<ConsumptionLog>> getLogsWithoutPostCheck(String userId) async {
    // Get all consumption logs
    final logsResponse = await _supabase
        .from('consumption_logs')
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false)
        .limit(10); // Only recent ones

    final logs = (logsResponse as List)
        .map((json) => ConsumptionLog.fromJson(json))
        .toList();

    // Filter out those that have post-checks
    final logsWithoutChecks = <ConsumptionLog>[];

    for (final log in logs) {
      final hasCheck = await hasPostCheck(log.id!);
      if (!hasCheck) {
        // Check if enough time has passed (at least 30 min)
        final minutesSince =
            DateTime.now().difference(log.timestamp).inMinutes;
        if (minutesSince >= 30 && minutesSince <= 180) {
          // 30-180 min window
          logsWithoutChecks.add(log);
        }
      }
    }

    return logsWithoutChecks;
  }

  // ========== STRAIN CORRELATIONS ==========

  /// Získá korelace pro strain
  Future<StrainUserCorrelation?> getStrainCorrelation({
    required String userId,
    required String strainId,
  }) async {
    final response = await _supabase
        .from('strain_user_correlations')
        .select()
        .eq('user_id', userId)
        .eq('strain_id', strainId)
        .maybeSingle();

    if (response == null) return null;

    return StrainUserCorrelation.fromJson(response);
  }

  /// Získá všechny strain correlations (seřazené podle ratingu)
  Future<List<StrainUserCorrelation>> getAllStrainCorrelations(
      String userId) async {
    final response = await _supabase
        .from('strain_user_correlations')
        .select()
        .eq('user_id', userId)
        .order('personal_rating', ascending: false);

    return (response as List)
        .map((json) => StrainUserCorrelation.fromJson(json))
        .toList();
  }

  /// Získá top N strain pro uživatele
  Future<List<StrainUserCorrelation>> getTopStrains({
    required String userId,
    int limit = 5,
  }) async {
    final response = await _supabase
        .from('strain_user_correlations')
        .select()
        .eq('user_id', userId)
        .order('personal_rating', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => StrainUserCorrelation.fromJson(json))
        .toList();
  }

  /// Získá worst strains pro uživatele
  Future<List<StrainUserCorrelation>> getWorstStrains({
    required String userId,
    int limit = 5,
  }) async {
    final response = await _supabase
        .from('strain_user_correlations')
        .select()
        .eq('user_id', userId)
        .order('personal_rating', ascending: true)
        .limit(limit);

    return (response as List)
        .map((json) => StrainUserCorrelation.fromJson(json))
        .toList();
  }

  // ========== INSIGHTS ==========

  /// Získá aktivní insights pro uživatele
  Future<List<ConsumptionInsight>> getActiveInsights(String userId) async {
    final response = await _supabase
        .from('consumption_insights')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('priority', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ConsumptionInsight.fromJson(json))
        .toList();
  }

  /// Generuje basic insights based on correlations
  /// (Advanced ML-based insights by backend service)
  Future<void> generateBasicInsights(String userId) async {
    // Get correlations
    final correlations = await getAllStrainCorrelations(userId);

    if (correlations.length < 3) return; // Need at least 3 strains

    // Find best match
    if (correlations.isNotEmpty) {
      final best = correlations.first;
      if (best.personalRating != null && best.personalRating! > 7.0) {
        await _supabase.from('consumption_insights').insert({
          'user_id': userId,
          'insight_type': 'best_match',
          'title': 'Nejlepší strain pro tebe',
          'description':
              'Na základě ${best.totalConsumptions}× užití má ${best.strainId} u tebe rating ${best.personalRating!.toStringAsFixed(1)}/10',
          'data': {
            'strain_id': best.strainId,
            'rating': best.personalRating,
            'consumptions': best.totalConsumptions,
          },
          'confidence_score': best.totalConsumptions >= 5 ? 0.9 : 0.7,
          'priority': 10,
        });
      }
    }

    // Find worst match
    final worst = correlations.last;
    if (worst.personalRating != null && worst.personalRating! < 5.0) {
      await _supabase.from('consumption_insights').insert({
        'user_id': userId,
        'insight_type': 'worst_match',
        'title': 'Strain který ti nesedí',
        'description':
            '${worst.strainId} má u tebe nízký rating ${worst.personalRating!.toStringAsFixed(1)}/10',
        'data': {
          'strain_id': worst.strainId,
          'rating': worst.personalRating,
          'anxiety_level': worst.avgAnxietyLevel,
        },
        'confidence_score': worst.totalConsumptions >= 3 ? 0.8 : 0.6,
        'priority': 8,
      });
    }

    // High anxiety pattern
    final highAnxietyStrains = correlations
        .where((c) => c.avgAnxietyLevel != null && c.avgAnxietyLevel! > 6.0)
        .toList();

    if (highAnxietyStrains.isNotEmpty) {
      await _supabase.from('consumption_insights').insert({
        'user_id': userId,
        'insight_type': 'terpene_sensitivity',
        'title': 'Pozor na anxiety',
        'description':
            '${highAnxietyStrains.length} strain(ů) u tebe zvyšuje anxiety',
        'data': {
          'strains': highAnxietyStrains.map((s) => s.strainId).toList(),
          'avg_anxiety': highAnxietyStrains
              .map((s) => s.avgAnxietyLevel!)
              .reduce((a, b) => a + b) /
              highAnxietyStrains.length,
        },
        'confidence_score': 0.85,
        'priority': 9,
      });
    }
  }

  // ========== STATISTICS ==========

  /// Získá základní stats
  Future<ConsumptionStats> getStats(String userId) async {
    final logs = await getConsumptionLogs(userId: userId, limit: 1000);

    final totalConsumptions = logs.length;

    final logsWithChecks = await Future.wait(
      logs.where((l) => l.id != null).take(100).map((l) async {
        final hasCheck = await hasPostCheck(l.id!);
        return hasCheck;
      }),
    );

    final checkCompletionRate = logsWithChecks.isEmpty
        ? 0.0
        : logsWithChecks.where((c) => c).length / logsWithChecks.length;

    final correlations = await getAllStrainCorrelations(userId);

    return ConsumptionStats(
      totalConsumptions: totalConsumptions,
      uniqueStrains: correlations.length,
      checkCompletionRate: checkCompletionRate,
      topStrainRating: correlations.isNotEmpty &&
              correlations.first.personalRating != null
          ? correlations.first.personalRating!
          : null,
    );
  }
}

/// Stats pro dashboard
class ConsumptionStats {
  final int totalConsumptions;
  final int uniqueStrains;
  final double checkCompletionRate; // 0-1
  final double? topStrainRating;

  ConsumptionStats({
    required this.totalConsumptions,
    required this.uniqueStrains,
    required this.checkCompletionRate,
    this.topStrainRating,
  });
}
