import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/lab/lab_timeline_model.dart';
import '../../../providers/lab_provider.dart';
import '../../../theme/theme.dart';

/// Obrazovka pro pridani noveho timeline zaznamu
class ChronosAddEntryScreen extends ConsumerStatefulWidget {
  final String growId;

  const ChronosAddEntryScreen({super.key, required this.growId});

  @override
  ConsumerState<ChronosAddEntryScreen> createState() =>
      _ChronosAddEntryScreenState();
}

class _ChronosAddEntryScreenState
    extends ConsumerState<ChronosAddEntryScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TimelineEventType _selectedType = TimelineEventType.note;
  MilestoneType? _selectedMilestone;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final grow = ref.read(labGrowByIdProvider(widget.growId)).value;
    if (grow == null) return;

    final result = await ref.read(labTimelineNotifierProvider.notifier).addEntry(
      growId: widget.growId,
      dayNumber: grow.dayCount,
      eventType: _selectedType,
      milestoneType: _selectedType == TimelineEventType.milestone
          ? _selectedMilestone
          : null,
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : null,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      phaseAtTime: grow.phase.name,
    );

    if (result != null && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timelineState = ref.watch(labTimelineNotifierProvider);
    final grow = ref.watch(labGrowByIdProvider(widget.growId));

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: Column(
        children: [
          // Custom header with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface,
                  AppColors.surfaceLight,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.functionalSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.functionalBorder,
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'NOVY ZAZNAM',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent,
                            AppColors.accent.withAlpha(200),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withAlpha(60),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: timelineState.isLoading ? null : _submit,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: timelineState.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.functionalBg,
                                    ),
                                  )
                                : Text(
                                    'ULOZIT',
                                    style: TextStyle(
                                      color: AppColors.functionalBg,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Den info - larger with gradient
                grow.when(
                  data: (g) => g != null
                      ? Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.accent.withAlpha(25),
                                    AppColors.accent.withAlpha(15),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.accent.withAlpha(60),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Den ${g.dayCount}',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withAlpha(40),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.accent,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '${g.phase.icon} ${g.phase.label}',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.accent.withAlpha(100),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox(),
                  loading: () => const SizedBox(),
                  error: (_, _) => const SizedBox(),
                ),
                const SizedBox(height: 24),

                // Typ udalosti
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Typ zaznamu',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: TimelineEventType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent.withAlpha(30)
                              : AppColors.functionalSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.functionalBorder,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.accent.withAlpha(40),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accent.withAlpha(80)
                                    : AppColors.functionalBorder.withAlpha(100),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  type.icon,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              type.label,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Milestone type (jen pokud je typ milestone)
                if (_selectedType == TimelineEventType.milestone) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        color: AppColors.gold,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Typ milniku',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: MilestoneType.values.map((milestone) {
                      final isSelected = _selectedMilestone == milestone;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedMilestone = milestone),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      AppColors.gold.withAlpha(40),
                                      AppColors.gold.withAlpha(25),
                                    ],
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : AppColors.functionalSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.gold
                                  : AppColors.functionalBorder,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.gold.withAlpha(40),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            milestone.label,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.gold
                                  : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Titulek
                Row(
                  children: [
                    Icon(
                      Icons.title,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Titulek (volitelne)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.functionalBg.withAlpha(100),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _titleController,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'napr. Prvni pravy list',
                      hintStyle: TextStyle(color: AppColors.functionalMuted),
                      filled: true,
                      fillColor: AppColors.functionalSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.functionalBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.functionalBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.accent, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Popis
                Row(
                  children: [
                    Icon(
                      Icons.notes,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Popis (volitelne)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.functionalBg.withAlpha(100),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _descriptionController,
                    style: TextStyle(color: AppColors.textPrimary),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Podrobny popis...',
                      hintStyle: TextStyle(color: AppColors.functionalMuted),
                      filled: true,
                      fillColor: AppColors.functionalSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.functionalBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.functionalBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.accent, width: 2),
                      ),
                    ),
                  ),
                ),

                // Error with left border line
                if (timelineState.hasError) ...[
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: null,
                        constraints: const BoxConstraints(minHeight: 40),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withAlpha(60),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.error.withAlpha(60),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            timelineState.errorMessage!,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
