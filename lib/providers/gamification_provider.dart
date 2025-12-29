import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gamification_service.dart';
import '../models/rank_model.dart';
import '../models/daily_quest_model.dart';
import '../models/strain_card_model.dart';

/// Provider pro gamification service
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return GamificationService();
});

/// Provider pro XP aktualniho uzivatele
final userXpProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getUserXp();
});

/// Provider pro rank aktualniho uzivatele
final userRankProvider = FutureProvider<SpiderRank>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getUserRank();
});

/// Provider pro dnesni questy
final dailyQuestsProvider = FutureProvider<List<DailyQuest>>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getTodayQuests();
});

/// Provider pro karty uzivatele
final userCardsProvider = FutureProvider<List<StrainCard>>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getUserCards();
});

/// Provider pro vsechny karty
final allCardsProvider = FutureProvider<List<StrainCard>>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getAllCards();
});

/// Provider pro statistiky kolekce
final collectionStatsProvider = FutureProvider<({int total, int collected, Map<CardRarity, int> byRarity})>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getCollectionStats();
});

/// Provider pro pocet vlaken
final userWebsProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getUserWebs();
});

/// Provider pro uroven pavuciny (vizualizace)
final webLevelProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getWebLevel();
});

/// Provider pro leaderboard
final leaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getXpLeaderboard(limit: 20);
});

/// Provider pro pozici v leaderboardu
final leaderboardPositionProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getUserLeaderboardPosition();
});

/// Notifier pro gamification akce
class GamificationNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  GamificationService get _service => ref.read(gamificationServiceProvider);

  /// Prida XP
  Future<({int newXp, SpiderRank? newRank, bool levelUp})> addXp(int amount, {String? reason}) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.addXp(amount, reason: reason);
      ref.invalidate(userXpProvider);
      ref.invalidate(userRankProvider);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return (newXp: 0, newRank: null, levelUp: false);
    }
  }

  /// Aktualizuje progress questu
  Future<bool> updateQuestProgress(String questId, int progress) async {
    try {
      final completed = await _service.updateQuestProgress(questId, progress);
      ref.invalidate(dailyQuestsProvider);
      if (completed) {
        ref.invalidate(userXpProvider);
      }
      return completed;
    } catch (e) {
      return false;
    }
  }

  /// Sebere kartu
  Future<bool> collectCard(String cardId) async {
    try {
      final success = await _service.collectCard(cardId);
      if (success) {
        ref.invalidate(userCardsProvider);
        ref.invalidate(collectionStatsProvider);
        ref.invalidate(userXpProvider);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Prida vlakno (web)
  Future<bool> addWeb({
    required String toUserId,
    required String contentId,
    required String contentType,
  }) async {
    try {
      final success = await _service.addWeb(
        toUserId: toUserId,
        contentId: contentId,
        contentType: contentType,
      );
      if (success) {
        ref.invalidate(userWebsProvider);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Odebere vlakno
  Future<bool> removeWeb({
    required String toUserId,
    required String contentId,
    required String contentType,
  }) async {
    try {
      final success = await _service.removeWeb(
        toUserId: toUserId,
        contentId: contentId,
        contentType: contentType,
      );
      if (success) {
        ref.invalidate(userWebsProvider);
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}

final gamificationProvider = NotifierProvider<GamificationNotifier, AsyncValue<void>>(() {
  return GamificationNotifier();
});
