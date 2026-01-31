import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';

/// Focus/Sustained Attention Test - Tests ability to maintain focus over time
class FocusTestScreen extends ConsumerStatefulWidget {
  const FocusTestScreen({super.key});

  @override
  ConsumerState<FocusTestScreen> createState() => _FocusTestScreenState();
}

class _FocusTestScreenState extends ConsumerState<FocusTestScreen> {
  // Test states
  bool _hasStarted = false;
  bool _testRunning = false;
  bool _testComplete = false;

  // Test configuration
  final int _totalDuration = 60; // seconds
  final double _targetFrequency = 0.3; // 30% chance per second

  // Game state
  int _secondsRemaining = 60;
  bool _targetVisible = false;
  int _targetsShown = 0;
  int _targetsHit = 0;
  int _falsePositives = 0;

  Timer? _gameTimer;
  Timer? _targetTimer;
  final _random = Random();

  @override
  void dispose() {
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    super.dispose();
  }

  void _startTest() {
    setState(() {
      _hasStarted = true;
      _testRunning = true;
      _secondsRemaining = _totalDuration;
      _targetsShown = 0;
      _targetsHit = 0;
      _falsePositives = 0;
      _targetVisible = false;
    });

    // Main game timer (counts down seconds)
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _secondsRemaining--;
      });

      if (_secondsRemaining <= 0) {
        _finishTest();
      }
    });

    // Target appearance timer
    _scheduleNextTarget();
  }

  void _scheduleNextTarget() {
    if (!_testRunning) return;

    // Random interval between 1-4 seconds
    final delay = 1000 + _random.nextInt(3000);

    _targetTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted || !_testRunning) return;

      // 30% chance to show target
      if (_random.nextDouble() < _targetFrequency) {
        _showTarget();
      } else {
        _scheduleNextTarget();
      }
    });
  }

  void _showTarget() {
    if (!_testRunning) return;

    setState(() {
      _targetVisible = true;
      _targetsShown++;
    });

    // Target visible for 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _targetVisible) {
        // Missed target
        setState(() {
          _targetVisible = false;
        });
        _scheduleNextTarget();
      }
    });
  }

  void _handleTap() {
    if (!_testRunning) return;

    if (_targetVisible) {
      // Hit!
      setState(() {
        _targetsHit++;
        _targetVisible = false;
      });
      _scheduleNextTarget();
    } else {
      // False positive
      setState(() {
        _falsePositives++;
      });
    }
  }

  void _finishTest() {
    _gameTimer?.cancel();
    _targetTimer?.cancel();

    setState(() {
      _testRunning = false;
      _testComplete = true;
    });

    // TODO: Save to Supabase
  }

  double _calculateScore() {
    if (_targetsShown == 0) return 0;

    final accuracy = _targetsHit / _targetsShown;
    final falsePositiveRate = _falsePositives / 60; // per second

    // Penalize false positives heavily
    final penaltyFactor = max(0, 1 - (falsePositiveRate * 10));

    return (accuracy * 100 * penaltyFactor).clamp(0, 100);
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
        title: const Text('Sustained Focus Test'),
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
                      const Color(0xFF4FC3F7).withValues(alpha: 0.2),
                      const Color(0xFF4FC3F7).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4FC3F7).withValues(alpha: 0.3),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.center_focus_strong,
                      size: 64,
                      color: Color(0xFF4FC3F7),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Test Udržení Pozornosti',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Test měří tvoji schopnost udržet pozornost a reagovat pouze na relevantní podněty po dobu 60 sekund.',
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
                text: 'Sleduj střed obrazovky',
              ),
              const SizedBox(height: 12),
              _InstructionStep(
                number: 2,
                text: 'Když se objeví MODRÝ TERČ - ťukni co nejrychleji',
              ),
              const SizedBox(height: 12),
              _InstructionStep(
                number: 3,
                text: 'NEŤUKEJ, když není terč (false positive = trest)',
              ),
              const SizedBox(height: 12),
              _InstructionStep(
                number: 4,
                text: 'Drž pozornost celých 60 sekund',
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Minimalizuj okolní rušení. Najdi si klidné místo.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
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
    return GestureDetector(
      onTap: _handleTap,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        body: SafeArea(
          child: Stack(
            children: [
              // Timer
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      '${_secondsRemaining}s',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // Stats
              Positioned(
                top: 80,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MiniStat(
                      label: 'Trefil',
                      value: '$_targetsHit/$_targetsShown',
                      color: Colors.green,
                    ),
                    _MiniStat(
                      label: 'Chyby',
                      value: '$_falsePositives',
                      color: Colors.red,
                    ),
                  ],
                ),
              ),

              // Center - Target area
              Center(
                child: AnimatedScale(
                  scale: _targetVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FC3F7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4FC3F7).withValues(alpha: 0.6),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Instruction
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Ťukni na modrý terč',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.5),
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
    final score = _calculateScore();
    final accuracy = _targetsShown > 0 ? (_targetsHit / _targetsShown) * 100 : 0;
    final missedTargets = _targetsShown - _targetsHit;

    String performanceText;
    Color performanceColor;

    if (score >= 90) {
      performanceText = 'Vynikající! 🎯';
      performanceColor = Colors.green;
    } else if (score >= 70) {
      performanceText = 'Velmi dobré 👍';
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
                      const Color(0xFF4FC3F7).withValues(alpha: 0.2),
                      const Color(0xFF4FC3F7).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4FC3F7).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.center_focus_strong,
                      size: 48,
                      color: Color(0xFF4FC3F7),
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
                label: 'Přesnost',
                value: '${accuracy.toStringAsFixed(1)}%',
                icon: Icons.my_location,
                color: const Color(0xFF4FC3F7),
              ),
              const SizedBox(height: 12),
              _StatTile(
                label: 'Trefené Terče',
                value: '$_targetsHit / $_targetsShown',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _StatTile(
                label: 'Minulé Terče',
                value: '$missedTargets',
                icon: Icons.cancel,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              _StatTile(
                label: 'Chybné Kliky (False Positives)',
                value: '$_falsePositives',
                icon: Icons.warning,
                color: Colors.red,
              ),

              const SizedBox(height: 24),

              // Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.functionalSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF4FC3F7),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'O Udržení Pozornosti',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sustained attention je schopnost udržet focus na úkolu po delší dobu bez rozptýlení. '
                      'Je klíčová pro produktivitu a může být ovlivněna konzumací, především u sativa-dominant strainů.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (_falsePositives > 5) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Máš hodně false positives ($_falsePositives). To může znamenat impulzivitu nebo nízkou inhibici. '
                                'Zkus se více soustředit na čekání na správný podnět.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
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

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
            color: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF4FC3F7),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4FC3F7),
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
