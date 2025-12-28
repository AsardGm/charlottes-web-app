import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_settings_model.dart';

/// Služba pro správu uživatelských nastavení
///
/// Umožňuje načítat a ukládat nastavení jako téma,
/// notifikace, jazyk a další preference.
class SettingsService {
  /// Supabase klient
  final SupabaseClient _supabase = Supabase.instance.client;

  /// ID aktuálního uživatele
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Získá nastavení uživatele
  ///
  /// Pokud nastavení neexistuje, vytvoří výchozí.
  Future<UserSettingsModel?> getSettings() async {
    if (currentUserId == null) return null;

    final response = await _supabase
        .from('user_settings')
        .select()
        .eq('user_id', currentUserId!)
        .maybeSingle();

    if (response == null) {
      // Vytvoř výchozí nastavení
      return await _createDefaultSettings();
    }

    return UserSettingsModel.fromJson(response);
  }

  /// Vytvoří výchozí nastavení pro uživatele
  Future<UserSettingsModel> _createDefaultSettings() async {
    final defaultSettings = {
      'user_id': currentUserId,
      'theme': 'dark',
      'notifications_enabled': true,
      'email_notifications': false,
      'show_online_status': true,
      'allow_messages_from': 'everyone',
      'language': 'cs',
    };

    final response = await _supabase
        .from('user_settings')
        .insert(defaultSettings)
        .select()
        .single();

    return UserSettingsModel.fromJson(response);
  }

  /// Aktualizuje nastavení
  Future<UserSettingsModel> updateSettings(Map<String, dynamic> updates) async {
    if (currentUserId == null) {
      throw Exception('Uživatel není přihlášen');
    }

    updates['updated_at'] = DateTime.now().toIso8601String();

    final response = await _supabase
        .from('user_settings')
        .update(updates)
        .eq('user_id', currentUserId!)
        .select()
        .single();

    return UserSettingsModel.fromJson(response);
  }

  /// Změní téma (light/dark)
  Future<UserSettingsModel> setTheme(String theme) async {
    return updateSettings({'theme': theme});
  }

  /// Zapne/vypne notifikace
  Future<UserSettingsModel> setNotificationsEnabled(bool enabled) async {
    return updateSettings({'notifications_enabled': enabled});
  }

  /// Nastaví kdo může posílat zprávy
  ///
  /// Hodnoty: 'everyone', 'followers', 'nobody'
  Future<UserSettingsModel> setAllowMessagesFrom(String value) async {
    return updateSettings({'allow_messages_from': value});
  }

  /// Nastaví viditelnost online statusu
  Future<UserSettingsModel> setShowOnlineStatus(bool visible) async {
    return updateSettings({'show_online_status': visible});
  }

  /// Změní jazyk aplikace
  Future<UserSettingsModel> setLanguage(String language) async {
    return updateSettings({'language': language});
  }
}
