import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/theme.dart';
import '../../providers/cognitive_provider.dart';
import '../../models/cognitive_test_model.dart';
import '../../services/cognitive_service.dart';

/// Obrazovka s historií a trendy cognitive testů
class CognitiveHistoryScreen extends ConsumerWidget {
  const CognitiveHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(cognitiveHistoryProvider);
    final baselineAsync = ref.watch(cognitiveBaselineProvider);
    final streakAsync = ref.watch(cognitiveStreakProvider);
    final dailyScoresAsync = ref.watch(dailyScoresProvider(30));

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        title: const Text('Cognitive Historie'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(cognitiveHistoryProvider);
          ref.invalidate(cognitiveBaselineProvider);
          ref.invalidate(cognitiveStreakProvider);
          ref.invalidate(dailyScoresProvider(30));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baseline card
              baselineAsync.when(
                data: (baseline) => baseline != null
                    ? _buildBaselineCard(baseline)
                    : _buildNoBaselineCard(),
                loading: () => _buildLoadingCard(),
                error: (_, _) => _buildErrorCard('Chyba při načítání baseline'),
              ),

              const SizedBox(height: 16),

              // Streak stats
              streakAsync.when(
                data: (stats) => _buildStreakCard(stats),
                loading: () => _buildLoadingCard(),
                error: (_, _) => _buildErrorCard('Chyba při načítání streaku'),
              ),

              const SizedBox(height: 24),

              // Trend graph
              Text(
                'TREND (30 DNÍ)',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),

              dailyScoresAsync.when(
                data: (scores) => scores.isNotEmpty
                    ? _buildTrendGraph(scores, baselineAsync.value?.averageScore)
                    : _buildNoDataCard('Zatím nemáš dostatek dat pro graf'),
                loading: () => _buildLoadingCard(),
                error: (_, _) => _buildErrorCard('Chyba při načítání trendu'),
              ),

              const SizedBox(height: 24),

              // History list
              Text(
                'HISTORIE TESTŮ',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),

              historyAsync.when(
                data: (tests) => tests.isNotEmpty
                    ? _buildHistoryList(tests, baselineAsync.value?.averageScore)
                    : _buildNoDataCard('Zatím nemáš žádné testy'),
                loading: () => _buildLoadingCard(),
                error: (_, _) => _buildErrorCard('Chyba při načítání historie'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBaselineCard(CognitiveBaseline baseline) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withAlpha(30),
            AppColors.accent.withAlpha(15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withAlpha(80),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: AppColors.accent, size: 28),
              const SizedBox(width: 12),
              Text(
                'Tvůj Baseline',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBaselineStat(
                  'Score',
                  '${baseline.averageScore}/100',
                  Icons.analytics,
                ),
              ),
              Expanded(
                child: _buildBaselineStat(
                  'Reakce',
                  '${baseline.averageReactionMs}ms',
                  Icons.flash_on,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBaselineStat(
                  'Paměť',
                  '${(baseline.averageMemoryAccuracy * 100).round()}%',
                  Icons.memory,
                ),
              ),
              Expanded(
                child: _buildBaselineStat(
                  'Vzory',
                  '${(baseline.averagePatternAccuracy * 100).round()}%',
                  Icons.pattern,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Vypočítáno z posledních ${baseline.totalTests > 7 ? 7 : baseline.totalTests} testů',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaselineStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard(CognitiveStreakStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.functionalBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department,
                        color: stats.currentStreak > 0 ? Colors.orange : AppColors.textMuted,
                        size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Aktuální streak',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${stats.currentStreak} ${_getDayLabel(stats.currentStreak)}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.functionalBorder,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events,
                        color: AppColors.accent,
                        size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Nejdelší',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${stats.longestStreak} ${_getDayLabel(stats.longestStreak)}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(int count) {
    if (count == 1) return 'den';
    if (count >= 2 && count <= 4) return 'dny';
    return 'dní';
  }

  Widget _buildTrendGraph(List<DailyScore> scores, int? baseline) {
    if (scores.isEmpty) {
      return _buildNoDataCard('Zatím nemáš dostatek dat');
    }

    final maxScore = scores.map((s) => s.averageScore).reduce((a, b) => a > b ? a : b);
    final minScore = scores.map((s) => s.averageScore).reduce((a, b) => a < b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.functionalBorder,
          width: 1,
        ),
      ),
      child: CustomPaint(
        painter: _TrendGraphPainter(
          scores: scores,
          baseline: baseline,
          maxScore: maxScore,
          minScore: minScore,
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildHistoryList(List<CognitiveTestResult> tests, int? baseline) {
    return Column(
      children: tests.map((test) => _buildHistoryItem(test, baseline)).toList(),
    );
  }

  Widget _buildHistoryItem(CognitiveTestResult test, int? baseline) {
    final diff = baseline != null ? test.totalScore - baseline : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('d.M.').format(test.timestamp),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                DateFormat('HH:mm').format(test.timestamp),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Score
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.status.label,
                  style: TextStyle(
                    color: _getStatusColor(test.status),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${test.totalScore}',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    if (diff != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        diff >= 0 ? '+$diff' : '$diff',
                        style: TextStyle(
                          color: diff >= 0 ? AppColors.success : AppColors.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Mini scores
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildMiniScore(Icons.flash_on, test.reactionTime.score),
              const SizedBox(height: 4),
              _buildMiniScore(Icons.memory, test.memoryFlash.score),
              const SizedBox(height: 4),
              _buildMiniScore(Icons.pattern, test.patternRecognition.score),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScore(IconData icon, int score) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          '$score',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNoBaselineCard() {
    return _buildNoDataCard('Proveď alespoň 1 test pro vytvoření baseline');
  }

  Widget _buildNoDataCard(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.functionalBorder,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withAlpha(80),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CognitiveStatus status) {
    switch (status) {
      case CognitiveStatus.sharp:
        return const Color(0xFF4CAF50);
      case CognitiveStatus.normal:
        return AppColors.accent;
      case CognitiveStatus.tired:
        return const Color(0xFFFFA726);
      case CognitiveStatus.blurry:
        return const Color(0xFFFF9800);
      case CognitiveStatus.overloaded:
        return const Color(0xFFF44336);
    }
  }
}

/// Custom painter pro trend graf
class _TrendGraphPainter extends CustomPainter {
  final List<DailyScore> scores;
  final int? baseline;
  final int maxScore;
  final int minScore;

  _TrendGraphPainter({
    required this.scores,
    required this.baseline,
    required this.maxScore,
    required this.minScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    // Draw baseline line if exists
    if (baseline != null) {
      final baselinePaint = Paint()
        ..color = AppColors.textMuted.withAlpha(80)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      final baselineY = size.height -
          ((baseline! - minScore) / (maxScore - minScore)) * size.height;

      canvas.drawLine(
        Offset(0, baselineY),
        Offset(size.width, baselineY),
        baselinePaint,
      );
    }

    // Draw line graph
    final path = Path();
    for (var i = 0; i < scores.length; i++) {
      final x = (i / (scores.length - 1)) * size.width;
      final y = size.height -
          ((scores[i].averageScore - minScore) / (maxScore - minScore)) *
              size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
