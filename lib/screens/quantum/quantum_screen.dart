import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';

/// QUANTUM - Cognitive Testing Module
/// Comprehensive brain performance testing suite
class QuantumScreen extends ConsumerWidget {
  const QuantumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: const Color(0xFF0A1628),
            expandedHeight: 180,
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
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 80,
                        height: 80,
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
                          Icons.psychology,
                          size: 40,
                          color: Color(0xFF00ACC1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'QUANTUM',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const Text(
                        'Cognitive Testing Suite',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF00ACC1),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Introduction
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.functionalSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00ACC1).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF00ACC1),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'O Testování',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Quantum testuje tvoji cognitive performance pomocí vědecky podložených metod. '
                          'Pravidelné testování ti pomůže trackovat cognitive drift a optimalizovat konzumaci.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tests Grid
                  const Text(
                    'Dostupné Testy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Reaction Time Test
                  _TestCard(
                    title: 'Reaction Time',
                    subtitle: 'Rychlost reakce',
                    description: 'Test tvé reakční doby na vizuální podněty',
                    icon: Icons.flash_on,
                    color: const Color(0xFFFFB74D),
                    duration: '~2 min',
                    difficulty: 'Snadný',
                    onTap: () => context.push('/quantum/reaction-test'),
                  ),

                  const SizedBox(height: 12),

                  // Memory Test
                  _TestCard(
                    title: 'Memory Sequence',
                    subtitle: 'Pracovní paměť',
                    description: 'Test zapamatování a reprodukce sekvencí',
                    icon: Icons.memory,
                    color: const Color(0xFF9575CD),
                    duration: '~3 min',
                    difficulty: 'Střední',
                    onTap: () => context.push('/quantum/memory-test'),
                  ),

                  const SizedBox(height: 12),

                  // Focus Test
                  _TestCard(
                    title: 'Sustained Focus',
                    subtitle: 'Udržení pozornosti',
                    description: 'Test schopnosti udržet pozornost dlouhodobě',
                    icon: Icons.center_focus_strong,
                    color: const Color(0xFF4FC3F7),
                    duration: '~5 min',
                    difficulty: 'Náročný',
                    onTap: () => context.push('/quantum/focus-test'),
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions
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
                        child: _QuickActionButton(
                          icon: Icons.analytics,
                          label: 'Moje Výsledky',
                          onTap: () => context.push('/quantum/results'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.trending_up,
                          label: 'Insights',
                          onTap: () => context.push('/cognitive'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Best Practices
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Color(0xFF00ACC1),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tipy pro Nejlepší Výsledky',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _BestPracticeTile(
                          icon: Icons.schedule,
                          text: 'Testuj se vždy ve stejnou denní dobu',
                        ),
                        _BestPracticeTile(
                          icon: Icons.local_cafe,
                          text: 'Před testem minimalizuj kofein a jiné stimulanty',
                        ),
                        _BestPracticeTile(
                          icon: Icons.phone_disabled,
                          text: 'Minimalizuj rušení a notifikace',
                        ),
                        _BestPracticeTile(
                          icon: Icons.repeat,
                          text: 'Pravidelné testování = přesnější baseline',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Test card widget
class _TestCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final String duration;
  final String difficulty;
  final VoidCallback onTap;

  const _TestCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.duration,
    required this.difficulty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.functionalSurface,
                AppColors.functionalBg,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.timer,
                          label: duration,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.bar_chart,
                          label: difficulty,
                          color: color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Info chip widget
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick action button
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
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
            color: AppColors.functionalSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.functionalBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: const Color(0xFF00ACC1),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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

/// Best practice tile
class _BestPracticeTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BestPracticeTile({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF00ACC1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
