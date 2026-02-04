import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme.dart';
import '../../models/brain_heatmap_model.dart';
import '../../services/cognitive_service.dart';
import '../../utils/haptic_utils.dart';

/// Brain Heatmap Over Time - dlouhodobý trend cognitive zdraví
class BrainHeatmapScreen extends ConsumerStatefulWidget {
  const BrainHeatmapScreen({super.key});

  @override
  ConsumerState<BrainHeatmapScreen> createState() => _BrainHeatmapScreenState();
}

class _BrainHeatmapScreenState extends ConsumerState<BrainHeatmapScreen> {
  List<BrainHeatmapData>? _heatmapData;
  List<BrainHealthInsight>? _insights;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        setState(() {
          _error = 'Nejsi přihlášený';
          _isLoading = false;
        });
        return;
      }

      final service = CognitiveService(supabase);

      // Load weekly heatmap data (last 12 weeks)
      final heatmapData = await service.getWeeklyHeatmapData(
        userId: userId,
        weeks: 12,
      );

      // Generate insights
      final insights = service.generateInsights(heatmapData);

      setState(() {
        _heatmapData = heatmapData;
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Chyba při načítání dat: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        title: const Text('Brain Heatmap'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _heatmapData == null || _heatmapData!.isEmpty
                  ? _buildEmptyState()
                  : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 64),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, color: AppColors.textMuted, size: 64),
            const SizedBox(height: 16),
            Text(
              'Zatím nemáš dost dat',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Udělej pár cognitive testů a uvidíš trendy',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Zpět'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Insights
              if (_insights != null && _insights!.isNotEmpty) ...[
                _buildInsightsSection(),
                const SizedBox(height: 24),
              ],

              // Heatmap calendar
              _buildHeatmapSection(),
              const SizedBox(height: 24),

              // Metrics trends
              _buildMetricsTrends(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INSIGHTS',
          style: TextStyle(
            fontFamily: 'MightySpidey',
            fontSize: 18,
            color: AppColors.accent,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ..._insights!.map((insight) => _buildInsightCard(insight)),
      ],
    );
  }

  Widget _buildInsightCard(BrainHealthInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: insight.severity.color.withAlpha(80),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: insight.color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(insight.icon, color: insight.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: TextStyle(
                    color: AppColors.textSecondary,
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

  Widget _buildHeatmapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TÝDENNÍ HEATMAP',
          style: TextStyle(
            fontFamily: 'MightySpidey',
            fontSize: 18,
            color: AppColors.accent,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Barvy ukazují celkové brain health skóre',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        _buildHeatmapGrid(),
        const SizedBox(height: 16),
        _buildHeatmapLegend(),
      ],
    );
  }

  Widget _buildHeatmapGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _heatmapData!.map((data) {
        return InkWell(
          onTap: () {
            HapticUtils.lightImpact();
            _showWeekDetail(data);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: data.heatmapColor.withValues(alpha:data.intensity),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.functionalBorder,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${data.weekStart.day}/${data.weekStart.month}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.healthScore.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeatmapLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Zdravý', const Color(0xFF4CAF50)),
        _buildLegendItem('Varování', const Color(0xFFFFB74D)),
        _buildLegendItem('Pauza', const Color(0xFFEF5350)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
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

  Widget _buildMetricsTrends() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRENDY METRIK',
          style: TextStyle(
            fontFamily: 'MightySpidey',
            fontSize: 18,
            color: AppColors.accent,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        _buildMetricTrendCard(
          'Focus',
          _heatmapData!.map((d) => d.avgFocus).toList(),
          Icons.psychology,
          AppColors.primary,
        ),
        const SizedBox(height: 12),
        _buildMetricTrendCard(
          'Anxiety',
          _heatmapData!.map((d) => d.avgAnxiety).toList(),
          Icons.favorite,
          AppColors.error,
        ),
        const SizedBox(height: 12),
        _buildMetricTrendCard(
          'Creativity',
          _heatmapData!.map((d) => d.avgCreativity).toList(),
          Icons.lightbulb,
          AppColors.gold,
        ),
        const SizedBox(height: 12),
        _buildMetricTrendCard(
          'Mood',
          _heatmapData!.map((d) => d.avgMood).toList(),
          Icons.emoji_emotions,
          AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildMetricTrendCard(
    String title,
    List<double> values,
    IconData icon,
    Color color,
  ) {
    if (values.isEmpty) return const SizedBox.shrink();

    final current = values.last;
    final previous = values.length > 1 ? values[values.length - 2] : current;
    final trend = current > previous
        ? 'up'
        : current < previous
            ? 'down'
            : 'stable';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.functionalBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
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
                  '${current.toStringAsFixed(1)} / 10',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            trend == 'up'
                ? Icons.trending_up
                : trend == 'down'
                    ? Icons.trending_down
                    : Icons.trending_flat,
            color: trend == 'up'
                ? AppColors.success
                : trend == 'down'
                    ? AppColors.error
                    : AppColors.textMuted,
            size: 24,
          ),
        ],
      ),
    );
  }

  void _showWeekDetail(BrainHeatmapData data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.functionalSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Týden ${data.weekStart.day}/${data.weekStart.month}',
                  style: TextStyle(
                    fontFamily: 'MightySpidey',
                    fontSize: 20,
                    color: AppColors.accent,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: data.heatmapColor.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data.healthScore.toStringAsFixed(1),
                    style: TextStyle(
                      color: data.heatmapColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailMetric('Focus', data.avgFocus, data.focusTrend),
            const SizedBox(height: 12),
            _buildDetailMetric('Anxiety', data.avgAnxiety, data.anxietyTrend),
            const SizedBox(height: 12),
            _buildDetailMetric('Creativity', data.avgCreativity, null),
            const SizedBox(height: 12),
            _buildDetailMetric('Mood', data.avgMood, null),
            const SizedBox(height: 16),
            Text(
              '${data.testCount} testů tento týden',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            if (data.needsBreak) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tento týden ukazuje, že potřebuješ pauzu',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildDetailMetric(
    String label,
    double value,
    TrendDirection? trend,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: value / 10,
                  backgroundColor: AppColors.functionalBorder,
                  color: AppColors.accent,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (trend != null) ...[
                const SizedBox(width: 8),
                Icon(
                  trend.icon,
                  color: trend.color,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
