import 'dart:async';

/// Simple in-memory cache service for API responses
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, _CacheEntry> _cache = {};
  final Duration _defaultExpiry = const Duration(minutes: 5);

  /// Get cached data or null if expired/not found
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  /// Set cache with optional custom expiry
  void set<T>(String key, T data, {Duration? expiry}) {
    _cache[key] = _CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(expiry ?? _defaultExpiry),
    );
  }

  /// Check if key exists and is not expired
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;

    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// Clear specific key
  void clear(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  void clearAll() {
    _cache.clear();
  }

  /// Clear expired entries
  void clearExpired() {
    _cache.removeWhere((key, entry) => entry.isExpired);
  }

  /// Get cache stats
  Map<String, dynamic> getStats() {
    final expired = _cache.values.where((e) => e.isExpired).length;
    return {
      'total_entries': _cache.length,
      'expired_entries': expired,
      'active_entries': _cache.length - expired,
    };
  }

  /// Cache with auto-fetch if missing
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? expiry,
    bool forceRefresh = false,
  }) async {
    // Force refresh bypasses cache
    if (!forceRefresh) {
      final cached = get<T>(key);
      if (cached != null) return cached;
    }

    // Fetch fresh data
    final data = await fetcher();
    set(key, data, expiry: expiry);
    return data;
  }

  /// Invalidate cache by prefix (e.g., all user-specific caches)
  void invalidatePrefix(String prefix) {
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Preload cache in background
  Future<void> preload<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? expiry,
  }) async {
    if (has(key)) return; // Already cached

    try {
      final data = await fetcher();
      set(key, data, expiry: expiry);
    } catch (e) {
      // Silent fail for preload
    }
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry({
    required this.data,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Cache key helpers
class CacheKeys {
  // User-specific
  static String userChallenges(String userId) => 'user_challenges_$userId';
  static String userAchievements(String userId) => 'user_achievements_$userId';
  static String userStats(String userId) => 'user_stats_$userId';
  static String userJournal(String userId) => 'user_journal_$userId';
  static String userSettings(String userId) => 'user_settings_$userId';

  // Global
  static const challenges = 'challenges_all';
  static const achievements = 'achievements_all';

  // Prefixes for batch invalidation
  static String userPrefix(String userId) => 'user_${userId}_';
}
