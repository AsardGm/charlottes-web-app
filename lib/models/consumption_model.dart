/// Consumption method
enum ConsumptionMethod {
  joint('Joint', '🚬'),
  vape('Vaporizer', '💨'),
  bong('Bong', '🫧'),
  edible('Edible', '🍪'),
  pipe('Pipe', '🌬️'),
  other('Other', '🔄');

  const ConsumptionMethod(this.label, this.emoji);
  final String label;
  final String emoji;
}

extension ConsumptionMethodExtension on ConsumptionMethod {
  static ConsumptionMethod fromString(String value) {
    return ConsumptionMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ConsumptionMethod.other,
    );
  }
}

/// Time of day
enum TimeOfDay {
  morning('Ráno', '🌅'),
  afternoon('Odpoledne', '☀️'),
  evening('Večer', '🌆'),
  night('Noc', '🌙');

  const TimeOfDay(this.label, this.emoji);
  final String label;
  final String emoji;
}

extension TimeOfDayExtension on TimeOfDay {
  static TimeOfDay fromString(String value) {
    return TimeOfDay.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TimeOfDay.evening,
    );
  }

  static TimeOfDay fromDateTime(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour >= 5 && hour < 12) return TimeOfDay.morning;
    if (hour >= 12 && hour < 17) return TimeOfDay.afternoon;
    if (hour >= 17 && hour < 22) return TimeOfDay.evening;
    return TimeOfDay.night;
  }
}

/// Body state after consumption
enum BodyState {
  relaxed('Relaxed', '😌'),
  heavy('Heavy', '😴'),
  clear('Clear', '✨'),
  tense('Tense', '😬'),
  energized('Energized', '⚡'),
  numb('Numb', '🫥');

  const BodyState(this.label, this.emoji);
  final String label;
  final String emoji;
}

extension BodyStateExtension on BodyState {
  static BodyState fromString(String value) {
    return BodyState.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BodyState.relaxed,
    );
  }
}

/// Appetite change
enum AppetiteChange {
  increased('Increased', '🍔'),
  decreased('Decreased', '🚫'),
  noChange('No change', '➖');

  const AppetiteChange(this.label, this.emoji);
  final String label;
  final String emoji;
}

extension AppetiteChangeExtension on AppetiteChange {
  static AppetiteChange fromString(String value) {
    return AppetiteChange.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppetiteChange.noChange,
    );
  }
}

/// Consumption log - záznam o užití
class ConsumptionLog {
  final String? id;
  final String userId;
  final String strainId;
  final DateTime timestamp;
  final double amount; // grams
  final ConsumptionMethod method;
  final TimeOfDay? timeOfDay;
  final String? context;
  final String? notes;

  // Pre-consumption state (optional)
  final int? preCognitiveScore;
  final int? preMood;
  final int? preEnergy;

