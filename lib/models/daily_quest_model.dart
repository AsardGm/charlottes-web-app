/// Model pro denni ukol
class DailyQuest {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final QuestType type;
  final int targetCount;
  final int currentProgress;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? timeConstraint; // napr. "before_8am"

  const DailyQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.type,
    required this.targetCount,
    this.currentProgress = 0,
    this.isCompleted = false,
    this.completedAt,
    this.timeConstraint,
  });

  double get progress => targetCount > 0 ? currentProgress / targetCount : 0;

  DailyQuest copyWith({
    String? id,
    String? title,
    String? description,
    int? xpReward,
    QuestType? type,
    int? targetCount,
    int? currentProgress,
    bool? isCompleted,
    DateTime? completedAt,
    String? timeConstraint,
  }) {
    return DailyQuest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      timeConstraint: timeConstraint ?? this.timeConstraint,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'xp_reward': xpReward,
        'type': type.name,
        'target_count': targetCount,
        'current_progress': currentProgress,
        'is_completed': isCompleted,
        'completed_at': completedAt?.toIso8601String(),
        'time_constraint': timeConstraint,
      };

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    return DailyQuest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      xpReward: json['xp_reward'] as int,
      type: QuestType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => QuestType.like,
      ),
      targetCount: json['target_count'] as int,
      currentProgress: json['current_progress'] as int? ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      timeConstraint: json['time_constraint'] as String?,
    );
  }
}

/// Typy questu
enum QuestType {
  like,
  comment,
  uploadPhoto,
  rateStrain,
  sharePost,
  visitProfile,
  sendMessage,
  collectCard,
  contestEntry,
}

/// Predefinovane denni ukoly
class DailyQuests {
  static DailyQuest earlyBird = const DailyQuest(
    id: 'early_bird',
    title: 'Ranni ptace',
    description: 'Lajkni fotku pred 8:00 rano',
    xpReward: 10,
    type: QuestType.like,
    targetCount: 1,
    timeConstraint: 'before_8am',
  );

  static DailyQuest expert = const DailyQuest(
    id: 'expert',
    title: 'Znalec',
    description: 'Ohodno­t 3 ruzne strainy',
    xpReward: 30,
    type: QuestType.rateStrain,
    targetCount: 3,
  );

  static DailyQuest photographer = const DailyQuest(
    id: 'photographer',
    title: 'Fotograf',
    description: 'Nahraj fotku do tydenni souteze',
    xpReward: 50,
    type: QuestType.contestEntry,
    targetCount: 1,
  );

  static DailyQuest socialButterfly = const DailyQuest(
    id: 'social_butterfly',
    title: 'Spolecensky',
    description: 'Komentuj 5 prispevku',
    xpReward: 25,
    type: QuestType.comment,
    targetCount: 5,
  );

  static DailyQuest explorer = const DailyQuest(
    id: 'explorer',
    title: 'Pruzkumnik',
    description: 'Navstiv 10 profilu',
    xpReward: 15,
    type: QuestType.visitProfile,
    targetCount: 10,
  );

  static DailyQuest collector = const DailyQuest(
    id: 'collector',
    title: 'Sberatel',
    description: 'Ziskej novou kartu',
    xpReward: 40,
    type: QuestType.collectCard,
    targetCount: 1,
  );

  static DailyQuest supporter = const DailyQuest(
    id: 'supporter',
    title: 'Podporovatel',
    description: 'Lajkni 10 prispevku',
    xpReward: 20,
    type: QuestType.like,
    targetCount: 10,
  );

  /// Vsechny dostupne questy
  static List<DailyQuest> get all => [
        earlyBird,
        expert,
        photographer,
        socialButterfly,
        explorer,
        collector,
        supporter,
      ];

  /// Nahodne vybere N questu pro dnesek
  static List<DailyQuest> getRandomQuests(int count, {int? seed}) {
    final shuffled = List<DailyQuest>.from(all);
    // Pouzij seed pro stabilni poradi (stejne questy cely den)
    if (seed != null) {
      shuffled.sort((a, b) => (a.id.hashCode ^ seed).compareTo(b.id.hashCode ^ seed));
    } else {
      shuffled.shuffle();
    }
    return shuffled.take(count).toList();
  }

  /// Ziska dnesni questy (stabilni pro cely den)
  static List<DailyQuest> getTodayQuests() {
    final seed = DateTime.now().year * 1000 + DateTime.now().month * 100 + DateTime.now().day;
    return getRandomQuests(3, seed: seed);
  }
}
