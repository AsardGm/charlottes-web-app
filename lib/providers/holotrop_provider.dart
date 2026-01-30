import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/holotrop_state_model.dart';

/// Hlavni holotrop session state
final holotropSessionProvider =
    NotifierProvider<HolotropSessionNotifier, HolotropSessionState>(
  HolotropSessionNotifier.new,
);

/// Derived provider - zda je holotrop mod aktivni
final holotropModeActiveProvider = Provider<bool>((ref) {
  return ref.watch(holotropSessionProvider).isActive;
});

class HolotropSessionNotifier extends Notifier<HolotropSessionState> {
  @override
  HolotropSessionState build() => const HolotropSessionState();

  void startSession() {
    state = state.copyWith(isActive: true);
  }

  void endSession() {
    state = const HolotropSessionState();
  }

  void setSection(HolotropSection section) {
    state = state.copyWith(currentSection: section);
  }

  void setBreathingPhase(BreathingPhase phase) {
    state = state.copyWith(breathingPhase: phase);
  }

  void incrementCycle() {
    state = state.copyWith(
      breathingCycleCount: state.breathingCycleCount + 1,
    );
  }

  void setGroundingStep(int step) {
    state = state.copyWith(groundingStep: step);
  }
}
