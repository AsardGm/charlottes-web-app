import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/cognitive_insights_service.dart';
import '../../models/cognitive_insights_model.dart';

/// Provider for cognitive insights
final cognitiveInsightsProvider = FutureProvider<CognitiveInsights>((ref) async {
  final user = await ref.read(currentUserProvider.future);
  if (user == null) return CognitiveInsights.empty;

  final service = CognitiveInsightsService();
  return await service.generateInsights(user.id);
});

/// Comprehensive Cognitive Insights Dashboard
class CognitiveInsightsDashboard extends ConsumerWidget {
  const CognitiveInsightsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(cognitiveInsightsProvider);

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: const Color(0xFF0A1628),
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0A1628),
                      Color(0xFF1A2C4E),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF00ACC1).withValues(alpha: 0.3),
                                    const Color(0xFF00ACC1).withValues(alpha: 0.1),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFF00ACC1),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.insights,
                                color: Color(0xFF00ACC1),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cognitive Insights',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Tvoje Brain Performance',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF00ACC1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          insightsAsync.when(
            data: (insights) => _buildContent(context, insights),
            loading: () => SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFF00ACC1),
                ),
              ),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Chyba načítání dat',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, CognitiveInsights insights) {
    if (insights.totalTests == 0) {
      return _buildEmptyState(context);
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Score Card
            _CurrentScoreCard(insights: insights),

            const SizedBox(height: 16),

            // Trend Card
            _TrendCard(insights: insights),

            const SizedBox(height: 16),

            // Test Breakdown
            if (insights.currentScore != null) ...[
              const Text(
                'Breakdown Výkonu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _PerformanceLevelCard(insights: insights),
              const SizedBox(height: 16),
            ],

            // Consumption Correlation
            if (insights.hasConsumptionCorrelation) ...[
              const Text(
                'Korelace s Konzumací',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _ConsumptionCorrelationCard(insights: insights),
              const SizedBox(height: 16),
            ],

            // Time Patterns
            if (insights.scoresByTimeOfDay.isNotEmpty) ...[
              const Text(
                'Denní Vzorce',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _TimePatternCard(insights: insights),
              const SizedBox(height: 16),
            ],

            // Warnings
            if (insights.warnings.isNotEmpty) ...[
              const Text(
                'Upozornění',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ...insights.warnings.map((warning) => _WarningCard(warning: warning)),
              const SizedBox(height: 16),
            ],

            // Recommendations
            _RecommendationsCard(insights: insights),

            const SizedBox(height: 16),

            // Quick Actions
            _QuickActionsRow(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SliverFillRemaining(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00ACC1).withValues(alpha: 0.2),
                    const Color(0xFF00ACC1).withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: const Icon(
                Icons.psychology_outlined,
                size: 60,
                color: Color(0xFF00ACC1),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Zatím žádné testy',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Začni s QUANTUM testy, abys viděl své cognitive insights',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/quantum'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ACC1),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Začít Testování',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
}

/// Current Score Card
class _CurrentScoreCard extends StatelessWidget {
  final CognitiveInsights insights;

  const _CurrentScoreCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final score = insights.currentScore ?? insights.averageScore ?? 0;
    final hasBaseline = insights.baselineScore != null && insights.currentScore != null;
    final change = hasBaseline ? insights.currentScore! - insights.baselineScore! : null;

    Color scoreColor;
    if (score >= 80) {
      scoreColor = Colors.green;
    } else if (score >= 60) {
      scoreColor = Colors.lightGreen;
    } else if (score >= 40) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00ACC1).withValues(alpha: 0.2),
            const Color(0xFF00ACC1).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00ACC1).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Aktuální Skóre',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
              const Text(
                '/100',
                style: TextStyle(
                  fontSize: 24,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (change != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  change >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: change >= 0 ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} od baseline',
                  style: TextStyle(
                    fontSize: 13,
                    color: change >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniStat(
                label: 'Celkem Testů',
                value: '${insights.totalTests}',
              ),
              Container(
                width: 1,
                height: 30,
                color: AppColors.functionalBorder,
              ),
              _MiniStat(
                label: 'Tento Týden',
                value: '${insights.last7DaysTests}',
              ),
              Container(
                width: 1,
                height: 30,
                color: AppColors.functionalBorder,
              ),
              _MiniStat(
                label: 'Level',
                value: insights.performanceLevel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Trend Card
class _TrendCard extends StatelessWidget {
  final CognitiveInsights insights;

  const _TrendCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    Color trendColor;
    IconData trendIcon;

    switch (insights.trend) {
      case CognitiveTrend.improving:
        trendColor = Colors.green;
        trendIcon = Icons.trending_up;
        break;
      case CognitiveTrend.stable:
        trendColor = Colors.blue;
        trendIcon = Icons.trending_flat;
        break;
      case CognitiveTrend.declining:
        trendColor = Colors.red;
        trendIcon = Icons.trending_down;
        break;
      case CognitiveTrend.insufficient:
        trendColor = Colors.grey;
        trendIcon = Icons.help_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: trendColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              trendIcon,
              color: trendColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insights.trend.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (insights.trendPercentage != null)
                  Text(
                    '${insights.trendPercentage! >= 0 ? '+' : ''}${insights.trendPercentage!.toStringAsFixed(1)}% změna',
                    style: TextStyle(
                      fontSize: 13,
                      color: trendColor,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            insights.trend.emoji,
            style: const TextStyle(fontSize: 32),
          ),
        ],
      ),
    );
  }
}

/// Performance Level Card
class _PerformanceLevelCard extends StatelessWidget {
  final CognitiveInsights insights;

  const _PerformanceLevelCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final score = insights.currentScore!;
    final levels = [
      {'min': 0.0, 'max': 40.0, 'label': 'Poor', 'color': Colors.red},
      {'min': 40.0, 'max': 60.0, 'label': 'Below Average', 'color': Colors.orange},
      {'min': 60.0, 'max': 70.0, 'label': 'Average', 'color': Colors.yellow},
      {'min': 70.0, 'max': 80.0, 'label': 'Good', 'color': Colors.lightGreen},
      {'min': 80.0, 'max': 100.0, 'label': 'Excellent', 'color': Colors.green},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ...levels.map((level) {
            final min = level['min'] as double;
            final max = level['max'] as double;
            final isActive = score >= min && score <= max;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? (level['color'] as Color).withValues(alpha: 0.2)
                          : AppColors.functionalBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isActive
                            ? level['color'] as Color
                            : AppColors.functionalBorder,
                      ),
                    ),
                    child: Text(
                      level['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? level['color'] as Color : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.functionalBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        if (isActive)
                          FractionallySizedBox(
                            widthFactor: (score - min) / (max - min),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: level['color'] as Color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${min.toInt()}-${max.toInt()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? level['color'] as Color : AppColors.textMuted,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Consumption Correlation Card
class _ConsumptionCorrelationCard extends StatelessWidget {
  final CognitiveInsights insights;

  const _ConsumptionCorrelationCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final impact = insights.averageScoreAfterConsumption! -
        insights.averageScoreWithoutConsumption!;
    final isPositive = impact > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isPositive ? Colors.green : Colors.orange).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Po Konzumaci',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insights.averageScoreAfterConsumption!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? Colors.green : Colors.orange,
                size: 32,
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Bez Konzumace',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insights.averageScoreWithoutConsumption!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : Colors.orange).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isPositive ? Icons.check_circle : Icons.warning,
                  color: isPositive ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPositive
                        ? 'Pozitivní vliv: +${impact.toStringAsFixed(1)} bodů'
                        : 'Negativní vliv: ${impact.toStringAsFixed(1)} bodů',
                    style: TextStyle(
                      fontSize: 13,
                      color: isPositive ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Time Pattern Card
class _TimePatternCard extends StatelessWidget {
  final CognitiveInsights insights;

  const _TimePatternCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final timeLabels = {
      'morning': 'Ráno',
      'afternoon': 'Odpoledne',
      'evening': 'Večer',
      'night': 'Noc',
    };

    final maxScore = insights.scoresByTimeOfDay.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Výkon během Dne',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...timeLabels.entries.map((entry) {
            final score = insights.scoresByTimeOfDay[entry.key] ?? 0;
            final isBest = score == maxScore && score > 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 13,
                        color: isBest ? const Color(0xFF00ACC1) : AppColors.textSecondary,
                        fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.functionalBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        if (score > 0)
                          FractionallySizedBox(
                            widthFactor: score / 100,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: isBest ? const Color(0xFF00ACC1) : Colors.blue.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 40,
                    child: Text(
                      score > 0 ? score.toStringAsFixed(0) : '-',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isBest ? const Color(0xFF00ACC1) : Colors.white,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Warning Card
class _WarningCard extends StatelessWidget {
  final String warning;

  const _WarningCard({required this.warning});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              warning,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.orange,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recommendations Card
class _RecommendationsCard extends StatelessWidget {
  final CognitiveInsights insights;

  const _RecommendationsCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final recommendations = insights.generateRecommendations();

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Doporučení',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00ACC1).withValues(alpha: 0.1),
                const Color(0xFF00ACC1).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00ACC1).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: recommendations.map((rec) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00ACC1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rec,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Quick Actions Row
class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rychlé Akce',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.psychology,
                label: 'QUANTUM Testy',
                color: const Color(0xFF00ACC1),
                onTap: () => context.push('/quantum'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.chat_bubble,
                label: 'Zeptat Charlotte',
                color: AppColors.accent,
                onTap: () => context.push('/charlotte'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
