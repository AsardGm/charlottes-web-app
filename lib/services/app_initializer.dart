import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'analytics_service.dart';
import 'cache_service.dart';
import 'notification_handler_service.dart';

/// Centralized app initialization service
/// Handles startup sequence, service initialization, and error recovery
class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  factory AppInitializer() => _instance;
  AppInitializer._internal();

  bool _isInitialized = false;
  final List<String> _initializationLog = [];
  DateTime? _startTime;

  bool get isInitialized => _isInitialized;
  List<String> get initializationLog => List.unmodifiable(_initializationLog);

  /// Initialize all app services in correct order
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('App already initialized');
      return;
    }

    _startTime = DateTime.now();
    _log('Starting app initialization');

    try {
      // Step 1: Initialize core services
      await _initializeCoreServices();

      // Step 2: Initialize user-specific services
      await _initializeUserServices();

      // Step 3: Clean up and optimize
      await _performCleanup();

      _isInitialized = true;
      final duration = DateTime.now().difference(_startTime!).inMilliseconds;
      _log('App initialization complete in ${duration}ms');

      // Track initialization success
      AnalyticsService().trackEvent('app_initialized', properties: {
        'duration_ms': duration,
        'steps': _initializationLog.length,
      });
    } catch (e, stackTrace) {
      _log('Initialization failed: $e');
      debugPrint('Initialization error: $e\n$stackTrace');

      // Track initialization failure
      AnalyticsService().trackError('initialization_failed', stackTrace: stackTrace.toString(), properties: {
        'error': e.toString(),
        'step': _initializationLog.last,
      });

      rethrow;
    }
  }

  /// Initialize core services (cache, analytics base)
  Future<void> _initializeCoreServices() async {
    _log('Initializing core services');

    // Cache service is singleton, just verify it's ready
    final cache = CacheService();
    _log('✓ Cache service ready');

    // Clear expired cache entries
    cache.clearExpired();
    _log('✓ Cache cleanup complete');
  }

  /// Initialize user-specific services
  Future<void> _initializeUserServices() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _log('No authenticated user, skipping user services');
      return;
    }

    _log('Initializing user services for ${user.id}');

    // Initialize analytics with user ID
    AnalyticsService().initialize(user.id);
    _log('✓ Analytics initialized');

    // Start analytics session
    await AnalyticsService().trackSessionStart();
    _log('✓ Analytics session started');

    // Initialize notification handler (singleton)
    NotificationHandlerService();
    _log('✓ Notification handler ready');

    // Load user preferences
    await _loadUserPreferences(user.id);
    _log('✓ User preferences loaded');
  }

  /// Load user preferences (theme, analytics opt-in, etc.)
  Future<void> _loadUserPreferences(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        // Set analytics preference
        final analyticsEnabled = response['data_analytics_enabled'] ?? true;
        AnalyticsService().setEnabled(analyticsEnabled);
        _log('Analytics enabled: $analyticsEnabled');
      }
    } catch (e) {
      _log('Warning: Could not load user preferences: $e');
      // Don't fail initialization if preferences can't be loaded
    }
  }

  /// Perform cleanup operations
  Future<void> _performCleanup() async {
    _log('Performing cleanup');

    final cache = CacheService();

    // Clear very old cache entries
    cache.clearExpired();

    // Log cache stats
    final stats = cache.getStats();
    _log('Cache stats: ${stats['active_entries']} active, ${stats['expired_entries']} expired');
  }

  /// Reset initialization state (for testing or re-initialization)
  void reset() {
    _isInitialized = false;
    _initializationLog.clear();
    _startTime = null;
    _log('Initialization reset');
  }

  /// Log initialization step
  void _log(String message) {
    _initializationLog.add('[${DateTime.now().toIso8601String()}] $message');
    if (kDebugMode) {
      debugPrint('AppInitializer: $message');
    }
  }

  /// Get initialization summary
  Map<String, dynamic> getSummary() {
    return {
      'is_initialized': _isInitialized,
      'duration_ms': _startTime != null
          ? DateTime.now().difference(_startTime!).inMilliseconds
          : 0,
      'steps_completed': _initializationLog.length,
      'log': _initializationLog,
    };
  }

  /// Graceful shutdown
  Future<void> shutdown() async {
    if (!_isInitialized) return;

    _log('Starting app shutdown');

    try {
      // Track session end
      await AnalyticsService().trackSessionEnd();
      _log('✓ Analytics session ended');

      // Clear in-memory caches
      CacheService().clearAll();
      _log('✓ Cache cleared');

      _isInitialized = false;
      _log('App shutdown complete');
    } catch (e) {
      _log('Shutdown error: $e');
    }
  }
}

/// Helper for initialization status display
class InitializationStatus {
  final bool isComplete;
  final double progress;
  final String currentStep;
  final List<String> completedSteps;

  const InitializationStatus({
    required this.isComplete,
    required this.progress,
    required this.currentStep,
    required this.completedSteps,
  });

  factory InitializationStatus.fromInitializer(AppInitializer initializer) {
    final log = initializer.initializationLog;
    final isComplete = initializer.isInitialized;

    return InitializationStatus(
      isComplete: isComplete,
      progress: isComplete ? 1.0 : (log.length / 10).clamp(0.0, 0.9),
      currentStep: log.isNotEmpty ? log.last : 'Starting...',
      completedSteps: log,
    );
  }
}
