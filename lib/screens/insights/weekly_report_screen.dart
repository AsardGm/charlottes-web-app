import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../models/weekly_insight_model.dart';
import '../../services/weekly_insights_service.dart';
import '../../widgets/common/animated_widgets.dart';
import '../../widgets/common/shimmer_loading.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Weekly Report Screen - Charlotte's AI-generated weekly insights
class WeeklyReportScreen extends ConsumerStatefulWidget {
  final String? insightId;

  const WeeklyReportScreen({super.key, this.insightId});

  @override
  ConsumerState<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen> {
  final _insightsService = WeeklyInsightsService();
  bool _isLoading = true;
  WeeklyInsight? _insight;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInsight();
  }

  Future<void> _loadInsight() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      WeeklyInsight? insight;
      if (widget.insightId != null) {
        // Load specific insight by ID
        final response = await Supabase.instance.client
            .from('weekly_insights')
            .select()
            .eq('id', widget.insightId!)
            .single();
        insight = WeeklyInsight.fromJson(response);
      } else {
        // Load latest unviewed or generate new one
        insight = await _insightsService.getLatestUnviewedInsight(userId);
        insight ??= await _insightsService.generateWeeklyInsight(userId);
      }

      // Mark as viewed
      if (!insight.isViewed) {
        await _insightsService.markAsViewed(insight.id, userId);
      }

