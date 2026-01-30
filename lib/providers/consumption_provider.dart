import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/consumption_model.dart';
import '../services/consumption_service.dart';

// ========== SERVICE ==========

final consumptionServiceProvider = Provider<ConsumptionService>((ref) {
  return ConsumptionService(Supabase.instance.client);
});

// ========== STATS ==========

final consumptionStatsProvider = FutureProvider<ConsumptionStats>((ref) async {
  final service = ref.watch(consumptionServiceProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('User not logged in');
  }

  return service.getStats(userId);
});

// ========== INSIGHTS ==========

final consumptionInsightsProvider =
    FutureProvider<List<ConsumptionInsight>>((ref) async {
  final service = ref.watch(consumptionServiceProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('User not logged in');
  }

  return service.getActiveInsights(userId);
});

// ========== STRAIN CORRELATIONS ==========

final topStrainsProvider =
    FutureProvider<List<StrainUserCorrelation>>((ref) async {
  final service = ref.watch(consumptionServiceProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('User not logged in');
  }

  return service.getTopStrains(userId: userId, limit: 5);
});

final worstStrainsProvider =
    FutureProvider<List<StrainUserCorrelation>>((ref) async {
  final service = ref.watch(consumptionServiceProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('User not logged in');
  }

  return service.getWorstStrains(userId: userId, limit: 3);
});

final allStrainCorrelationsProvider =
    FutureProvider<List<StrainUserCorrelation>>((ref) async {
  final service = ref.watch(consumptionServiceProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('User not logged in');
  }

  return service.getAllStrainCorrelations(userId);
});

// ========== CONSUMPTION LOGS ==========

final consumptionLogsProvider =
    FutureProvider<List<ConsumptionLog>>((ref) async {
  final service = ref.watch(consumptionServiceProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('User not logged in');
  }

  return service.getConsumptionLogs(userId: userId, limit: 50);
});

final recentConsumptionLogsProvider =
    FutureProvider.family<List<ConsumptionLog>, int>((ref, days) async {
  final service = ref.watch(consumptionServiceProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('User not logged in');
  }

  return service.getRecentConsumptionLogs(userId: userId, days: days);
});

final logsWithoutPostCheckProvider =
    FutureProvider<List<ConsumptionLog>>((ref) async {
  final service = ref.watch(consumptionServiceProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('User not logged in');
  }

  return service.getLogsWithoutPostCheck(userId);
});

// ========== CONSUMPTION LOG WITH CHECK ==========

final consumptionWithCheckProvider = FutureProvider.family<
    (ConsumptionLog, PostConsumptionCheck?)?, String>((ref, logId) async {
  final service = ref.watch(consumptionServiceProvider);
  return service.getConsumptionWithCheck(logId);
});

// ========== NOTIFIERS (for mutations) ==========

class ConsumptionNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<ConsumptionLog> saveConsumptionLog(ConsumptionLog log) async {
    final service = ref.read(consumptionServiceProvider);
    final savedLog = await service.saveConsumptionLog(log);

    // Invalidate related providers
    ref.invalidate(consumptionLogsProvider);
    ref.invalidate(recentConsumptionLogsProvider);
    ref.invalidate(consumptionStatsProvider);
    ref.invalidate(logsWithoutPostCheckProvider);

    return savedLog;
  }

  Future<PostConsumptionCheck> savePostConsumptionCheck(
      PostConsumptionCheck check) async {
    final service = ref.read(consumptionServiceProvider);
    final savedCheck = await service.savePostConsumptionCheck(check);

    // Invalidate related providers
    ref.invalidate(consumptionLogsProvider);
    ref.invalidate(recentConsumptionLogsProvider);
    ref.invalidate(consumptionStatsProvider);
    ref.invalidate(topStrainsProvider);
    ref.invalidate(worstStrainsProvider);
    ref.invalidate(allStrainCorrelationsProvider);
    ref.invalidate(consumptionInsightsProvider);
    ref.invalidate(logsWithoutPostCheckProvider);

    // Trigger insight generation
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await service.generateBasicInsights(userId);
      ref.invalidate(consumptionInsightsProvider);
    }

    return savedCheck;
  }

  Future<void> generateInsights() async {
    final service = ref.read(consumptionServiceProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('User not logged in');
    }

    await service.generateBasicInsights(userId);
    ref.invalidate(consumptionInsightsProvider);
  }
}

final consumptionNotifierProvider = NotifierProvider<ConsumptionNotifier, void>(
  ConsumptionNotifier.new,
);
