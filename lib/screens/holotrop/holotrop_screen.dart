import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/holotrop_state_model.dart';
import '../../providers/holotrop_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/holotrop_colors.dart';
import '../../widgets/holotrop/holotrop_progress_bar.dart';
import 'holotrop_breathing_section.dart';
import 'holotrop_biohacks_section.dart';
import 'holotrop_grounding_section.dart';

/// Hlavni Holotrop obrazovka - plna uklidnujici zkusenost
/// Navigace pres GoRouter '/holotrop'
class HolotropScreen extends ConsumerStatefulWidget {
  const HolotropScreen({super.key});

  @override
  ConsumerState<HolotropScreen> createState() => _HolotropScreenState();
}

class _HolotropScreenState extends ConsumerState<HolotropScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _bgTransitionController;
  late Animation<Color?> _bgColorAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Animace prechodu z cyberpunk do uklidnujiciho modu
    _bgTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _bgColorAnimation = ColorTween(
      begin: AppColors.functionalBg,
      end: HolotropColors.background,
    ).animate(CurvedAnimation(
      parent: _bgTransitionController,
      curve: Curves.easeInOut,
    ));

    _bgTransitionController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(holotropSessionProvider.notifier).startSession();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgTransitionController.dispose();
    super.dispose();
  }

  void _goToSection(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    final sections = HolotropSection.values;
    if (index < sections.length) {
      ref.read(holotropSessionProvider.notifier).setSection(sections[index]);
    }
  }

  void _endSession() {
    ref.read(holotropSessionProvider.notifier).endSession();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(holotropSessionProvider);

    return AnimatedBuilder(
      animation: _bgTransitionController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _bgColorAnimation.value,
          body: SafeArea(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(session),
                // Sekce
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      HolotropBreathingSection(
                        onComplete: () => _goToSection(1),
                      ),
                      HolotropBiohacksSection(
                        onComplete: () => _goToSection(2),
                      ),
                      HolotropGroundingSection(
                        onComplete: _endSession,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(HolotropSessionState session) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Zavrit
          GestureDetector(
            onTap: _endSession,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: HolotropColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: HolotropColors.accent.withAlpha(60),
                ),
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: HolotropColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nazev
          const Text(
            'HOLOTROP',
            style: TextStyle(
              color: HolotropColors.accent,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
          const Spacer(),
          // Progress
          HolotropProgressBar(currentSection: session.currentSection),
        ],
      ),
    );
  }
}