      setState(() {
        _insight = insight;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Weekly Report'),
        backgroundColor: AppColors.surface,
        actions: [
          if (_insight != null)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => context.push('/insights/history'),
              tooltip: 'Historie reportů',
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _insight == null
                  ? _buildEmptyState()
                  : _buildReportContent(),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ShimmerCard(height: 120),
        SizedBox(height: 16),
        ShimmerCard(height: 200),
        SizedBox(height: 16),
        ShimmerCard(height: 150),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Chyba při načítání reportu',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Něco se pokazilo',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInsight,
              child: const Text('Zkusit znovu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Žádné insights zatím',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Trackuj svou konzumaci a cognitive testy,\nCharlotte ti vygeneruje weekly report.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    final insight = _insight!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header Card
        RevealAnimation(
          child: _buildHeaderCard(insight),
        ),
        const SizedBox(height: 16),

        // Summary
        if (insight.summary != null) ...[
          RevealAnimation(
            delay: const Duration(milliseconds: 50),
            child: _buildSummaryCard(insight),
          ),
          const SizedBox(height: 16),
        ],

        // Patterns (if any high severity)
        if (insight.patterns.isNotEmpty) ...[
          RevealAnimation(
            delay: const Duration(milliseconds: 100),
            child: _buildPatternsCard(insight),
          ),
          const SizedBox(height: 16),
        ],

        // Insights
        if (insight.insights.isNotEmpty) ...[
          RevealAnimation(
            delay: const Duration(milliseconds: 150),
            child: _buildInsightsCard(insight),
          ),
          const SizedBox(height: 16),
        ],

        // Achievements
        if (insight.achievements.isNotEmpty) ...[
          RevealAnimation(
            delay: const Duration(milliseconds: 200),
            child: _buildAchievementsCard(insight),
          ),
          const SizedBox(height: 16),
        ],

        // Comparison
        if (insight.comparison != null) ...[
          RevealAnimation(
            delay: const Duration(milliseconds: 250),
            child: _buildComparisonCard(insight),
          ),
          const SizedBox(height: 16),
        ],

        // Recommendations
        if (insight.recommendations.isNotEmpty) ...[
          RevealAnimation(
            delay: const Duration(milliseconds: 300),
            child: _buildRecommendationsCard(insight),
          ),
          const SizedBox(height: 16),
        ],

        // Goals Progress
        if (insight.goalsProgress.isNotEmpty) ...[
          RevealAnimation(
            delay: const Duration(milliseconds: 350),
            child: _buildGoalsCard(insight),
          ),
        ],
      ],
    );
  }

  Widget _buildHeaderCard(WeeklyInsight insight) {
    final color = Color(int.parse('0xFF${insight.statusColorHex}'));

    return AnimatedCard(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  insight.statusEmoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Week in Review',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insight.weekRangeString,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(
                  icon: Icons.event_available,
                  label: 'Sessions',
                  value: '${insight.totalSessions}',
                  color: color,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.grass,
                  label: 'Strains',
                  value: '${insight.uniqueStrains}',
                  color: color,
                ),
                if (insight.cognitiveAverage != null) ...[
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.psychology,
                    label: 'Cognitive',
                    value: '${insight.cognitiveAverage!.toStringAsFixed(0)}%',
                    color: color,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(WeeklyInsight insight) {
    return AnimatedCard(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Shrnutí',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight.summary!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternsCard(WeeklyInsight insight) {
    return AnimatedCard(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Color(0xFFFF9800), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Detekované vzorce',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insight.patterns.map((pattern) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PatternItem(pattern: pattern),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard(WeeklyInsight insight) {
    return AnimatedCard(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Color(0xFFFFB74D), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Insights',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insight.insights.map((finding) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InsightItem(finding: finding),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsCard(WeeklyInsight insight) {
    return AnimatedCard(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Úspěchy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insight.achievements.map((achievement) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AchievementItem(achievement: achievement),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(WeeklyInsight insight) {
    final comparison = insight.comparison!;

    return AnimatedCard(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Srovnání s minulým týdnem',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (comparison.sessions != null)
              _ComparisonItem(
                label: 'Sessions',
                comparison: comparison.sessions!,
              ),
            if (comparison.cognitive != null) ...[
              const SizedBox(height: 12),
              _ComparisonItem(
                label: 'Cognitive Score',
                comparison: comparison.cognitive!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(WeeklyInsight insight) {
    return AnimatedCard(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Doporučení',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insight.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecommendationItem(recommendation: rec),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsCard(WeeklyInsight insight) {
    return AnimatedCard(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Pokrok v cílech',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insight.goalsProgress.map((goal) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GoalItem(goal: goal),
                )),
          ],
        ),
      ),
    );
  }
}

// ========== WIDGETS ==========

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PatternItem extends StatelessWidget {
  final InsightPattern pattern;

  const _PatternItem({required this.pattern});

  @override
  Widget build(BuildContext context) {
    Color severityColor;
    switch (pattern.severity) {
      case 'high':
        severityColor = const Color(0xFFFF5252);
        break;
      case 'medium':
        severityColor = const Color(0xFFFF9800);
        break;
      default:
        severityColor = const Color(0xFF2196F3);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severityColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pattern.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (pattern.recommendation != null) ...[
            const SizedBox(height: 4),
            Text(
              '→ ${pattern.recommendation}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final InsightFinding finding;

  const _InsightItem({required this.finding});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                finding.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(finding.confidence * 100).toInt()}%',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          finding.description,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final InsightAchievement achievement;

  const _AchievementItem({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          achievement.icon,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (achievement.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  achievement.description!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ComparisonItem extends StatelessWidget {
  final String label;
  final MetricComparison comparison;

  const _ComparisonItem({
    required this.label,
    required this.comparison,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = comparison.trend == 'up';
    final isDown = comparison.trend == 'down';
    final color = isUp
        ? const Color(0xFF66BB6A)
        : isDown
            ? const Color(0xFFFF5252)
            : Colors.grey;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${comparison.current}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isUp
                    ? Icons.arrow_upward
                    : isDown
                        ? Icons.arrow_downward
                        : Icons.remove,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                comparison.change,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecommendationItem extends StatelessWidget {
  final InsightRecommendation recommendation;

  const _RecommendationItem({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recommendation.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
          if (recommendation.actionLabel != null &&
              recommendation.actionRoute != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push(recommendation.actionRoute!),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              ),
              child: Text(
                recommendation.actionLabel!,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalItem extends StatelessWidget {
  final GoalProgress goal;

  const _GoalItem({required this.goal});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (goal.status) {
      case 'completed':
        statusColor = const Color(0xFF66BB6A);
        break;
      case 'on_track':
        statusColor = const Color(0xFF2196F3);
        break;
      default:
        statusColor = const Color(0xFFFF9800);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                goal.goal,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${(goal.progress * 100).toInt()}%',
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedProgressBar(
          value: goal.progress,
          height: 6,
          color: statusColor,
        ),
      ],
    );
  }
}
