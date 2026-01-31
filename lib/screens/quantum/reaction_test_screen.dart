import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';

/// Reaction Time Test - Measures response time to visual stimuli
class ReactionTestScreen extends ConsumerStatefulWidget {
  const ReactionTestScreen({super.key});

  @override
  ConsumerState<ReactionTestScreen> createState() => _ReactionTestScreenState();
}

class _ReactionTestScreenState extends ConsumerState<ReactionTestScreen> {
  // Test states
  bool _hasStarted = false;
  bool _isWaiting = false;
  bool _showTarget = false;
  bool _canClick = false;
  bool _tooEarly = false;
  bool _testComplete = false;

  // Results
  final List<int> _reactionTimes = [];
  int _currentRound = 0;
  final int _totalRounds = 5;
  int? _currentStartTime;

  // Timer
  Timer? _delayTimer;

  // Random generator
  final _random = Random();

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  void _startTest() {
    setState(() {
      _hasStarted = true;
      _reactionTimes.clear();
      _currentRound = 0;
      _tooEarly = false;
    });
    _startRound();
  }

  void _startRound() {
    if (_currentRound >= _totalRounds) {
      _finishTest();
      return;
    }

    setState(() {
      _isWaiting = true;
      _showTarget = false;
      _canClick = false;
      _tooEarly = false;
      _currentRound++;
    });

    // Random delay between 1-4 seconds
    final delay = 1000 + _random.nextInt(3000);

    _delayTimer = Timer(Duration(milliseconds: delay), () {
      if (mounted) {
        setState(() {
          _showTarget = true;
          _canClick = true;
          _isWaiting = false;
          _currentStartTime = DateTime.now().millisecondsSinceEpoch;
        });
      }
    });
  }

  void _handleTap() {
    if (_tooEarly) {
      // Already failed this round
      return;
    }

    if (_isWaiting) {
      // Tapped too early
      _delayTimer?.cancel();
      setState(() {
        _tooEarly = true;
        _isWaiting = false;
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _startRound();
        }
      });
      return;
    }

    if (_canClick && _showTarget) {
      // Valid reaction
      final reactionTime = DateTime.now().millisecondsSinceEpoch - _currentStartTime!;
      _reactionTimes.add(reactionTime);

      setState(() {
        _showTarget = false;
        _canClick = false;
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _startRound();
        }
      });
    }
  }

  void _finishTest() {
    final avgReactionTime = _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;

    setState(() {
      _testComplete = true;
    });

    // TODO: Save results to Supabase
    // final score = _calculateScore(avgReactionTime);
  }

  double _calculateScore(double avgMs) {
    // Score calculation (0-100)
    // < 200ms = 100
    // 200-300ms = 90-80
    // 300-400ms = 80-60
    // 400-500ms = 60-40
    // > 500ms = 40-0

    if (avgMs < 200) return 100;
    if (avgMs < 300) return 100 - ((avgMs - 200) / 100 * 20);
    if (avgMs < 400) return 80 - ((avgMs - 300) / 100 * 20);
    if (avgMs < 500) return 60 - ((avgMs - 400) / 100 * 20);
    return max(0, 40 - ((avgMs - 500) / 100 * 10));
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasStarted) {
      return _buildInstructions();
    }

    if (_testComplete) {
      return _buildResults();
    }

    return _buildTestScreen();
  }

  Widget _buildInstructions() {
    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        title: const Text('Reaction Time Test'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFB74D).withValues(alpha: 0.2),
                      const Color(0xFFFFB74D).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFB74D).withValues(alpha: 0.3),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.flash_on,
                      size: 64,
                      color: Color(0xFFFFB74D),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Reakce na Vizuální Podnět',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Test měří, jak rychle dokážeš reagovat na vizuální podnět.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _InstructionStep(
                number: 1,
                text: 'Obrazovka zčervená - ČEKEJ',
              ),
              const SizedBox(height: 12),
              _InstructionStep(
                number: 2,
                text: 'Když se objeví zelený terč - ŤUKNI CO NEJRYCHLEJI',
              ),
              const SizedBox(height: 12),
              _InstructionStep(
                number: 3,
                text: 'Neťukej moc brzo, jinak musíš znovu',
              ),
              const SizedBox(height: 12),
              _InstructionStep(
                number: 4,
                text: 'Celkem 5 kol',
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _startTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB74D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Začít Test',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestScreen() {
    Color bgColor;
    String instruction;
    Widget centerWidget;

    if (_tooEarly) {
      bgColor = Colors.orange.shade900;
      instruction = 'Příliš brzo! Počkej na zelený terč.';
      centerWidget = const Icon(
        Icons.warning_amber,
        size: 100,
        color: Colors.orange,
      );
    } else if (_isWaiting) {
      bgColor = Colors.red.shade900;
      instruction = 'Čekej...';
      centerWidget = Container();
    } else if (_showTarget) {
      bgColor = Colors.green.shade900;
      instruction = 'TEĎKA!';
      centerWidget = Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      );
    } else {
      bgColor = AppColors.functionalBg;
      instruction = 'Připraven...';
      centerWidget = Container();
    }

    return GestureDetector(
      onTap: _handleTap,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Stack(
            children: [
              // Center content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    centerWidget,
                    const SizedBox(height: 40),
                    Text(
                      instruction,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Progress
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Kolo $_currentRound / $_totalRounds',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  Widget _buildResults() {
    final avgReactionTime = _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
    final score = _calculateScore(avgReactionTime);
    final bestTime = _reactionTimes.reduce((a, b) => a < b ? a : b);
    final worstTime = _reactionTimes.reduce((a, b) => a > b ? a : b);

    String performanceText;
    Color performanceColor;

    if (score >= 90) {
      performanceText = 'Výborné! ⚡';
      performanceColor = Colors.green;
    } else if (score >= 70) {
      performanceText = 'Dobré 👍';
      performanceColor = Colors.lightGreen;
    } else if (score >= 50) {
      performanceText = 'Průměrné';
      performanceColor = Colors.orange;
    } else {
      performanceText = 'Pod průměrem';
      performanceColor = Colors.red;
    }

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        title: const Text('Výsledky Testu'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Score Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFB74D).withValues(alpha: 0.2),
                      const Color(0xFFFFB74D).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFB74D).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.flash_on,
                      size: 48,
                      color: Color(0xFFFFB74D),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${score.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Skóre',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      performanceText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: performanceColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats
              _StatTile(
                label: 'Průměrná Reakce',
                value: '${avgReactionTime.toStringAsFixed(0)} ms',
                icon: Icons.av_timer,
                color: const Color(0xFFFFB74D),
              ),
              const SizedBox(height: 12),
              _StatTile(
                label: 'Nejlepší Čas',
                value: '$bestTime ms',
                icon: Icons.star,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _StatTile(
                label: 'Nejhorší Čas',
                value: '$worstTime ms',
                icon: Icons.trending_down,
                color: Colors.red,
              ),

              const SizedBox(height: 24),

              // Individual attempts
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.functionalSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jednotlivé Pokusy',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._reactionTimes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final time = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB74D).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFB74D),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.functionalBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: min(time / 600, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB74D),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$time ms',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Actions
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasStarted = false;
                    _testComplete = false;
                    _reactionTimes.clear();
                    _currentRound = 0;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB74D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Opakovat Test',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.functionalBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Zpět na Quantum',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int number;
  final String text;

  const _InstructionStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB74D).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFB74D),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFB74D),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
