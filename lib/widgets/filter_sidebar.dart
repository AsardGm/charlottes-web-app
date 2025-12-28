import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme.dart';
import '../providers/posts_provider.dart';
import '../providers/category_provider.dart';
import '../models/thread_type_model.dart';

class FilterSidebar extends ConsumerWidget {
  final bool isDrawer;

  const FilterSidebar({
    super.key,
    this.isDrawer = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final currentFilter = ref.watch(postsProvider.notifier).currentFilter;

    final content = Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withAlpha(10),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  'Filtry',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (currentFilter.hasActiveFilters)
                  TextButton(
                    onPressed: () {
                      ref.read(postsProvider.notifier).clearFilters();
                      if (isDrawer) Navigator.of(context).pop();
                    },
                    child: const Text('Vymazat'),
                  ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stav vlákna
                _FilterSection(
                  title: 'Stav',
                  icon: Icons.flag_outlined,
                  children: [
                    _FilterOption(
                      label: 'Otevřené',
                      icon: Icons.radio_button_unchecked,
                      color: ThreadStatus.open.color,
                      isSelected: currentFilter.status == 'open',
                      onTap: () {
                        ref.read(postsProvider.notifier).filterByStatus(
                              currentFilter.status == 'open' ? null : 'open',
                            );
                      },
                    ),
                    _FilterOption(
                      label: 'Vyřešené',
                      icon: Icons.check_circle_outline,
                      color: ThreadStatus.resolved.color,
                      isSelected: currentFilter.status == 'resolved',
                      onTap: () {
                        ref.read(postsProvider.notifier).filterByStatus(
                              currentFilter.status == 'resolved'
                                  ? null
                                  : 'resolved',
                            );
                      },
                    ),
                    _FilterOption(
                      label: 'Zamčené',
                      icon: Icons.lock_outline,
                      color: ThreadStatus.locked.color,
                      isSelected: currentFilter.status == 'locked',
                      onTap: () {
                        ref.read(postsProvider.notifier).filterByStatus(
                              currentFilter.status == 'locked'
                                  ? null
                                  : 'locked',
                            );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Speciální filtry
                _FilterSection(
                  title: 'Speciální',
                  icon: Icons.star_outline,
                  children: [
                    _FilterOption(
                      label: 'S termínem',
                      icon: Icons.schedule,
                      color: AppColors.warning,
                      isSelected: currentFilter.hasDeadline == true,
                      onTap: () {
                        ref.read(postsProvider.notifier).filterByDeadline(
                              currentFilter.hasDeadline != true,
                            );
                      },
                    ),
                    _FilterOption(
                      label: 'Po termínu',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.error,
                      isSelected: currentFilter.isOverdue == true,
                      onTap: () {
                        ref.read(postsProvider.notifier).filterOverdue(
                              currentFilter.isOverdue != true,
                            );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Kategorie
                _FilterSection(
                  title: 'Kategorie',
                  icon: Icons.category_outlined,
                  children: [
                    categoriesAsync.when(
                      data: (categories) => Column(
                        children: categories.map((category) {
                          final isSelected =
                              currentFilter.categoryId == category.id;
                          return _FilterOption(
                            label: category.name,
                            icon: category.iconData,
                            color: category.colorValue,
                            isSelected: isSelected,
                            onTap: () {
                              ref.read(postsProvider.notifier).filterByCategory(
                                    isSelected ? null : category.id,
                                  );
                            },
                          );
                        }).toList(),
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isDrawer) {
      return Drawer(
        backgroundColor: AppColors.surface,
        child: SafeArea(child: content),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(
            color: Colors.white.withAlpha(10),
            width: 1,
          ),
        ),
      ),
      child: content,
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _FilterSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color.withAlpha(20) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? color.withAlpha(50) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    size: 16,
                    color: color,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
