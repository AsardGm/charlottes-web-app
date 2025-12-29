import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rank_model.dart';
import '../models/daily_quest_model.dart';
import '../models/strain_card_model.dart';

/// Service pro gamifikaci - XP, ranky, questy, karty
class GamificationService {
  final _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ============================================
  // XP SYSTEM
  // ============================================

  /// Ziska aktualni XP uzivatele
  Future<int> getUserXp([String? oderId]) async {
    final uid = oderId ?? currentUserId;
    if (uid == null) return 0;

    try {
      final response = await _supabase
          .from('user_stats')
          .select('xp')
          .eq('user_id', uid)
          .maybeSingle();

      return response?['xp'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting user XP: $e');
      return 0;
    }
  }

  /// Prida XP uzivateli
  Future<({int newXp, SpiderRank? newRank, bool levelUp})> addXp(int amount, {String? reason}) async {
    if (currentUserId == null) {
      return (newXp: 0, newRank: null, levelUp: false);
    }

    try {
      final currentXp = await getUserXp();
      final currentRank = SpiderRanks.getRankByXp(currentXp);
      final newXp = currentXp + amount;
      final newRank = SpiderRanks.getRankByXp(newXp);
      final levelUp = newRank.id != currentRank.id;

      // Aktualizuj XP v databazi
      await _supabase.from('user_stats').upsert({
        'user_id': currentUserId,
        'xp': newXp,
        'rank_id': newRank.id,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Zaloguj XP transakci
      await _supabase.from('xp_transactions').insert({
        'user_id': currentUserId,
        'amount': amount,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Pokud je level up, zaloguj
      if (levelUp) {
        await _supabase.from('rank_history').insert({
          'user_id': currentUserId,
          'old_rank': currentRank.id,
          'new_rank': newRank.id,
          'xp_at_change': newXp,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return (newXp: newXp, newRank: levelUp ? newRank : null, levelUp: levelUp);
    } catch (e) {
      debugPrint('Error adding XP: $e');
      return (newXp: 0, newRank: null, levelUp: false);
    }
  }

  /// Ziska rank uzivatele
  Future<SpiderRank> getUserRank([String? oderId]) async {
    final xp = await getUserXp(oderId);
    return SpiderRanks.getRankByXp(xp);
  }

  /// Zkontroluje, zda ma uzivatel opravneni
  Future<bool> hasPermission(String permission) async {
    final rank = await getUserRank();
    return rank.hasPermission(permission);
  }

  // ============================================
  // DAILY QUESTS
  // ============================================

  /// Ziska dnesni questy pro uzivatele
  Future<List<DailyQuest>> getTodayQuests() async {
    if (currentUserId == null) return DailyQuests.getTodayQuests();

    try {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Zkus nacist ulozene questy pro dnesek
      final response = await _supabase
          .from('user_daily_quests')
          .select()
          .eq('user_id', currentUserId!)
          .eq('date', todayStr);

      if (response.isEmpty) {
        // Vytvor nove questy pro dnesek
        final quests = DailyQuests.getTodayQuests();
        for (final quest in quests) {
          await _supabase.from('user_daily_quests').insert({
            'user_id': currentUserId,
            'date': todayStr,
            'quest_id': quest.id,
            'current_progress': 0,
            'is_completed': false,
          });
        }
        return quests;
      }

      // Mapuj ulozene questy
      return response.map((row) {
        final questId = row['quest_id'] as String;
        final baseQuest = DailyQuests.all.firstWhere(
          (q) => q.id == questId,
          orElse: () => DailyQuests.supporter,
        );
        return baseQuest.copyWith(
          currentProgress: row['current_progress'] as int? ?? 0,
          isCompleted: row['is_completed'] as bool? ?? false,
          completedAt: row['completed_at'] != null
              ? DateTime.parse(row['completed_at'] as String)
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting today quests: $e');
      return DailyQuests.getTodayQuests();
    }
  }

  /// Aktualizuje progress questu
  Future<bool> updateQuestProgress(String questId, int progress) async {
    if (currentUserId == null) return false;

    try {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Najdi quest
      final baseQuest = DailyQuests.all.firstWhere(
        (q) => q.id == questId,
        orElse: () => DailyQuests.supporter,
      );

      final isCompleted = progress >= baseQuest.targetCount;

      await _supabase
          .from('user_daily_quests')
          .update({
            'current_progress': progress,
            'is_completed': isCompleted,
            'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
          })
          .eq('user_id', currentUserId!)
          .eq('date', todayStr)
          .eq('quest_id', questId);

      // Pridej XP pokud je dokonceno
      if (isCompleted) {
        await addXp(baseQuest.xpReward, reason: 'Quest: ${baseQuest.title}');
      }

      return isCompleted;
    } catch (e) {
      debugPrint('Error updating quest progress: $e');
      return false;
    }
  }

  // ============================================
  // STRAIN CARDS
  // ============================================

  /// Ziska vsechny dostupne karty
  Future<List<StrainCard>> getAllCards() async {
    try {
      final response = await _supabase
          .from('strain_cards')
          .select()
          .order('released_at', ascending: false);

      return response.map((row) => StrainCard.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Error getting all cards: $e');
      return [];
    }
  }

  /// Ziska karty uzivatele
  Future<List<StrainCard>> getUserCards([String? oderId]) async {
    final uid = oderId ?? currentUserId;
    if (uid == null) return [];

    try {
      final response = await _supabase
          .from('user_cards')
          .select('*, strain_cards(*)')
          .eq('user_id', uid)
          .order('collected_at', ascending: false);

      return response.map((row) {
        final cardData = row['strain_cards'] as Map<String, dynamic>;
        cardData['card_number'] = row['card_number'];
        return StrainCard.fromJson(cardData);
      }).toList();
    } catch (e) {
      debugPrint('Error getting user cards: $e');
      return [];
    }
  }

  /// Prida kartu uzivateli
  Future<bool> collectCard(String cardId) async {
    if (currentUserId == null) return false;

    try {
      // Zkontroluj, zda uz kartu nema
      final existing = await _supabase
          .from('user_cards')
          .select('id')
          .eq('user_id', currentUserId!)
          .eq('card_id', cardId)
          .maybeSingle();

      if (existing != null) return false; // Uz ma

      // Ziskej info o karte pro XP
      final cardResponse = await _supabase
          .from('strain_cards')
          .select('rarity, total_cards')
          .eq('id', cardId)
          .single();

      final rarity = CardRarity.values.firstWhere(
        (r) => r.name == cardResponse['rarity'],
        orElse: () => CardRarity.common,
      );

      // Zvys pocet karet v obehu
      final totalCards = (cardResponse['total_cards'] as int? ?? 0) + 1;
      await _supabase
          .from('strain_cards')
          .update({'total_cards': totalCards})
          .eq('id', cardId);

      // Pridej kartu uzivateli
      await _supabase.from('user_cards').insert({
        'user_id': currentUserId,
        'card_id': cardId,
        'card_number': totalCards,
        'collected_at': DateTime.now().toIso8601String(),
      });

      // Pridej XP
      await addXp(rarity.xpValue, reason: 'Collected card');

      return true;
    } catch (e) {
      debugPrint('Error collecting card: $e');
      return false;
    }
  }

  /// Ziska statistiky kolekce
  Future<({int total, int collected, Map<CardRarity, int> byRarity})> getCollectionStats() async {
    if (currentUserId == null) {
      return (total: 0, collected: 0, byRarity: <CardRarity, int>{});
    }

    try {
      final allCards = await getAllCards();
      final userCards = await getUserCards();

      final byRarity = <CardRarity, int>{};
      for (final card in userCards) {
        byRarity[card.rarity] = (byRarity[card.rarity] ?? 0) + 1;
      }

      return (
        total: allCards.length,
        collected: userCards.length,
        byRarity: byRarity,
      );
    } catch (e) {
      debugPrint('Error getting collection stats: $e');
      return (total: 0, collected: 0, byRarity: <CardRarity, int>{});
    }
  }

  // ============================================
  // WEBS (VLAKNA) SYSTEM
  // ============================================

  /// Ziska pocet vlaken uzivatele
  Future<int> getUserWebs([String? oderId]) async {
    final uid = oderId ?? currentUserId;
    if (uid == null) return 0;

    try {
      final response = await _supabase
          .from('user_stats')
          .select('webs')
          .eq('user_id', uid)
          .maybeSingle();

      return response?['webs'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting user webs: $e');
      return 0;
    }
  }

  /// Prida vlakno uzivateli (od jineho uzivatele)
  Future<bool> addWeb({
    required String toUserId,
    required String contentId,
    required String contentType, // 'post', 'comment', 'photo'
  }) async {
    if (currentUserId == null || currentUserId == toUserId) return false;

    try {
      // Zkontroluj, zda uz nedal vlakno
      final existing = await _supabase
          .from('webs')
          .select('id')
          .eq('from_user_id', currentUserId!)
          .eq('to_user_id', toUserId)
          .eq('content_id', contentId)
          .eq('content_type', contentType)
          .maybeSingle();

      if (existing != null) return false; // Uz dal

      // Pridej vlakno
      await _supabase.from('webs').insert({
        'from_user_id': currentUserId,
        'to_user_id': toUserId,
        'content_id': contentId,
        'content_type': contentType,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Aktualizuj pocet vlaken prijemce
      final currentWebs = await getUserWebs(toUserId);
      await _supabase.from('user_stats').upsert({
        'user_id': toUserId,
        'webs': currentWebs + 1,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Pridej XP prijemci
      // Toto by melo byt volano s kontextem prijemce, ale pro jednoduchost...
      await _supabase.from('xp_transactions').insert({
        'user_id': toUserId,
        'amount': XpRewards.receiveLike,
        'reason': 'Received web',
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error adding web: $e');
      return false;
    }
  }

  /// Odebere vlakno
  Future<bool> removeWeb({
    required String toUserId,
    required String contentId,
    required String contentType,
  }) async {
    if (currentUserId == null) return false;

    try {
      await _supabase
          .from('webs')
          .delete()
          .eq('from_user_id', currentUserId!)
          .eq('to_user_id', toUserId)
          .eq('content_id', contentId)
          .eq('content_type', contentType);

      // Aktualizuj pocet vlaken
      final currentWebs = await getUserWebs(toUserId);
      if (currentWebs > 0) {
        await _supabase.from('user_stats').update({
          'webs': currentWebs - 1,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', toUserId);
      }

      return true;
    } catch (e) {
      debugPrint('Error removing web: $e');
      return false;
    }
  }

  /// Ziska uroven pavuciny (pro vizualizaci kolem avataru)
  Future<int> getWebLevel([String? oderId]) async {
    final webs = await getUserWebs(oderId);
    // Kazdy level = 100 vlaken
    return (webs / 100).floor().clamp(0, 10);
  }

  // ============================================
  // LEADERBOARD
  // ============================================

  /// Ziska top uzivatele podle XP
  Future<List<Map<String, dynamic>>> getXpLeaderboard({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('user_stats')
          .select('user_id, xp, rank_id, profiles!inner(username, avatar_url)')
          .order('xp', ascending: false)
          .limit(limit);

      return response.map((row) {
        final profile = row['profiles'] as Map<String, dynamic>;
        return {
          'user_id': row['user_id'],
          'xp': row['xp'],
          'rank': SpiderRanks.getRankById(row['rank_id'] as String? ?? 'egg') ?? SpiderRanks.egg,
          'username': profile['username'],
          'avatar_url': profile['avatar_url'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }

  /// Ziska pozici uzivatele v leaderboardu
  Future<int> getUserLeaderboardPosition() async {
    if (currentUserId == null) return 0;

    try {
      final userXp = await getUserXp();
      final response = await _supabase
          .from('user_stats')
          .select('user_id')
          .gt('xp', userXp);

      return response.length + 1;
    } catch (e) {
      debugPrint('Error getting leaderboard position: $e');
      return 0;
    }
  }
}
