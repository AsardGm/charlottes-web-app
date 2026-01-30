import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme.dart';
import '../../models/cognitive_test_model.dart';
import '../../providers/cognitive_provider.dart';

/// Hlavní obrazovka pro cognitive test
/// Obsahuje všechny 3 mikrotesty v jednom flow
class CognitiveTestScreen extends ConsumerStatefulWidget {
  const CognitiveTestScreen({super.key});

  @override
  ConsumerState<CognitiveTestScreen> createState() => _CognitiveTestScreenState();
}

class _CognitiveTestScreenState extends ConsumerState<CognitiveTestScreen> {
  int _currentPhase = 0; // 0=intro, 1=reaction, 2=memory, 3=pattern, 4=done

  // Reaction time data
  final List<int> _reactionTimes = [];
  DateTime? _reactionStartTime;
  bool _showGreenCircle = false;
  Timer? _reactionTimer;
  int _reactionAttempts = 0;
  static const int _totalReactionAttempts = 8;

  // Memory flash data
  List<int> _memorySequence = [];
  List<int> _selectedMemory = [];
  int _memoryAttempt = 0;
  static const int _totalMemoryAttempts = 4;
  int _correctMemoryAnswers = 0;

  // Pattern recognition data
  List<_PatternQuestion> _patternQuestions = [];
  int _patternAttempt = 0;
  int _correctPatternAnswers = 0;
  final List<int> _patternTimes = [];
  DateTime? _patternStartTime;

  @override
  void initState() {
    super.initState();
    _generatePatternQuestions();
  }

  @override
  void dispose() {
    _reactionTimer?.cancel();
    super.dispose();
  }

  void _startTest() {
    setState(() => _currentPhase = 1);
    _scheduleReactionTest();
  }

  // ========== REACTION TIME TEST ==========

