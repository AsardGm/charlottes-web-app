import 'package:flutter/material.dart';

/// Kategorie odznaku
enum BadgeCategory {
  achievement,    // Dosazene uspech
  milestone,      // Milniky (pocet prispevku, XP, atd.)
  special,        // Specialni (zakladajici clen, VIP, atd.)
  event,          // Eventove (souteze, akce)
  seasonal,       // Sezonni (Halloween, Vanoce, atd.)
}

extension BadgeCategoryExtension on BadgeCategory {
  String get name {
    switch (this) {
      case BadgeCategory.achievement:
        return 'Uspechy';
      case BadgeCategory.milestone:
        return 'Milniky';
      case BadgeCategory.special:
        return 'Specialni';
      case BadgeCategory.event:
        return 'Eventy';
      case BadgeCategory.seasonal:
        return 'Sezonni';
    }
  }

  IconData get icon {
    switch (this) {
      case BadgeCategory.achievement:
        return Icons.emoji_events;
      case BadgeCategory.milestone:
        return Icons.flag;
      case BadgeCategory.special:
        return Icons.star;
      case BadgeCategory.event:
        return Icons.celebration;
      case BadgeCategory.seasonal:
        return Icons.ac_unit;
    }
  }

  Color get color {
    switch (this) {
      case BadgeCategory.achievement:
        return const Color(0xFFFFD700);
      case BadgeCategory.milestone:
        return const Color(0xFF4CAF50);
      case BadgeCategory.special:
        return const Color(0xFF9C27B0);
      case BadgeCategory.event:
        return const Color(0xFFFF5722);
      case BadgeCategory.seasonal:
        return const Color(0xFF03A9F4);
    }
  }
}

/// Rarita odznaku
enum BadgeRarity {
  common,
  rare,
  epic,
  legendary,
}

extension BadgeRarityExtension on BadgeRarity {
  String get name {
    switch (this) {
      case BadgeRarity.common:
        return 'Bezny';
      case BadgeRarity.rare:
        return 'Vzacny';
      case BadgeRarity.epic:
        return 'Epicky';
      case BadgeRarity.legendary:
        return 'Legendarni';
    }
  }

  Color get color {
    switch (this) {
      case BadgeRarity.common:
        return const Color(0xFF9E9E9E);
      case BadgeRarity.rare:
        return const Color(0xFF2196F3);
      case BadgeRarity.epic:
        return const Color(0xFF9C27B0);
      case BadgeRarity.legendary:
        return const Color(0xFFFFD700);
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case BadgeRarity.common:
        return [const Color(0xFF757575), const Color(0xFF9E9E9E)];
      case BadgeRarity.rare:
        return [const Color(0xFF1565C0), const Color(0xFF42A5F5)];
      case BadgeRarity.epic:
        return [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)];
      case BadgeRarity.legendary:
        return [const Color(0xFFFF8F00), const Color(0xFFFFD54F)];
    }
  }
}

/// Model pro odznak
class Badge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final BadgeCategory category;
  final BadgeRarity rarity;
  final String? imageUrl;
  final int xpReward;
  final bool isSecret;  // Skryty odznak dokud neziskas
  final BadgeRequirement? requirement;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.rarity,
    this.imageUrl,
    this.xpReward = 0,
    this.isSecret = false,
    this.requirement,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'emoji': emoji,
    'category': category.name,
    'rarity': rarity.name,
    'image_url': imageUrl,
    'xp_reward': xpReward,
    'is_secret': isSecret,
  };

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String? ?? '🏆',
      category: BadgeCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => BadgeCategory.achievement,
      ),
      rarity: BadgeRarity.values.firstWhere(
        (r) => r.name == json['rarity'],
        orElse: () => BadgeRarity.common,
      ),
      imageUrl: json['image_url'] as String?,
      xpReward: json['xp_reward'] as int? ?? 0,
      isSecret: json['is_secret'] as bool? ?? false,
    );
  }
}

/// Pozadavek pro ziskani odznaku
class BadgeRequirement {
  final String type;  // 'posts', 'xp', 'likes', 'cards', 'webs', 'days', atd.
  final int targetValue;
  final String? description;

  const BadgeRequirement({
    required this.type,
    required this.targetValue,
    this.description,
  });
}

/// Odznak uzivatele
class UserBadge {
  final String oderId;
  final String oderId2;
  final String badgeId;
  final Badge badge;
  final DateTime earnedAt;
  final bool isNew;  // Jeste nezobrazeno uzivateli
  final bool isFeatured;  // Zobrazeno v profilu

  const UserBadge({
    required this.oderId,
    required this.oderId2,
    required this.badgeId,
    required this.badge,
    required this.earnedAt,
    this.isNew = false,
    this.isFeatured = false,
  });

  Map<String, dynamic> toJson() => {
    'user_id': oderId,
    'badge_id': badgeId,
    'earned_at': earnedAt.toIso8601String(),
    'is_new': isNew,
    'is_featured': isFeatured,
  };

