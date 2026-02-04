import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tolerance_break_model.dart';
import 'challenge_service.dart';

class TBreakService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ChallengeService _challengeService = ChallengeService();

  // Start a new tolerance break
  Future<ToleranceBreak> startToleranceBreak({
    required String userId,
    required int targetDays,
    required TBreakMotivation motivation,
    String? customMotivation,
  }) async {
    final now = DateTime.now();
    final targetEndDate = now.add(Duration(days: targetDays));

    final data = {
      'user_id': userId,
      'start_date': now.toIso8601String(),
      'target_end_date': targetEndDate.toIso8601String(),
      'target_days': targetDays,
      'status': 'active',
      'motivation': _motivationToString(motivation),
      'custom_motivation': customMotivation,
      'days_completed': 0,
    };

    final response = await _supabase
        .from('tolerance_breaks')
        .insert(data)
        .select()
        .single();

    return ToleranceBreak.fromJson(response);
  }

  // Get active tolerance break for user
  Future<ToleranceBreak?> getActiveToleranceBreak(String userId) async {
    try {
      final response = await _supabase
          .from('tolerance_breaks')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return ToleranceBreak.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Get all tolerance breaks for user (history)
  Future<List<ToleranceBreak>> getToleranceBreakHistory(String userId) async {
    final response = await _supabase
        .from('tolerance_breaks')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ToleranceBreak.fromJson(json))
        .toList();
  }

  // Add daily check-in
  Future<TBreakCheckIn> addCheckIn({
    required String tbreakId,
    required int dayNumber,
    required int moodScore,
    required bool hadCravings,
    required int sleepQuality,
    required int anxietyLevel,
    List<String>? symptoms,
    String? notes,
  }) async {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);

    final data = {
      'tbreak_id': tbreakId,
      'date': dateOnly.toIso8601String(),
      'day_number': dayNumber,
      'mood_score': moodScore,
      'had_cravings': hadCravings,
      'sleep_quality': sleepQuality,
      'anxiety_level': anxietyLevel,
      'symptoms': symptoms ?? [],
      'notes': notes,
    };

    final response = await _supabase
        .from('tbreak_checkins')
        .insert(data)
        .select()
        .single();

    // Update challenge progress for t-break streak
    final tbreak = await _supabase
        .from('tolerance_breaks')
        .select('user_id')
        .eq('id', tbreakId)
        .single();

    final userId = tbreak['user_id'] as String;
    _challengeService.updateStreakProgress(userId, 'tbreak', dayNumber);

    return TBreakCheckIn.fromJson(response);
  }

  // Get check-ins for a tolerance break
  Future<List<TBreakCheckIn>> getCheckIns(String tbreakId) async {
    final response = await _supabase
        .from('tbreak_checkins')
        .select()
        .eq('tbreak_id', tbreakId)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => TBreakCheckIn.fromJson(json))
        .toList();
  }

  // Get today's check-in (if exists)
  Future<TBreakCheckIn?> getTodayCheckIn(String tbreakId) async {
    try {
      final today = DateTime.now();
      final dateOnly = DateTime(today.year, today.month, today.day);

      final response = await _supabase
          .from('tbreak_checkins')
          .select()
          .eq('tbreak_id', tbreakId)
          .eq('date', dateOnly.toIso8601String())
          .maybeSingle();

      if (response == null) return null;
      return TBreakCheckIn.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Mark tolerance break as failed
  Future<void> markAsFailed(String tbreakId) async {
    await _supabase.from('tolerance_breaks').update({
      'status': 'failed',
      'failed_date': DateTime.now().toIso8601String(),
    }).eq('id', tbreakId);
  }

  // Get statistics for user's tolerance breaks
  Future<Map<String, dynamic>> getStatistics(String userId) async {
    final breaks = await getToleranceBreakHistory(userId);

    if (breaks.isEmpty) {
      return {
        'total_breaks': 0,
        'completed_breaks': 0,
        'failed_breaks': 0,
        'active_breaks': 0,
        'success_rate': 0.0,
        'longest_streak': 0,
        'total_days_clean': 0,
      };
    }

    final completed = breaks.where((b) => b.status == TBreakStatus.completed).toList();
    final failed = breaks.where((b) => b.status == TBreakStatus.failed).toList();
    final active = breaks.where((b) => b.status == TBreakStatus.active).toList();

    final longestStreak = breaks.isEmpty
        ? 0
        : breaks.map((b) => b.daysCompleted).reduce((a, b) => a > b ? a : b);

    final totalDaysClean = breaks.fold<int>(0, (sum, b) => sum + b.daysCompleted);

    final successRate = (completed.length + failed.length) > 0
        ? (completed.length / (completed.length + failed.length)) * 100
        : 0.0;

    return {
      'total_breaks': breaks.length,
      'completed_breaks': completed.length,
      'failed_breaks': failed.length,
      'active_breaks': active.length,
      'success_rate': successRate,
      'longest_streak': longestStreak,
      'total_days_clean': totalDaysClean,
    };
  }

  // Helper: Convert motivation enum to string
  String _motivationToString(TBreakMotivation motivation) {
    switch (motivation) {
      case TBreakMotivation.lowerTolerance:
        return 'lowerTolerance';
      case TBreakMotivation.health:
        return 'health';
      case TBreakMotivation.saveMoney:
        return 'saveMoney';
      case TBreakMotivation.resetReceptors:
        return 'resetReceptors';
      case TBreakMotivation.proveMyself:
        return 'proveMyself';
      case TBreakMotivation.other:
        return 'other';
    }
  }
}
