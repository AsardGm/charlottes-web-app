import 'package:flutter/foundation.dart';

/// Role uživatele v aplikaci
enum UserRole {
  grower,     // Pěstitel
  consumer,   // Konzument
  both,       // Obojí
  learner,    // Jen se učím
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.grower:
        return 'Grower';
      case UserRole.consumer:
        return 'Consumer';
      case UserRole.both:
        return 'Both';
      case UserRole.learner:
        return 'Learner';
    }
  }

  String get displayNameCz {
    switch (this) {
      case UserRole.grower:
        return 'Pěstitel';
      case UserRole.consumer:
        return 'Konzument';
      case UserRole.both:
        return 'Obojí';
      case UserRole.learner:
        return 'Učím se';
    }
  }

  String get description {
    switch (this) {
      case UserRole.grower:
        return 'Pěstuji vlastní rostliny';
      case UserRole.consumer:
        return 'Konzumuji, ale negroduji';
      case UserRole.both:
        return 'Dělám obojí - groduji i konzumuji';
      case UserRole.learner:
        return 'Zatím se jen zajímám a učím';
    }
  }

  String get emoji {
    switch (this) {
      case UserRole.grower:
        return '🌱';
      case UserRole.consumer:
        return '💨';
      case UserRole.both:
        return '🌿';
      case UserRole.learner:
        return '📚';
    }
  }
}

/// Úroveň zkušeností
enum ExperienceLevel {
  beginner,       // 0-1 rok
  intermediate,   // 1-3 roky
  experienced,    // 3-5 let
  expert,         // 5+ let
}

extension ExperienceLevelExtension on ExperienceLevel {
  String get displayName {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'Začátečník';
      case ExperienceLevel.intermediate:
        return 'Středně pokročilý';
      case ExperienceLevel.experienced:
        return 'Zkušený';
      case ExperienceLevel.expert:
        return 'Expert';
    }
  }

  String get description {
    switch (this) {
      case ExperienceLevel.beginner:
        return '0-1 rok zkušeností';
      case ExperienceLevel.intermediate:
        return '1-3 roky zkušeností';
      case ExperienceLevel.experienced:
        return '3-5 let zkušeností';
      case ExperienceLevel.expert:
        return '5+ let zkušeností';
    }
  }

  String get emoji {
    switch (this) {
      case ExperienceLevel.beginner:
        return '🌱';
      case ExperienceLevel.intermediate:
        return '🌿';
      case ExperienceLevel.experienced:
        return '🍁';
      case ExperienceLevel.expert:
        return '🏆';
    }
  }
}

/// Oblasti zájmu
enum UserInterest {
  genetics,       // Genetika a historie strainů
  terpenes,       // Terpeny a jejich efekty
  growing,        // Growing techniky
  healthWellness, // Zdraví a wellness
  community,      // Komunita a socializace
  competitions,   // Soutěže a challenges
  education,      // Vzdělávání
  tracking,       // Trackování consumption/grows
}

extension UserInterestExtension on UserInterest {
  String get displayName {
    switch (this) {
      case UserInterest.genetics:
        return 'Genetika strainů';
      case UserInterest.terpenes:
        return 'Terpeny & efekty';
      case UserInterest.growing:
        return 'Growing techniky';
      case UserInterest.healthWellness:
        return 'Zdraví & wellness';
      case UserInterest.community:
        return 'Komunita';
      case UserInterest.competitions:
        return 'Soutěže & výzvy';
      case UserInterest.education:
        return 'Vzdělávání';
      case UserInterest.tracking:
        return 'Trackování';
    }
  }

  String get emoji {
    switch (this) {
      case UserInterest.genetics:
        return '🧬';
      case UserInterest.terpenes:
        return '🌿';
      case UserInterest.growing:
        return '🌱';
      case UserInterest.healthWellness:
        return '🧘';
      case UserInterest.community:
        return '👥';
      case UserInterest.competitions:
        return '🏆';
      case UserInterest.education:
        return '📚';
      case UserInterest.tracking:
        return '📊';
    }
  }
}

/// Cíle používání aplikace
enum UserGoal {
  trackConsumption,   // Trackovat konzumaci a efekty
  improveGrows,       // Zlepšit grows
  learnCannabis,      // Naučit se o konopí
  connectCommunity,   // Spojit se s komunitou
  manageTolerance,    // Spravovat toleranci
  monitorHealth,      // Sledovat cognitive health
  findStrains,        // Objevovat nové strainy
  shareKnowledge,     // Sdílet znalosti
}

