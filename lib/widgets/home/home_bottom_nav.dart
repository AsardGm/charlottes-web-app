import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/unread_counts_provider.dart';
import '../../theme/theme.dart';
import '../../utils/haptic_utils.dart';

/// Spodni navigace s Functional Dark designem
/// Funguje stejně na nativním i PWA
class HomeBottomNav extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadMessages = ref.watch(unreadMessagesCountProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Výška navigace - na webu bez extra padding, na mobile s safe area
    final navHeight = kIsWeb ? 56.0 : 56.0 + bottomPadding;

    return Container(
      height: navHeight,
      decoration: BoxDecoration(
        color: AppColors.functionalBg.withAlpha(242),
        border: Border(
          top: BorderSide(
            color: AppColors.accent.withAlpha(50),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: kIsWeb ? 0 : bottomPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Hub',
              isActive: currentIndex == 0,
              onTap: () {
                HapticUtils.selectionClick();
                onDestinationSelected(0);
              },
            ),
            _NavItem(
              icon: Icons.chat_bubble_outline,
              activeIcon: Icons.chat_bubble,
              label: 'Comms',
              isActive: currentIndex == 1,
              badgeCount: unreadMessages,
              onTap: () {
                HapticUtils.selectionClick();
                onDestinationSelected(1);
              },
            ),
            _NavItem(
              icon: Icons.document_scanner_outlined,
              activeIcon: Icons.document_scanner,
              label: 'Skener',
              isActive: currentIndex == 2,
              onTap: () {
                HapticUtils.selectionClick();
                onDestinationSelected(2);
              },
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              isActive: currentIndex == 3,
              onTap: () {
                HapticUtils.selectionClick();
                onDestinationSelected(3);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Jednotlivy nav item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isActive ? AppColors.accent : AppColors.functionalMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with optional badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.accent.withAlpha(25) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: activeColor,
                    size: 22,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            // Label
            Text(
              label,
              style: TextStyle(
                color: activeColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
