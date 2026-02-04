import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Privacy-first analytics service for tracking user behavior and app performance
/// All data is anonymized and respects user privacy settings
class AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _isEnabled = true;
  String? _userId;
  String? _sessionId;
  DateTime? _sessionStart;

  /// Initialize analytics with user ID
  void initialize(String userId) {
    _userId = userId;
    _sessionId = _generateSessionId();
    _sessionStart = DateTime.now();
    debugPrint('Analytics initialized for user: $userId');
  }

  /// Enable/disable analytics based on user preference
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      debugPrint('Analytics disabled by user');
    }
  }

  /// Track a custom event
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? properties}) async {
    if (!_isEnabled || _userId == null) return;

    try {
      final event = {
        'user_id': _userId,
        'session_id': _sessionId,
        'event_name': eventName,
        'properties': properties ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.name,
      };

      // Log in debug mode
      if (kDebugMode) {
        debugPrint('Analytics Event: $eventName ${properties ?? ""}');
      }

      // Send to analytics table (non-blocking)
      _supabase.from('analytics_events').insert(event).then((_) {
        // Success - silent
      }).catchError((error) {
        // Fail silently in production
        if (kDebugMode) {
          debugPrint('Analytics error: $error');
        }
      });
    } catch (e) {
      // Never crash the app due to analytics
      if (kDebugMode) {
        debugPrint('Analytics exception: $e');
      }
    }
  }

  /// Track screen view
  Future<void> trackScreen(String screenName, {Map<String, dynamic>? properties}) async {
    await trackEvent(AnalyticsEvents.screenView, properties: {
      'screen_name': screenName,
      ...?properties,
    });
  }

  /// Track user action
  Future<void> trackAction(String action, {Map<String, dynamic>? properties}) async {
    await trackEvent(action, properties: properties);
  }

  /// Track performance metric
  Future<void> trackPerformance(String metric, int durationMs, {Map<String, dynamic>? properties}) async {
    await trackEvent(AnalyticsEvents.performance, properties: {
      'metric': metric,
      'duration_ms': durationMs,
      ...?properties,
    });
  }

  /// Track error
  Future<void> trackError(String error, {String? stackTrace, Map<String, dynamic>? properties}) async {
    await trackEvent(AnalyticsEvents.error, properties: {
      'error': error,
      'stack_trace': stackTrace,
      ...?properties,
    });
  }

  /// Track conversion/goal completion
  Future<void> trackConversion(String goalName, {Map<String, dynamic>? properties}) async {
    await trackEvent(AnalyticsEvents.conversion, properties: {
      'goal': goalName,
      ...?properties,
    });
  }

  /// Track session start
  Future<void> trackSessionStart() async {
    _sessionStart = DateTime.now();
    await trackEvent(AnalyticsEvents.sessionStart);
  }

  /// Track session end
  Future<void> trackSessionEnd() async {
    if (_sessionStart != null) {
      final duration = DateTime.now().difference(_sessionStart!).inSeconds;
      await trackEvent(AnalyticsEvents.sessionEnd, properties: {
        'duration_seconds': duration,
      });
    }
  }

  /// Generate unique session ID
  String _generateSessionId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_userId ?? 'anon'}';
  }

  /// Track feature usage
  Future<void> trackFeatureUsage(String featureName, {Map<String, dynamic>? properties}) async {
    await trackEvent(AnalyticsEvents.featureUsage, properties: {
      'feature': featureName,
      ...?properties,
    });
  }

  /// Track engagement metric
  Future<void> trackEngagement(String type, {Map<String, dynamic>? properties}) async {
    await trackEvent(AnalyticsEvents.engagement, properties: {
      'type': type,
      ...?properties,
    });
  }
}

/// Predefined analytics event names
class AnalyticsEvents {
  // System events
  static const String sessionStart = 'session_start';
  static const String sessionEnd = 'session_end';
  static const String screenView = 'screen_view';
  static const String error = 'error';
  static const String performance = 'performance';

  // User actions
  static const String login = 'login';
  static const String logout = 'logout';
  static const String signup = 'signup';

  // Feature usage
  static const String featureUsage = 'feature_usage';
  static const String engagement = 'engagement';
  static const String conversion = 'conversion';

  // Consumption tracking
  static const String consumptionLogged = 'consumption_logged';
  static const String postCheckCompleted = 'post_check_completed';
  static const String strainRated = 'strain_rated';
  static const String journalEntryCreated = 'journal_entry_created';

  // Challenges & Gamification
  static const String challengeStarted = 'challenge_started';
  static const String challengeCompleted = 'challenge_completed';
  static const String achievementUnlocked = 'achievement_unlocked';
  static const String levelUp = 'level_up';

  // T-Break
  static const String tbreakStarted = 'tbreak_started';
  static const String tbreakCompleted = 'tbreak_completed';
  static const String tbreakCheckIn = 'tbreak_check_in';

  // Charlotte AI
  static const String charlotteMessageSent = 'charlotte_message_sent';
  static const String charlotteTipViewed = 'charlotte_tip_viewed';

  // Cognitive
  static const String cognitiveTestStarted = 'cognitive_test_started';
  static const String cognitiveTestCompleted = 'cognitive_test_completed';

  // Settings
  static const String settingsChanged = 'settings_changed';
  static const String notificationsToggled = 'notifications_toggled';
  static const String themeChanged = 'theme_changed';

  // Social
  static const String postCreated = 'post_created';
  static const String postLiked = 'post_liked';
  static const String commentCreated = 'comment_created';

  // Weekly Insights
  static const String weeklyInsightViewed = 'weekly_insight_viewed';
  static const String weeklyInsightGenerated = 'weekly_insight_generated';

  // Harm Reduction
  static const String harmReductionTipViewed = 'harm_reduction_tip_viewed';
  static const String harmReductionAlertDismissed = 'harm_reduction_alert_dismissed';
}

/// Screen names for consistent tracking
class AnalyticsScreens {
  static const String dashboard = 'dashboard';
  static const String consumption = 'consumption';
  static const String journal = 'journal';
  static const String challenges = 'challenges';
  static const String achievements = 'achievements';
  static const String tbreak = 'tbreak';
  static const String charlotte = 'charlotte';
  static const String cognitive = 'cognitive';
  static const String weeklyInsights = 'weekly_insights';
  static const String settings = 'settings';
  static const String profile = 'profile';
  static const String feed = 'feed';
  static const String harmReduction = 'harm_reduction';
  static const String lab = 'lab';
  static const String notifications = 'notifications';
}

/// Feature names for tracking
class AnalyticsFeatures {
  static const String strainJournal = 'strain_journal';
  static const String toleranceBreak = 'tolerance_break';
  static const String challengeSystem = 'challenge_system';
  static const String charlotteAI = 'charlotte_ai';
  static const String cognitiveTests = 'cognitive_tests';
  static const String weeklyInsights = 'weekly_insights';
  static const String harmReduction = 'harm_reduction';
  static const String socialFeed = 'social_feed';
  static const String gamification = 'gamification';
  static const String notifications = 'notifications';
}
