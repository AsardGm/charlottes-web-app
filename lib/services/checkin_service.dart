import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_checkin_model.dart';
import 'challenge_service.dart';

class CheckinService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ChallengeService _challengeService = ChallengeService();

  Future<DailyCheckin?> saveCheckin(DailyCheckin checkin) async {
    try {
      final response = await _supabase
          .from('daily_checkins')
          .insert(checkin.toJson())
          .select()
          .single();

      // Calculate current streak and update wellness challenges
      final currentStreak = await _calculateCurrentStreak(checkin.userId);
      _challengeService.updateStreakProgress(
        checkin.userId,
        'wellness',
        currentStreak,
      );

      return DailyCheckin.fromJson(response);
    } catch (e) {
      print('Error saving checkin: $e');
      return null;
    }
  }

  /// Calculate current consecutive check-in streak
  Future<int> _calculateCurrentStreak(String userId) async {
    try {
      final checkins = await getCheckinHistory(userId, limit: 100);
      if (checkins.isEmpty) return 1; // First check-in

      int streak = 1; // Count today
      DateTime previousDate = DateTime.now();

      for (final checkin in checkins) {
        final checkinDate = checkin.createdAt;
        final daysDifference = previousDate.difference(checkinDate).inDays;

        // If consecutive day (1 day apart)
        if (daysDifference == 1) {
          streak++;
          previousDate = checkinDate;
        } else if (daysDifference > 1) {
          // Streak broken
          break;
        }
        // If same day (daysDifference == 0), continue to next
      }

      return streak;
    } catch (e) {
      return 1; // Default to 1 on error
    }
  }

  Future<DailyCheckin?> getTodayCheckin(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final response = await _supabase
          .from('daily_checkins')
          .select()
          .eq('user_id', userId)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .maybeSingle();
      if (response == null) return null;
      return DailyCheckin.fromJson(response);
    } catch (e) {
      print('Error getting today checkin: $e');
      return null;
    }
  }

  Future<List<DailyCheckin>> getCheckinHistory(String userId, {int limit = 30}) async {
    try {
      final response = await _supabase
          .from('daily_checkins')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List).map((json) => DailyCheckin.fromJson(json)).toList();
    } catch (e) {
      print('Error getting checkin history: $e');
      return [];
    }
  }

  String generateInsight(DailyCheckin checkin) {
    final insights = <String>[];
    if (checkin.mood <= 2) {
      insights.add('Nizka nalada? Zkus strain s vyssim obsahem limonenu.');
    } else if (checkin.mood >= 4) {
      insights.add('Skvela nalada! Udrzuj ji s vyvazenymi hybridy.');
    }
    if (checkin.energy <= 2) {
      insights.add('Potrebujes energii? Sativa s pinene ti muze pomoci.');
    }
    if (checkin.bodyState == BodyState.anxious) {
      insights.add('Citis uzkost? Hledej strainy s linalool a myrcene.');
    }
    if (checkin.bodyState == BodyState.heavy) {
      insights.add('Tezke telo? Indica s caryophyllene muze uvolnit napeti.');
    }
    if (checkin.plantContact == true) {
      insights.add('Kontakt s rostlinou zaznameman.');
    }
    if (insights.isEmpty) {
      insights.add('Pokracuj v dennich check-inech pro lepsi insighty!');
    }
    return insights.join('\n\n');
  }
}
