import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for saving QUANTUM cognitive test results to Supabase
class QuantumTestService {
  final _supabase = Supabase.instance.client;

  /// Save Reaction Time Test results
  Future<void> saveReactionTest({
    required String userId,
    required List<int> reactionTimes,
    required double averageMs,
    required int bestMs,
    required int worstMs,
    required double score,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'quantum_reaction': {
          'reaction_times_ms': reactionTimes,
          'average_ms': averageMs.toInt(),
          'best_ms': bestMs,
          'worst_ms': worstMs,
          'score': score.toInt(),
        },
        // Dummy data for required fields (will be null for QUANTUM-only tests)
        'memory_flash': {'score': 0},
        'pattern_recognition': {'score': 0},
        'total_score': score.toInt(),
        'status': _getStatusFromScore(score.toInt()),
      };

      await _supabase.from('cognitive_test_results').insert(data);
    } catch (e) {
      throw Exception('Failed to save reaction test: $e');
    }
  }

  /// Save Memory Sequence Test results
  Future<void> saveMemoryTest({
    required String userId,
    required int maxLevel,
    required int correctRounds,
    required int sequenceLength,
    required double score,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'quantum_memory': {
          'max_level': maxLevel,
          'correct_rounds': correctRounds,
          'sequence_length': sequenceLength,
          'score': score.toInt(),
        },
        // Dummy data for required fields
        'reaction_time': {'average_ms': 0},
        'pattern_recognition': {'score': 0},
        'total_score': score.toInt(),
        'status': _getStatusFromScore(score.toInt()),
      };

      await _supabase.from('cognitive_test_results').insert(data);
    } catch (e) {
      throw Exception('Failed to save memory test: $e');
    }
  }

  /// Save Sustained Focus Test results
  Future<void> saveFocusTest({
    required String userId,
    required int targetsShown,
    required int targetsHit,
    required int falsePositives,
    required double accuracy,
    required double score,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'quantum_focus': {
          'targets_shown': targetsShown,
          'targets_hit': targetsHit,
          'false_positives': falsePositives,
          'accuracy': accuracy,
          'score': score.toInt(),
        },
        // Dummy data for required fields
        'reaction_time': {'average_ms': 0},
        'memory_flash': {'score': 0},
        'total_score': score.toInt(),
        'status': _getStatusFromScore(score.toInt()),
      };

      await _supabase.from('cognitive_test_results').insert(data);
    } catch (e) {
      throw Exception('Failed to save focus test: $e');
    }
  }

  /// Determine cognitive status from score
  String _getStatusFromScore(int score) {
    if (score >= 90) return 'sharp';
    if (score >= 70) return 'normal';
    if (score >= 50) return 'tired';
    if (score >= 30) return 'blurry';
    return 'overloaded';
  }

  /// Get user's QUANTUM test history
  Future<List<Map<String, dynamic>>> getTestHistory(String userId) async {
    try {
      final response = await _supabase
          .from('cognitive_test_results')
          .select()
          .eq('user_id', userId)
          .or('quantum_reaction.neq.null,quantum_memory.neq.null,quantum_focus.neq.null')
          .order('timestamp', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to get test history: $e');
    }
  }

  /// Get test stats for user
  Future<Map<String, dynamic>> getTestStats(String userId) async {
    try {
      final tests = await getTestHistory(userId);

      if (tests.isEmpty) {
        return {
          'total_tests': 0,
          'reaction_avg': null,
          'memory_max': null,
          'focus_accuracy': null,
        };
      }

      // Calculate stats
      final reactionTests = tests.where((t) => t['quantum_reaction'] != null).toList();
      final memoryTests = tests.where((t) => t['quantum_memory'] != null).toList();
      final focusTests = tests.where((t) => t['quantum_focus'] != null).toList();

      double? reactionAvg;
      if (reactionTests.isNotEmpty) {
        final avgMs = reactionTests.map((t) => t['quantum_reaction']['average_ms'] as int).toList();
        reactionAvg = avgMs.reduce((a, b) => a + b) / avgMs.length;
      }

      int? memoryMax;
      if (memoryTests.isNotEmpty) {
        memoryMax = memoryTests
            .map((t) => t['quantum_memory']['max_level'] as int)
            .reduce((a, b) => a > b ? a : b);
      }

      double? focusAccuracy;
      if (focusTests.isNotEmpty) {
        final accuracies = focusTests.map((t) => t['quantum_focus']['accuracy'] as double).toList();
        focusAccuracy = accuracies.reduce((a, b) => a + b) / accuracies.length;
      }

      return {
        'total_tests': tests.length,
        'reaction_avg': reactionAvg,
        'memory_max': memoryMax,
        'focus_accuracy': focusAccuracy,
      };
    } catch (e) {
      throw Exception('Failed to get test stats: $e');
    }
  }
}
