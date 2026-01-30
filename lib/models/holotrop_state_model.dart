/// Faze dychani
enum BreathingPhase { inhale, hold, exhale, idle }

/// Sekce Holotrop pruvodce
enum HolotropSection { breathing, biohacks, grounding }

/// Stav holotrop session
class HolotropSessionState {
  final bool isActive;
  final HolotropSection currentSection;
  final BreathingPhase breathingPhase;
  final int breathingCycleCount;
  final int totalCycles;
  final int groundingStep;

  const HolotropSessionState({
    this.isActive = false,
    this.currentSection = HolotropSection.breathing,
    this.breathingPhase = BreathingPhase.idle,
    this.breathingCycleCount = 0,
    this.totalCycles = 5,
    this.groundingStep = 0,
  });

  HolotropSessionState copyWith({
    bool? isActive,
    HolotropSection? currentSection,
    BreathingPhase? breathingPhase,
    int? breathingCycleCount,
    int? totalCycles,
    int? groundingStep,
  }) {
    return HolotropSessionState(
      isActive: isActive ?? this.isActive,
      currentSection: currentSection ?? this.currentSection,
      breathingPhase: breathingPhase ?? this.breathingPhase,
      breathingCycleCount: breathingCycleCount ?? this.breathingCycleCount,
      totalCycles: totalCycles ?? this.totalCycles,
      groundingStep: groundingStep ?? this.groundingStep,
    );
  }
}
