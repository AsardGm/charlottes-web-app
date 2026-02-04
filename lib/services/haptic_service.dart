import 'package:flutter/services.dart';

/// Haptic feedback service for enhanced user experience
class HapticService {
  /// Light impact - for selections, taps
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact - for confirmations, state changes
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for important actions, completions
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection feedback - for picker/slider changes
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Success pattern - celebration for achievements
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// Error pattern - for failures
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.heavyImpact();
  }

  /// Level up pattern - for XP gains, level ups
  static Future<void> levelUp() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }

  /// Streak milestone - for daily streaks
  static Future<void> streak() async {
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }
}
