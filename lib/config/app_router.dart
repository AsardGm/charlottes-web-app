import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/feed/create_post_screen.dart';
import '../screens/feed/post_detail_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/post_management_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/gamification/gamification_screen.dart';
import '../screens/gamification/cards_screen.dart';
import '../screens/gamification/leaderboard_screen.dart';
import '../screens/gamification/badges_screen.dart';

/// Notifier pro refresh routeru při změně auth stavu
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
}

final _authChangeNotifier = AuthChangeNotifier();

/// Provider pro GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _authChangeNotifier,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      // Pokud není přihlášen a není na auth stránce, přesměruj na login
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // Pokud je přihlášen a je na auth stránce, přesměruj na home
      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Home
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),

      // Feed
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) => PostDetailScreen(
          postId: state.pathParameters['id']!,
        ),
      ),

      // Admin
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        path: '/admin/posts',
        builder: (context, state) => const PostManagementScreen(),
      ),

      // Profile
      GoRoute(
        path: '/profile',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) => UserProfileScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // Chat
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatScreen(
          conversationId: state.pathParameters['id']!,
        ),
      ),

      // Other
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),

      // Gamification
      GoRoute(
        path: '/gamification',
        builder: (context, state) => const GamificationScreen(),
      ),
      GoRoute(
        path: '/cards',
        builder: (context, state) => const CardsScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/badges',
        builder: (context, state) => const BadgesScreen(),
      ),
    ],
  );
});
