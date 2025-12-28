import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';

/// Plovoucí akční tlačítka pro feed
///
/// Obsahuje tlačítko pro filtr (pouze na mobilních zařízeních)
/// a tlačítko pro vytvoření nového příspěvku.
class FeedFab extends StatelessWidget {
  /// Je obrazovka široká? (desktop/tablet)
  final bool isWideScreen;

  /// Jsou aktivní nějaké filtry?
  final bool hasActiveFilters;

  /// Callback pro otevření filtrovacího panelu
  final VoidCallback onOpenFilters;

  const FeedFab({
    super.key,
    required this.isWideScreen,
    required this.hasActiveFilters,
    required this.onOpenFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tlačítko pro filtr (pouze na mobilech)
        if (!isWideScreen) ...[
          FloatingActionButton.small(
            heroTag: 'filter',
            onPressed: onOpenFilters,
            backgroundColor: AppColors.surfaceLight,
            child: Badge(
              isLabelVisible: hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Tlačítko pro vytvoření příspěvku
        FloatingActionButton(
          heroTag: 'create',
          onPressed: () => context.go('/create-post'),
          child: const Icon(Icons.add),
        ),
      ],
    );
  }
}
