import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../models/consumption_model.dart';
import '../../providers/consumption_provider.dart';
import '../../services/consumption_service.dart';

/// Personal science dashboard - insights o tvých strain preferences
class InsightsDashboardScreen extends ConsumerWidget {
  const InsightsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(consumptionInsightsProvider);
    final topStrainsAsync = ref.watch(topStrainsProvider);
    final worstStrainsAsync = ref.watch(worstStrainsProvider);
    final statsAsync = ref.watch(consumptionStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        title: const Text('Plant → Mind Insights'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Navigate to consumption history
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'PERSONAL SCIENCE',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tvoje individuální korelace mezi strainy a efekty',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            // Stats overview
            statsAsync.when(
              data: (stats) => _buildStatsCard(stats),
              loading: () => _buildStatsCardLoading(),
              error: (e, st) => _buildStatsCardError(),
            ),

            const SizedBox(height: 24),

            // Active insights
            Text(
              'ACTIVE INSIGHTS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),

            // TODO: Replace with real data
            _buildInsightCard(
              type: InsightType.bestMatch,
              title: 'Nejlepší strain pro tebe',
              description: 'Na základě 5× užití má Blue Dream u tebe rating 8.5/10',
              icon: Icons.star,
              color: const Color(0xFF4CAF50),
              confidence: 0.9,
            ),
            const SizedBox(height: 12),
            _buildInsightCard(
              type: InsightType.terpeneSensitivity,
              title: 'Pozor na anxiety',
              description: '2 strainy u tebe zvyšují anxiety (průměr 7.2/10)',
              icon: Icons.warning,
              color: const Color(0xFFFFA726),
              confidence: 0.85,
            ),
            const SizedBox(height: 12),
            _buildInsightCard(
              type: InsightType.toleranceWarning,
              title: 'Tolerance build-up',
              description: 'Efekty Blue Dream klesají při denním užívání',
              icon: Icons.trending_down,
              color: const Color(0xFF00ACC1),
              confidence: 0.75,
            ),

            const SizedBox(height: 24),

            // Top strains
            Text(
              'TOP STRAINS PRO TEBE',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),

            // TODO: Replace with real data
            _buildStrainRankCard(
              rank: 1,
              strainName: 'Blue Dream',
              rating: 8.5,
              consumptions: 5,
              effects: 'High focus, calm mood, zero anxiety',
            ),
            const SizedBox(height: 8),
            _buildStrainRankCard(
              rank: 2,
              strainName: 'Green Crack',
              rating: 8.2,
              consumptions: 3,
              effects: 'Energy boost, creativity, mild anxiety',
            ),
            const SizedBox(height: 8),
            _buildStrainRankCard(
              rank: 3,
              strainName: 'Northern Lights',
              rating: 7.8,
              consumptions: 4,
              effects: 'Relaxed, sleepy, good mood',
            ),

            const SizedBox(height: 24),

            // Worst strains (avoid)
            Text(
              'AVOID THESE',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),

            // TODO: Replace with real data
            _buildAvoidStrainCard(
              strainName: 'Durban Poison',
              rating: 4.2,
              consumptions: 2,
              reason: 'High anxiety (8/10), racing thoughts',
            ),

            const SizedBox(height: 24),

            // CTA
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.push('/consumption/log'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '+ Log New Consumption',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Data privacy note
            Container(
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
                  Icon(
                    Icons.lock,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tvoje data jsou 100% private. Nikdo kromě tebe je nevidí.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
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

  Widget _buildStatsCard(ConsumptionStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withAlpha(20),
            AppColors.accent.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withAlpha(60),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatItem(
                label: 'Total Sessions',
                value: '${stats.totalConsumptions}',
                icon: Icons.grass,
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                label: 'Strains Tried',
                value: '${stats.uniqueStrains}',
                icon: Icons.science,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                label: 'Check Rate',
                value: '${(stats.checkCompletionRate * 100).toInt()}%',
                icon: Icons.check_circle,
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                label: 'Top Rating',
                value: stats.topStrainRating != null
                    ? stats.topStrainRating!.toStringAsFixed(1)
                    : 'N/A',
                icon: Icons.star,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCardLoading() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withAlpha(20),
            AppColors.accent.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withAlpha(60),
          width: 1,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildStatsCardError() {
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
      child: Text(
        'No data yet. Start logging your consumption!',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.accent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required InsightType type,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required double confidence,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(80),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(confidence * 100).toInt()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrainRankCard({
    required int rank,
    required String strainName,
    required double rating,
    required int consumptions,
    required String effects,
  }) {
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
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: rank == 1
                    ? [const Color(0xFFFFD700), const Color(0xFFFFB300)]
                    : rank == 2
                        ? [const Color(0xFFC0C0C0), const Color(0xFFA0A0A0)]
                        : [const Color(0xFFCD7F32), const Color(0xFFB87333)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      strainName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.star, color: AppColors.accent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  effects,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$consumptions× užito',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvoidStrainCard({
    required String strainName,
    required double rating,
    required int consumptions,
    required String reason,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withAlpha(80),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: AppColors.error,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      strainName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '/10',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$consumptions× užito',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
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
