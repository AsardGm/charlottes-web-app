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
    _loadTheme();
    return ThemeMode.dark; // default
  }

  /// Načte uložené téma z preferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 2; // default dark
    state = ThemeMode.values[themeIndex];
  }

  /// Uloží téma do preferences
  Future<void> _saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  /// Nastaví světlé téma
  void setLight() {
    state = ThemeMode.light;
    _saveTheme(ThemeMode.light);
  }

  /// Nastaví tmavé téma
  void setDark() {
    state = ThemeMode.dark;
    _saveTheme(ThemeMode.dark);
  }

  /// Nastaví systémové téma
  void setSystem() {
    state = ThemeMode.system;
    _saveTheme(ThemeMode.system);
  }

  /// Přepne mezi světlým a tmavým
  void toggle() {
    if (state == ThemeMode.dark) {
      setLight();
    } else {
      setDark();
    }
  }

  /// Nastaví téma podle indexu
  void setByIndex(int index) {
    if (index >= 0 && index < ThemeMode.values.length) {
      state = ThemeMode.values[index];
      _saveTheme(state);
    }
  }
}

/// Helper pro zjištění, zda je aktuálně tmavé téma
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  return themeMode == ThemeMode.dark;
});
