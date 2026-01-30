import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cognitive_service.dart';
import '../models/cognitive_test_model.dart';

/// Provider pro Supabase client
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider pro CognitiveService
final cognitiveServiceProvider = Provider<CognitiveService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return CognitiveService(supabase);
});

/// Provider pro baseline uživatele
final cognitiveBaselineProvider = FutureProvider<CognitiveBaseline?>((ref) async {
  final service = ref.watch(cognitiveServiceProvider);
  final userId = ref.watch(supabaseProvider).auth.currentUser?.id;

  if (userId == null) return null;

  return await service.getBaseline(userId);
});

/// Provider pro historii testů (30 dní)
final cognitiveHistoryProvider = FutureProvider<List<CognitiveTestResult>>((ref) async {
  final service = ref.watch(cognitiveServiceProvider);
  final userId = ref.watch(supabaseProvider).auth.currentUser?.id;

  if (userId == null) return [];

  return await service.getTestHistory(userId: userId, limit: 30);
});

/// Provider pro nedávné testy (7 dní)
final recentCognitiveTestsProvider = FutureProvider<List<CognitiveTestResult>>((ref) async {
  final service = ref.watch(cognitiveServiceProvider);
  final userId = ref.watch(supabaseProvider).auth.currentUser?.id;

  if (userId == null) return [];

  return await service.getRecentTests(userId: userId, days: 7);
});

/// Provider pro streak stats
final cognitiveStreakProvider = FutureProvider<CognitiveStreakStats>((ref) async {
  final service = ref.watch(cognitiveServiceProvider);
  final userId = ref.watch(supabaseProvider).auth.currentUser?.id;

  if (userId == null) {
    return CognitiveStreakStats(
      currentStreak: 0,
      longestStreak: 0,
      totalTests: 0,
      lastTestDate: null,
    );
  }

  return await service.getStreakStats(userId);
});

/// Provider pro denní scores (pro graf)
final dailyScoresProvider = FutureProvider.family<List<DailyScore>, int>((ref, days) async {
  final service = ref.watch(cognitiveServiceProvider);
  final userId = ref.watch(supabaseProvider).auth.currentUser?.id;

  if (userId == null) return [];

  return await service.getDailyScores(userId: userId, days: days);
});

/// Provider pro kontrolu, zda byl test dnes proveden
final hasTestTodayProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(cognitiveServiceProvider);
  final userId = ref.watch(supabaseProvider).auth.currentUser?.id;

  if (userId == null) return false;

  return await service.hasTestToday(userId);
});

/// Provider pro ukládání test resultu
final cognitiveTestNotifierProvider =
    NotifierProvider<CognitiveTestNotifier, AsyncValue<void>>(
  CognitiveTestNotifier.new,
);

/// Notifier pro ukládání výsledku testu
class CognitiveTestNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Uloží výsledek testu a invaliduje relevantní providery
  Future<void> saveTestResult(CognitiveTestResult result) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final service = ref.read(cognitiveServiceProvider);
      await service.saveTestResult(result);

      // Invalidate providers aby se reloadly data
      ref.invalidate(cognitiveBaselineProvider);
      ref.invalidate(cognitiveHistoryProvider);
      ref.invalidate(recentCognitiveTestsProvider);
      ref.invalidate(cognitiveStreakProvider);
      ref.invalidate(hasTestTodayProvider);
    });
  }
}
