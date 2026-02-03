import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme.dart';
import '../../services/personal_science_service.dart';
import '../../models/personal_science_model.dart';
import '../../widgets/common/shimmer_loading.dart';

/// Personal Science Dashboard - Advanced analytics and correlations
class PersonalScienceDashboard extends ConsumerStatefulWidget {
  const PersonalScienceDashboard({super.key});

  @override
  ConsumerState<PersonalScienceDashboard> createState() =>
      _PersonalScienceDashboardState();
}

class _PersonalScienceDashboardState
    extends ConsumerState<PersonalScienceDashboard> {
  final _scienceService = PersonalScienceService();

  bool _isLoading = true;
  List<StrainEffect> _topStrains = [];
  ConsumptionPattern? _pattern;
  List<CorrelationInsight> _correlations = [];
  List<StrainRecommendation> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Load all data in parallel
      final results = await Future.wait([
        _scienceService.getTopStrains(userId, limit: 5),
        _scienceService.getConsumptionPattern(userId),
        _scienceService.getCorrelationInsights(userId),
        _scienceService.getStrainRecommendations(userId, limit: 5),
      ]);

      setState(() {
        _topStrains = results[0] as List<StrainEffect>;
        _pattern = results[1] as ConsumptionPattern?;
        _correlations = results[2] as List<CorrelationInsight>;
        _recommendations = results[3] as List<StrainRecommendation>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba při načítání: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            if (_isLoading)
              _buildLoadingState()
            else ...[
              _buildOverviewSection(),
              _buildTopStrainsSection(),
              if (_pattern != null) _buildPatternsSection(),
              if (_correlations.isNotEmpty) _buildCorrelationsSection(),
              if (_recommendations.isNotEmpty) _buildRecommendationsSection(),
              if (_topStrains.isEmpty && _pattern == null)
                _buildEmptyState(),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.surface,
      flexibleSpace: FlexibleSpaceBar(
        title: const Row(
          children: [
            Icon(Icons.science, size: 24),
            SizedBox(width: 8),
            Text(
              'Personal Science',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            _showInfoDialog();
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const ShimmerCard(height: 150),
          const SizedBox(height: 16),
          const ShimmerCard(height: 200),
          const SizedBox(height: 16),
          const ShimmerCard(height: 180),
        ]),
      ),
    );
  }

  Widget _buildOverviewSection() {
    final sessionsCount = _topStrains.fold<int>(
      0,
      (sum, effect) => sum + effect.totalSessions,
    );

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: AppColors.accent, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Tvoje Data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatChip(
                    label: 'Sessions',
                    value: sessionsCount.toString(),
                    icon: Icons.event_note,
                  ),
                  _buildStatChip(
                    label: 'Strains',
                    value: _topStrains.length.toString(),
                    icon: Icons.grass,
                  ),
                  _buildStatChip(
                    label: 'Insights',
                    value: _correlations.length.toString(),
                    icon: Icons.lightbulb,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.accent, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildTopStrainsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Performing Strains',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full strain effects list
                  },
                  child: Text(
                    'Zobrazit vše',
                    style: TextStyle(color: AppColors.accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._topStrains.map((effect) => _buildStrainEffectCard(effect)),
          ],
        ),
      ),
    );
  }

  Widget _buildStrainEffectCard(StrainEffect effect) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_florist,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      effect.strainName ?? 'Unknown Strain',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${effect.totalSessions} sessions',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      effect.effectivenessScore.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEffectBar(
                  label: 'Mood',
                  value: effect.moodBoost,
                  icon: Icons.mood,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEffectBar(
                  label: 'Focus',
                  value: effect.focusChange,
                  icon: Icons.center_focus_strong,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEffectBar(
                  label: 'Energy',
                  value: effect.energyChange,
                  icon: Icons.bolt,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEffectBar({
    required String label,
    required double value,
    required IconData icon,
  }) {
    final normalized = (value / 10).clamp(0.0, 1.0);
    final isPositive = value > 0;

    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: isPositive ? AppColors.success : AppColors.error,
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.functionalBorder,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: normalized,
            child: Container(
              decoration: BoxDecoration(
                color: isPositive ? AppColors.success : AppColors.error,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildPatternsSection() {
    if (_pattern == null) return const SliverToBoxAdapter();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consumption Patterns',
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (_pattern!.bestTimeOfDay.isNotEmpty) ...[
                    _buildPatternRow(
                      icon: Icons.wb_sunny,
                      label: 'Best Time',
                      value: _pattern!.bestTimeOfDay.join(', '),
                      color: AppColors.success,
                    ),
                    const Divider(height: 24),
                  ],
                  if (_pattern!.bestDayOfWeek.isNotEmpty) ...[
                    _buildPatternRow(
                      icon: Icons.calendar_today,
                      label: 'Best Days',
                      value: _pattern!.bestDayOfWeek.map(_capitalize).join(', '),
                      color: AppColors.primary,
                    ),
                    const Divider(height: 24),
                  ],
                  _buildPatternRow(
                    icon: Icons.analytics,
                    label: 'Confidence',
                    value: '${(_pattern!.confidence * 100).toStringAsFixed(0)}%',
                    color: _pattern!.isHighConfidence
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  if (!_pattern!.hasEnoughData) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Needs more data (${_pattern!.basedOnSessions}/10 sessions)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warning,
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
          ],
        ),
      ),
    );
  }

  Widget _buildPatternRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCorrelationsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ..._correlations.take(3).map((insight) => _buildCorrelationCard(insight)),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationCard(CorrelationInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: insight.isSignificant
            ? Border.all(color: AppColors.accent.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                insight.isSignificant ? Icons.verified : Icons.info_outline,
                color: insight.isSignificant ? AppColors.accent : AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight.summary,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (insight.recommendation != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                insight.recommendation!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommended to Try',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ..._recommendations.map((rec) => _buildRecommendationCard(rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(StrainRecommendation rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.grass, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.strainName ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (rec.recommendedFor.isNotEmpty)
                      Text(
                        rec.recommendedFor.join(', '),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${(rec.score * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          if (rec.reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rec.reasons.take(2).map((reason) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.functionalBorder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reason.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.science_outlined,
                size: 64,
                color: AppColors.textMuted.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Not Enough Data Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track at least 10 sessions with post-checks to unlock personal science insights',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/consumption/log'),
                icon: const Icon(Icons.add),
                label: const Text('Log Session'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'About Personal Science',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Personal Science analyzuje tvoje data a hledá korelace mezi:\n\n'
          '• Strains a cognitive performance\n'
          '• Consumption patterns a well-being\n'
          '• Time of day a effectiveness\n\n'
          'Čím víc dat, tím přesnější insights!',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
