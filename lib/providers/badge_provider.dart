import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/badge_service.dart';
import '../models/badge_model.dart';

/// Provider pro badge service
final badgeServiceProvider = Provider<BadgeService>((ref) {
  return BadgeService();
});

/// Provider pro odznaky aktualniho uzivatele
final userBadgesProvider = FutureProvider<List<UserBadge>>((ref) async {
  final service = ref.watch(badgeServiceProvider);
  return service.getUserBadges();
});

/// Provider pro featured odznaky (zobrazene v profilu)
final featuredBadgesProvider = FutureProvider<List<UserBadge>>((ref) async {
  final service = ref.watch(badgeServiceProvider);
  return service.getFeaturedBadges();
});

/// Provider pro nove (neprecetne) odznaky
final newBadgesProvider = FutureProvider<List<UserBadge>>((ref) async {
  final service = ref.watch(badgeServiceProvider);
  return service.getNewBadges();
});

/// Provider pro statistiky odznaku
final badgeStatsProvider = FutureProvider<({
  int total,
  int earned,
  Map<BadgeCategory, int> byCategory,
  Map<BadgeRarity, int> byRarity,
})>((ref) async {
  final service = ref.watch(badgeServiceProvider);
  return service.getBadgeStats();
});

/// Provider pro pocet novych odznaku (pro notifikaci)
final newBadgeCountProvider = FutureProvider<int>((ref) async {
  final newBadges = await ref.watch(newBadgesProvider.future);
  return newBadges.length;
});

/// Provider pro odznaky podle kategorie
final badgesByCategoryProvider = Provider.family<List<Badge>, BadgeCategory>((ref, category) {
  return Badges.getByCategory(category);
});

/// Provider pro odznaky podle rarity
final badgesByRarityProvider = Provider.family<List<Badge>, BadgeRarity>((ref, rarity) {
  return Badges.getByRarity(rarity);
});

/// Provider pro kontrolu, zda uzivatel ma odznak
final hasBadgeProvider = FutureProvider.family<bool, String>((ref, badgeId) async {
  final badges = await ref.watch(userBadgesProvider.future);
  return badges.any((b) => b.badgeId == badgeId);
});

/// Notifier pro badge akce
class BadgeNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  BadgeService get _service => ref.read(badgeServiceProvider);

  /// Zkontroluje a prideli nove odznaky
  Future<List<UserBadge>> checkAndAwardBadges() async {
    state = const AsyncValue.loading();
    try {
      final awarded = await _service.checkAndAwardBadges();
      if (awarded.isNotEmpty) {
        ref.invalidate(userBadgesProvider);
        ref.invalidate(badgeStatsProvider);
        ref.invalidate(newBadgesProvider);
        ref.invalidate(newBadgeCountProvider);
      }
      state = const AsyncValue.data(null);
      return awarded;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  /// Oznaci odznak jako precteny
  Future<void> markBadgeAsSeen(String badgeId) async {
    try {
      await _service.markBadgeAsSeen(badgeId);
      ref.invalidate(newBadgesProvider);
      ref.invalidate(newBadgeCountProvider);
    } catch (e) {
      // Ignore
    }
  }

  /// Oznaci vsechny odznaky jako prectene
  Future<void> markAllBadgesAsSeen() async {
    try {
      final newBadges = await ref.read(newBadgesProvider.future);
      for (final badge in newBadges) {
        await _service.markBadgeAsSeen(badge.badgeId);
      }
      ref.invalidate(newBadgesProvider);
      ref.invalidate(newBadgeCountProvider);
    } catch (e) {
      // Ignore
    }
  }

  /// Prepne featured stav odznaku
  Future<bool> toggleFeaturedBadge(String badgeId, bool isFeatured) async {
    try {
      final success = await _service.toggleFeaturedBadge(badgeId, isFeatured);
      if (success) {
        ref.invalidate(userBadgesProvider);
        ref.invalidate(featuredBadgesProvider);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Prideli specialni odznak (pro adminy)
  Future<UserBadge?> awardSpecialBadge(String badgeId, [String? userId]) async {
    try {
      final badge = await _service.awardBadge(badgeId, userId);
      if (badge != null) {
        ref.invalidate(userBadgesProvider);
        ref.invalidate(badgeStatsProvider);
        ref.invalidate(newBadgesProvider);
      }
      return badge;
    } catch (e) {
      return null;
    }
  }

  /// Zkontroluje nocni aktivitu
  Future<UserBadge?> checkNightOwlBadge() async {
    try {
      final badge = await _service.checkNightOwlBadge();
      if (badge != null) {
        ref.invalidate(userBadgesProvider);
        ref.invalidate(badgeStatsProvider);
        ref.invalidate(newBadgesProvider);
      }
      return badge;
    } catch (e) {
      return null;
    }
  }

  /// Prideli sezonni odznak
  Future<UserBadge?> awardSeasonalBadge(String badgeId) async {
    try {
      final badge = await _service.awardSeasonalBadge(badgeId);
      if (badge != null) {
        ref.invalidate(userBadgesProvider);
        ref.invalidate(badgeStatsProvider);
        ref.invalidate(newBadgesProvider);
      }
      return badge;
    } catch (e) {
      return null;
    }
  }
}

final badgeProvider = NotifierProvider<BadgeNotifier, AsyncValue<void>>(() {
  return BadgeNotifier();
});
