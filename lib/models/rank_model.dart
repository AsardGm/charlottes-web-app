import 'package:flutter/material.dart';

/// Model pro Spider Rank (urovne uzivatelu)
class SpiderRank {
  final String id;
  final String name;
  final String nameEn;
  final String description;
  final int minXp;
  final int maxXp;
  final Color color;
  final String emoji;
  final List<String> permissions;

  const SpiderRank({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.minXp,
    required this.maxXp,
    required this.color,
    required this.emoji,
    required this.permissions,
  });

  /// Zjisti, zda ma uzivatel s timto rankem dane opravneni
  bool hasPermission(String permission) => permissions.contains(permission);

  /// Vypocita procento progressu v aktualnim ranku
  double getProgress(int currentXp) {
    if (currentXp >= maxXp) return 1.0;
    if (currentXp < minXp) return 0.0;
    return (currentXp - minXp) / (maxXp - minXp);
  }

  /// XP potrebne pro dalsi rank
  int xpToNextRank(int currentXp) {
    if (currentXp >= maxXp) return 0;
    return maxXp - currentXp;
  }
}

/// Opravneni pro ranky
class RankPermissions {
  static const String view = 'view';
  static const String like = 'like';
  static const String comment = 'comment';
  static const String uploadPhoto = 'upload_photo';
  static const String createThread = 'create_thread';
  static const String accessSecretDrops = 'access_secret_drops';
  static const String moderate = 'moderate';
  static const String veto = 'veto';
}

/// Definice vsech Spider Ranks
class SpiderRanks {
  static const SpiderRank egg = SpiderRank(
    id: 'egg',
    name: 'Vajicko',
    nameEn: 'Egg',
    description: 'Novacek, muze jen prohli­zet a lajkovat.',
    minXp: 0,
    maxXp: 100,
    color: Color(0xFFE0E0E0),
    emoji: '🥚',
    permissions: [
      RankPermissions.view,
      RankPermissions.like,
    ],
  );

  static const SpiderRank spiderling = SpiderRank(
    id: 'spiderling',
    name: 'Maly krizak',
    nameEn: 'Spiderling',
    description: 'Muze nahravat fotky.',
    minXp: 100,
    maxXp: 500,
    color: Color(0xFF81C784),
    emoji: '🕷️',
    permissions: [
      RankPermissions.view,
      RankPermissions.like,
      RankPermissions.comment,
      RankPermissions.uploadPhoto,
    ],
  );

  static const SpiderRank hunter = SpiderRank(
    id: 'hunter',
    name: 'Lovec',
    nameEn: 'Hunter',
    description: 'Muze zakladat vlastni vlakna.',
    minXp: 500,
    maxXp: 2000,
    color: Color(0xFF64B5F6),
    emoji: '🎯',
    permissions: [
      RankPermissions.view,
      RankPermissions.like,
      RankPermissions.comment,
      RankPermissions.uploadPhoto,
      RankPermissions.createThread,
    ],
  );

  static const SpiderRank weaver = SpiderRank(
    id: 'weaver',
    name: 'Tkadlec',
    nameEn: 'Weaver',
    description: 'Zkuseny clen komunity.',
    minXp: 2000,
    maxXp: 5000,
    color: Color(0xFFBA68C8),
    emoji: '🕸️',
    permissions: [
      RankPermissions.view,
      RankPermissions.like,
      RankPermissions.comment,
      RankPermissions.uploadPhoto,
      RankPermissions.createThread,
    ],
  );

  static const SpiderRank widow = SpiderRank(
    id: 'widow',
    name: 'Vdova',
    nameEn: 'The Widow',
    description: 'Elitni clen, ma pristup k tajnym dropum merche.',
    minXp: 5000,
    maxXp: 15000,
    color: Color(0xFFE53935),
    emoji: '🖤',
    permissions: [
      RankPermissions.view,
      RankPermissions.like,
      RankPermissions.comment,
      RankPermissions.uploadPhoto,
      RankPermissions.createThread,
      RankPermissions.accessSecretDrops,
    ],
  );

  static const SpiderRank master = SpiderRank(
    id: 'master',
    name: 'Spider Master',
    nameEn: 'Spider Master',
    description: 'Moderator s pravem veta. Top 1%.',
    minXp: 15000,
    maxXp: 999999,
    color: Color(0xFFFFD700),
    emoji: '👑',
    permissions: [
      RankPermissions.view,
      RankPermissions.like,
      RankPermissions.comment,
      RankPermissions.uploadPhoto,
      RankPermissions.createThread,
      RankPermissions.accessSecretDrops,
      RankPermissions.moderate,
      RankPermissions.veto,
    ],
  );

  /// Vsechny ranky serazene podle XP
  static const List<SpiderRank> all = [
    egg,
    spiderling,
    hunter,
    weaver,
    widow,
    master,
  ];

  /// Ziskej rank podle XP
  static SpiderRank getRankByXp(int xp) {
    for (final rank in all.reversed) {
      if (xp >= rank.minXp) return rank;
    }
    return egg;
  }

  /// Ziskej rank podle ID
  static SpiderRank? getRankById(String id) {
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Ziskej dalsi rank
  static SpiderRank? getNextRank(SpiderRank current) {
    final index = all.indexOf(current);
    if (index < 0 || index >= all.length - 1) return null;
    return all[index + 1];
  }
}

/// XP hodnoty za ruzne akce
class XpRewards {
  static const int dailyLogin = 5;
  static const int like = 1;
  static const int receiveLike = 2;
  static const int comment = 3;
  static const int receiveComment = 5;
  static const int uploadPhoto = 10;
  static const int createThread = 15;
  static const int threadUpvote = 3;
  static const int dailyQuestComplete = 20;
  static const int weeklyQuestComplete = 100;
  static const int cardCollected = 25;
  static const int contestWin = 200;
  static const int firstPostOfDay = 10;
  static const int shareApp = 50;
}
