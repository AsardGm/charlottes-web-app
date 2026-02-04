/// Analytics Integration Guide
///
/// This guide shows how to integrate analytics tracking throughout the app
/// for better insights into user behavior and app performance.

/*
// ==================== SETUP ====================

1. Initialize Analytics (in main.dart or app.dart):

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(...);

  // Initialize analytics when user logs in
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId != null) {
    AnalyticsService().initialize(userId);
    AnalyticsService().trackSessionStart();
  }

  runApp(MyApp());
}

2. Create Analytics Events Table (Supabase):

CREATE TABLE analytics_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  session_id TEXT NOT NULL,
  event_name TEXT NOT NULL,
  properties JSONB DEFAULT '{}',
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  platform TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_analytics_user ON analytics_events(user_id);
CREATE INDEX idx_analytics_event ON analytics_events(event_name);
CREATE INDEX idx_analytics_timestamp ON analytics_events(timestamp);

// ==================== SCREEN TRACKING ====================

3. Add AnalyticsMixin to Screens:

// Before:
class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // ...
}

// After:
import '../utils/analytics_mixin.dart';
import '../services/analytics_service.dart';

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with AnalyticsMixin<DashboardScreen> {

  @override
  String get screenName => AnalyticsScreens.dashboard;

  @override
  Map<String, dynamic>? get screenProperties => {
    'has_active_tbreak': _activeBreak != null,
    'active_challenges': _activeChallenges?.length ?? 0,
  };

  // Existing code...
}

// ==================== BUTTON TRACKING ====================

4. Replace Regular Buttons with Tracked Buttons:

// Before:
FilledButton(
  onPressed: _startChallenge,
  child: Text('Start Challenge'),
)

// After:
TrackedButton(
  eventName: AnalyticsEvents.challengeStarted,
  eventProperties: {'challenge_id': challenge.id},
  onPressed: _startChallenge,
  child: Text('Start Challenge'),
)

// ==================== MANUAL EVENT TRACKING ====================

5. Track Custom Events in Code:

// In a service or screen:
final analytics = AnalyticsService();

// Track consumption log
Future<void> saveConsumptionLog(ConsumptionLog log) async {
  final saved = await _supabase.from('consumption_logs').insert(log.toJson());

  // Track analytics
  analytics.trackEvent(AnalyticsEvents.consumptionLogged, properties: {
    'strain_id': log.strainId,
    'method': log.method,
    'has_notes': log.notes != null,
  });

  return saved;
}

// Track challenge completion
Future<void> completeChallenge(String challengeId) async {
  await _supabase.rpc('complete_challenge', params: {'id': challengeId});

  analytics.trackEvent(AnalyticsEvents.challengeCompleted, properties: {
    'challenge_id': challengeId,
    'completion_time': DateTime.now().toIso8601String(),
  });
}

// Track errors
try {
  await riskyOperation();
} catch (e, stackTrace) {
  analytics.trackError(e.toString(), stackTrace: stackTrace.toString(), properties: {
    'operation': 'riskyOperation',
  });
  rethrow;
}

// ==================== PERFORMANCE TRACKING ====================

6. Track Performance Metrics:

Future<void> loadDashboardData() async {
  final startTime = DateTime.now();

  try {
    final data = await fetchData();

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    AnalyticsService().trackPerformance('dashboard_load', duration, properties: {
      'data_items': data.length,
    });

  } catch (e) {
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    AnalyticsService().trackPerformance('dashboard_load_failed', duration, properties: {
      'error': e.toString(),
    });
  }
}

// ==================== CONVERSION TRACKING ====================

7. Track Important Conversions:

// User completes onboarding
analytics.trackConversion('onboarding_completed', properties: {
  'selected_goals': goals.join(','),
});

// User creates first journal entry
analytics.trackConversion('first_journal_entry');

// User starts first T-break
analytics.trackConversion('first_tbreak');

// ==================== FEATURE USAGE TRACKING ====================

8. Track Feature Usage:

// When user opens a feature for first time
analytics.trackFeatureUsage(AnalyticsFeatures.strainJournal, properties: {
  'is_first_use': isFirstUse,
});

// Track engagement with features
analytics.trackEngagement('charlotte_chat', properties: {
  'messages_sent': messagesCount,
  'session_duration': durationSeconds,
});

// ==================== SETTINGS TRACKING ====================

9. Track Settings Changes:

Future<void> updateSetting(String key, dynamic value) async {
  await _supabase.from('user_settings').update({key: value});

  analytics.trackEvent(AnalyticsEvents.settingsChanged, properties: {
    'setting': key,
    'value': value.toString(),
  });
}

// Theme change
void changeTheme(ThemeMode mode) {
  ref.read(themeModeProvider.notifier).setMode(mode);

  analytics.trackEvent(AnalyticsEvents.themeChanged, properties: {
    'theme': mode.name,
  });
}

// Notifications toggle
void toggleNotifications(bool enabled) {
  updateSetting('notifications_enabled', enabled);

  analytics.trackEvent(AnalyticsEvents.notificationsToggled, properties: {
    'enabled': enabled,
  });
}

// ==================== PRIVACY CONTROLS ====================

10. Respect User Privacy:

// In settings screen:
class SettingsScreen extends ConsumerStatefulWidget {
  // ...
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _analyticsEnabled = true;

  Future<void> _loadSettings() async {
    final settings = await _loadUserSettings();
    setState(() {
      _analyticsEnabled = settings['data_analytics_enabled'] ?? true;
    });

    // Update analytics service
    AnalyticsService().setEnabled(_analyticsEnabled);
  }

  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text('Analytics'),
      subtitle: Text('Help us improve the app'),
      value: _analyticsEnabled,
      onChanged: (value) {
        setState(() => _analyticsEnabled = value);
        _saveSettings();
        AnalyticsService().setEnabled(value);
      },
    );
  }
}

// ==================== QUERYING ANALYTICS DATA ====================

11. Query Analytics (Supabase Dashboard or API):

-- Most popular screens
SELECT event_name, COUNT(*) as views
FROM analytics_events
WHERE event_name = 'screen_view'
AND timestamp > NOW() - INTERVAL '7 days'
GROUP BY event_name
ORDER BY views DESC;

-- Feature usage over time
SELECT DATE(timestamp) as date, COUNT(*) as uses
FROM analytics_events
WHERE event_name = 'feature_usage'
AND properties->>'feature' = 'strain_journal'
AND timestamp > NOW() - INTERVAL '30 days'
GROUP BY DATE(timestamp)
ORDER BY date;

-- User engagement metrics
SELECT
  user_id,
  COUNT(DISTINCT session_id) as sessions,
  COUNT(*) as total_events,
  MAX(timestamp) - MIN(timestamp) as total_duration
FROM analytics_events
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY user_id;

// ==================== BEST PRACTICES ====================

✅ DO:
- Track meaningful events that help improve UX
- Include relevant context in properties
- Respect user privacy settings
- Handle analytics errors gracefully (never crash)
- Use consistent event naming
- Track both successes and failures
- Monitor performance impact

❌ DON'T:
- Track sensitive personal information
- Track without user consent
- Block UI while tracking
- Track too frequently (causes noise)
- Include PII in event properties
- Force analytics if user opts out

💡 TIPS:
- Use AnalyticsMixin for automatic screen tracking
- Use TrackedButton for important CTAs
- Track conversion funnels (start → complete)
- Monitor error rates and performance
- Regular review of unused events
- A/B test with tracked variants
*/
