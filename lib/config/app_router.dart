import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

/// Provider pro GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
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
    ],
  );
});
