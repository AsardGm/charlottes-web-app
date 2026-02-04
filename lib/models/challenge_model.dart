import 'package:flutter/foundation.dart';

/// Challenge definition
@immutable
class Challenge {
  final String id;
  final String title;
  final String description;
  final String category;
  final String targetType;
  final int targetValue;
  final String? targetUnit;
  final String difficulty;
  final int points;
  final String? badgeIcon;
  final String? badgeColor;
  final bool isRepeatable;
  final int? cooldownDays;
  final bool isActive;
  final int requiredLevel;
  final DateTime createdAt;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetType,
    required this.targetValue,
    this.targetUnit,
    required this.difficulty,
    required this.points,
    this.badgeIcon,
    this.badgeColor,
    this.isRepeatable = false,
    this.cooldownDays,
    this.isActive = true,
    this.requiredLevel = 0,
    required this.createdAt,
  });

  String get displayTarget {
    if (targetUnit != null) {
      return '$targetValue $targetUnit';
    }
    return targetValue.toString();
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      targetType: json['target_type'] as String,
      targetValue: json['target_value'] as int,
      targetUnit: json['target_unit'] as String?,
      difficulty: json['difficulty'] as String,
      points: json['points'] as int,
      badgeIcon: json['badge_icon'] as String?,
      badgeColor: json['badge_color'] as String?,
      isRepeatable: json['is_repeatable'] as bool? ?? false,
      cooldownDays: json['cooldown_days'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      requiredLevel: json['required_level'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// User's progress on a challenge
@immutable
class UserChallenge {
  final String id;
  final String userId;
  final String challengeId;
  final Challenge? challenge;
  final String status;
  final int currentProgress;
  final int targetProgress;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final String? notes;

  const UserChallenge({
    required this.id,
    required this.userId,
    required this.challengeId,
    this.challenge,
    required this.status,
    required this.currentProgress,
    required this.targetProgress,
    required this.startedAt,
    this.completedAt,
    this.expiresAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.notes,
  });

  double get progressPercent {
    if (targetProgress == 0) return 0.0;
    return (currentProgress / targetProgress).clamp(0.0, 1.0);
  }

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory UserChallenge.fromJson(Map<String, dynamic> json) {
    return UserChallenge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      challengeId: json['challenge_id'] as String,
      challenge: json['challenges'] != null
          ? Challenge.fromJson(json['challenges'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String,
      currentProgress: json['current_progress'] as int? ?? 0,
      targetProgress: json['target_progress'] as int,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastActivityDate: json['last_activity_date'] != null
          ? DateTime.parse(json['last_activity_date'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}

/// Achievement definition
@immutable
class Achievement {
  final String id;
  final String title;
  final String description;
  final String category;
  final String icon;
  final String? color;
  final String rarity;
  final Map<String, dynamic> unlockConditions;
  final int points;
  final String? unlocksFeature;
  final bool isSecret;
  final bool isActive;
  final DateTime createdAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    this.color,
    required this.rarity,
    required this.unlockConditions,
    required this.points,
    this.unlocksFeature,
    this.isSecret = false,
    this.isActive = true,
    required this.createdAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String?,
      rarity: json['rarity'] as String,
      unlockConditions: json['unlock_conditions'] as Map<String, dynamic>,
      points: json['points'] as int,
      unlocksFeature: json['unlocks_feature'] as String?,
      isSecret: json['is_secret'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// User's unlocked achievement
@immutable
class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final Achievement? achievement;
  final DateTime unlockedAt;
  final Map<String, dynamic>? progressData;
  final bool isShowcased;

  const UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    this.achievement,
    required this.unlockedAt,
    this.progressData,
    this.isShowcased = false,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      achievementId: json['achievement_id'] as String,
      achievement: json['achievements'] != null
          ? Achievement.fromJson(json['achievements'] as Map<String, dynamic>)
          : null,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      progressData: json['progress_data'] as Map<String, dynamic>?,
      isShowcased: json['is_showcased'] as bool? ?? false,
    );
  }
}

/// User gamification stats
@immutable
class GamificationStats {
  final String userId;
  final int totalPoints;
  final int currentLevel;
  final int pointsToNextLevel;
  final int challengesCompleted;
  final int achievementsUnlocked;
  final int currentDailyStreak;
  final int longestDailyStreak;
  final DateTime? lastActivityDate;
  final int totalJournalEntries;
  final int totalTBreakDays;
  final int totalCognitiveTests;
  final DateTime updatedAt;

  const GamificationStats({
    required this.userId,
    required this.totalPoints,
    required this.currentLevel,
    required this.pointsToNextLevel,
    required this.challengesCompleted,
    required this.achievementsUnlocked,
    required this.currentDailyStreak,
    required this.longestDailyStreak,
    this.lastActivityDate,
    required this.totalJournalEntries,
    required this.totalTBreakDays,
    required this.totalCognitiveTests,
    required this.updatedAt,
  });

  double get levelProgress {
    // Calculate progress to next level
    final pointsForLevel = (currentLevel * 50) + 100;
    final currentLevelPoints = totalPoints % pointsForLevel;
    return (currentLevelPoints / pointsToNextLevel).clamp(0.0, 1.0);
  }

  factory GamificationStats.fromJson(Map<String, dynamic> json) {
    return GamificationStats(
      userId: json['user_id'] as String,
      totalPoints: json['total_points'] as int? ?? 0,
      currentLevel: json['current_level'] as int? ?? 1,
      pointsToNextLevel: json['points_to_next_level'] as int? ?? 100,
      challengesCompleted: json['challenges_completed'] as int? ?? 0,
      achievementsUnlocked: json['achievements_unlocked'] as int? ?? 0,
      currentDailyStreak: json['current_daily_streak'] as int? ?? 0,
      longestDailyStreak: json['longest_daily_streak'] as int? ?? 0,
      lastActivityDate: json['last_activity_date'] != null
          ? DateTime.parse(json['last_activity_date'] as String)
          : null,
      totalJournalEntries: json['total_journal_entries'] as int? ?? 0,
      totalTBreakDays: json['total_tbreak_days'] as int? ?? 0,
      totalCognitiveTests: json['total_cognitive_tests'] as int? ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
