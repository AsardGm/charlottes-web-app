import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'search_bar_button.dart';

/// AppBar pro hlavni obrazovku
///
/// Zobrazuje search bar na Zdi, nebo titulek na ostatnich tabech.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Index aktualniho tabu
  final int currentIndex;

  const HomeAppBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _getTitle() {
    switch (currentIndex) {
      case 0:
        return 'Zeď';
      case 1:
        return 'Zpravy';
      case 2:
        return 'Profil';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Feed tab - search bar + notifikace
    if (currentIndex == 0) {
      return AppBar(
        title: SearchBarButton(
          onTap: () => context.push('/search'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      );
    }

    // Ostatni taby - pouze titulek
    return AppBar(
      title: Text(_getTitle()),
      centerTitle: true,
    );
  }
}
