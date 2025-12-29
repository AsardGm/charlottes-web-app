import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/unread_counts_provider.dart';
import '../../theme/theme.dart';

/// Spodni navigace pro hlavni obrazovku
class HomeBottomNav extends ConsumerWidget {
  /// Aktualni index
  final int currentIndex;

  /// Callback pri zmene tabu
  final ValueChanged<int> onDestinationSelected;

  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadMessages = ref.watch(unreadMessagesCountProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withAlpha(10),
            width: 1,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Zed',
          ),
          NavigationDestination(
            icon: _BadgeIcon(
              icon: Icons.chat_bubble_outline,
              count: unreadMessages,
            ),
            selectedIcon: _BadgeIcon(
              icon: Icons.chat_bubble,
              count: unreadMessages,
            ),
            label: 'Zpravy',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Widget pro ikonu s badge
class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;

  const _BadgeIcon({
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppColors.primary,
      child: Icon(icon),
    );
  }
}
