import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/smart_onboarding_flow.dart';
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
import '../screens/checkin/daily_checkin_screen.dart';
import '../screens/games/terpene_match_game.dart';
import '../screens/games/spider_focus_game.dart';
import '../screens/games/pass_timer_game.dart';
import '../screens/strains/strain_database_screen.dart';
import '../screens/strains/strain_detail_screen.dart';
import '../screens/strains/model_of_year_screen.dart';
import '../screens/news/news_feed_screen.dart';
import '../screens/news/article_detail_screen.dart';
import '../screens/emergency/calm_mode_screen.dart';
import '../screens/education/myth_buster_screen.dart';
import '../screens/cognitive/cognitive_test_screen.dart';
import '../screens/cognitive/cognitive_results_screen.dart';
import '../screens/cognitive/cognitive_history_screen.dart';
import '../screens/cognitive/cognitive_insights_dashboard.dart';
import '../screens/consumption/log_consumption_screen.dart';
import '../screens/consumption/post_check_screen.dart';
import '../screens/consumption/insights_dashboard_screen.dart';
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
import '../screens/scanner/scan_result_screen.dart';
import '../screens/scanner/scan_history_screen.dart';
import '../screens/scanner/camera_scanner_screen.dart';
import '../screens/scanner/quality_check_screen.dart';
import '../screens/brain_map/brain_map_screen.dart';
import '../screens/lab/lab_screen.dart';
import '../screens/lab/brain_heatmap_screen.dart';
import '../screens/lab/lab_grow_list_screen.dart';
import '../screens/lab/lab_create_grow_screen.dart';
import '../screens/lab/chronos/chronos_timeline_screen.dart';
import '../screens/lab/chronos/chronos_add_entry_screen.dart';
import '../screens/lab/alchymista/alchymista_dashboard_screen.dart';
import '../screens/lab/alchymista/alchymista_charts_screen.dart';
import '../screens/lab/alchymista/alchymista_schedules_screen.dart';
import '../screens/lab/oci_arasaky/oci_scanner_screen.dart';
import '../screens/lab/oci_arasaky/oci_result_screen.dart';
import '../screens/lab/ghost/ghost_protocol_screen.dart';
import '../screens/charlotte/charlotte_chat_screen.dart';
import '../screens/quantum/quantum_screen.dart';
import '../screens/quantum/reaction_test_screen.dart';
import '../screens/quantum/memory_test_screen.dart';
import '../screens/quantum/focus_test_screen.dart';
import '../screens/tbreak/tbreak_dashboard.dart';
import '../screens/harm_reduction/harm_reduction_screen.dart';
import '../screens/holotrop/holotrop_screen.dart';
import '../screens/wiki/wiki_screen.dart';
import '../screens/wiki/wiki_article_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/insights/weekly_report_screen.dart';
import '../screens/personal_science/personal_science_dashboard.dart';
import '../screens/strain_journal/strain_journal_screen.dart';

class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
}

final _authChangeNotifier = AuthChangeNotifier();

bool? _onboardingCompleted;

Future<bool> _checkOnboardingCompleted() async {
  if (_onboardingCompleted != null) return _onboardingCompleted!;
  final prefs = await SharedPreferences.getInstance();
  _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  return _onboardingCompleted!;
}

