import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/lab/lab_grow_model.dart';
import '../../../models/lab/lab_timeline_model.dart';
import '../../../providers/lab_provider.dart';
import '../../../theme/theme.dart';

/// Chronos Timeline - vertikalni timeline growu
class ChronosTimelineScreen extends ConsumerWidget {
  final String growId;

  const ChronosTimelineScreen({super.key, required this.growId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grow = ref.watch(labGrowByIdProvider(growId));
    final timeline = ref.watch(labTimelineProvider(growId));

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: grow.when(
        data: (growData) {
          if (growData == null) {
            return const Center(child: Text('Grow nenalezen'));
          }
          return CustomScrollView(
            slivers: [
              // Header s info o growu
              SliverToBoxAdapter(
                child: _buildGrowHeader(context, growData),
              ),

              // Phase progress bar
              SliverToBoxAdapter(
                child: _buildPhaseBar(context, ref, growData),
              ),

              // Divider
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.accent.withAlpha(40),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Timeline entries
              timeline.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyTimeline(),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _TimelineEntryCard(
                          entry: entries[index],
                          isFirst: index == 0,
                          isLast: index == entries.length - 1,
                        ),
                        childCount: entries.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(
                    child: Text('Chyba: $e',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => Center(
          child: Text('Chyba: $e', style: TextStyle(color: AppColors.error)),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withAlpha(80),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/lab/chronos/$growId/add'),
          backgroundColor: AppColors.accent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
        ),
      ),
    );
  }

  Widget _buildGrowHeader(BuildContext context, LabGrowModel grow) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.surfaceLight.withAlpha(80),
            AppColors.functionalBg,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back button
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.functionalSurface.withAlpha(180),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.functionalBorder,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 14),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'CHRONOS',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 1,
                          color: AppColors.accent.withAlpha(60),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      grow.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    if (grow.strainName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.eco_outlined,
                              color: AppColors.success.withAlpha(150), size: 14),
                          const SizedBox(width: 5),
                          Text(
                            grow.strainName!,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Day counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withAlpha(20),
                      AppColors.accent.withAlpha(8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.accent.withAlpha(50),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withAlpha(15),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '${grow.dayCount}',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DNI',
                      style: TextStyle(
                        color: AppColors.accent.withAlpha(150),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseBar(BuildContext context, WidgetRef ref, LabGrowModel grow) {
    final phases = GrowPhase.values;
    final currentIndex = grow.phase.index;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress line
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 3,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final progress = (currentIndex + 1) / phases.length;
                return Stack(
                  children: [
                    // Background track
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.functionalBorder.withAlpha(80),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Active progress
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.success,
                              AppColors.accent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withAlpha(40),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Phase chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: phases.asMap().entries.map((entry) {
                final index = entry.key;
                final phase = entry.value;
                final isCurrent = grow.phase == phase;
                final isPast = currentIndex > index;
                final isFuture = currentIndex < index;

                return Padding(
                  padding: EdgeInsets.only(right: index < phases.length - 1 ? 6 : 0),
                  child: GestureDetector(
                    onTap: isCurrent
                        ? null
                        : () => _showPhaseChangeDialog(context, ref, grow, phase),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.accent.withAlpha(25)
                            : isPast
                                ? AppColors.success.withAlpha(12)
                                : AppColors.functionalSurface.withAlpha(120),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.accent
                              : isPast
                                  ? AppColors.success.withAlpha(50)
                                  : AppColors.functionalBorder.withAlpha(100),
                          width: isCurrent ? 1.5 : 1,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.accent.withAlpha(20),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPast) ...[
                            Icon(Icons.check_rounded,
                                color: AppColors.success.withAlpha(180),
                                size: 13),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '${phase.icon} ${phase.label}',
                            style: TextStyle(
                              color: isCurrent
                                  ? AppColors.accent
                                  : isPast
                                      ? AppColors.success.withAlpha(200)
                                      : AppColors.textMuted.withAlpha(isFuture ? 120 : 255),
                              fontSize: 12,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : isPast
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhaseChangeDialog(
    BuildContext context,
    WidgetRef ref,
    LabGrowModel grow,
    GrowPhase newPhase,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.functionalBorder),
        ),
        title: Text(
          'Zmenit fazi?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Zmenit fazi z "${grow.phase.label}" na "${newPhase.label}"?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Zrusit', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(labGrowNotifierProvider.notifier).changePhase(grow.id, newPhase);
              ref.invalidate(labGrowByIdProvider(grow.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Zmenit'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTimeline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          // Glow icon
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withAlpha(15),
                  AppColors.accent.withAlpha(5),
                  Colors.transparent,
                ],
                stops: const [0.3, 0.7, 1.0],
              ),
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.functionalSurface,
                  border: Border.all(
                    color: AppColors.accent.withAlpha(30),
                    width: 1.5,
                  ),
                ),
                child: Icon(Icons.timeline_rounded,
                    size: 32, color: AppColors.accent.withAlpha(120)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Prazdna timeline',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Zacni zaznamenavat svuj grow',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          // CTA hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accent.withAlpha(30),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded,
                    color: AppColors.accent.withAlpha(150), size: 18),
                const SizedBox(width: 10),
                Text(
                  'Klepni na  +  pro prvni zaznam',
                  style: TextStyle(
                    color: AppColors.accent.withAlpha(180),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

/// Karta timeline zaznamu s vertikalni carou
class _TimelineEntryCard extends StatelessWidget {
  final LabTimelineEntryModel entry;
  final bool isFirst;
  final bool isLast;

  const _TimelineEntryCard({
    required this.entry,
    this.isFirst = false,
    this.isLast = false,
  });

  Color get _eventColor {
    switch (entry.eventType) {
      case TimelineEventType.note:
        return AppColors.textSecondary;
      case TimelineEventType.photo:
        return AppColors.accent;
      case TimelineEventType.phaseChange:
        return AppColors.rarityExotic;
      case TimelineEventType.milestone:
        return AppColors.gold;
      case TimelineEventType.water:
        return const Color(0xFF42A5F5);
      case TimelineEventType.feed:
        return AppColors.success;
      case TimelineEventType.transplant:
        return const Color(0xFF8D6E63);
      case TimelineEventType.training:
        return AppColors.warning;
      case TimelineEventType.issue:
        return AppColors.error;
      case TimelineEventType.harvest:
        return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertikalni cara s teckou
          SizedBox(
            width: 44,
            child: Column(
              children: [
                // Horni cara
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.functionalBorder.withAlpha(100),
                            _eventColor.withAlpha(60),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                // Dot with glow
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _eventColor,
                    border: Border.all(
                      color: AppColors.functionalBg,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _eventColor.withAlpha(50),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                // Spodni cara
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _eventColor.withAlpha(60),
                            AppColors.functionalBorder.withAlpha(100),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Obsah
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.functionalSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _eventColor.withAlpha(25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Event icon with bg
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _eventColor.withAlpha(18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            entry.eventType.icon,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.title ?? entry.eventType.label,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _eventColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _eventColor.withAlpha(30),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Den ${entry.dayNumber}',
                          style: TextStyle(
                            color: _eventColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (entry.description != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      entry.description!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (entry.imageUrl != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        entry.imageUrl!,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.functionalBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
