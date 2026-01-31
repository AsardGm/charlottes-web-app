import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shadow_mode_model.dart';
import '../services/shadow_mode_service.dart';

/// Provider pro ShadowModeService instance
final shadowModeServiceProvider = Provider<ShadowModeService>((ref) {
  return ShadowModeService();
});

/// Provider pro Shadow Mode state (reactive)
class ShadowModeNotifier extends Notifier<ShadowModeState> {
  @override
  ShadowModeState build() {
    _loadState();
    return ShadowModeState.empty;
  }

  ShadowModeService get _service => ref.read(shadowModeServiceProvider);

  /// Načti stav ze storage
  Future<void> _loadState() async {
    state = await _service.getState();
  }

  /// Aktivuj Shadow Mode
  Future<void> activate({
    ShadowModeReason? reason,
    String? customNote,
  }) async {
    await _service.activate(reason: reason, customNote: customNote);
    state = _service.currentState;
  }

  /// Deaktivuj Shadow Mode
  Future<void> deactivate() async {
    await _service.deactivate();
    state = _service.currentState;
  }

  /// Toggle Shadow Mode
  Future<void> toggle({
    ShadowModeReason? reason,
    String? customNote,
  }) async {
    await _service.toggle(reason: reason, customNote: customNote);
    state = _service.currentState;
  }

  /// Refresh state (pro sync s service)
  Future<void> refresh() async {
    state = await _service.getState();
  }
}

final shadowModeStateProvider =
    NotifierProvider<ShadowModeNotifier, ShadowModeState>(() {
  return ShadowModeNotifier();
});

/// Helper provider - je Shadow Mode aktivní? (bool)
final isShadowModeActiveProvider = Provider<bool>((ref) {
  final state = ref.watch(shadowModeStateProvider);
  return state.isActive;
});

/// Helper provider - aktuální session duration
final shadowModeSessionDurationProvider = Provider<Duration?>((ref) {
  final state = ref.watch(shadowModeStateProvider);
  return state.currentSessionDuration;
});
