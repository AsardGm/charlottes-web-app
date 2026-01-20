import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/feed/create_post_screen.dart';
import '../screens/feed/post_detail_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/post_management_screen.dart';
import '../screens/admin/reports_screen.dart';
import '../screens/admin/analytics_screen.dart';
import '../screens/admin/moderation_screen.dart';
import '../screens/admin/content_management_screen.dart';
import '../screens/admin/user_tools_screen.dart';
import '../screens/admin/audit_log_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/privacy_security_screen.dart';
import '../screens/settings/blocked_users_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/profile/follow_requests_screen.dart';
import '../screens/gamification/gamification_screen.dart';
import '../screens/gamification/cards_screen.dart';
import '../screens/gamification/leaderboard_screen.dart';
import '../screens/gamification/badges_screen.dart';
import '../screens/scanner/scanner_screen.dart';
import '../screens/scanner/scan_result_screen.dart';
import '../screens/scanner/scan_history_screen.dart';
import '../screens/brain_map/brain_map_screen.dart';

/// Notifier pro refresh routeru při změně auth stavu
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
}

final _authChangeNotifier = AuthChangeNotifier();

/// Cache pro onboarding status (aby se nevolalo SharedPreferences při každém redirectu)
bool? _onboardingCompleted;

/// Načte onboarding status z SharedPreferences
Future<bool> _checkOnboardingCompleted() async {
  if (_onboardingCompleted != null) return _onboardingCompleted!;
  final prefs = await SharedPreferences.getInstance();
  _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  return _onboardingCompleted!;
}

/// Resetuje cache (volat po změně onboarding statusu)
void resetOnboardingCache() {
  _onboardingCompleted = null;
}

/// Provider pro GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _authChangeNotifier,
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isAuthRoute = state.matchedLocation == '/login' ||
                          state.matchedLocation == '/register' ||
                          state.matchedLocation == '/forgot-password';

      // Splash screen se nezpracovává - nechej ho běžet
      if (isSplash) {
        return null;
      }

      // Zkontroluj onboarding status
      final onboardingCompleted = await _checkOnboardingCompleted();

      // Pokud onboarding není dokončen a není na onboarding stránce
      if (!onboardingCompleted && !isOnboarding) {
        return '/onboarding';
      }

      // Pokud onboarding je dokončen a je na onboarding stránce
      if (onboardingCompleted && isOnboarding) {
        return isLoggedIn ? '/' : '/login';
      }

      // Pokud není přihlášen a není na auth/onboarding stránce
      if (!isLoggedIn && !isAuthRoute && !isOnboarding) {
        return '/login';
      }

      // Pokud je přihlášen a je na auth stránce
      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
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
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/admin/moderation',
        builder: (context, state) => const ModerationScreen(),
      ),
      GoRoute(
        path: '/admin/content',
        builder: (context, state) => const ContentManagementScreen(),
      ),
      GoRoute(
        path: '/admin/user-tools',
        builder: (context, state) => const UserToolsScreen(),
      ),
      GoRoute(
        path: '/admin/audit-log',
        builder: (context, state) => const AuditLogScreen(),
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
      GoRoute(
        path: '/follow-requests',
        builder: (context, state) => const FollowRequestsScreen(),
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
        path: '/privacy-security',
        builder: (context, state) => const PrivacySecurityScreen(),
      ),
      GoRoute(
        path: '/blocked-users',
        builder: (context, state) => const BlockedUsersScreen(),
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

      // Scanner
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/scanner/result/:id',
        builder: (context, state) => ScanResultScreen(
          scanId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/scanner/history',
        builder: (context, state) => const ScanHistoryScreen(),
      ),

      // Brain Map
      GoRoute(
        path: '/brain-map',
        builder: (context, state) => const BrainMapScreen(),
      ),
    ],
  );
});