void resetOnboardingCache() {
  _onboardingCompleted = null;
}

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

      if (isSplash) return null;

      final onboardingCompleted = await _checkOnboardingCompleted();

      if (!onboardingCompleted && !isOnboarding) return '/onboarding';
      if (onboardingCompleted && isOnboarding) return isLoggedIn ? '/' : '/login';
      if (!isLoggedIn && !isAuthRoute && !isOnboarding) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/smart-onboarding',
        builder: (context, state) => const SmartOnboardingFlow(),
      ),
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
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
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
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatScreen(
          conversationId: state.pathParameters['id']!,
        ),
      ),
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
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const CameraScannerScreen(),
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
      GoRoute(
        path: '/quality-check',
        builder: (context, state) => const QualityCheckScreen(),
      ),

      // Lab
      GoRoute(
        path: '/lab',
        builder: (context, state) => const LabScreen(),
      ),
      GoRoute(
        path: '/lab/grows',
        builder: (context, state) => const LabGrowListScreen(),
      ),
      GoRoute(
        path: '/lab/create-grow',
        builder: (context, state) => const LabCreateGrowScreen(),
      ),
      GoRoute(
        path: '/lab/chronos/:growId',
        builder: (context, state) => ChronosTimelineScreen(
          growId: state.pathParameters['growId']!,
        ),
      ),
      GoRoute(
        path: '/lab/chronos/:growId/add',
        builder: (context, state) => ChronosAddEntryScreen(
          growId: state.pathParameters['growId']!,
        ),
      ),
      GoRoute(
        path: '/lab/alchymista/:growId',
        builder: (context, state) => AlchymistaDashboardScreen(
          growId: state.pathParameters['growId']!,
        ),
      ),
      GoRoute(
        path: '/lab/alchymista/:growId/charts',
        builder: (context, state) => AlchymistaChartsScreen(
          growId: state.pathParameters['growId']!,
        ),
      ),
      GoRoute(
        path: '/lab/schedules',
        builder: (context, state) => const AlchymistaSchedulesScreen(),
      ),
      GoRoute(
        path: '/lab/oci/:growId',
        builder: (context, state) => OciScannerScreen(
          growId: state.pathParameters['growId']!,
        ),
      ),
      GoRoute(
        path: '/lab/oci/:growId/result/:diagnosticId',
        builder: (context, state) => OciResultScreen(
          growId: state.pathParameters['growId']!,
          diagnosticId: state.pathParameters['diagnosticId']!,
        ),
      ),
      GoRoute(
        path: '/lab/ghost',
        builder: (context, state) => const GhostProtocolScreen(),
      ),

      // Charlotte AI
      GoRoute(
        path: '/charlotte',
        builder: (context, state) => const CharlotteChatScreen(),
      ),

      // Quantum - Cognitive Testing
      GoRoute(
        path: '/quantum',
        builder: (context, state) => const QuantumScreen(),
      ),
      GoRoute(
        path: '/quantum/reaction-test',
        builder: (context, state) => const ReactionTestScreen(),
      ),
      GoRoute(
        path: '/quantum/memory-test',
        builder: (context, state) => const MemoryTestScreen(),
      ),
      GoRoute(
        path: '/quantum/focus-test',
        builder: (context, state) => const FocusTestScreen(),
      ),

      // Tolerance Break Tracker
      GoRoute(
        path: '/tbreak',
        builder: (context, state) => const TBreakDashboard(),
      ),

      // Harm Reduction Education
      GoRoute(
        path: '/harm-reduction',
        builder: (context, state) => const HarmReductionScreen(),
      ),

      // Holotrop
      GoRoute(
        path: '/holotrop',
        builder: (context, state) => const HolotropScreen(),
      ),

      // Wiki
      GoRoute(
        path: '/wiki',
        builder: (context, state) => const WikiScreen(),
      ),
      GoRoute(
        path: '/wiki/article/:slug',
        builder: (context, state) => WikiArticleScreen(
          slug: state.pathParameters['slug']!,
        ),
      ),

      // Brain Map
      GoRoute(
        path: '/brain-map',
        builder: (context, state) => const BrainMapScreen(),
      ),
      GoRoute(
        path: '/brain-heatmap',
        builder: (context, state) => const BrainHeatmapScreen(),
      ),
      GoRoute(
        path: '/checkin',
        builder: (context, state) => const DailyCheckinScreen(),
      ),
      GoRoute(
        path: '/terpene-match',
        builder: (context, state) => const TerpeneMatchGame(),
      ),
      GoRoute(
        path: '/spider-focus',
        builder: (context, state) => const SpiderFocusGame(),
      ),
      GoRoute(
        path: '/myth-buster',
        builder: (context, state) => const MythBusterScreen(),
      ),
      GoRoute(
        path: '/pass-timer',
        builder: (context, state) => const PassTimerGame(),
      ),
      GoRoute(
        path: '/strains',
        builder: (context, state) => const StrainDatabaseScreen(),
      ),
      GoRoute(
        path: '/strain/:id',
        builder: (context, state) => StrainDetailScreen(
          strainId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/model-of-year',
        builder: (context, state) => const ModelOfYearScreen(),
      ),
      GoRoute(
        path: '/news',
        builder: (context, state) => const NewsFeedScreen(),
      ),
      GoRoute(
        path: '/news/:id',
        builder: (context, state) => ArticleDetailScreen(
          articleId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/calm',
        builder: (context, state) => const CalmModeScreen(),
      ),
      GoRoute(
        path: '/cognitive',
        builder: (context, state) => const CognitiveTestScreen(),
      ),
      GoRoute(
        path: '/cognitive/results',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CognitiveResultsScreen(
            reactionTime: extra['reactionTime'],
            memoryFlash: extra['memoryFlash'],
            patternRecognition: extra['patternRecognition'],
            totalScore: extra['totalScore'],
            status: extra['status'],
            baselineScore: extra['baselineScore'],
          );
        },
      ),
      GoRoute(
        path: '/cognitive/history',
        builder: (context, state) => const CognitiveHistoryScreen(),
      ),
      GoRoute(
        path: '/cognitive/insights',
        builder: (context, state) => const CognitiveInsightsDashboard(),
      ),

      // Consumption Tracking (Plant → Mind Feedback Loop)
      GoRoute(
        path: '/consumption/log',
        builder: (context, state) {
          final strainId = state.uri.queryParameters['strainId'];
          return LogConsumptionScreen(strainId: strainId);
        },
      ),
      GoRoute(
        path: '/consumption/post-check/:logId',
        builder: (context, state) => PostCheckScreen(
          consumptionLogId: state.pathParameters['logId']!,
        ),
      ),
      GoRoute(
        path: '/consumption/insights',
        builder: (context, state) => const InsightsDashboardScreen(),
      ),

      // Weekly Insights
      GoRoute(
        path: '/insights/weekly',
        builder: (context, state) => const WeeklyReportScreen(),
      ),
      GoRoute(
        path: '/insights/weekly/:id',
        builder: (context, state) => WeeklyReportScreen(
          insightId: state.pathParameters['id'],
        ),
      ),

      // Personal Science
      GoRoute(
        path: '/personal-science',
        builder: (context, state) => const PersonalScienceDashboard(),
      ),

      // Strain Journal
      GoRoute(
        path: '/strain-journal',
        builder: (context, state) => const StrainJournalScreen(),
      ),
      GoRoute(
        path: '/strain-journal/:id',
        builder: (context, state) => StrainJournalScreen(
          strainId: state.pathParameters['id'],
        ),
      ),
    ],
  );
});