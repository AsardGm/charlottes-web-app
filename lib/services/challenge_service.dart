import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge_model.dart';
import 'notification_handler_service.dart';
import 'cache_service.dart';

/// Service for challenges and achievements
class ChallengeService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CacheService _cache = CacheService();
  NotificationHandlerService? _notificationHandler;

  // ==================== CHALLENGES ====================

  /// Get all available challenges
  Future<List<Challenge>> getChallenges({
    String? category,
    bool forceRefresh = false,
  }) async {
    final cacheKey = category != null
        ? '${CacheKeys.challenges}_$category'
        : CacheKeys.challenges;

    return await _cache.getOrFetch(
      cacheKey,
      () async {
        var query = _supabase
            .from('challenges')
            .select()
            .eq('is_active', true);

        if (category != null) {
          query = query.eq('category', category);
        }

        final response = await query.order('difficulty', ascending: true);

        return (response as List)
            .map((json) => Challenge.fromJson(json))
            .toList();
      },
      expiry: const Duration(minutes: 10),
      forceRefresh: forceRefresh,
    );
  }

  /// Get user's active challenges
  Future<List<UserChallenge>> getUserChallenges(
    String userId, {
    bool forceRefresh = false,
  }) async {
    return await _cache.getOrFetch(
      CacheKeys.userChallenges(userId),
      () async {
        final response = await _supabase
            .from('user_challenges')
            .select('*, challenges(*)')
            .eq('user_id', userId)
            .order('started_at', ascending: false);

        return (response as List)
            .map((json) => UserChallenge.fromJson(json))
            .toList();
      },
      expiry: const Duration(minutes: 3),
      forceRefresh: forceRefresh,
    );
  }

  /// Start a challenge
  Future<UserChallenge> startChallenge(
    String userId,
    String challengeId,
  ) async {
    final challenge = await _supabase
        .from('challenges')
        .select()
        .eq('id', challengeId)
        .single();

    final response = await _supabase
        .from('user_challenges')
        .insert({
          'user_id': userId,
          'challenge_id': challengeId,
          'target_progress': challenge['target_value'],
          'status': 'in_progress',
        })
        .select('*, challenges(*)')
        .single();

    // Invalidate user challenges cache
    _cache.clear(CacheKeys.userChallenges(userId));

    return UserChallenge.fromJson(response);
  }

  /// Complete challenge
  Future<void> completeChallenge(
    String userChallengeId, {
    String? userId,
  }) async {
    await _supabase.rpc('complete_challenge', params: {
      'p_user_challenge_id': userChallengeId,
    });

    // Invalidate caches if userId provided
    if (userId != null) {
      _cache.clear(CacheKeys.userChallenges(userId));
      _cache.clear(CacheKeys.userStats(userId));
      _cache.clear(CacheKeys.userAchievements(userId));
    }
  }

  /// Update challenge progress for a category
  /// Automatically increments progress for active challenges in the given category
  Future<void> updateChallengeProgress(
    String userId,
    String category, {
    int increment = 1,
  }) async {
    try {
      // Get user's active challenges in this category
      final userChallenges = await _supabase
          .from('user_challenges')
          .select('*, challenges(*)')
          .eq('user_id', userId)
          .eq('status', 'in_progress')
          .eq('challenges.category', category);

      bool hasUpdates = false;

      for (final challengeData in userChallenges) {
        final userChallengeId = challengeData['id'] as String;
        final currentProgress = challengeData['current_progress'] as int? ?? 0;
        final targetProgress = challengeData['target_progress'] as int;

        // Increment progress
        final newProgress = currentProgress + increment;

        // Update progress
        await _supabase.from('user_challenges').update({
          'current_progress': newProgress,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userChallengeId);

        hasUpdates = true;

        // If completed, call complete function
        if (newProgress >= targetProgress &&
            challengeData['status'] == 'in_progress') {
          await completeChallenge(userChallengeId, userId: userId);
        }
      }

      // Invalidate caches if any updates were made
      if (hasUpdates) {
        _cache.clear(CacheKeys.userChallenges(userId));
      }
    } catch (e) {
      // Silent fail - progress update is not critical
      debugPrint('Error updating challenge progress: $e');
    }
  }

  /// Increment streak-based challenges (for daily check-ins)
  Future<void> updateStreakProgress(
    String userId,
    String category,
    int currentStreak,
  ) async {
    try {
      // Get user's active streak-based challenges in this category
      final userChallenges = await _supabase
          .from('user_challenges')
          .select('*, challenges(*)')
          .eq('user_id', userId)
          .eq('status', 'in_progress')
          .eq('challenges.category', category)
          .eq('challenges.target_type', 'streak');

      bool hasUpdates = false;

      for (final challengeData in userChallenges) {
        final userChallengeId = challengeData['id'] as String;
        final targetProgress = challengeData['target_progress'] as int;

        // Update streak (not increment, but set to current streak)
        await _supabase.from('user_challenges').update({
          'current_progress': currentStreak,
          'current_streak': currentStreak,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userChallengeId);

        hasUpdates = true;

        // If completed
        if (currentStreak >= targetProgress &&
            challengeData['status'] == 'in_progress') {
          await completeChallenge(userChallengeId, userId: userId);
        }
      }

      // Invalidate caches if any updates were made
      if (hasUpdates) {
        _cache.clear(CacheKeys.userChallenges(userId));
      }
    } catch (e) {
      debugPrint('Error updating streak progress: $e');
    }
  }

  // ==================== ACHIEVEMENTS ====================

  /// Get all achievements
  Future<List<Achievement>> getAchievements({
    String? category,
    bool forceRefresh = false,
  }) async {
    final cacheKey = category != null
        ? '${CacheKeys.achievements}_$category'
        : CacheKeys.achievements;

    return await _cache.getOrFetch(
      cacheKey,
      () async {
        var query = _supabase
            .from('achievements')
            .select()
            .eq('is_active', true);

        if (category != null) {
          query = query.eq('category', category);
        }

        final response = await query.order('rarity', ascending: false);

        return (response as List)
            .map((json) => Achievement.fromJson(json))
            .toList();
      },
      expiry: const Duration(minutes: 15),
      forceRefresh: forceRefresh,
    );
  }

  /// Get user's unlocked achievements
  Future<List<UserAchievement>> getUserAchievements(
    String userId, {
    bool forceRefresh = false,
  }) async {
    return await _cache.getOrFetch(
      CacheKeys.userAchievements(userId),
      () async {
        final response = await _supabase
            .from('user_achievements')
            .select('*, achievements(*)')
            .eq('user_id', userId)
            .order('unlocked_at', ascending: false);

        return (response as List)
            .map((json) => UserAchievement.fromJson(json))
            .toList();
      },
      expiry: const Duration(minutes: 5),
      forceRefresh: forceRefresh,
    );
  }

  // ==================== STATS ====================

  /// Get user gamification stats
  Future<GamificationStats> getUserStats(
    String userId, {
    bool forceRefresh = false,
  }) async {
    return await _cache.getOrFetch(
      CacheKeys.userStats(userId),
      () async {
        final response = await _supabase
            .from('user_gamification_stats')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (response == null) {
          // Create initial stats
          final created = await _supabase
              .from('user_gamification_stats')
              .insert({'user_id': userId})
              .select()
              .single();

          return GamificationStats.fromJson(created);
        }

        return GamificationStats.fromJson(response);
      },
      expiry: const Duration(minutes: 2),
      forceRefresh: forceRefresh,
    );
  }
}
