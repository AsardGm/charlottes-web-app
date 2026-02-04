import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/strain_journal_model.dart';
import 'challenge_service.dart';

/// Service for managing strain journal entries with AI analysis
class StrainJournalService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ChallengeService _challengeService = ChallengeService();

  // ==================== JOURNAL ENTRIES ====================

  /// Get all journal entries for user
  Future<List<StrainJournalEntry>> getJournalEntries(
    String userId, {
    String? strainId,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _supabase
        .from('strain_journal_entries')
        .select('*, strains(name)')
        .eq('user_id', userId);

    if (strainId != null) {
      query = query.eq('strain_id', strainId);
    }

    final response = await query
        .order('consumed_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((json) {
      final map = Map<String, dynamic>.from(json);
      if (json['strains'] != null) {
        map['strain_name'] = json['strains']['name'];
      }
      return StrainJournalEntry.fromJson(map);
    }).toList();
  }

  /// Get single journal entry
  Future<StrainJournalEntry?> getJournalEntry(String entryId) async {
    try {
      final response = await _supabase
          .from('strain_journal_entries')
          .select('*, strains(name)')
          .eq('id', entryId)
          .maybeSingle();

      if (response == null) return null;

      final map = Map<String, dynamic>.from(response);
      if (response['strains'] != null) {
        map['strain_name'] = response['strains']['name'];
      }
      return StrainJournalEntry.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  /// Get favorite entries
  Future<List<StrainJournalEntry>> getFavoriteEntries(String userId) async {
    final response = await _supabase
        .from('strain_journal_entries')
        .select('*, strains(name)')
        .eq('user_id', userId)
        .eq('is_favorite', true)
        .order('consumed_at', ascending: false)
        .limit(20);

    return (response as List).map((json) {
      final map = Map<String, dynamic>.from(json);
      if (json['strains'] != null) {
        map['strain_name'] = json['strains']['name'];
      }
      return StrainJournalEntry.fromJson(map);
    }).toList();
  }

  /// Create journal entry
  Future<StrainJournalEntry> createJournalEntry({
    required String userId,
    required String strainId,
    required DateTime consumedAt,
    String? method,
    double? amount,
    String? amountUnit,
    List<String>? setting,
    List<String>? activities,
    int? moodBefore,
    String? intention,
    PhysicalEffects? physicalEffects,
    MentalEffects? mentalEffects,
    EmotionalEffects? emotionalEffects,
    int? onsetTime,
    int? peakTime,
    int? totalDuration,
    double? overallRating,
    bool? wouldUseAgain,
    String? title,
    String? notes,
    List<String>? highlights,
    List<String>? drawbacks,
    List<String>? tags,
    bool? isFavorite,
  }) async {
    final entry = {
      'user_id': userId,
      'strain_id': strainId,
      'consumed_at': consumedAt.toIso8601String(),
      'method': method,
      'amount': amount,
      'amount_unit': amountUnit,
      'setting': setting,
      'activities': activities,
      'mood_before': moodBefore,
      'intention': intention,
      ...?physicalEffects?.toJson(),
      ...?mentalEffects?.toJson(),
      ...?emotionalEffects?.toJson(),
      'onset_time': onsetTime,
      'peak_time': peakTime,
      'total_duration': totalDuration,
      'overall_rating': overallRating,
      'would_use_again': wouldUseAgain,
      'title': title,
      'notes': notes,
      'highlights': highlights,
      'drawbacks': drawbacks,
      'tags': tags,
      'is_favorite': isFavorite ?? false,
    };

    final response = await _supabase
        .from('strain_journal_entries')
        .insert(entry)
        .select('*, strains(name)')
        .single();

    final map = Map<String, dynamic>.from(response);
    if (response['strains'] != null) {
      map['strain_name'] = response['strains']['name'];
    }

    final created = StrainJournalEntry.fromJson(map);

    // Trigger AI analysis asynchronously
    _analyzeEntry(created.id);

    // Update challenge progress for journal category
    _challengeService.updateChallengeProgress(userId, 'journal');

    return created;
  }

  /// Update journal entry
  Future<StrainJournalEntry> updateJournalEntry(
    String entryId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _supabase
        .from('strain_journal_entries')
        .update(updates)
        .eq('id', entryId)
        .select('*, strains(name)')
        .single();

    final map = Map<String, dynamic>.from(response);
    if (response['strains'] != null) {
      map['strain_name'] = response['strains']['name'];
    }

    return StrainJournalEntry.fromJson(map);
  }

  /// Delete journal entry
  Future<void> deleteJournalEntry(String entryId) async {
    await _supabase.from('strain_journal_entries').delete().eq('id', entryId);
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String entryId, bool isFavorite) async {
    await _supabase
        .from('strain_journal_entries')
        .update({'is_favorite': isFavorite}).eq('id', entryId);
  }

  // ==================== AI ANALYSIS ====================

  /// Analyze journal entry with Charlotte AI
  Future<void> _analyzeEntry(String entryId) async {
    try {
      final entry = await getJournalEntry(entryId);
      if (entry == null) return;

      final analysis = await _generateAIAnalysis(entry);

      await _supabase.from('strain_journal_entries').update({
        'ai_summary': analysis['summary'],
        'ai_recommendations': analysis['recommendations'],
        'ai_analyzed_at': DateTime.now().toIso8601String(),
      }).eq('id', entryId);
    } catch (e) {
      // Silent fail - AI analysis is optional
    }
  }

  /// Generate AI analysis (Charlotte AI simulation)
  Future<Map<String, dynamic>> _generateAIAnalysis(
    StrainJournalEntry entry,
  ) async {
    final recommendations = <Map<String, dynamic>>[];

    // Analyze effects and generate recommendations
    if (entry.physicalEffects.sleepiness != null &&
        entry.physicalEffects.sleepiness! >= 7) {
      recommendations.add({
        'type': 'timing',
        'message': 'Tato odrůda způsobuje silnou únavu - zvažte použití večer před spaním',
      });
    }

    if (entry.mentalEffects.focus != null &&
        entry.mentalEffects.focus! >= 7) {
      recommendations.add({
        'type': 'activity',
        'message':
            'Vysoké skóre focus - ideální pro produktivní práci nebo studium',
      });
    }

    if (entry.mentalEffects.creativity != null &&
        entry.mentalEffects.creativity! >= 7) {
      recommendations.add({
        'type': 'activity',
        'message': 'Silný boost kreativity - perfektní pro tvůrčí projekty',
      });
    }

    if (entry.emotionalEffects.anxietyRelief != null &&
        entry.emotionalEffects.anxietyRelief! >= 7) {
      recommendations.add({
        'type': 'wellbeing',
        'message': 'Výborná úleva od anxiety - vhodné pro stresové situace',
      });
    }

    if (entry.mentalEffects.paranoia != null &&
        entry.mentalEffects.paranoia! >= 5) {
      recommendations.add({
        'type': 'caution',
        'message':
            'Zaznamenána paranoia - zkuste nižší dávku nebo jinou odrůdu',
      });
    }

    // Generate summary
    final effectsList = <String>[];

    if (entry.physicalEffects.bodyHigh != null &&
        entry.physicalEffects.bodyHigh! >= 6) {
      effectsList.add('silný tělesný efekt');
    }
    if (entry.mentalEffects.headHigh != null &&
        entry.mentalEffects.headHigh! >= 6) {
      effectsList.add('výrazný psychoaktivní efekt');
    }
    if (entry.emotionalEffects.happiness != null &&
        entry.emotionalEffects.happiness! >= 7) {
      effectsList.add('silné pozitivní emoce');
    }

    String summary = 'Tato session ';
    if (effectsList.isNotEmpty) {
      summary += 'vykazovala ${effectsList.join(", ")}. ';
    } else {
      summary += 'byla mírná. ';
    }

    if (entry.overallRating != null) {
      if (entry.overallRating! >= 4.0) {
        summary += 'Celkově velmi pozitivní zkušenost.';
      } else if (entry.overallRating! >= 3.0) {
        summary += 'Průměrná zkušenost.';
      } else {
        summary += 'Méně příjemná zkušenost.';
      }
    }

    return {
      'summary': summary,
      'recommendations': recommendations,
    };
  }

  /// Re-analyze all entries for a user (for testing/updates)
  Future<void> reanalyzeAllEntries(String userId) async {
    final entries = await getJournalEntries(userId, limit: 100);

    for (final entry in entries) {
      await _analyzeEntry(entry.id);
      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // ==================== STATISTICS ====================

  /// Get journal statistics for user
  Future<Map<String, dynamic>> getJournalStats(String userId) async {
    final entries = await getJournalEntries(userId, limit: 1000);

    if (entries.isEmpty) {
      return {
        'total_entries': 0,
        'unique_strains': 0,
        'avg_rating': 0.0,
        'favorite_count': 0,
      };
    }

    final uniqueStrains = entries.map((e) => e.strainId).toSet().length;
    final ratingsOnly = entries
        .where((e) => e.overallRating != null)
        .map((e) => e.overallRating!)
        .toList();
    final avgRating = ratingsOnly.isEmpty
        ? 0.0
        : ratingsOnly.reduce((a, b) => a + b) / ratingsOnly.length;
    final favoriteCount = entries.where((e) => e.isFavorite).length;

    return {
      'total_entries': entries.length,
      'unique_strains': uniqueStrains,
      'avg_rating': avgRating,
      'favorite_count': favoriteCount,
      'entries_with_ai': entries.where((e) => e.hasAIAnalysis).length,
      'complete_entries': entries.where((e) => e.isComplete).length,
    };
  }

  /// Get most used methods
  Future<Map<String, int>> getMostUsedMethods(String userId) async {
    final entries = await getJournalEntries(userId, limit: 1000);

    final methodCounts = <String, int>{};
    for (final entry in entries) {
      if (entry.method != null) {
        methodCounts[entry.method!] = (methodCounts[entry.method!] ?? 0) + 1;
      }
    }

    // Sort by count descending
    final sorted = methodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted);
  }

  // ==================== QUICK RATINGS ====================

  /// Add quick rating
  Future<StrainQuickRating> addQuickRating({
    required String userId,
    required String strainId,
    required double rating,
    String? quickNotes,
  }) async {
    final response = await _supabase
        .from('strain_quick_ratings')
        .insert({
          'user_id': userId,
          'strain_id': strainId,
          'rating': rating,
          'quick_notes': quickNotes,
        })
        .select()
        .single();

    return StrainQuickRating.fromJson(response);
  }

  /// Get quick ratings for strain
  Future<List<StrainQuickRating>> getQuickRatings(String strainId) async {
    final response = await _supabase
        .from('strain_quick_ratings')
        .select()
        .eq('strain_id', strainId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => StrainQuickRating.fromJson(json))
        .toList();
  }

  // ==================== SEARCH & FILTER ====================

  /// Search journal entries by text
  Future<List<StrainJournalEntry>> searchJournalEntries(
    String userId,
    String query,
  ) async {
    final response = await _supabase
        .from('strain_journal_entries')
        .select('*, strains(name)')
        .eq('user_id', userId)
        .or('title.ilike.%$query%,notes.ilike.%$query%')
        .order('consumed_at', ascending: false)
        .limit(50);

    return (response as List).map((json) {
      final map = Map<String, dynamic>.from(json);
      if (json['strains'] != null) {
        map['strain_name'] = json['strains']['name'];
      }
      return StrainJournalEntry.fromJson(map);
    }).toList();
  }

  /// Get entries by tag
  Future<List<StrainJournalEntry>> getEntriesByTag(
    String userId,
    String tag,
  ) async {
    final response = await _supabase
        .from('strain_journal_entries')
        .select('*, strains(name)')
        .eq('user_id', userId)
        .contains('tags', [tag])
        .order('consumed_at', ascending: false)
        .limit(50);

    return (response as List).map((json) {
      final map = Map<String, dynamic>.from(json);
      if (json['strains'] != null) {
        map['strain_name'] = json['strains']['name'];
      }
      return StrainJournalEntry.fromJson(map);
    }).toList();
  }

  /// Get all user tags (for autocomplete)
  Future<List<String>> getUserTags(String userId) async {
    final entries = await getJournalEntries(userId, limit: 500);

    final allTags = <String>{};
    for (final entry in entries) {
      allTags.addAll(entry.tags);
    }

    return allTags.toList()..sort();
  }
}