  factory UserBadge.fromJson(Map<String, dynamic> json, Badge badge) {
    return UserBadge(
      oderId: json['user_id'] as String,
      oderId2: json['user_id'] as String,
      badgeId: json['badge_id'] as String,
      badge: badge,
      earnedAt: DateTime.parse(json['earned_at'] as String),
      isNew: json['is_new'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
    );
  }

  UserBadge copyWith({
    bool? isNew,
    bool? isFeatured,
  }) {
    return UserBadge(
      oderId: oderId,
      oderId2: oderId2,
      badgeId: badgeId,
      badge: badge,
      earnedAt: earnedAt,
      isNew: isNew ?? this.isNew,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}

/// Predefinovane odznaky
class Badges {
  // Achievement badges
  static const Badge firstPost = Badge(
    id: 'first_post',
    name: 'Prvni prispevek',
    description: 'Vytvoril jsi svuj prvni prispevek',
    emoji: '📝',
    category: BadgeCategory.achievement,
    rarity: BadgeRarity.common,
    xpReward: 25,
    requirement: BadgeRequirement(type: 'posts', targetValue: 1),
  );

  static const Badge photoUploader = Badge(
    id: 'photo_uploader',
    name: 'Fotograf',
    description: 'Nahral jsi 10 fotek',
    emoji: '📸',
    category: BadgeCategory.achievement,
    rarity: BadgeRarity.common,
    xpReward: 50,
    requirement: BadgeRequirement(type: 'photos', targetValue: 10),
  );

  static const Badge socialButterfly = Badge(
    id: 'social_butterfly',
    name: 'Spolecensky typ',
    description: 'Sleduje te 50 lidi',
    emoji: '🦋',
    category: BadgeCategory.achievement,
    rarity: BadgeRarity.rare,
    xpReward: 100,
    requirement: BadgeRequirement(type: 'followers', targetValue: 50),
  );

  static const Badge strainExpert = Badge(
    id: 'strain_expert',
    name: 'Znalec strainu',
    description: 'Sebral jsi 25 ruznych karet',
    emoji: '🌿',
    category: BadgeCategory.achievement,
    rarity: BadgeRarity.rare,
    xpReward: 150,
    requirement: BadgeRequirement(type: 'cards', targetValue: 25),
  );

  static const Badge terpeneMaster = Badge(
    id: 'terpene_master',
    name: 'Mistr terpenu',
    description: 'Ohodnotil jsi 100 strainu',
    emoji: '🧪',
    category: BadgeCategory.achievement,
    rarity: BadgeRarity.epic,
    xpReward: 200,
    requirement: BadgeRequirement(type: 'reviews', targetValue: 100),
  );

  // Milestone badges
  static const Badge xp100 = Badge(
    id: 'xp_100',
    name: 'Zacatecnik',
    description: 'Dosahl jsi 100 XP',
    emoji: '⭐',
    category: BadgeCategory.milestone,
    rarity: BadgeRarity.common,
    requirement: BadgeRequirement(type: 'xp', targetValue: 100),
  );

  static const Badge xp1000 = Badge(
    id: 'xp_1000',
    name: 'Pokrocily',
    description: 'Dosahl jsi 1000 XP',
    emoji: '🌟',
    category: BadgeCategory.milestone,
    rarity: BadgeRarity.rare,
    requirement: BadgeRequirement(type: 'xp', targetValue: 1000),
  );

  static const Badge xp5000 = Badge(
    id: 'xp_5000',
    name: 'Veterán',
    description: 'Dosahl jsi 5000 XP',
    emoji: '💫',
    category: BadgeCategory.milestone,
    rarity: BadgeRarity.epic,
    requirement: BadgeRequirement(type: 'xp', targetValue: 5000),
  );

  static const Badge xp15000 = Badge(
    id: 'xp_15000',
    name: 'Legenda',
    description: 'Dosahl jsi 15000 XP',
    emoji: '👑',
    category: BadgeCategory.milestone,
    rarity: BadgeRarity.legendary,
    requirement: BadgeRequirement(type: 'xp', targetValue: 15000),
  );

  static const Badge week1 = Badge(
    id: 'week_1',
    name: 'Prvni tyden',
    description: 'Jsi tu uz tyden!',
    emoji: '📅',
    category: BadgeCategory.milestone,
    rarity: BadgeRarity.common,
    xpReward: 20,
    requirement: BadgeRequirement(type: 'days', targetValue: 7),
  );

  static const Badge month1 = Badge(
    id: 'month_1',
    name: 'Mesicni clen',
    description: 'Jsi tu uz mesic!',
    emoji: '🗓️',
    category: BadgeCategory.milestone,
    rarity: BadgeRarity.rare,
    xpReward: 50,
    requirement: BadgeRequirement(type: 'days', targetValue: 30),
  );

  static const Badge year1 = Badge(
    id: 'year_1',
    name: 'Rocni veterán',
    description: 'Jsi tu uz rok!',
    emoji: '🎂',
    category: BadgeCategory.milestone,
    rarity: BadgeRarity.epic,
    xpReward: 200,
    requirement: BadgeRequirement(type: 'days', targetValue: 365),
  );

  // Special badges
  static const Badge founder = Badge(
    id: 'founder',
    name: 'Zakladajici clen',
    description: 'Byl jsi tady od zacatku',
    emoji: '🕷️',
    category: BadgeCategory.special,
    rarity: BadgeRarity.legendary,
    xpReward: 500,
  );

  static const Badge vip = Badge(
    id: 'vip',
    name: 'VIP',
    description: 'Jsi VIP clenem komunity',
    emoji: '💎',
    category: BadgeCategory.special,
    rarity: BadgeRarity.legendary,
    xpReward: 300,
  );

  static const Badge moderator = Badge(
    id: 'moderator',
    name: 'Moderator',
    description: 'Pomáháš udržovat komunitu',
    emoji: '🛡️',
    category: BadgeCategory.special,
    rarity: BadgeRarity.epic,
  );

  static const Badge verified = Badge(
    id: 'verified',
    name: 'Overeny',
    description: 'Overeny profil',
    emoji: '✅',
    category: BadgeCategory.special,
    rarity: BadgeRarity.rare,
  );

  // Event badges
  static const Badge photoContestWinner = Badge(
    id: 'photo_contest_winner',
    name: 'Vitez foto souteze',
    description: 'Vyhral jsi foto soutez',
    emoji: '🏆',
    category: BadgeCategory.event,
    rarity: BadgeRarity.epic,
    xpReward: 200,
  );

  static const Badge quizMaster = Badge(
    id: 'quiz_master',
    name: 'Kvizovy mistr',
    description: 'Vyhral jsi kviz o strainech',
    emoji: '🧠',
    category: BadgeCategory.event,
    rarity: BadgeRarity.rare,
    xpReward: 100,
  );

  static const Badge earlyBird = Badge(
    id: 'early_bird',
    name: 'Ranni ptace',
    description: 'Zucastnil ses early bird eventu',
    emoji: '🐦',
    category: BadgeCategory.event,
    rarity: BadgeRarity.rare,
    xpReward: 75,
  );

  // Seasonal badges
  static const Badge halloween2024 = Badge(
    id: 'halloween_2024',
    name: 'Halloween 2024',
    description: 'Zucastnil ses Halloween eventu 2024',
    emoji: '🎃',
    category: BadgeCategory.seasonal,
    rarity: BadgeRarity.rare,
    xpReward: 50,
  );

  static const Badge christmas2024 = Badge(
    id: 'christmas_2024',
    name: 'Vanoce 2024',
    description: 'Zucastnil ses Vanocniho eventu 2024',
    emoji: '🎄',
    category: BadgeCategory.seasonal,
    rarity: BadgeRarity.rare,
    xpReward: 50,
  );

  static const Badge newYear2025 = Badge(
    id: 'new_year_2025',
    name: 'Novy rok 2025',
    description: 'Privital jsi rok 2025 s nami',
    emoji: '🎆',
    category: BadgeCategory.seasonal,
    rarity: BadgeRarity.rare,
    xpReward: 50,
  );

  // Secret badges
  static const Badge nightOwl = Badge(
    id: 'night_owl',
    name: 'Nocni sova',
    description: 'Prispival jsi o pulnoci',
    emoji: '🦉',
    category: BadgeCategory.achievement,
    rarity: BadgeRarity.rare,
    xpReward: 30,
    isSecret: true,
  );

  static const Badge legendaryCard = Badge(
    id: 'legendary_card',
    name: 'Sberatel legend',
    description: 'Ziskal jsi legendarni kartu',
    emoji: '🃏',
    category: BadgeCategory.achievement,
    rarity: BadgeRarity.legendary,
    xpReward: 100,
    isSecret: true,
  );

  /// Vsechny predefinovane odznaky
  static const List<Badge> all = [
    // Achievement
    firstPost,
    photoUploader,
    socialButterfly,
    strainExpert,
    terpeneMaster,
    // Milestone
    xp100,
    xp1000,
    xp5000,
    xp15000,
    week1,
    month1,
    year1,
    // Special
    founder,
    vip,
    moderator,
    verified,
    // Event
    photoContestWinner,
    quizMaster,
    earlyBird,
    // Seasonal
    halloween2024,
    christmas2024,
    newYear2025,
    // Secret
    nightOwl,
    legendaryCard,
  ];

  /// Ziskej odznak podle ID
  static Badge? getById(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Ziskej odznaky podle kategorie
  static List<Badge> getByCategory(BadgeCategory category) {
    return all.where((b) => b.category == category).toList();
  }

  /// Ziskej odznaky podle rarity
  static List<Badge> getByRarity(BadgeRarity rarity) {
    return all.where((b) => b.rarity == rarity).toList();
  }
}
