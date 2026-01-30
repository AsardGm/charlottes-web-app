import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/holotrop_state_model.dart';
import '../../providers/holotrop_provider.dart';
import '../../theme/holotrop_colors.dart';
import '../../widgets/guide/charlotte_animated.dart';
import '../../widgets/holotrop/breathing_circle.dart';

/// Sekce dychacich cviceni - jadro Holotropu
/// Charlotte v meditacnim modu + animovany dychaci kruh 4-4-4
class HolotropBreathingSection extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const HolotropBreathingSection({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<HolotropBreathingSection> createState() =>
      _HolotropBreathingSectionState();
}

class _HolotropBreathingSectionState
    extends ConsumerState<HolotropBreathingSection> {
  bool _isRunning = false;
  int _completedCycles = 0;
  static const int _targetCycles = 5;

  // Uklidnujici texty, ktere se stridi s kazdym cyklem
  static const List<String> _calmingTexts = [
    'Jsi v bezpeci. Tohle prejde.',
    'Tvoje telo vi, co dela. Dychej.',
    'Kazdy vydech te vraci zpet.',
    'Nic spatneho se nedeje. Jen dychej.',
    'Jsi silnejsi nez tenhle pocit.',
  ];

  // Texty pod kruhem behem pauzy mezi cykly
  static const List<String> _phaseMotivations = [
    'Skvele. Pokracuj dal...',
    'Tvuj tep se zpomaluje. Funguje to.',
    'Jsi na dobre ceste. Dalsi cyklus...',
    'Tvoje telo se uklodnuje. Jeste chvili.',
    'Posledni kolo. Zvladnes to.',
  ];

  void _toggleBreathing() {
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _onPhaseChange(BreathingPhase phase) {
    ref.read(holotropSessionProvider.notifier).setBreathingPhase(phase);
  }

  void _onCycleComplete() {
    setState(() {
      _completedCycles++;
    });
    ref.read(holotropSessionProvider.notifier).incrementCycle();

    if (_completedCycles >= _targetCycles) {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(holotropSessionProvider);

    return Column(
      children: [
        const SizedBox(height: 16),
        // Charlotte v meditacnim modu
        const SizedBox(
          height: 130,
          child: CharlotteAnimated(
            size: 90,
            state: CharlotteState.meditation,
            showScanlines: false,
            showNoise: false,
          ),
        ),
        // Instrukce
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _isRunning
                ? _phaseInstruction(session.breathingPhase)
                : 'Klepni na kruh pro zahajeni',
            key: ValueKey(_isRunning ? session.breathingPhase : 'idle'),
            style: TextStyle(
              color: _isRunning
                  ? HolotropColors.textPrimary
                  : HolotropColors.textSecondary,
              fontSize: 15,
              fontWeight: _isRunning ? FontWeight.w500 : FontWeight.w400,
              letterSpacing: 0.5,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Uklidnujici text - meni se s kazdym cyklem
        if (_isRunning || _completedCycles > 0) ...[
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: Text(
              _calmingTexts[_completedCycles.clamp(0, _calmingTexts.length - 1)],
              key: ValueKey(_completedCycles),
              style: TextStyle(
                color: HolotropColors.accent.withAlpha(150),
                fontSize: 12,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 8),
        // Dychaci kruh - tap pro start/pauza
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleBreathing,
            child: BreathingCircle(
              isRunning: _isRunning,
              onPhaseChange: _onPhaseChange,
              onCycleComplete: _onCycleComplete,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Motivacni text po dokonceni cyklu
        if (_completedCycles > 0 && !_isRunning)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              _phaseMotivations[(_completedCycles - 1).clamp(0, _phaseMotivations.length - 1)],
              style: TextStyle(
                color: HolotropColors.accentSoft,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        // Progress oblast
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              // Cyklus indikatory (tecky misto textu)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_targetCycles, (i) {
                  final isCompleted = i < _completedCycles;
                  final isCurrent = i == _completedCycles && _isRunning;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isCurrent ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isCompleted
                          ? HolotropColors.accent
                          : isCurrent
                              ? HolotropColors.accent.withAlpha(150)
                              : HolotropColors.surface,
                      border: Border.all(
                        color: isCompleted || isCurrent
                            ? HolotropColors.accent.withAlpha(120)
                            : HolotropColors.surfaceLight,
                        width: 1,
                      ),
                      boxShadow: isCompleted
                          ? [
                              BoxShadow(
                                color: HolotropColors.accent.withAlpha(60),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                '$_completedCycles / $_targetCycles',
                style: TextStyle(
                  color: HolotropColors.textMuted.withAlpha(150),
                  fontSize: 11,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tlacitka
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildActionButton(
                  label: _isRunning ? 'PAUZA' : (_completedCycles > 0 ? 'POKRACOVAT' : 'ZACIT'),
                  icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  onTap: _toggleBreathing,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildActionButton(
                  label: 'DALSI',
                  icon: Icons.arrow_forward_rounded,
                  onTap: widget.onComplete,
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  String _phaseInstruction(BreathingPhase phase) {
    switch (phase) {
      case BreathingPhase.inhale:
        return 'Pomalu se nadechni nosem...';
      case BreathingPhase.hold:
        return 'Zadrz dech...';
      case BreathingPhase.exhale:
        return 'Pomalu vydechni usty...';
      case BreathingPhase.idle:
        return 'Sleduj kruh a dychej';
    }
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: HolotropColors.accent.withAlpha(30),
        highlightColor: HolotropColors.accent.withAlpha(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: isPrimary
                ? LinearGradient(
                    colors: [
                      HolotropColors.accent.withAlpha(35),
                      HolotropColors.accent.withAlpha(15),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            color: isPrimary ? null : HolotropColors.surface.withAlpha(180),
            border: Border.all(
              color: isPrimary
                  ? HolotropColors.accent.withAlpha(140)
                  : HolotropColors.surfaceLight,
              width: isPrimary ? 1.5 : 1,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: HolotropColors.accent.withAlpha(25),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary
                    ? HolotropColors.accent
                    : HolotropColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? HolotropColors.accent
                      : HolotropColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
