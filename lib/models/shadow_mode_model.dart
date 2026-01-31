import 'package:flutter/foundation.dart';

/// Důvody pro aktivaci Shadow Mode
enum ShadowModeReason {
  needBreak,      // Potřebuji pauzu
  overwhelmed,    // Cítím se zahltěn
  focus,          // Chci se soustředit
  offline,        // Jdu offline
  custom,         // Vlastní důvod
}

extension ShadowModeReasonExtension on ShadowModeReason {
  String get displayName {
    switch (this) {
      case ShadowModeReason.needBreak:
        return 'Potřebuji pauzu';
      case ShadowModeReason.overwhelmed:
        return 'Cítím se zahltěn';
      case ShadowModeReason.focus:
        return 'Chci se soustředit';
      case ShadowModeReason.offline:
        return 'Jdu offline';
      case ShadowModeReason.custom:
        return 'Jiný důvod';
    }
  }

  String get emoji {
    switch (this) {
      case ShadowModeReason.needBreak:
        return '⏸️';
      case ShadowModeReason.overwhelmed:
        return '😵';
      case ShadowModeReason.focus:
        return '🎯';
      case ShadowModeReason.offline:
        return '📵';
      case ShadowModeReason.custom:
        return '💭';
    }
  }
}

/// Model pro Shadow Mode stav
@immutable
class ShadowModeState {
  /// Je Shadow Mode aktivní?
  final bool isActive;

  /// Kdy byl aktivován
  final DateTime? activatedAt;

  /// Důvod aktivace
  final ShadowModeReason? reason;

  /// Custom poznámka (pokud reason == custom)
  final String? customNote;

  /// Celkový čas strávený v Shadow Mode (v sekundách)
  final int totalSecondsInShadowMode;

  /// Počet aktivací Shadow Mode
  final int activationCount;

  const ShadowModeState({
    this.isActive = false,
    this.activatedAt,
    this.reason,
    this.customNote,
    this.totalSecondsInShadowMode = 0,
    this.activationCount = 0,
  });

  /// Vytvoř kopii s novými hodnotami
  ShadowModeState copyWith({
    bool? isActive,
    DateTime? activatedAt,
    ShadowModeReason? reason,
    String? customNote,
    int? totalSecondsInShadowMode,
    int? activationCount,
  }) {
    return ShadowModeState(
      isActive: isActive ?? this.isActive,
      activatedAt: activatedAt ?? this.activatedAt,
      reason: reason ?? this.reason,
      customNote: customNote ?? this.customNote,
      totalSecondsInShadowMode:
          totalSecondsInShadowMode ?? this.totalSecondsInShadowMode,
      activationCount: activationCount ?? this.activationCount,
    );
  }

  /// Aktivuj Shadow Mode
  ShadowModeState activate({
    ShadowModeReason? reason,
    String? customNote,
  }) {
    return copyWith(
      isActive: true,
      activatedAt: DateTime.now(),
      reason: reason,
      customNote: customNote,
      activationCount: activationCount + 1,
    );
  }

  /// Deaktivuj Shadow Mode
  ShadowModeState deactivate() {
    int additionalSeconds = 0;
    if (isActive && activatedAt != null) {
      additionalSeconds = DateTime.now().difference(activatedAt!).inSeconds;
    }

    return ShadowModeState(
      isActive: false,
      activatedAt: null,
      reason: null,
      customNote: null,
      totalSecondsInShadowMode: totalSecondsInShadowMode + additionalSeconds,
      activationCount: activationCount,
    );
  }

  /// Jak dlouho je Shadow Mode aktivní? (current session)
  Duration? get currentSessionDuration {
    if (!isActive || activatedAt == null) return null;
    return DateTime.now().difference(activatedAt!);
  }

  /// Formátovaný čas celkově strávený v Shadow Mode
  String get formattedTotalTime {
    final hours = totalSecondsInShadowMode ~/ 3600;
    final minutes = (totalSecondsInShadowMode % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '<1m';
    }
  }

  /// Serializace do JSON
  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'activatedAt': activatedAt?.toIso8601String(),
      'reason': reason?.name,
      'customNote': customNote,
      'totalSecondsInShadowMode': totalSecondsInShadowMode,
      'activationCount': activationCount,
    };
  }

  /// Deserializace z JSON
  factory ShadowModeState.fromJson(Map<String, dynamic> json) {
    return ShadowModeState(
      isActive: json['isActive'] as bool? ?? false,
      activatedAt: json['activatedAt'] != null
          ? DateTime.parse(json['activatedAt'] as String)
          : null,
      reason: json['reason'] != null
          ? ShadowModeReason.values
              .firstWhere((e) => e.name == json['reason'] as String)
          : null,
      customNote: json['customNote'] as String?,
      totalSecondsInShadowMode: json['totalSecondsInShadowMode'] as int? ?? 0,
      activationCount: json['activationCount'] as int? ?? 0,
    );
  }

  /// Prázdný/defaultní stav
  static const ShadowModeState empty = ShadowModeState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowModeState &&
          runtimeType == other.runtimeType &&
          isActive == other.isActive &&
          activatedAt == other.activatedAt &&
          reason == other.reason &&
          customNote == other.customNote &&
          totalSecondsInShadowMode == other.totalSecondsInShadowMode &&
          activationCount == other.activationCount;

  @override
  int get hashCode =>
      isActive.hashCode ^
      activatedAt.hashCode ^
      reason.hashCode ^
      customNote.hashCode ^
      totalSecondsInShadowMode.hashCode ^
      activationCount.hashCode;
}
