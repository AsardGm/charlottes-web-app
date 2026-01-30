import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_preferences_model.dart';
import '../services/personalization_service.dart';

/// Provider pro PersonalizationService
final personalizationServiceProvider = Provider<PersonalizationService>((ref) {
  return PersonalizationService(Supabase.instance.client);
});

/// Provider pro user preferences
final userPreferencesProvider =
    FutureProvider<UserPreferences>((ref) async {
  final service = ref.watch(personalizationServiceProvider);
  return await service.getUserPreferences();
});

/// Provider pro quick actions (personalizované)
final quickActionsProvider = FutureProvider<List<QuickAction>>((ref) async {
  final service = ref.watch(personalizationServiceProvider);
  final prefs = await ref.watch(userPreferencesProvider.future);
  return service.getPersonalizedQuickActions(prefs);
});

/// Provider pro featured categories
final featuredCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(personalizationServiceProvider);
  final prefs = await ref.watch(userPreferencesProvider.future);
  return service.getFeaturedContentCategories(prefs);
});
