import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/badge_model.dart';

/// Service pro spravu odznaku
class BadgeService {
  final _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ============================================
  // BADGE RETRIEVAL
  // ============================================

  /// Ziska vsechny odznaky uzivatele
  Future<List<UserBadge>> getUserBadges([String? userId]) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return [];

    try {
      final response = await _supabase
          .from('user_badges')
          .select()
          .eq('user_id', uid)
          .order('earned_at', ascending: false);

      return response.map((row) {
        final badgeId = row['badge_id'] as String;
        final badge = Badges.getById(badgeId);
        if (badge == null) return null;
        return UserBadge.fromJson(row, badge);
      }).whereType<UserBadge>().toList();
    } catch (e) {
      debugPrint('Error getting user badges: $e');
      return [];
    }
  }

  /// Ziska featured odznaky uzivatele (zobrazene v profilu)
  Future<List<UserBadge>> getFeaturedBadges([String? userId]) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return [];

    try {
      final response = await _supabase
          .from('user_badges')
          .select()
          .eq('user_id', uid)
          .eq('is_featured', true)
          .order('earned_at', ascending: false)
          .limit(3);

      return response.map((row) {
        final badgeId = row['badge_id'] as String;
        final badge = Badges.getById(badgeId);
        if (badge == null) return null;
        return UserBadge.fromJson(row, badge);
      }).whereType<UserBadge>().toList();
    } catch (e) {
      debugPrint('Error getting featured badges: $e');
      return [];
    }
  }

  /// Ziska nove (neprecetne) odznaky
  Future<List<UserBadge>> getNewBadges() async {
    if (currentUserId == null) return [];

    try {
      final response = await _supabase
          .from('user_badges')
          .select()
          .eq('user_id', currentUserId!)
          .eq('is_new', true)
          .order('earned_at', ascending: false);

      return response.map((row) {
        final badgeId = row['badge_id'] as String;
        final badge = Badges.getById(badgeId);
        if (badge == null) return null;
        return UserBadge.fromJson(row, badge);
      }).whereType<UserBadge>().toList();
    } catch (e) {
      debugPrint('Error getting new badges: $e');
      return [];
    }
  }

  /// Oznaci odznak jako precteny
  Future<void> markBadgeAsSeen(String badgeId) async {
    if (currentUserId == null) return;

    try {
      await _supabase
          .from('user_badges')
          .update({'is_new': false})
          .eq('user_id', currentUserId!)
          .eq('badge_id', badgeId);
    } catch (e) {
      debugPrint('Error marking badge as seen: $e');
    }
  }

  /// Nastavi/zrusi featured odznak
  Future<bool> toggleFeaturedBadge(String badgeId, bool isFeatured) async {
    if (currentUserId == null) return false;

    try {
      // Pokud pridavame, zkontroluj limit 3
      if (isFeatured) {
        final currentFeatured = await getFeaturedBadges();
        if (currentFeatured.length >= 3) {
          // Odeber nejstarsi featured
          final oldest = currentFeatured.last;
          await _supabase
              .from('user_badges')
              .update({'is_featured': false})
              .eq('user_id', currentUserId!)
              .eq('badge_id', oldest.badgeId);
        }
      }

      await _supabase
          .from('user_badges')
          .update({'is_featured': isFeatured})
          .eq('user_id', currentUserId!)
          .eq('badge_id', badgeId);

      return true;
    } catch (e) {
      debugPrint('Error toggling featured badge: $e');
      return false;
    }
  }

  // ============================================
  // BADGE AWARDING
  // ============================================

  /// Prideli odznak uzivateli
  Future<UserBadge?> awardBadge(String badgeId, [String? userId]) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return null;

    try {
      // Zkontroluj, zda uz odznak nema
      final existing = await _supabase
          .from('user_badges')
          .select('id')
          .eq('user_id', uid)
          .eq('badge_id', badgeId)
          .maybeSingle();

      if (existing != null) return null; // Uz ma

      final badge = Badges.getById(badgeId);
      if (badge == null) return null;

      // Pridej odznak
      final now = DateTime.now();
      await _supabase.from('user_badges').insert({
        'user_id': uid,
        'badge_id': badgeId,
        'earned_at': now.toIso8601String(),
        'is_new': true,
        'is_featured': false,
      });

      // Pridej XP pokud ma
      if (badge.xpReward > 0) {
        await _addXpForBadge(uid, badge.xpReward, badge.name);
      }

      return UserBadge(
        oderId: uid,
        oderId2: uid,
        badgeId: badgeId,
        badge: badge,
        earnedAt: now,
        isNew: true,
        isFeatured: false,
      );
    } catch (e) {
      debugPrint('Error awarding badge: $e');
      return null;
    }
  }

  /// Pomocna metoda pro pridani XP
  Future<void> _addXpForBadge(String oderId, int amount, String badgeName) async {
    try {
      // Ziskej aktualni XP
      final response = await _supabase
          .from('user_stats')
          .select('xp')
          .eq('user_id', oderId)
          .maybeSingle();

      final currentXp = response?['xp'] as int? ?? 0;
      final newXp = currentXp + amount;

      // Aktualizuj XP
      await _supabase.from('user_stats').upsert({
        'user_id': oderId,
        'xp': newXp,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Zaloguj transakci
      await _supabase.from('xp_transactions').insert({
        'user_id': oderId,
        'amount': amount,
        'reason': 'Badge: $badgeName',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error adding XP for badge: $e');
    }
  }

  // ============================================
  // BADGE CHECKING
  // ============================================

  /// Zkontroluje a prideli odznaky na zaklade aktivity
  Future<List<UserBadge>> checkAndAwardBadges() async {
    if (currentUserId == null) return [];

    final awarded = <UserBadge>[];

    try {
      // Ziskej statistiky uzivatele
      final stats = await _getUserStats();
      final existingBadges = await getUserBadges();
      final existingIds = existingBadges.map((b) => b.badgeId).toSet();

      // Projdi vsechny odznaky a zkontroluj podminky
      for (final badge in Badges.all) {
        if (existingIds.contains(badge.id)) continue;
        if (badge.requirement == null) continue;

        final shouldAward = _checkRequirement(badge.requirement!, stats);
        if (shouldAward) {
          final userBadge = await awardBadge(badge.id);
          if (userBadge != null) {
            awarded.add(userBadge);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking badges: $e');
    }

    return awarded;
  }

  /// Ziska statistiky uzivatele pro kontrolu odznaku
  Future<Map<String, int>> _getUserStats() async {
    if (currentUserId == null) return {};

    try {
      // XP a webs
      final statsResponse = await _supabase
          .from('user_stats')
          .select('xp, webs')
          .eq('user_id', currentUserId!)
          .maybeSingle();

      // Pocet prispevku
      final postsResponse = await _supabase
          .from('posts')
          .select('id')
          .eq('author_id', currentUserId!);

      // Pocet fotek
      final photosResponse = await _supabase
          .from('post_images')
          .select('id, posts!inner(author_id)')
          .eq('posts.author_id', currentUserId!);

      // Pocet sledujicich
      final followersResponse = await _supabase
          .from('follows')
          .select('id')
          .eq('following_id', currentUserId!);

      // Pocet karet
      final cardsResponse = await _supabase
          .from('user_cards')
          .select('id')
          .eq('user_id', currentUserId!);

      // Pocet hodnoceni
      final reviewsResponse = await _supabase
          .from('strain_reviews')
          .select('id')
          .eq('user_id', currentUserId!);

      // Dny od registrace
      final profileResponse = await _supabase
          .from('profiles')
          .select('created_at')
          .eq('id', currentUserId!)
          .maybeSingle();

      int daysSinceJoin = 0;
      if (profileResponse != null) {
        final createdAt = DateTime.parse(profileResponse['created_at'] as String);
        daysSinceJoin = DateTime.now().difference(createdAt).inDays;
      }

      return {
        'xp': statsResponse?['xp'] as int? ?? 0,
        'webs': statsResponse?['webs'] as int? ?? 0,
        'posts': postsResponse.length,
        'photos': photosResponse.length,
        'followers': followersResponse.length,
        'cards': cardsResponse.length,
        'reviews': reviewsResponse.length,
        'days': daysSinceJoin,
      };
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return {};
    }
  }

  /// Zkontroluje, zda uzivatel splnuje pozadavek
  bool _checkRequirement(BadgeRequirement requirement, Map<String, int> stats) {
    final currentValue = stats[requirement.type] ?? 0;
    return currentValue >= requirement.targetValue;
  }

  // ============================================
  // SPECIAL BADGES
  // ============================================

  /// Prideli founder odznak (pro zakladajici cleny)
  Future<UserBadge?> awardFounderBadge() async {
    return awardBadge('founder');
  }

  /// Prideli VIP odznak
  Future<UserBadge?> awardVipBadge() async {
    return awardBadge('vip');
  }

  /// Prideli moderator odznak
  Future<UserBadge?> awardModeratorBadge() async {
    return awardBadge('moderator');
  }

  /// Prideli verified odznak
  Future<UserBadge?> awardVerifiedBadge() async {
    return awardBadge('verified');
  }

  /// Zkontroluje nocni aktivitu pro Night Owl odznak
  Future<UserBadge?> checkNightOwlBadge() async {
    if (currentUserId == null) return null;

    final now = DateTime.now();
    // Mezi 00:00 a 01:00
    if (now.hour == 0 || now.hour == 23) {
      return awardBadge('night_owl');
    }
    return null;
  }

  /// Prideli sezonni odznak
  Future<UserBadge?> awardSeasonalBadge(String badgeId) async {
    final badge = Badges.getById(badgeId);
    if (badge == null || badge.category != BadgeCategory.seasonal) {
      return null;
    }
    return awardBadge(badgeId);
  }

  /// Prideli eventovy odznak
  Future<UserBadge?> awardEventBadge(String badgeId) async {
    final badge = Badges.getById(badgeId);
    if (badge == null || badge.category != BadgeCategory.event) {
      return null;
    }
    return awardBadge(badgeId);
  }

  // ============================================
  // STATISTICS
  // ============================================

  /// Ziska statistiky odznaku
  Future<({int total, int earned, Map<BadgeCategory, int> byCategory, Map<BadgeRarity, int> byRarity})> getBadgeStats() async {
    final userBadges = await getUserBadges();

    final byCategory = <BadgeCategory, int>{};
    final byRarity = <BadgeRarity, int>{};

    for (final ub in userBadges) {
      byCategory[ub.badge.category] = (byCategory[ub.badge.category] ?? 0) + 1;
      byRarity[ub.badge.rarity] = (byRarity[ub.badge.rarity] ?? 0) + 1;
    }

    // Pocet dostupnych (ne-secret) odznaku
    final availableBadges = Badges.all.where((b) => !b.isSecret).length;

    return (
      total: availableBadges,
      earned: userBadges.length,
      byCategory: byCategory,
      byRarity: byRarity,
    );
  }
}
