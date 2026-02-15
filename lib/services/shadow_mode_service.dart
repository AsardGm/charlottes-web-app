import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shadow_mode_model.dart';

/// Service pro správu Shadow Mode™
///
/// Shadow Mode = offline wellness režim
/// - Žádné notifikace
/// - Žádný social pressure
/// - Jen solo wellness features
class ShadowModeService {
  static const String _cacheKey = 'shadow_mode_state';
  ShadowModeState _currentState = ShadowModeState.empty;

  /// Získej aktuální stav Shadow Mode
  Future<ShadowModeState> getState() async {
    // Pokud už máme stav v paměti, vrať ho
    if (_currentState != ShadowModeState.empty) {
      return _currentState;
    }

    // Jinak načti z cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);

      if (cached == null) {
        _currentState = ShadowModeState.empty;
        return _currentState;
      }

      final json = jsonDecode(cached) as Map<String, dynamic>;
      _currentState = ShadowModeState.fromJson(json);
      return _currentState;
    } catch (e) {
      debugPrint('Error loading Shadow Mode state: $e');
      _currentState = ShadowModeState.empty;
      return _currentState;
    }
  }

  /// Aktivuj Shadow Mode
  Future<void> activate({
    ShadowModeReason? reason,
    String? customNote,
  }) async {
    _currentState = _currentState.activate(
      reason: reason,
      customNote: customNote,
    );

    await _saveState();
  }

  /// Deaktivuj Shadow Mode
  Future<void> deactivate() async {
    _currentState = _currentState.deactivate();
    await _saveState();
  }

  /// Toggle Shadow Mode (on/off)
  Future<void> toggle({
    ShadowModeReason? reason,
    String? customNote,
  }) async {
    if (_currentState.isActive) {
      await deactivate();
    } else {
      await activate(reason: reason, customNote: customNote);
    }
  }

  /// Je Shadow Mode aktivní?
  bool get isActive => _currentState.isActive;

  /// Aktuální stav (sync getter)
  ShadowModeState get currentState => _currentState;

  /// Ulož stav do cache
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_currentState.toJson());
      await prefs.setString(_cacheKey, json);
    } catch (e) {
      debugPrint('Error saving Shadow Mode state: $e');
    }
  }

  /// Resetuj statistiky (for testing)
  Future<void> resetStats() async {
    _currentState = ShadowModeState.empty;
    await _saveState();
  }

  /// Získej doporučený čas pro aktivaci Shadow Mode
  /// (based na time of day, usage patterns, etc.)
  String getRecommendedTime() {
    final hour = DateTime.now().hour;

    if (hour >= 22 || hour < 6) {
      return 'Večer je ideální čas na odpočinek 🌙';
    } else if (hour >= 12 && hour < 14) {
      return 'Polední pauza může pomoci 🧘';
    } else if (hour >= 6 && hour < 9) {
      return 'Ranní klid nastaví mood na celý den ☀️';
    } else {
      return 'Kdykoli cítíš potřebu klidu 🕶️';
    }
  }
}