  void _scheduleReactionTest() {
    if (_reactionAttempts >= _totalReactionAttempts) {
      // Přejít na memory test
      setState(() => _currentPhase = 2);
      _startMemoryTest();
      return;
    }

    // Random delay 1-3 sekundy
    final delay = Duration(milliseconds: 1000 + Random().nextInt(2000));
    _reactionTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _showGreenCircle = true;
        _reactionStartTime = DateTime.now();
      });
    });
  }

  void _handleReactionTap() {
    if (!_showGreenCircle) return;

    final reactionTime = DateTime.now().difference(_reactionStartTime!).inMilliseconds;
    setState(() {
      _reactionTimes.add(reactionTime);
      _showGreenCircle = false;
      _reactionAttempts++;
    });

    // Další pokus
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _scheduleReactionTest();
    });
  }

  ReactionTimeResult _calculateReactionResult() {
    final avg = (_reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length).round();
    final best = _reactionTimes.reduce(min);
    final worst = _reactionTimes.reduce(max);

    // Score: 200ms = 100, 500ms = 50, 800ms+ = 0
    int score = 100;
    if (avg > 200) {
      score = (100 - ((avg - 200) / 6)).round().clamp(0, 100);
    }

    return ReactionTimeResult(
      reactionTimesMs: _reactionTimes,
      averageMs: avg,
      bestMs: best,
      worstMs: worst,
      score: score,
    );
  }

  // ========== MEMORY FLASH TEST ==========

  void _startMemoryTest() {
    _generateMemorySequence();
  }

  void _generateMemorySequence() {
    final random = Random();
    final length = 3 + (_memoryAttempt ~/ 2).clamp(0, 2); // 3-5 items
    _memorySequence = List.generate(length, (_) => random.nextInt(8));
    _selectedMemory = [];

    setState(() {});

    // Zobrazit na 2 sekundy
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      setState(() {}); // Trigger rebuild to hide sequence
    });
  }

  void _selectMemoryItem(int item) {
    setState(() {
      if (_selectedMemory.contains(item)) {
        _selectedMemory.remove(item);
      } else {
        _selectedMemory.add(item);
      }
    });
  }

  void _submitMemoryAnswer() {
    // Check if correct
    final correct = _memorySequence.length == _selectedMemory.length &&
        _memorySequence.every((item) => _selectedMemory.contains(item));

    if (correct) _correctMemoryAnswers++;

    _memoryAttempt++;

    if (_memoryAttempt >= _totalMemoryAttempts) {
      // Přejít na pattern test
      setState(() => _currentPhase = 3);
      _startPatternTest();
    } else {
      _generateMemorySequence();
    }
  }

  MemoryFlashResult _calculateMemoryResult() {
    final accuracy = _correctMemoryAnswers / _totalMemoryAttempts;
    final score = (accuracy * 100).round();

    return MemoryFlashResult(
      totalAttempts: _totalMemoryAttempts,
      correctAnswers: _correctMemoryAnswers,
      score: score,
    );
  }

  // ========== PATTERN RECOGNITION TEST ==========

  void _generatePatternQuestions() {
    final random = Random();
    _patternQuestions = List.generate(4, (index) {
      final shapes = [Icons.circle, Icons.square, Icons.star, Icons.favorite];
      final patternLength = 3 + index;
      final repeatingShape = shapes[random.nextInt(shapes.length)];

      // Create pattern with repeating element
      final pattern = List.generate(patternLength, (i) {
        if (i % 2 == 0) return repeatingShape;
        return shapes[random.nextInt(shapes.length)];
      });

      return _PatternQuestion(
        pattern: pattern,
        correctAnswer: repeatingShape,
        options: shapes..shuffle(),
      );
    });
  }

  void _startPatternTest() {
    _patternStartTime = DateTime.now();
  }

  void _selectPatternAnswer(IconData answer) {
    final elapsed = DateTime.now().difference(_patternStartTime!).inMilliseconds;
    _patternTimes.add(elapsed);

    final correct = _patternQuestions[_patternAttempt].correctAnswer == answer;
    if (correct) _correctPatternAnswers++;

    _patternAttempt++;

    if (_patternAttempt >= _patternQuestions.length) {
      // Dokončeno!
      _finishTest();
    } else {
      setState(() => _patternStartTime = DateTime.now());
    }
  }

  PatternRecognitionResult _calculatePatternResult() {
    final avgTime = (_patternTimes.reduce((a, b) => a + b) / _patternTimes.length).round();
    final accuracy = _correctPatternAnswers / _patternQuestions.length;
    final score = (accuracy * 100).round();

    return PatternRecognitionResult(
      totalAttempts: _patternQuestions.length,
      correctAnswers: _correctPatternAnswers,
      averageTimeMs: avgTime,
      score: score,
    );
  }

  // ========== FINISH ==========

  Future<void> _finishTest() async {
    final reactionResult = _calculateReactionResult();
    final memoryResult = _calculateMemoryResult();
    final patternResult = _calculatePatternResult();

    final totalScore = CognitiveTestResult.calculateTotalScore(
      reactionTime: reactionResult,
      memoryFlash: memoryResult,
      patternRecognition: patternResult,
    );

    // Get baseline
    final baselineAsync = ref.read(cognitiveBaselineProvider);
    final baseline = baselineAsync.value;
    final baselineScore = baseline?.averageScore;

    final status = CognitiveStatusExtension.fromScore(totalScore, baselineScore);

    // Create test result
    final userId = ref.read(supabaseProvider).auth.currentUser?.id;
    if (userId != null) {
      final testResult = CognitiveTestResult(
        userId: userId,
        reactionTime: reactionResult,
        memoryFlash: memoryResult,
        patternRecognition: patternResult,
        totalScore: totalScore,
        status: status,
      );

      // Save to database
      await ref.read(cognitiveTestNotifierProvider.notifier).saveTestResult(testResult);
    }

    if (!mounted) return;

    // Navigate to results
    context.push('/cognitive/results', extra: {
      'reactionTime': reactionResult,
      'memoryFlash': memoryResult,
      'patternRecognition': patternResult,
      'totalScore': totalScore,
      'status': status,
      'baselineScore': baselineScore,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: SafeArea(
        child: _buildPhase(),
      ),
    );
  }

  Widget _buildPhase() {
    switch (_currentPhase) {
      case 0:
        return _buildIntro();
      case 1:
        return _buildReactionTest();
      case 2:
        return _buildMemoryTest();
      case 3:
        return _buildPatternTest();
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withAlpha(40),
                  AppColors.accent.withAlpha(0),
                ],
              ),
            ),
            child: Icon(
              Icons.psychology,
              size: 48,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Cognitive Drift Monitor',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Test trvá 30-45 sekund\nZměříme tvou reakční dobu, paměť a pozornost',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildTestInfo(Icons.flash_on, 'Reakce', '8× zmáčkni zelený kruh'),
          const SizedBox(height: 16),
          _buildTestInfo(Icons.memory, 'Paměť', 'Zapamatuj si symboly'),
          const SizedBox(height: 16),
          _buildTestInfo(Icons.pattern, 'Vzory', 'Najdi opakující se tvar'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Začít test',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestInfo(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.functionalBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionTest() {
    return GestureDetector(
      onTap: _handleReactionTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: _showGreenCircle ? Colors.green : AppColors.functionalBg,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Pokus ${_reactionAttempts + 1}/$_totalReactionAttempts',
                style: TextStyle(
                  color: _showGreenCircle ? Colors.white : AppColors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 48),
              if (_showGreenCircle)
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                )
              else
                Text(
                  'Počkej na zelený kruh...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryTest() {
    final showingSequence = _memoryAttempt < _totalMemoryAttempts &&
                            _memorySequence.isNotEmpty &&
                            DateTime.now().difference(_patternStartTime ?? DateTime.now()).inMilliseconds < 2000;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Paměť - ${_memoryAttempt + 1}/$_totalMemoryAttempts',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            showingSequence
                ? 'Zapamatuj si tyto symboly:'
                : 'Vyber symboly, které jsi viděl:',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          if (showingSequence)
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: _memorySequence
                  .map((i) => _buildMemorySymbol(_getSymbolIcon(i), null, true))
                  .toList(),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: List.generate(8, (i) {
                final selected = _selectedMemory.contains(i);
                return _buildMemorySymbol(_getSymbolIcon(i), () => _selectMemoryItem(i), selected);
              }),
            ),
          const Spacer(),
          if (!showingSequence)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedMemory.isEmpty ? null : _submitMemoryAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Potvrdit'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemorySymbol(IconData icon, VoidCallback? onTap, bool selected) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withAlpha(30) : AppColors.functionalSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.functionalBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: 32,
          color: selected ? AppColors.accent : AppColors.textPrimary,
        ),
      ),
    );
  }

  IconData _getSymbolIcon(int index) {
    final icons = [
      Icons.star,
      Icons.favorite,
      Icons.circle,
      Icons.square,
      Icons.change_history, // triangle
      Icons.wb_sunny, // sun
      Icons.ac_unit, // snowflake
      Icons.wb_cloudy, // cloud
    ];
    return icons[index % icons.length];
  }

  Widget _buildPatternTest() {
    if (_patternAttempt >= _patternQuestions.length) {
      return const Center(child: CircularProgressIndicator());
    }

    final question = _patternQuestions[_patternAttempt];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Vzory - ${_patternAttempt + 1}/${_patternQuestions.length}',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Který tvar se opakuje?',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          // Pattern display
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: question.pattern
                .map((icon) => Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.functionalSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 32, color: AppColors.accent),
                    ))
                .toList(),
          ),
          const Spacer(),
          // Answer options
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: question.options
                .map((icon) => GestureDetector(
                      onTap: () => _selectPatternAnswer(icon),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(30),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.accent,
                            width: 2,
                          ),
                        ),
                        child: Icon(icon, size: 40, color: AppColors.accent),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _PatternQuestion {
  final List<IconData> pattern;
  final IconData correctAnswer;
  final List<IconData> options;

  _PatternQuestion({
    required this.pattern,
    required this.correctAnswer,
    required this.options,
  });
}
