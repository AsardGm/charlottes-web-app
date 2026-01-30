import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../models/myth_buster_model.dart';
import '../../data/myth_buster_data.dart';
import '../../utils/haptic_utils.dart';

/// Genetic Myth Buster - swipeable educational quiz
class MythBusterScreen extends StatefulWidget {
  const MythBusterScreen({super.key});

  @override
  State<MythBusterScreen> createState() => _MythBusterScreenState();
}

class _MythBusterScreenState extends State<MythBusterScreen>
    with SingleTickerProviderStateMixin {
  late List<CannabisMyth> _myths;
  int _currentIndex = 0;
  bool _showAnswer = false;
  int _totalXP = 0;
  int _correctCount = 0;
  int _wrongCount = 0;

  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _myths = List.from(MythBusterData.allMyths)..shuffle();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  void _onGuess(bool userGuess) {
    if (_showAnswer) return;

    HapticUtils.selectionClick();

    final myth = _myths[_currentIndex];
    final isCorrect = userGuess == myth.isTrue;

    setState(() {
      _showAnswer = true;
      if (isCorrect) {
        _correctCount++;
        _totalXP += myth.xpReward;
      } else {
        _wrongCount++;
      }
    });

    _cardController.forward();

    // Auto-advance after showing answer
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _nextMyth();
      }
    });
  }

  void _nextMyth() {
    if (_currentIndex >= _myths.length - 1) {
      // Quiz completed
      _showCompletionDialog();
      return;
    }

    _cardController.reverse().then((_) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    });
  }

  void _showCompletionDialog() {
    HapticUtils.success();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.functionalSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.accent.withAlpha(80),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: AppColors.gold,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'QUEST COMPLETE!',
                style: TextStyle(
                  fontFamily: 'MightySpidey',
                  fontSize: 24,
                  color: AppColors.accent,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Myth Buster dokončen',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              // Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.functionalBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          '✅ $_correctCount',
                          'Správně',
                          AppColors.success,
                        ),
                        _buildStatColumn(
                          '❌ $_wrongCount',
                          'Špatně',
                          AppColors.error,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withAlpha(30),
                            AppColors.accent.withAlpha(10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.stars,
                            color: AppColors.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+$_totalXP XP',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Hotovo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final myth = _myths[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        title: const Text('Myth Buster'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          // XP counter
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.stars, color: AppColors.accent, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_totalXP XP',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '${_currentIndex + 1}',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        ' / ${_myths.length}',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      // Category badge
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
                          '${myth.category.emoji} ${myth.category.label}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (_currentIndex + 1) / _myths.length,
                    backgroundColor: AppColors.functionalBorder,
                    color: AppColors.accent,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),

            // Main card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AnimatedBuilder(
                  animation: _cardAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _showAnswer ? 1.0 - (_cardAnimation.value * 0.05) : 1.0,
                      child: _showAnswer
                          ? _buildAnswerCard(myth)
                          : _buildQuestionCard(myth),
                    );
                  },
                ),
              ),
            ),

            // Answer buttons (only show when not answered)
            if (!_showAnswer)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAnswerButton(
                        label: 'MÝTUS',
                        icon: Icons.close,
                        color: AppColors.error,
                        onTap: () => _onGuess(false),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAnswerButton(
                        label: 'PRAVDA',
                        icon: Icons.check,
                        color: AppColors.success,
                        onTap: () => _onGuess(true),
                      ),
                    ),
                  ],
                ),
              ),

            // Next button (show after answer)
            if (_showAnswer)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextMyth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentIndex >= _myths.length - 1 ? 'Dokončit' : 'Další',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentIndex >= _myths.length - 1
                              ? Icons.emoji_events
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

  Widget _buildQuestionCard(CannabisMyth myth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withAlpha(60),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withAlpha(20),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline,
            color: AppColors.accent,
            size: 48,
          ),
          const SizedBox(height: 24),
          Text(
            'Pravda nebo mýtus?',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            myth.mythStatement,
            style: TextStyle(
              fontFamily: 'MightySpidey',
              color: AppColors.textPrimary,
              fontSize: 28,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Swipe nebo vyber odpověď',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(CannabisMyth myth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: myth.isTrue
              ? AppColors.success.withAlpha(80)
              : AppColors.error.withAlpha(80),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (myth.isTrue ? AppColors.success : AppColors.error)
                .withAlpha(30),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Reality banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (myth.isTrue ? AppColors.success : AppColors.error)
                    .withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                myth.reality,
                style: TextStyle(
                  color: myth.isTrue ? AppColors.success : AppColors.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Original statement
            Text(
              myth.mythStatement,
              style: TextStyle(
                fontFamily: 'MightySpidey',
                color: AppColors.textPrimary,
                fontSize: 22,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Divider
            Container(
              height: 1,
              width: 60,
              color: AppColors.functionalBorder,
            ),
            const SizedBox(height: 20),

            // Explanation
            Text(
              myth.explanation,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // XP reward
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '+${myth.xpReward} XP',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withAlpha(80),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
