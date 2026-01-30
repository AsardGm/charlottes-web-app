import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_router.dart';
import '../../theme/theme.dart';
import '../../utils/haptic_utils.dart';
import '../../widgets/guide/guide.dart';

/// Onboarding obrazovka s holografickou průvodkyní Buddy
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showTypingText = false;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Ahoj!',
      message: 'Jsem Buddy, tvůj digitální průvodce. Vítej v komunitě Buds and Buddies!',
      charlotteState: CharlotteState.welcome,
      accentColor: AppColors.accent,
    ),
    OnboardingStep(
      title: 'Komunita',
      message: 'Buds and Buddies je místo, kde se setkávají přátelé a sdílí své zkušenosti. Diskutuj, ptej se a pomáhej ostatním.',
      charlotteState: CharlotteState.scanning,
      accentColor: AppColors.primary,
    ),
    OnboardingStep(
      title: 'Safe Chat',
      message: 'Všechny zprávy jsou šifrované end-to-end. Tvoje soukromí je naší prioritou. Nikdo jiný je nemůže číst.',
      charlotteState: CharlotteState.success,
      accentColor: AppColors.accent,
    ),
    OnboardingStep(
      title: 'Získej odznaky',
      message: 'Buď aktivní, získávej XP a postupuj v hodnostech. Sbírej unikátní karty a odznaky!',
      charlotteState: CharlotteState.success,
      accentColor: AppColors.gold,
    ),
    OnboardingStep(
      title: 'Připraveno!',
      message: 'Teď už víš vše potřebné. Pokud budeš potřebovat pomoct, jsem tu pro tebe. Pojďme začít!',
      charlotteState: CharlotteState.pointing,
      accentColor: AppColors.success,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Spustit typing efekt po chvíli
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showTypingText = true);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    resetOnboardingCache();
    if (mounted) {
      context.go('/login');
    }
  }

  void _nextPage() {
    HapticUtils.selectionClick();
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    HapticUtils.lightImpact();
    _completeOnboarding();
  }

  void _onPageChanged(int index) {
    HapticUtils.selectionClick();
    setState(() {
      _currentPage = index;
      _showTypingText = false;
    });
    // Reset typing efekt
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _showTypingText = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header s skip tlačítkem
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Krok indikátor
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.functionalSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.functionalBorder,
                      ),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${_steps.length}',
                      style: TextStyle(
                        color: AppColors.functionalMuted,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  // Skip tlačítko
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Přeskočit',
                      style: TextStyle(
                        color: AppColors.functionalMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Hlavní obsah
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return _buildPage(_steps[index], index == _currentPage);
                },
              ),
            ),

            // Progress dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (index) => _buildDot(index),
                ),
              ),
            ),

            // Tlačítko Další/Začít
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentStep.accentColor,
                    foregroundColor: currentStep.accentColor == AppColors.gold
                        ? Colors.black
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == _steps.length - 1 ? 'Začít' : 'Další',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentPage == _steps.length - 1
                            ? Icons.rocket_launch
                            : Icons.arrow_forward,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingStep step, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Charlotte animovaná
          CharlotteAnimated(
            size: 180,
            state: isActive ? step.charlotteState : CharlotteState.idle,
            showGlow: true,
            showScanlines: true,
            showNoise: step.charlotteState == CharlotteState.error,
          ),

          const SizedBox(height: 32),

          // Bublina s textem
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.functionalSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: step.accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: step.accentColor.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: step.accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'BUDDY',
                        style: TextStyle(
                          color: step.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: step.accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: step.accentColor.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Titulek
                Text(
                  step.title,
                  style: TextStyle(
                    fontFamily: 'MightySpidey',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 12),

                // Zpráva s typing efektem
                if (_showTypingText && isActive)
                  CharlotteVoiceLine(
                    key: ValueKey('voice_$_currentPage'),
                    text: step.message,
                    typingSpeed: const Duration(milliseconds: 25),
                  )
                else
                  Text(
                    step.message,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = index == _currentPage;
    final isPast = index < _currentPage;
    final step = _steps[index];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 28 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive
            ? step.accentColor
            : isPast
                ? step.accentColor.withValues(alpha: 0.5)
                : AppColors.functionalBorder,
        borderRadius: BorderRadius.circular(5),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: step.accentColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }
}

/// Model pro krok onboardingu
class OnboardingStep {
  final String title;
  final String message;
  final CharlotteState charlotteState;
  final Color accentColor;

  const OnboardingStep({
    required this.title,
    required this.message,
    required this.charlotteState,
    required this.accentColor,
  });
}

/// Model pro onboarding stranku (zachováno pro zpětnou kompatibilitu)
class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

/// Helper pro kontrolu, zda uzivatel prosel onboardingem
class OnboardingHelper {
  static const _key = 'onboarding_completed';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
