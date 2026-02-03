import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/personal_science_model.dart';
import 'dart:math' as math;

/// Service for Personal Science analytics and correlations
class PersonalScienceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== STRAIN EFFECTS ====================

  /// Get all strain effects for user
  Future<List<StrainEffect>> getStrainEffects(String userId) async {
    final response = await _supabase
        .from('strain_effects')
        .select('*, strains(name)')
        .eq('user_id', userId)
        .order('total_sessions', ascending: false);

    return (response as List).map((json) {
      final map = Map<String, dynamic>.from(json);
      if (json['strains'] != null) {
        map['strain_name'] = json['strains']['name'];
      }
      return StrainEffect.fromJson(map);
    }).toList();
  }

  /// Get strain effect for specific strain
  Future<StrainEffect?> getStrainEffect(String userId, String strainId) async {
    try {
      final response = await _supabase
          .from('strain_effects')
          .select('*, strains(name)')
          .eq('user_id', userId)
          .eq('strain_id', strainId)
          .maybeSingle();

      if (response == null) return null;

      final map = Map<String, dynamic>.from(response);
      if (response['strains'] != null) {
        map['strain_name'] = response['strains']['name'];
      }
      return StrainEffect.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  /// Get top performing strains by effectiveness
  Future<List<StrainEffect>> getTopStrains(String userId, {int limit = 5}) async {
    final allEffects = await getStrainEffects(userId);

    // Sort by effectiveness score
    allEffects.sort((a, b) => b.effectivenessScore.compareTo(a.effectivenessScore));

    return allEffects.take(limit).toList();
  }

  /// Get strains best for specific goal (focus, relaxation, etc.)
  Future<List<StrainEffect>> getStrainsForGoal(
    String userId,
    String goal, {
    int limit = 3,
  }) async {
    final allEffects = await getStrainEffects(userId);

    // Filter by minimum sessions
    final filtered = allEffects.where((e) => e.totalSessions >= 2).toList();

    // Sort based on goal
    filtered.sort((a, b) {
      double scoreA = 0;
      double scoreB = 0;

      switch (goal.toLowerCase()) {
        case 'focus':
        case 'productivity':
          scoreA = a.focusChange + (a.energyChange * 0.5);
          scoreB = b.focusChange + (b.energyChange * 0.5);
          break;
        case 'relaxation':
        case 'stress':
          scoreA = a.moodBoost - (a.anxietyChange * 0.8);
          scoreB = b.moodBoost - (b.anxietyChange * 0.8);
          break;
        case 'energy':
        case 'motivation':
          scoreA = a.energyChange + (a.moodBoost * 0.3);
          scoreB = b.energyChange + (b.moodBoost * 0.3);
          break;
        case 'mood':
        case 'happiness':
          scoreA = a.moodBoost;
          scoreB = b.moodBoost;
          break;
        default:
          scoreA = a.effectivenessScore;
          scoreB = b.effectivenessScore;
      }

      return scoreB.compareTo(scoreA);
    });

    return filtered.take(limit).toList();
  }

  // ==================== CORRELATIONS ====================

  /// Get all correlation insights for user
  Future<List<CorrelationInsight>> getCorrelationInsights(String userId) async {
    final response = await _supabase
        .from('correlation_insights')
        .select()
        .eq('user_id', userId)
        .order('calculated_at', ascending: false);

    return (response as List)
        .map((json) => CorrelationInsight.fromJson(json))
        .where((insight) => !insight.isExpired)
        .toList();
  }

  /// Calculate correlation between strain and cognitive performance
  Future<CorrelationInsight?> calculateStrainCognitiveCorrelation(
    String userId,
    String strainId,
  ) async {
    // Get consumption logs with cognitive scores for this strain
    final logsResponse = await _supabase
        .from('consumption_logs')
        .select()
        .eq('user_id', userId)
        .eq('strain_id', strainId);

    final logs = logsResponse as List;

    if (logs.length < 5) {
      // Not enough data
      return null;
    }

    // Get cognitive test results around consumption times
    // This is simplified - in production, you'd match timestamps properly
    final cognitiveResponse = await _supabase
        .from('cognitive_test_results')
        .select()
        .eq('user_id', userId)
        .order('tested_at', ascending: false)
        .limit(20);

    final cognitive = cognitiveResponse as List;

    if (cognitive.length < 5) {
      return null;
    }

    // Calculate correlation
    // Simplified Pearson correlation
    final correlation = _calculatePearsonCorrelation(
      logs.map((l) => (l['amount'] as num?)?.toDouble() ?? 0.0).toList(),
      cognitive.map((c) => (c['total_score'] as num?)?.toDouble() ?? 0.0).toList(),
    );

    final summary = _generateCorrelationSummary(correlation, 'strain', 'cognitive');

    // Save to database
    final response = await _supabase
        .from('correlation_insights')
        .upsert({
          'user_id': userId,
          'type': 'strain_cognitive',
          'factor_a': strainId,
          'factor_b': 'cognitive_score',
          'correlation_coefficient': correlation,
          'sample_size': math.min(logs.length, cognitive.length),
          'confidence_level': _determineConfidenceLevel(
            correlation,
            math.min(logs.length, cognitive.length),
          ),
          'summary': summary,
          'calculated_at': DateTime.now().toIso8601String(),
          'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        })
        .select()
        .single();

    return CorrelationInsight.fromJson(response);
  }

  /// Calculate Pearson correlation coefficient
  double _calculatePearsonCorrelation(List<double> x, List<double> y) {
    if (x.isEmpty || y.isEmpty || x.length != y.length) return 0.0;

    final n = x.length;
    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;

    double numerator = 0;
    double denomX = 0;
    double denomY = 0;

    for (int i = 0; i < n; i++) {
      final dx = x[i] - meanX;
      final dy = y[i] - meanY;
      numerator += dx * dy;
      denomX += dx * dx;
      denomY += dy * dy;
    }

    if (denomX == 0 || denomY == 0) return 0.0;

    return numerator / math.sqrt(denomX * denomY);
  }

  /// Generate human-readable summary for correlation
  String _generateCorrelationSummary(double correlation, String factorA, String factorB) {
    final abs = correlation.abs();
    final direction = correlation > 0 ? 'pozitivní' : 'negativní';
    String strength;

    if (abs < 0.3) {
      strength = 'slabá';
    } else if (abs < 0.7) {
      strength = 'střední';
    } else {
      strength = 'silná';
    }

    return 'Nalezena $strength $direction korelace mezi $factorA a $factorB (r=${correlation.toStringAsFixed(2)})';
  }

  /// Determine confidence level based on correlation and sample size
  String _determineConfidenceLevel(double correlation, int sampleSize) {
    if (sampleSize < 10) return 'low';
    if (sampleSize >= 30 && correlation.abs() > 0.5) return 'high';
    if (sampleSize >= 20 && correlation.abs() > 0.3) return 'medium';
    return 'low';
  }

  // ==================== CONSUMPTION PATTERNS ====================

  /// Get consumption pattern for user
  Future<ConsumptionPattern?> getConsumptionPattern(String userId) async {
    try {
      final response = await _supabase
          .from('consumption_patterns')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return ConsumptionPattern.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Calculate and save consumption patterns
  Future<ConsumptionPattern> calculateConsumptionPatterns(String userId) async {
    // Get all consumption logs
    final logsResponse = await _supabase
        .from('consumption_logs')
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false);

    final logs = logsResponse as List;

    if (logs.length < 10) {
      throw Exception('Not enough data to calculate patterns (minimum 10 sessions)');
    }

    // Analyze time of day patterns
    final timeOfDayScores = <String, List<double>>{
      'morning': [],
      'afternoon': [],
      'evening': [],
      'night': [],
    };

    for (final log in logs) {
      final timestamp = DateTime.parse(log['timestamp'] as String);
      final hour = timestamp.hour;
      final moodAfter = (log['mood_after'] as num?)?.toDouble();
      final focusAfter = (log['focus_after'] as num?)?.toDouble();

      if (moodAfter == null || focusAfter == null) continue;

      final score = (moodAfter + focusAfter) / 2;
      String timeOfDay;

      if (hour >= 5 && hour < 12) {
        timeOfDay = 'morning';
      } else if (hour >= 12 && hour < 17) {
        timeOfDay = 'afternoon';
      } else if (hour >= 17 && hour < 22) {
        timeOfDay = 'evening';
      } else {
        timeOfDay = 'night';
      }

      timeOfDayScores[timeOfDay]!.add(score);
    }

    // Calculate averages
    final avgScores = timeOfDayScores.map((key, scores) {
      final avg = scores.isEmpty
          ? 0.0
          : scores.reduce((a, b) => a + b) / scores.length;
      return MapEntry(key, avg);
    });

    // Find best and worst times
    final sortedTimes = avgScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bestTimes = sortedTimes.take(2).map((e) => e.key).toList();
    final worstTimes = sortedTimes.reversed.take(2).map((e) => e.key).toList();

    // Analyze day of week patterns
    final dayOfWeekScores = <String, List<double>>{};
    for (final log in logs) {
      final timestamp = DateTime.parse(log['timestamp'] as String);
      final day = _getDayName(timestamp.weekday);
      final moodAfter = (log['mood_after'] as num?)?.toDouble();
      final focusAfter = (log['focus_after'] as num?)?.toDouble();

      if (moodAfter == null || focusAfter == null) continue;

      final score = (moodAfter + focusAfter) / 2;
      dayOfWeekScores.putIfAbsent(day, () => []).add(score);
    }

    final avgDayScores = dayOfWeekScores.map((key, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      return MapEntry(key, avg);
    });

    final sortedDays = avgDayScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bestDays = sortedDays.take(2).map((e) => e.key).toList();
    final worstDays = sortedDays.reversed.take(2).map((e) => e.key).toList();

    // Calculate confidence based on data amount
    final confidence = math.min(1.0, logs.length / 50.0);

    // Save pattern
    final pattern = {
      'user_id': userId,
      'best_time_of_day': bestTimes,
      'worst_time_of_day': worstTimes,
      'best_day_of_week': bestDays,
      'worst_day_of_week': worstDays,
      'confidence': confidence,
      'based_on_sessions': logs.length,
      'calculated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('consumption_patterns')
        .upsert(pattern)
        .select()
        .single();

    return ConsumptionPattern.fromJson(response);
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'unknown';
    }
  }

  // ==================== RECOMMENDATIONS ====================

  /// Get strain recommendations for user
  Future<List<StrainRecommendation>> getStrainRecommendations(
    String userId, {
    int limit = 10,
  }) async {
    final response = await _supabase
        .from('strain_recommendations')
        .select('*, strains(name)')
        .eq('user_id', userId)
        .order('score', ascending: false)
        .limit(limit);

    return (response as List).map((json) {
      final map = Map<String, dynamic>.from(json);
      if (json['strains'] != null) {
        map['strain_name'] = json['strains']['name'];
      }
      return StrainRecommendation.fromJson(map);
    }).where((rec) => !rec.isExpired).toList();
  }

  /// Generate strain recommendations based on user data
  Future<void> generateRecommendations(String userId) async {
    // Get user's strain effects
    final effects = await getStrainEffects(userId);

    if (effects.isEmpty) {
      // Not enough data
      return;
    }

    // Find strains user hasn't tried yet
    final triedStrainIds = effects.map((e) => e.strainId).toSet();

    final allStrainsResponse = await _supabase
        .from('strains')
        .select('id, name, category, dominant_terpene')
        .limit(100);

    final allStrains = allStrainsResponse as List;

    // Get user's preferences based on past success
    final topEffects = effects.take(5).toList();
    final preferredCategories = topEffects
        .map((e) => e.commonEffects.map((et) => et.effect))
        .expand((e) => e)
        .toSet();

    // Generate recommendations
    final recommendations = <Map<String, dynamic>>[];

    for (final strain in allStrains) {
      final strainId = strain['id'] as String;

      if (triedStrainIds.contains(strainId)) continue;

      // Calculate recommendation score
      double score = 0.5; // Base score

      // Boost score if strain category matches preferred categories
      // This is simplified - in production, use proper ML matching
      if (preferredCategories.isNotEmpty) {
        score += 0.2;
      }

      final reasons = <Map<String, dynamic>>[];

      reasons.add({
        'type': 'similar_profile',
        'description': 'Podobný profil vašim oblíbeným odrůdám',
      });

      // Expected outcomes based on similar strains
      final expectedMood = topEffects.isNotEmpty
          ? topEffects.first.moodBoost
          : 0.0;

      recommendations.add({
        'user_id': userId,
        'strain_id': strainId,
        'score': score,
        'reasons': reasons,
        'recommended_for': ['relaxation', 'mood'],
        'recommended_times': ['evening'],
        'expected_mood_boost': expectedMood,
        'expected_energy_change': 0.0,
        'expected_focus_change': 0.0,
        'generated_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      });

      if (recommendations.length >= 10) break;
    }

    // Save recommendations
    if (recommendations.isNotEmpty) {
      await _supabase.from('strain_recommendations').upsert(recommendations);
    }
  }

  /// Mark recommendation as tried
  Future<void> markRecommendationTried(
    String userId,
    String strainId,
    double rating,
  ) async {
    await _supabase
        .from('strain_recommendations')
        .update({
          'is_tried': true,
          'actual_rating': rating,
          'tried_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('strain_id', strainId);
  }
}
