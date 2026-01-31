import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';

/// Memory Sequence Test - Tests working memory and pattern recognition
class MemoryTestScreen extends ConsumerStatefulWidget {
  const MemoryTestScreen({super.key});

  @override
  ConsumerState<MemoryTestScreen> createState() => _MemoryTestScreenState();
}

class _MemoryTestScreenState extends ConsumerState<MemoryTestScreen> {
  // Test states
  bool _hasStarted = false;
  bool _isShowingSequence = false;
  bool _isUserTurn = false;
  bool _testComplete = false;

  // Game data
  final List<int> _currentSequence = [];
  final List<int> _userSequence = [];
  int _level = 1;
  int _correctRounds = 0;
  int _maxLevel = 0;
  bool _wrongAnswer = false;

  final _random = Random();

  void _startTest() {
    setState(() {
      _hasStarted = true;
      _currentSequence.clear();
      _userSequence.clear();
      _level = 1;
      _correctRounds = 0;
      _maxLevel = 0;
    });
    _startRound();
  }

  void _startRound() {
    // Add new number to sequence
    _currentSequence.add(_random.nextInt(9));

    setState(() {
      _userSequence.clear();
      _wrongAnswer = false;
      _isUserTurn = false;
    });

    _showSequence();
  }

  Future<void> _showSequence() async {
    setState(() {
      _isShowingSequence = true;
    });

    // Wait before starting
    await Future.delayed(const Duration(milliseconds: 500));

    // Show each number in sequence
    for (int i = 0; i < _currentSequence.length; i++) {
      setState(() {
        // This will be read by the UI to highlight the number
      });

      await Future.delayed(const Duration(milliseconds: 800));
    }

    // User's turn
    setState(() {
      _isShowingSequence = false;
      _isUserTurn = true;
    });
  }

  void _numberPressed(int number) {
    if (!_isUserTurn || _wrongAnswer) return;

    _userSequence.add(number);

    // Check if correct so far
    final currentIndex = _userSequence.length - 1;
    if (_userSequence[currentIndex] != _currentSequence[currentIndex]) {
      // Wrong answer
      setState(() {
        _wrongAnswer = true;
      });

      Future.delayed(const Duration(milliseconds: 1000), () {
        _finishTest();
      });
      return;
    }

    // Check if sequence complete
    if (_userSequence.length == _currentSequence.length) {
      // Correct!
      setState(() {
        _correctRounds++;
        _level++;
        _maxLevel = max(_maxLevel, _level - 1);
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          if (_level > 8) {
            // Max level reached
            _finishTest();
          } else {
            _startRound();
          }
        }
      });
    }
  }

  void _finishTest() {
    setState(() {
      _testComplete = true;
    });

    // TODO: Save to Supabase
  }

  double _calculateScore() {
    // Score based on max level reached
    // Level 3 = 40
    // Level 4 = 55
    // Level 5 = 70
    // Level 6 = 80
    // Level 7 = 90
    // Level 8+ = 100

    if (_maxLevel <= 2) return _maxLevel * 20;
    if (_maxLevel == 3) return 40;
    if (_maxLevel == 4) return 55;
    if (_maxLevel == 5) return 70;
    if (_maxLevel == 6) return 80;
    if (_maxLevel == 7) return 90;
    return 100;
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
        title: const Text('Memory Sequence Test'),
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
                      const Color(0xFF9575CD).withValues(alpha: 0.2),
                      const Color(0xFF9575CD).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF9575CD).withValues(alpha: 0.3),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.memory,
                      size: 64,
                      color: Color(0xFF9575CD),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Test Pracovní Paměti',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Zapamatuj si sekvenci čísel a zopakuj ji ve správném pořadí.',
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
                text: 'Sleduj sekvenci čísel - budou blikat',
              ),
              const SizedBox(height: 12),
              _InstructionStep(
                number: 2,
                text: 'Zapamatuj si pořadí',
              ),
              const SizedBox(height: 12),
              _InstructionStep(
                number: 3,
                text: 'Zopakuj sekvenci klikáním na čísla',
              ),
              const SizedBox(height: 12),
              _InstructionStep(
                number: 4,
                text: 'Každé kolo přibude jedno číslo',
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _startTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9575CD),
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
                    color: Colors.white,
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
    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        title: Text('Level $_level'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.functionalSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Level',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_level',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9575CD),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.functionalBorder,
                  ),
                  Column(
                    children: [
                      const Text(
                        'Délka Sekvence',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_currentSequence.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _isShowingSequence
                    ? 'Sleduj sekvenci...'
                    : _wrongAnswer
                        ? 'Špatně! 😞'
                        : 'Zopakuj sekvenci',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _wrongAnswer ? Colors.red : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Number Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    return _NumberButton(
                      number: index,
                      isHighlighted: _isShowingSequence &&
                          _currentSequence.isNotEmpty &&
                          _currentSequence.last == index,
                      isEnabled: _isUserTurn && !_wrongAnswer,
                      isWrong: _wrongAnswer && _userSequence.isNotEmpty && _userSequence.last == index,
                      onPressed: () => _numberPressed(index),
                    );
                  },
                ),
              ),
            ),

            // Sequence display
            if (_isUserTurn)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.functionalSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Tvoje Sekvence',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _userSequence.map((num) {
                          return Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9575CD).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '$num',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9575CD),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final score = _calculateScore();

    String performanceText;
    Color performanceColor;

    if (score >= 90) {
      performanceText = 'Excelentní! 🧠';
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
                      const Color(0xFF9575CD).withValues(alpha: 0.2),
                      const Color(0xFF9575CD).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF9575CD).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.memory,
                      size: 48,
                      color: Color(0xFF9575CD),
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
                label: 'Maximální Level',
                value: '$_maxLevel',
                icon: Icons.emoji_events,
                color: const Color(0xFF9575CD),
              ),
              const SizedBox(height: 12),
              _StatTile(
                label: 'Nejdelší Sekvence',
                value: '$_maxLevel čísel',
                icon: Icons.format_list_numbered,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              _StatTile(
                label: 'Správné Odpovědi',
                value: '$_correctRounds',
                icon: Icons.check_circle,
                color: Colors.green,
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
                          color: Color(0xFF9575CD),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'O Pracovní Paměti',
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
                      'Pracovní paměť je schopnost krátkodobě udržet a manipulovat s informacemi. '
                      'Průměrný člověk si pamatuje 7±2 čísel. Konzumace může dočasně snížit kapacitu pracovní paměti.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
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
                  backgroundColor: const Color(0xFF9575CD),
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
                    color: Colors.white,
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

class _NumberButton extends StatefulWidget {
  final int number;
  final bool isHighlighted;
  final bool isEnabled;
  final bool isWrong;
  final VoidCallback onPressed;

  const _NumberButton({
    required this.number,
    required this.isHighlighted,
    required this.isEnabled,
    required this.isWrong,
    required this.onPressed,
  });

  @override
  State<_NumberButton> createState() => _NumberButtonState();
}

class _NumberButtonState extends State<_NumberButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_NumberButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final isAnimating = _controller.isAnimating;
        final highlighted = widget.isHighlighted || isAnimating;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isEnabled ? widget.onPressed : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: widget.isWrong
                    ? Colors.red.withValues(alpha: 0.3)
                    : highlighted
                        ? const Color(0xFF9575CD)
                        : AppColors.functionalSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isWrong
                      ? Colors.red
                      : highlighted
                          ? const Color(0xFF9575CD)
                          : AppColors.functionalBorder,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '${widget.number}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: highlighted ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
            color: const Color(0xFF9575CD).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF9575CD),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9575CD),
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
