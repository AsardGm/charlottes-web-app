import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../feed/feed_screen.dart';
import '../chat/conversations_screen.dart';
import '../wiki/wiki_screen.dart';
import '../lab/lab_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/home/home_app_bar.dart';
import '../../widgets/home/home_bottom_nav.dart';
import '../../widgets/holotrop/holotrop_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    FeedScreen(),
    ConversationsScreen(),
    WikiScreen(),
    LabScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Feed (0) a Profil (4) maji vlastni header/AppBar
    // Wiki (2) a Lab (3) maji taky vlastni AppBar
    final showAppBar = _currentIndex == 1; // Pouze pro Comms

    return Scaffold(
      appBar: showAppBar
          ? HomeAppBar(currentIndex: _currentIndex)
          : null,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          if (_currentIndex == 0 || _currentIndex == 1) // Pouze Hub a Comms
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
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
