import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/holotrop_provider.dart';
import '../../theme/holotrop_colors.dart';
import '../../widgets/holotrop/grounding_step_card.dart';

/// Cyberpunk verze techniky 5-4-3-2-1 pro uzemneni
/// Vcetne edukacniho obsahu o kanabinoidech na konci
class HolotropGroundingSection extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const HolotropGroundingSection({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<HolotropGroundingSection> createState() =>
      _HolotropGroundingSectionState();
}

class _HolotropGroundingSectionState
    extends ConsumerState<HolotropGroundingSection> {
  int _currentStep = 0;
  bool _groundingDone = false;

  static const _steps = [
    _GroundingStep(
      title: 'VIZUALNI SCAN',
      description:
          'Identifikuj 3 neonove barvy ve svem okoli. Podivej se kolem sebe a pojmenuj je.',
      icon: Icons.visibility,
    ),
    _GroundingStep(
      title: 'HMATOVY KONTAKT',
      description:
          'Poloz ruce na studeny povrch. Soustredi se na teplotu a texturu materialu.',
      icon: Icons.touch_app,
    ),
    _GroundingStep(
      title: 'AUDIO SCAN',
      description:
          'Zamer se na zvuk ventilatoru, hudby nebo ulice. Poslechni 3 ruzne zvuky.',
      icon: Icons.hearing,
    ),
    _GroundingStep(
      title: 'AROMATICKY RESET',
      description:
          'Nadechni se hluboko nosem. Zkus identifikovat 2 vune kolem sebe.',
      icon: Icons.air,
    ),
    _GroundingStep(
      title: 'GUSTATORICKY ANCHOR',
      description:
          'Napij se studene vody. Soustredi se na chlad a chut. Jsi tady a ted.',
      icon: Icons.water_drop,
    ),
  ];

  void _completeStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      ref
          .read(holotropSessionProvider.notifier)
          .setGroundingStep(_currentStep);
    } else {
      setState(() {
        _groundingDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HolotropColors.accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: HolotropColors.accent.withAlpha(60),
                  ),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: HolotropColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UZEMNENI',
                    style: TextStyle(
                      color: HolotropColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Technika 5-4-3-2-1 pro navrat do reality',
                    style: TextStyle(
                      color: HolotropColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Kroky uzemneni
          for (int i = 0; i < _steps.length; i++)
            GroundingStepCard(
              stepNumber: i + 1,
              title: _steps[i].title,
              description: _steps[i].description,
              icon: _steps[i].icon,
              isActive: i == _currentStep && !_groundingDone,
              isCompleted: i < _currentStep || _groundingDone,
              onDone: i == _currentStep ? _completeStep : null,
            ),

          if (_groundingDone) ...[
            const SizedBox(height: 16),
            // Uspech
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    HolotropColors.accent.withAlpha(20),
                    HolotropColors.accent.withAlpha(10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: HolotropColors.accent.withAlpha(80),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: HolotropColors.accent,
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'UZEMNENI DOKONCENO',
                    style: TextStyle(
                      color: HolotropColors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Jsi v bezpeci. Efekt postupne odezni.',
                    style: TextStyle(
                      color: HolotropColors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Edukacni obsah
            _buildEducationCard(
              title: 'DDoS utok na tvuj mozek',
              text:
                  'Tvoje CB1 receptory jsou pretizene. THC se na ne navazalo ve velkem mnozstvi a zpusobuje pretizetni signalizace. Je to jako DDoS utok - prilis mnoho pozadavku najednou. Holotrop ti pomuze tento utok ustat, nez se system stabilizuje.',
              icon: Icons.memory,
            ),
            const SizedBox(height: 12),
            _buildEducationCard(
              title: 'THC vs. syntetika',
              text:
                  'Klasicke THC z rostliny ma polocas rozpadu 1-3 hodiny. Synteticke kanabinoidy (HHC-P, THCP) mohou pusobit 6-12 hodin kvuli silnejsi vazbe na receptory. Pokud jsi uzil syntetiku, bud trpelivy - odezni to, jen to trva dele.',
              icon: Icons.compare_arrows,
            ),
            const SizedBox(height: 24),
            // Tlacitko ukoncit
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: widget.onComplete,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: HolotropColors.accent.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: HolotropColors.accent.withAlpha(120),
                      width: 1.5,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check,
                        color: HolotropColors.accent,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'UKONCIT HOLOTROP',
                        style: TextStyle(
                          color: HolotropColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEducationCard({
    required String title,
    required String text,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HolotropColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: HolotropColors.surfaceLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: HolotropColors.accentSoft, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: HolotropColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: HolotropColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroundingStep {
  final String title;
  final String description;
  final IconData icon;

  const _GroundingStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}
