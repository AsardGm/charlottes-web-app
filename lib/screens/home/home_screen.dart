import 'package:flutter/material.dart';
import '../feed/feed_screen.dart';
import '../chat/conversations_screen.dart';
import '../scanner/camera_scanner_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/home/home_app_bar.dart';
import '../../widgets/home/home_bottom_nav.dart';

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
    CameraScannerScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Feed (0) a Profil (3) maji vlastni header/AppBar
    // Scanner (2) ma taky vlastni AppBar
    final showAppBar = _currentIndex == 1; // Pouze pro Comms

    return Scaffold(
      appBar: showAppBar
          ? HomeAppBar(currentIndex: _currentIndex)
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
