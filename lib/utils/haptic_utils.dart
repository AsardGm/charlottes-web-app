import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Utility pro haptic feedback - vibrace pro lepsi UX
class HapticUtils {
  HapticUtils._();

  /// Lehka vibrace - pro bezne interakce (tap, select)
  static Future<void> lightImpact() async {
    if (kIsWeb) return; // Web nepodporuje haptic
    await HapticFeedback.lightImpact();
  }

  /// Stredni vibrace - pro dulezitejsi akce (like, follow)
  static Future<void> mediumImpact() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
  }

  /// Silna vibrace - pro vyznamne akce (delete, send)
  static Future<void> heavyImpact() async {
    if (kIsWeb) return;
    await HapticFeedback.heavyImpact();
  }

  /// Vibrace pro vyber - pro picker, slider
  static Future<void> selectionClick() async {
    if (kIsWeb) return;
    await HapticFeedback.selectionClick();
  }

  /// Vibrace pro uspech
  static Future<void> success() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
  }

  /// Vibrace pro chybu
  static Future<void> error() async {
    if (kIsWeb) return;
    await HapticFeedback.heavyImpact();
  }

  /// Vibrace pro upozorneni
  static Future<void> warning() async {
    if (kIsWeb) return;
    await HapticFeedback.lightImpact();
  }

  /// Vibrace pro like
  static Future<void> like() async {
    if (kIsWeb) return;
    await HapticFeedback.lightImpact();
  }

  /// Vibrace pro odeslani zpravy
  static Future<void> messageSent() async {
    if (kIsWeb) return;
    await HapticFeedback.selectionClick();
  }

  /// Vibrace pro pull-to-refresh
  static Future<void> refresh() async {
    if (kIsWeb) return;
    await HapticFeedback.selectionClick();
  }

  /// Vibrace pro tab switch
  static Future<void> tabSwitch() async {
    if (kIsWeb) return;
    await HapticFeedback.selectionClick();
  }
}
