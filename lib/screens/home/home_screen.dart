import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../feed/feed_screen.dart';
import '../chat/conversations_screen.dart';
import '../lab/lab_screen.dart';
import '../profile/profile_screen.dart';
import '../news/news_feed_screen.dart';
import '../../widgets/holotrop/holotrop_button.dart';
import '../../theme/theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(key: ValueKey('feed')),
    const NewsFeedScreen(key: ValueKey('news')),
    const ConversationsScreen(key: ValueKey('conversations')),
    const LabScreen(key: ValueKey('lab')),
    const ProfileScreen(key: ValueKey('profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.02, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _screens[_currentIndex],
          ),
          // Holotrop button visible on Hub and Chat tabs
          if (_currentIndex == 0 || _currentIndex == 2)
            Positioned(
              right: 20,
              bottom: 80,
              child: HolotropButton(
                onTap: () => context.push('/holotrop'),
                size: 44,
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.functionalBg,
          border: Border(
            top: BorderSide(
              color: AppColors.functionalBorder.withAlpha(100),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Hub',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.article_outlined,
                  activeIcon: Icons.article,
                  label: 'News',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Chat',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.biotech_outlined,
                  activeIcon: Icons.biotech,
                  label: 'Lab',
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.accent : AppColors.functionalMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.accent : AppColors.functionalMuted,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
