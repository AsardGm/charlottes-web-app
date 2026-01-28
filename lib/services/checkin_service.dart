import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_checkin_model.dart';

class CheckinService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<DailyCheckin?> saveCheckin(DailyCheckin checkin) async {
    try {
      final response = await _supabase
          .from('daily_checkins')
          .insert(checkin.toJson())
          .select()
          .single();
      return DailyCheckin.fromJson(response);
    } catch (e) {
      print('Error saving checkin: $e');
      return null;
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
