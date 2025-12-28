import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/theme.dart';
import '../../providers/posts_provider.dart';

/// Lišta zobrazující aktivní filtry
///
/// Zobrazuje se pod taby typů vláken když jsou aktivní nějaké filtry
/// (kategorie, stav, řazení).
class ActiveFiltersBar extends ConsumerWidget {
  /// Aktuální filtr příspěvků
  final PostsFilter filter;

  const ActiveFiltersBar({
    super.key,
    required this.filter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withAlpha(50),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Ikona filtru
          Icon(Icons.filter_alt, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),

          // Text "Aktivní filtry"
          Text(
            'Aktivní filtry',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),

          const Spacer(),

          // Tlačítko pro zrušení filtrů
          TextButton.icon(
            onPressed: () => ref.read(postsProvider.notifier).clearFilters(),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Zrušit'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
