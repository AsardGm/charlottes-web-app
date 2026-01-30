import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/lab/lab_grow_model.dart';
import '../../providers/lab_provider.dart';
import '../../theme/theme.dart';

/// Hlavni Lab hub obrazovka - cyberpunkovy kokpit pestitele
///
/// Zobrazuje 4 moduly (Chronos, Alchymista, Oci Arasaky, Ghost Protocol)
/// a aktivni grow kartu.
class LabScreen extends ConsumerWidget {
  const LabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGrow = ref.watch(labActiveGrowProvider);

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(context),
          ),

          // Aktivni grow karta
          SliverToBoxAdapter(
            child: activeGrow.when(
              data: (grow) => grow != null
                  ? _buildActiveGrowCard(context, grow)
                  : _buildNoGrowCard(context),
              loading: () => _buildLoadingCard(),
              error: (_, _) => _buildNoGrowCard(context),
            ),
          ),

          // Sekce modulu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  Text(
                    'MODULY',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withAlpha(80),
                            AppColors.accent.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4 moduly grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildListDelegate([
                _ModuleCard(
                  title: 'CHRONOS',
                  subtitle: 'Timeline & Diary',
                  icon: Icons.timeline,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A4B6E), Color(0xFF0D1B2A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  accentColor: AppColors.accent,
                  onTap: () {
                    final grow = activeGrow.value;
                    if (grow != null) {
                      context.push('/lab/chronos/${grow.id}');
                    } else {
                      context.push('/lab/grows');
                    }
                  },
                ),
                _ModuleCard(
                  title: 'ALCHYMISTA',
                  subtitle: 'Nutrients & pH/EC',
                  icon: Icons.science,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D6A2D), Color(0xFF0D2A0D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  accentColor: AppColors.success,
                  onTap: () {
                    final grow = activeGrow.value;
                    if (grow != null) {
                      context.push('/lab/alchymista/${grow.id}');
                    } else {
                      context.push('/lab/grows');
                    }
                  },
                ),
                _ModuleCard(
                  title: 'OCI ARASAKY',
                  subtitle: 'AI Diagnostika',
                  icon: Icons.remove_red_eye,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B1A6E), Color(0xFF2A0D2A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  accentColor: AppColors.rarityExotic,
                  onTap: () {
                    final grow = activeGrow.value;
                    if (grow != null) {
                      context.push('/lab/oci/${grow.id}');
                    } else {
                      context.push('/lab/grows');
                    }
                  },
                ),
                _ModuleCard(
                  title: 'GHOST',
                  subtitle: 'Protocol & Security',
                  icon: Icons.shield,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A1A1A), Color(0xFF1A0D0D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  accentColor: AppColors.primary,
                  onTap: () => context.push('/lab/ghost'),
                ),
                _ModuleCard(
                  title: 'HOLOTROP',
                  subtitle: 'Harm Reduction',
                  icon: Icons.self_improvement,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A3D3D), Color(0xFF0A1628)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  accentColor: const Color(0xFF00BFA5),
                  onTap: () => context.push('/holotrop'),
                ),
              ]),
            ),
          ),

          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text(
                    'RYCHLE AKCE',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withAlpha(80),
                            AppColors.accent.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _QuickActionTile(
                  icon: Icons.add_circle_outline,
                  title: 'Novy Grow',
                  subtitle: 'Zaloz novy pestovaci denik',
                  onTap: () => context.push('/lab/create-grow'),
                ),
                const SizedBox(height: 8),
                _QuickActionTile(
                  icon: Icons.list_alt,
                  title: 'Vsechny Grows',
                  subtitle: 'Prehled vsech growu',
                  onTap: () => context.push('/lab/grows'),
                ),
                const SizedBox(height: 8),
                _QuickActionTile(
                  icon: Icons.restaurant_menu,
                  title: 'Feeding Schedules',
                  subtitle: 'Prednastavene hnojive recepty',
                  onTap: () => context.push('/lab/schedules'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 20,
        16,
        24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface,
            AppColors.surfaceLight,
            AppColors.functionalBg,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Radial glow behind icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withAlpha(40),
                      AppColors.accent.withAlpha(0),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.accent.withAlpha(100),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withAlpha(30),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.biotech,
                  color: AppColors.accent,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'LAB',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: AppColors.accent.withAlpha(20),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 32,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent,
                            AppColors.accent.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pestovaci kokpit',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGrowCard(BuildContext context, LabGrowModel grow) {
    final phaseProgress = _calculatePhaseProgress(grow);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withAlpha(20),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surface,
              AppColors.surfaceLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            width: 1.5,
            color: Colors.transparent,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              width: 1,
              color: AppColors.accent.withAlpha(80),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/lab/chronos/${grow.id}'),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.accent.withAlpha(60),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'AKTIVNI GROW',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Day counter with glow
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.accent.withAlpha(25),
                                AppColors.accent.withAlpha(40),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.accent.withAlpha(100),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withAlpha(40),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            'Den ${grow.dayCount}',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: AppColors.accent.withAlpha(60),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      grow.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (grow.strainName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        grow.strainName!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _PhaseChip(phase: grow.phase),
                        const SizedBox(width: 8),
                        if (grow.environment != null)
                          _InfoChip(
                            icon: Icons.home,
                            label: grow.environment!.label,
                          ),
                        if (grow.medium != null) ...[
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.grass,
                            label: grow.medium!.label,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Phase progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pokrok faze',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '${(phaseProgress * 100).toInt()}%',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.functionalSurface,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: phaseProgress,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.accent,
                              ),
                            ),
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
    );
  }

  double _calculatePhaseProgress(LabGrowModel grow) {
    // Simple progress calculation based on typical phase durations
    final phaseDurations = {
      GrowPhase.germination: 7,
      GrowPhase.seedling: 14,
      GrowPhase.vegetative: 30,
      GrowPhase.flowering: 60,
      GrowPhase.harvest: 1,
      GrowPhase.drying: 7,
      GrowPhase.curing: 14,
      GrowPhase.completed: 1,
    };

    final duration = phaseDurations[grow.phase] ?? 30;
    final progress = (grow.dayCount % duration) / duration;
    return progress.clamp(0.0, 1.0);
  }

  Widget _buildNoGrowCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.functionalBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/lab/create-grow'),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // Double circle radial glow icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.accent.withAlpha(20),
                            AppColors.accent.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                    // Middle circle
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withAlpha(40),
                          width: 1,
                        ),
                      ),
                    ),
                    // Inner circle with icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withAlpha(20),
                        border: Border.all(
                          color: AppColors.accent.withAlpha(80),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.add_circle_outline,
                        color: AppColors.accent,
                        size: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Zadny aktivni grow',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: AppColors.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Klepni pro zalozeni noveho deniku',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 120,
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
}

