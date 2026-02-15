import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider pro správu tématu aplikace
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Notifier pro změnu tématu
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _themeKey = 'theme_mode';

  @override
  ThemeMode build() {
    // Načteme téma asynchronně a nastavíme state
    _loadTheme();
    // Mezitím vrátíme dark jako default
    return ThemeMode.dark;
  }

  /// Načte uložené téma z preferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 2; // default dark (index 2)
      if (themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
        state = ThemeMode.values[themeIndex];
      }
    } catch (e) {
      // Pokud selže načítání, ponecháme default dark
      state = ThemeMode.dark;
    }
  }

  /// Uloží téma do preferences
  Future<void> _saveTheme(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      // Ignorujeme chyby při ukládání
    }
  }

  /// Nastaví světlé téma
  Future<void> setLight() async {
    state = ThemeMode.light;
    await _saveTheme(ThemeMode.light);
  }

  /// Nastaví tmavé téma
  Future<void> setDark() async {
    state = ThemeMode.dark;
    await _saveTheme(ThemeMode.dark);
  }

  /// Nastaví systémové téma
  Future<void> setSystem() async {
    state = ThemeMode.system;
    await _saveTheme(ThemeMode.system);
  }

  /// Přepne mezi světlým a tmavým
  Future<void> toggle() async {
    if (state == ThemeMode.dark) {
      await setLight();
    } else {
      await setDark();
    }
  }

  /// Nastaví téma podle indexu
  Future<void> setByIndex(int index) async {
    if (index >= 0 && index < ThemeMode.values.length) {
      state = ThemeMode.values[index];
      await _saveTheme(state);
    }
  }
}

/// Helper pro zjištění, zda je aktuálně tmavé téma
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  return themeMode == ThemeMode.dark;
});
