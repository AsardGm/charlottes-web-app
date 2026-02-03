import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../widgets/common/animated_widgets.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../services/tbreak_service.dart';
import '../../services/consumption_service.dart';
import '../../services/charlotte_ai_service.dart';
import '../../models/tolerance_break_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

/// Personalized Dashboard Screen - Central hub for user's journey
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _tbreakService = TBreakService();
  late final _consumptionService = ConsumptionService(Supabase.instance.client);
  final _charlotteService = CharlotteAIService();

  bool _isLoading = true;
  ToleranceBreak? _activeBreak;
  Map<String, dynamic>? _todayStats;
  String? _charlotteTip;
  Map<String, dynamic>? _harmReductionAlert;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Load all dashboard data in parallel
      final results = await Future.wait([
        _tbreakService.getActiveToleranceBreak(userId),
        _consumptionService.getTodayStats(userId),
        _charlotteService.getDailyTip(userId),
        _charlotteService.analyzeHarmReductionNeeds(userId),
      ]);

      setState(() {
        _activeBreak = results[0] as ToleranceBreak?;
        _todayStats = results[1] as Map<String, dynamic>;
        _charlotteTip = results[2] as String;
        _harmReductionAlert = results[3] as Map<String, dynamic>;
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
        onRefresh: _loadDashboardData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _isLoading
                  ? _buildLoadingState()
                  : _buildDashboardContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final hour = DateTime.now().hour;
    String greeting = 'Dobré ráno';
    if (hour >= 12 && hour < 18) {
      greeting = 'Dobré odpoledne';
    } else if (hour >= 18) {
      greeting = 'Dobrý večer';
    }

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.surface,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          greeting,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.push('/notifications'),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SliverList(
      delegate: SliverChildListDelegate([
        const ShimmerCard(height: 180),
        const SizedBox(height: 16),
        const ShimmerCard(height: 120),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: const ShimmerCard(height: 100)),
            const SizedBox(width: 12),
            Expanded(child: const ShimmerCard(height: 100)),
          ],
        ),
      ]),
    );
  }

  Widget _buildDashboardContent() {
    return SliverList(
      delegate: SliverChildListDelegate([
        // Harm Reduction Alert (if any)
        if (_harmReductionAlert?['severity'] == 'high') ...[
          RevealAnimation(
            child: _HarmReductionAlertWidget(alert: _harmReductionAlert!),
          ),
          const SizedBox(height: 16),
        ],

        // Active T-Break Widget
        if (_activeBreak != null) ...[
          RevealAnimation(
            delay: const Duration(milliseconds: 50),
            child: _TBreakProgressWidget(tbreak: _activeBreak!),
          ),
          const SizedBox(height: 16),
        ],

        // Today's Stats Widget
        RevealAnimation(
          delay: Duration(milliseconds: _activeBreak != null ? 100 : 50),
          child: _TodayStatsWidget(stats: _todayStats ?? {}),
        ),
        const SizedBox(height: 16),

        // Charlotte's Daily Tip
        if (_charlotteTip != null) ...[
          RevealAnimation(
            delay: Duration(milliseconds: _activeBreak != null ? 150 : 100),
            child: _CharlotteTipWidget(tip: _charlotteTip!),
          ),
          const SizedBox(height: 16),
        ],

        // Quick Actions
        RevealAnimation(
          delay: Duration(milliseconds: _activeBreak != null ? 200 : 150),
          child: _QuickActionsWidget(),
        ),
        const SizedBox(height: 16),

        // Recent Activity
        RevealAnimation(
          delay: Duration(milliseconds: _activeBreak != null ? 250 : 200),
          child: _RecentActivityWidget(),
        ),
      ]),
    );
  }
}

/// T-Break Progress Widget with animated progress ring
class _TBreakProgressWidget extends StatelessWidget {
  final ToleranceBreak tbreak;

  const _TBreakProgressWidget({required this.tbreak});

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: () => context.push('/tbreak'),
      enableGlow: true,
      glowColor: const Color(0xFF66BB6A),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A4A1A), Color(0xFF0D2A0D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Animated Progress Ring
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: tbreak.progressPercentage / 100),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(100, 100),
                        painter: _ProgressRingPainter(
                          progress: value,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          progressColor: const Color(0xFF66BB6A),
                          strokeWidth: 8,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${tbreak.daysCompleted}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'dní',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 20),
            // T-Break Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aktivní T-Break',
                    style: TextStyle(
                      color: Color(0xFF66BB6A),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tbreak.daysRemaining} dní zbývá',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedProgressBar(
                    value: tbreak.progressPercentage / 100,
                    height: 6,
                    color: const Color(0xFF66BB6A),
                    duration: const Duration(milliseconds: 1500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tbreak.getEncouragementMessage(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
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

/// Custom painter for progress ring
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Today's Stats Widget
class _TodayStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _TodayStatsWidget({required this.stats});

  @override
  Widget build(BuildContext context) {
    final sessions = stats['sessions'] ?? 0;
    final lastSession = stats['last_session'] as DateTime?;
    final hasLogged = sessions > 0;

    return AnimatedCard(
      onTap: () => context.push('/consumption/insights'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Dnes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.event_available,
                    label: 'Sezení',
                    value: '$sessions',
                    color: hasLogged ? AppColors.primary : Colors.grey,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.1),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.schedule,
                    label: 'Poslední',
                    value: lastSession != null
                        ? _formatTime(lastSession)
                        : '-',
                    color: hasLogged ? AppColors.accent : Colors.grey,
                  ),
                ),
              ],
            ),
            if (!hasLogged) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nezapomeň zaznamenat svou konzumaci',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return 'před ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'před ${diff.inHours}h';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Charlotte's Daily Tip Widget
class _CharlotteTipWidget extends StatelessWidget {
  final String tip;

  const _CharlotteTipWidget({required this.tip});

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: () => context.push('/charlotte'),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withOpacity(0.2),
              AppColors.accent.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.lightbulb_outline,
                color: AppColors.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Charlotte\'s tip',
                    style: TextStyle(
                      color: Color(0xFFFFB74D),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
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

/// Harm Reduction Alert Widget
class _HarmReductionAlertWidget extends StatelessWidget {
  final Map<String, dynamic> alert;

  const _HarmReductionAlertWidget({required this.alert});

  @override
  Widget build(BuildContext context) {
    return GlowingContainer(
      glowColor: const Color(0xFFFF9800),
      glowRadius: 15,
      duration: const Duration(milliseconds: 2000),
      child: AnimatedCard(
        onTap: () => context.push('/harm-reduction'),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A2C00), Color(0xFF2D1A00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFF9800).withOpacity(0.5),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF9800),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Doporučení',
                      style: TextStyle(
                        color: Color(0xFFFF9800),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (alert['recommendations'] as List).first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFFFF9800),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick Actions Widget
class _QuickActionsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rychlé akce',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_circle_outline,
                label: 'Zaznamenat',
                color: AppColors.primary,
                onTap: () => context.push('/consumption/log'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.psychology_outlined,
                label: 'Test',
                color: const Color(0xFF2196F3),
                onTap: () => context.push('/quantum'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.check_circle_outline,
                label: 'Check-in',
                color: const Color(0xFF66BB6A),
                onTap: () => context.push('/checkin'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.color.withOpacity(0.3),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(
                    widget.icon,
                    color: widget.color,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Recent Activity Widget
class _RecentActivityWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Poslední aktivita',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/consumption/insights'),
              child: Text(
                'Zobrazit vše',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedCard(
          onTap: () => context.push('/consumption/insights'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.timeline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Přehled konzumace',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sleduj svůj pokrok a vzorce',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.3),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
