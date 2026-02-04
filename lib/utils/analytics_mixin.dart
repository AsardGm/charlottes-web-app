import 'package:flutter/widgets.dart';
import '../services/analytics_service.dart';

/// Mixin for automatic screen view tracking
/// Add to StatefulWidget states to automatically track screen views
mixin AnalyticsMixin<T extends StatefulWidget> on State<T> {
  final _analytics = AnalyticsService();
  DateTime? _screenEnterTime;

  /// Override this to provide screen name
  String get screenName;

  /// Override to provide additional properties
  Map<String, dynamic>? get screenProperties => null;

  @override
  void initState() {
    super.initState();
    _trackScreenView();
  }

  @override
  void dispose() {
    _trackScreenExit();
    super.dispose();
  }

  void _trackScreenView() {
    _screenEnterTime = DateTime.now();
    _analytics.trackScreen(screenName, properties: screenProperties);
  }

  void _trackScreenExit() {
    if (_screenEnterTime != null) {
      final duration = DateTime.now().difference(_screenEnterTime!).inSeconds;
      _analytics.trackEvent('screen_exit', properties: {
        'screen_name': screenName,
        'duration_seconds': duration,
        ...?screenProperties,
      });
    }
  }

  /// Helper method to track actions from this screen
  Future<void> trackAction(String action, {Map<String, dynamic>? properties}) {
    return _analytics.trackAction(action, properties: {
      'screen': screenName,
      ...?properties,
    });
  }

  /// Helper method to track feature usage from this screen
  Future<void> trackFeature(String feature, {Map<String, dynamic>? properties}) {
    return _analytics.trackFeatureUsage(feature, properties: {
      'screen': screenName,
      ...?properties,
    });
  }
}

/// Example usage:
///
/// class _DashboardScreenState extends ConsumerState<DashboardScreen>
///     with AnalyticsMixin<DashboardScreen> {
///
///   @override
///   String get screenName => AnalyticsScreens.dashboard;
///
///   @override
///   Map<String, dynamic>? get screenProperties => {
///     'has_active_tbreak': _activeBreak != null,
///   };
///
///   void _onChallengeStarted() {
///     trackAction(AnalyticsEvents.challengeStarted, properties: {
///       'challenge_id': challenge.id,
///     });
///   }
/// }
