import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/theme.dart';
import '../../models/thread_type_model.dart';
import '../../providers/posts_provider.dart';
import 'thread_type_chip.dart';

/// Horizontální seznam tabů pro filtrování podle typu vlákna
///
/// Zobrazuje "Vše" a všechny dostupné typy vláken (Diskuze, Otázka, Oznámení).
class ThreadTypeTabs extends ConsumerWidget {
  /// Asynchronní data typů vláken
  final AsyncValue<List<ThreadTypeModel>> threadTypesAsync;

  /// Aktuální filtr příspěvků
  final PostsFilter currentFilter;

  const ThreadTypeTabs({
    super.key,
    required this.threadTypesAsync,
    required this.currentFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return threadTypesAsync.when(
      data: (threadTypes) => _buildTabs(context, ref, threadTypes),
      loading: () => _buildLoadingState(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  /// Sestaví seznam tabů
  Widget _buildTabs(
    BuildContext context,
    WidgetRef ref,
    List<ThreadTypeModel> threadTypes,
  ) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withAlpha(10),
            width: 1,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          // Tab "Vše"
          ThreadTypeChip(
            label: 'Vše',
            emoji: '🏠',
            color: AppColors.primary,
            isSelected: currentFilter.threadTypeId == null,
            onTap: () {
              ref.read(postsProvider.notifier).filterByThreadType(null);
            },
          ),
          const SizedBox(width: 8),

          // Taby pro jednotlivé typy vláken
          ...threadTypes.map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ThreadTypeChip(
                  label: type.name,
                  emoji: type.emoji,
                  color: type.colorValue,
                  isSelected: currentFilter.threadTypeId == type.id,
                  onTap: () {
                    ref.read(postsProvider.notifier).filterByThreadType(type.id);
                  },
                ),
              )),
        ],
      ),
    );
  }

  /// Zobrazí loading stav
  Widget _buildLoadingState() {
    return const SizedBox(
      height: 56,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