  ConsumptionLog({
    this.id,
    required this.userId,
    required this.strainId,
    DateTime? timestamp,
    required this.amount,
    required this.method,
    this.timeOfDay,
    this.context,
    this.notes,
    this.preCognitiveScore,
    this.preMood,
    this.preEnergy,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ConsumptionLog.fromJson(Map<String, dynamic> json) {
    return ConsumptionLog(
      id: json['id'],
      userId: json['user_id'],
      strainId: json['strain_id'],
      timestamp: DateTime.parse(json['timestamp']),
      amount: (json['amount'] as num).toDouble(),
      method: ConsumptionMethodExtension.fromString(json['method']),
      timeOfDay: json['time_of_day'] != null
          ? TimeOfDayExtension.fromString(json['time_of_day'])
          : null,
      context: json['context'],
      notes: json['notes'],
      preCognitiveScore: json['pre_cognitive_score'],
      preMood: json['pre_mood'],
      preEnergy: json['pre_energy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'strain_id': strainId,
      'timestamp': timestamp.toIso8601String(),
      'amount': amount,
      'method': method.name,
      if (timeOfDay != null) 'time_of_day': timeOfDay!.name,
      if (context != null) 'context': context,
      if (notes != null) 'notes': notes,
      if (preCognitiveScore != null) 'pre_cognitive_score': preCognitiveScore,
      if (preMood != null) 'pre_mood': preMood,
      if (preEnergy != null) 'pre_energy': preEnergy,
    };
  }
}

/// Post-consumption check - hodnocení efektů po užití
class PostConsumptionCheck {
  final String? id;
  final String consumptionLogId;
  final String userId;
  final DateTime checkTimestamp;
  final int? minutesAfterConsumption;

  // Subjective effects (1-10)
  final int focusScore;
  final int moodScore;
  final int energyScore;
  final int anxietyLevel; // 0-10
  final int? creativityScore;

  final BodyState bodyState;
  final AppetiteChange? appetiteChange;
  final int? painRelief; // 0-10

  final String? notes;

  PostConsumptionCheck({
    this.id,
    required this.consumptionLogId,
    required this.userId,
    DateTime? checkTimestamp,
    this.minutesAfterConsumption,
    required this.focusScore,
    required this.moodScore,
    required this.energyScore,
    required this.anxietyLevel,
    this.creativityScore,
    required this.bodyState,
    this.appetiteChange,
    this.painRelief,
    this.notes,
  }) : checkTimestamp = checkTimestamp ?? DateTime.now();

  factory PostConsumptionCheck.fromJson(Map<String, dynamic> json) {
    return PostConsumptionCheck(
      id: json['id'],
      consumptionLogId: json['consumption_log_id'],
      userId: json['user_id'],
      checkTimestamp: DateTime.parse(json['check_timestamp']),
      minutesAfterConsumption: json['minutes_after_consumption'],
      focusScore: json['focus_score'],
      moodScore: json['mood_score'],
      energyScore: json['energy_score'],
      anxietyLevel: json['anxiety_level'],
      creativityScore: json['creativity_score'],
      bodyState: BodyStateExtension.fromString(json['body_state']),
      appetiteChange: json['appetite_change'] != null
          ? AppetiteChangeExtension.fromString(json['appetite_change'])
          : null,
      painRelief: json['pain_relief'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'consumption_log_id': consumptionLogId,
      'user_id': userId,
      'check_timestamp': checkTimestamp.toIso8601String(),
      if (minutesAfterConsumption != null)
        'minutes_after_consumption': minutesAfterConsumption,
      'focus_score': focusScore,
      'mood_score': moodScore,
      'energy_score': energyScore,
      'anxiety_level': anxietyLevel,
      if (creativityScore != null) 'creativity_score': creativityScore,
      'body_state': bodyState.name,
      if (appetiteChange != null) 'appetite_change': appetiteChange!.name,
      if (painRelief != null) 'pain_relief': painRelief,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Strain-user correlation - vypočítané korelace
class StrainUserCorrelation {
  final String id;
  final String userId;
  final String strainId;
  final int totalConsumptions;
  final double? avgFocusScore;
  final double? avgMoodScore;
  final double? avgEnergyScore;
  final double? avgAnxietyLevel;
  final double? avgCreativityScore;
  final double? personalRating; // 0-10
  final String? mostCommonBodyState;
  final DateTime lastUpdated;

  StrainUserCorrelation({
    required this.id,
    required this.userId,
    required this.strainId,
    required this.totalConsumptions,
    this.avgFocusScore,
    this.avgMoodScore,
    this.avgEnergyScore,
    this.avgAnxietyLevel,
    this.avgCreativityScore,
    this.personalRating,
    this.mostCommonBodyState,
    required this.lastUpdated,
  });

  factory StrainUserCorrelation.fromJson(Map<String, dynamic> json) {
    return StrainUserCorrelation(
      id: json['id'],
      userId: json['user_id'],
      strainId: json['strain_id'],
      totalConsumptions: json['total_consumptions'],
      avgFocusScore: (json['avg_focus_score'] as num?)?.toDouble(),
      avgMoodScore: (json['avg_mood_score'] as num?)?.toDouble(),
      avgEnergyScore: (json['avg_energy_score'] as num?)?.toDouble(),
      avgAnxietyLevel: (json['avg_anxiety_level'] as num?)?.toDouble(),
      avgCreativityScore: (json['avg_creativity_score'] as num?)?.toDouble(),
      personalRating: (json['personal_rating'] as num?)?.toDouble(),
      mostCommonBodyState: json['most_common_body_state'],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}

/// Insight type
enum InsightType {
  strainRecommendation('Strain Recommendation', '🌿'),
  terpeneSensitivity('Terpene Sensitivity', '🧬'),
  timingPattern('Timing Pattern', '⏰'),
  toleranceWarning('Tolerance Warning', '⚠️'),
  cognitiveImpact('Cognitive Impact', '🧠'),
  bestMatch('Best Match', '⭐'),
  worstMatch('Worst Match', '❌');

  const InsightType(this.label, this.emoji);
  final String label;
  final String emoji;
}

extension InsightTypeExtension on InsightType {
  static InsightType fromString(String value) {
    // Convert snake_case to camelCase for enum matching
    final camelCase = value.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (match) => match.group(1)!.toUpperCase(),
    );
    return InsightType.values.firstWhere(
      (e) => e.name == camelCase,
      orElse: () => InsightType.strainRecommendation,
    );
  }
}

/// Consumption insight
class ConsumptionInsight {
  final String id;
  final String userId;
  final InsightType insightType;
  final String title;
  final String description;
  final Map<String, dynamic>? data;
  final double? confidenceScore;
  final int priority;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;

  ConsumptionInsight({
    required this.id,
    required this.userId,
    required this.insightType,
    required this.title,
    required this.description,
    this.data,
    this.confidenceScore,
    required this.priority,
    required this.isActive,
    required this.createdAt,
    this.expiresAt,
  });

  factory ConsumptionInsight.fromJson(Map<String, dynamic> json) {
    return ConsumptionInsight(
      id: json['id'],
      userId: json['user_id'],
      insightType: InsightTypeExtension.fromString(json['insight_type']),
      title: json['title'],
      description: json['description'],
      data: json['data'] as Map<String, dynamic>?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      priority: json['priority'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      expiresAt:
          json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }
}
