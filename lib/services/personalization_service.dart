import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_preferences_model.dart';

/// Service pro správu uživatelských preferences a personalizaci
class PersonalizationService {
  final SupabaseClient _supabase;
  static const String _cacheKey = 'user_preferences_cache';

  PersonalizationService(this._supabase);

  /// Načti preferences pro aktuálního uživatele
  Future<UserPreferences> getUserPreferences() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return UserPreferences.empty;
    }

    try {
      // Zkus načíst z cache nejdřív (rychlejší)
      final cached = await _loadFromCache();
      if (cached != null) {
        return cached;
      }

      // Načti z Supabase
      final response = await _supabase
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return UserPreferences.empty;
      }

      final preferences = UserPreferences.fromJson(response);

      // Ulož do cache
      await _saveToCache(preferences);

      return preferences;
    } catch (e) {
      print('Error loading user preferences: $e');
      // Zkus cache jako fallback
      final cached = await _loadFromCache();
      return cached ?? UserPreferences.empty;
    }
  }

  /// Ulož preferences pro aktuálního uživatele
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final data = {
        'user_id': userId,
        ...preferences.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Upsert do Supabase (insert or update)
      await _supabase.from('user_preferences').upsert(data);

      // Ulož do cache
      await _saveToCache(preferences);
    } catch (e) {
      print('Error saving user preferences: $e');
      // I když selže Supabase, ulož alespoň do cache
      await _saveToCache(preferences);
      rethrow;
    }
  }

  /// Updatuj částečně preferences (merge s existujícími)
  Future<void> updateUserPreferences({
    UserRole? role,
    ExperienceLevel? experienceLevel,
    List<UserInterest>? interests,
    List<UserGoal>? goals,
    bool? onboardingCompleted,
  }) async {
    final current = await getUserPreferences();

    final updated = current.copyWith(
      role: role,
      experienceLevel: experienceLevel,
      interests: interests,
      goals: goals,
      onboardingCompleted: onboardingCompleted,
      completedAt:
          onboardingCompleted == true ? DateTime.now() : current.completedAt,
    );

    await saveUserPreferences(updated);
  }

  /// Kompletuj onboarding (nastaví vše najednou)
  Future<void> completeOnboarding({
    required UserRole role,
    required ExperienceLevel experienceLevel,
    required List<UserInterest> interests,
    required List<UserGoal> goals,
  }) async {
    final preferences = UserPreferences(
      role: role,
      experienceLevel: experienceLevel,
      interests: interests,
      goals: goals,
      onboardingCompleted: true,
      completedAt: DateTime.now(),
    );

    await saveUserPreferences(preferences);
  }

  /// Resetuj preferences (pro testing nebo re-onboarding)
  Future<void> resetPreferences() async {
    await saveUserPreferences(UserPreferences.empty);
    await _clearCache();
  }

  /// --- Cache helpers ---

  Future<UserPreferences?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);

      if (cached == null) return null;

      final json = jsonDecode(cached) as Map<String, dynamic>;
      return UserPreferences.fromJson(json);
    } catch (e) {
      print('Error loading preferences from cache: $e');
      return null;
    }
  }

  Future<void> _saveToCache(UserPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(preferences.toJson());
      await prefs.setString(_cacheKey, json);
    } catch (e) {
      print('Error saving preferences to cache: $e');
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      print('Error clearing preferences cache: $e');
    }
  }

  /// Generuj personalizované quick actions based na preferences
  List<QuickAction> getPersonalizedQuickActions(UserPreferences prefs) {
    final actions = <QuickAction>[];

    // Based na role a goals
    if (prefs.isInterestedInTracking) {
      actions.add(QuickAction(
        title: 'Log Consumption',
        icon: '💨',
        route: '/log-consumption',
      ));
    }

    if (prefs.isInterestedInGrowing) {
      actions.add(QuickAction(
        title: 'My Grows',
        icon: '🌱',
        route: '/lab/chronos',
      ));
    }

    if (prefs.goals.contains(UserGoal.monitorHealth)) {
      actions.add(QuickAction(
        title: 'Cognitive Test',
        icon: '🧠',
        route: '/cognitive-test',
      ));
    }

    if (prefs.isInterestedInCommunity) {
      actions.add(QuickAction(
        title: 'Community',
        icon: '👥',
        route: '/feed',
      ));
    }

    if (prefs.isInterestedInEducation) {
      actions.add(QuickAction(
        title: 'Learn',
        icon: '📚',
        route: '/wiki',
      ));
    }

    if (prefs.interests.contains(UserInterest.terpenes)) {
      actions.add(QuickAction(
        title: 'Terpenes',
        icon: '🌿',
        route: '/wiki/terpenes',
      ));
    }

    return actions.take(6).toList(); // Max 6 quick actions
  }

  /// Featured content based na preferences
  List<String> getFeaturedContentCategories(UserPreferences prefs) {
    final categories = <String>[];

    if (prefs.interests.contains(UserInterest.genetics)) {
      categories.add('genetics');
    }

    if (prefs.interests.contains(UserInterest.terpenes)) {
      categories.add('terpenes');
    }

    if (prefs.interests.contains(UserInterest.growing)) {
      categories.add('growing');
    }

    if (prefs.interests.contains(UserInterest.healthWellness)) {
      categories.add('health');
    }

    if (prefs.interests.contains(UserInterest.education)) {
      categories.add('education');
    }

    return categories;
  }
}

/// Quick action model
class QuickAction {
  final String title;
  final String icon;
  final String route;

  QuickAction({
    required this.title,
    required this.icon,
    required this.route,
  });
}