extension UserGoalExtension on UserGoal {
  String get displayName {
    switch (this) {
      case UserGoal.trackConsumption:
        return 'Trackovat konzumaci';
      case UserGoal.improveGrows:
        return 'Zlepšit grows';
      case UserGoal.learnCannabis:
        return 'Učit se o konopí';
      case UserGoal.connectCommunity:
        return 'Spojit se s lidmi';
      case UserGoal.manageTolerance:
        return 'Spravovat toleranci';
      case UserGoal.monitorHealth:
        return 'Sledovat brain health';
      case UserGoal.findStrains:
        return 'Objevovat strainy';
      case UserGoal.shareKnowledge:
        return 'Sdílet znalosti';
    }
  }

  String get emoji {
    switch (this) {
      case UserGoal.trackConsumption:
        return '📊';
      case UserGoal.improveGrows:
        return '🌱';
      case UserGoal.learnCannabis:
        return '📚';
      case UserGoal.connectCommunity:
        return '👥';
      case UserGoal.manageTolerance:
        return '⏸️';
      case UserGoal.monitorHealth:
        return '🧠';
      case UserGoal.findStrains:
        return '🔍';
      case UserGoal.shareKnowledge:
        return '💬';
    }
  }
}

/// Model uživatelských preferences pro personalizaci
@immutable
class UserPreferences {
  final UserRole? role;
  final ExperienceLevel? experienceLevel;
  final List<UserInterest> interests;
  final List<UserGoal> goals;
  final bool onboardingCompleted;
  final DateTime? completedAt;

  const UserPreferences({
    this.role,
    this.experienceLevel,
    this.interests = const [],
    this.goals = const [],
    this.onboardingCompleted = false,
    this.completedAt,
  });

  /// Vytvoř kopii s novými hodnotami
  UserPreferences copyWith({
    UserRole? role,
    ExperienceLevel? experienceLevel,
    List<UserInterest>? interests,
    List<UserGoal>? goals,
    bool? onboardingCompleted,
    DateTime? completedAt,
  }) {
    return UserPreferences(
      role: role ?? this.role,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      interests: interests ?? this.interests,
      goals: goals ?? this.goals,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Serializace do JSON
  Map<String, dynamic> toJson() {
    return {
      'role': role?.name,
      'experienceLevel': experienceLevel?.name,
      'interests': interests.map((i) => i.name).toList(),
      'goals': goals.map((g) => g.name).toList(),
      'onboardingCompleted': onboardingCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// Deserializace z JSON
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      role: json['role'] != null
          ? UserRole.values.firstWhere((e) => e.name == json['role'])
          : null,
      experienceLevel: json['experienceLevel'] != null
          ? ExperienceLevel.values
              .firstWhere((e) => e.name == json['experienceLevel'])
          : null,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((i) =>
                  UserInterest.values.firstWhere((e) => e.name == i as String))
              .toList() ??
          [],
      goals: (json['goals'] as List<dynamic>?)
              ?.map(
                  (g) => UserGoal.values.firstWhere((e) => e.name == g as String))
              .toList() ??
          [],
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  /// Empty/default preferences
  static const UserPreferences empty = UserPreferences();

  /// Je onboarding kompletní?
  bool get isComplete =>
      role != null &&
      experienceLevel != null &&
      interests.isNotEmpty &&
      goals.isNotEmpty;

  /// Má user zájem o growing?
  bool get isInterestedInGrowing =>
      role == UserRole.grower ||
      role == UserRole.both ||
      interests.contains(UserInterest.growing);

  /// Má user zájem o consumption tracking?
  bool get isInterestedInTracking =>
      role == UserRole.consumer ||
      role == UserRole.both ||
      goals.contains(UserGoal.trackConsumption) ||
      interests.contains(UserInterest.tracking);

  /// Má user zájem o community?
  bool get isInterestedInCommunity =>
      interests.contains(UserInterest.community) ||
      goals.contains(UserGoal.connectCommunity) ||
      goals.contains(UserGoal.shareKnowledge);

  /// Má user zájem o zdraví a wellness?
  bool get isInterestedInHealth =>
      interests.contains(UserInterest.healthWellness) ||
      goals.contains(UserGoal.monitorHealth) ||
      goals.contains(UserGoal.manageTolerance);

  /// Má user zájem o vzdělávání?
  bool get isInterestedInEducation =>
      role == UserRole.learner ||
      interests.contains(UserInterest.education) ||
      goals.contains(UserGoal.learnCannabis);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          runtimeType == other.runtimeType &&
          role == other.role &&
          experienceLevel == other.experienceLevel &&
          listEquals(interests, other.interests) &&
          listEquals(goals, other.goals) &&
          onboardingCompleted == other.onboardingCompleted;

  @override
  int get hashCode =>
      role.hashCode ^
      experienceLevel.hashCode ^
      interests.hashCode ^
      goals.hashCode ^
      onboardingCompleted.hashCode;
}