/// Karta modulu v gridu
class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withAlpha(50),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(15),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative corner triangle
          Positioned(
            bottom: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(16),
              ),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withAlpha(40),
                      accentColor.withAlpha(20),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CustomPaint(
                  painter: _CornerTrianglePainter(accentColor),
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withAlpha(40),
                            accentColor.withAlpha(25),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: accentColor.withAlpha(80),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(icon, color: accentColor, size: 24),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withAlpha(160),
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for corner triangle decoration
class _CornerTrianglePainter extends CustomPainter {
  final Color color;

  _CornerTrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Rychla akce tile
class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.functionalBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.accent.withAlpha(10),
          highlightColor: AppColors.accent.withAlpha(5),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withAlpha(30),
                        AppColors.accent.withAlpha(15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: AppColors.accent.withAlpha(60),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: AppColors.accent.withAlpha(120),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Phase chip widget
class _PhaseChip extends StatelessWidget {
  final GrowPhase phase;

  const _PhaseChip({required this.phase});

  Color get _phaseColor {
    switch (phase) {
      case GrowPhase.germination:
        return const Color(0xFF8B7355);
      case GrowPhase.seedling:
        return const Color(0xFF66BB6A);
      case GrowPhase.vegetative:
        return const Color(0xFF2E7D32);
      case GrowPhase.flowering:
        return const Color(0xFFAB47BC);
      case GrowPhase.harvest:
        return const Color(0xFFFFA726);
      case GrowPhase.drying:
        return const Color(0xFF8D6E63);
      case GrowPhase.curing:
        return const Color(0xFFFFCA28);
      case GrowPhase.completed:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _phaseColor.withAlpha(35),
            _phaseColor.withAlpha(25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _phaseColor.withAlpha(100),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _phaseColor.withAlpha(25),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        '${phase.icon} ${phase.label}',
        style: TextStyle(
          color: _phaseColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Info chip widget
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.functionalBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
