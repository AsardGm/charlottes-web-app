import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge_model.dart';

/// Service for challenges and achievements
class ChallengeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== CHALLENGES ====================

  /// Get all available challenges
  Future<List<Challenge>> getChallenges({String? category}) async {
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
  }

  /// Get user's active challenges
  Future<List<UserChallenge>> getUserChallenges(String userId) async {
    final response = await _supabase
        .from('user_challenges')
        .select('*, challenges(*)')
        .eq('user_id', userId)
        .order('started_at', ascending: false);

    return (response as List)
        .map((json) => UserChallenge.fromJson(json))
        .toList();
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

    return UserChallenge.fromJson(response);
  }

  /// Complete challenge
  Future<void> completeChallenge(String userChallengeId) async {
    await _supabase.rpc('complete_challenge', params: {
      'p_user_challenge_id': userChallengeId,
    });
  }

  // ==================== ACHIEVEMENTS ====================

  /// Get all achievements
  Future<List<Achievement>> getAchievements({String? category}) async {
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
  }

  /// Get user's unlocked achievements
  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    final response = await _supabase
        .from('user_achievements')
        .select('*, achievements(*)')
        .eq('user_id', userId)
        .order('unlocked_at', ascending: false);

    return (response as List)
        .map((json) => UserAchievement.fromJson(json))
        .toList();
  }

  // ==================== STATS ====================

  /// Get user gamification stats
  Future<GamificationStats> getUserStats(String userId) async {
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
  }
}
