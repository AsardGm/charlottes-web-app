/// Status cognitive stavu
enum CognitiveStatus {
  sharp('Sharp 🔥', 'Jsi dnes v top formě'),
  normal('Normal ✅', 'Standardní výkon'),
  tired('Unavený 😴', 'Trochu pomalejší než obvykle'),
  blurry('Rozostřený 🌫️', 'Dnes nejsi ve formě'),
  overloaded('Přetažený 🔴', 'Mozek potřebuje pauzu');

  const CognitiveStatus(this.label, this.description);
  final String label;
  final String description;
}

extension CognitiveStatusExtension on CognitiveStatus {
  static CognitiveStatus fromString(String value) {
    return CognitiveStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CognitiveStatus.normal,
    );
  }

  /// Vypočítá status z score a baseline
  static CognitiveStatus fromScore(int score, int? baselineScore) {
    if (baselineScore == null) {
      // Bez baseline používáme absolutní hodnoty
      if (score >= 90) return CognitiveStatus.sharp;
      if (score >= 75) return CognitiveStatus.normal;
      if (score >= 60) return CognitiveStatus.tired;
      if (score >= 45) return CognitiveStatus.blurry;
      return CognitiveStatus.overloaded;
    }

    // S baseline porovnáváme relativně
    final diff = score - baselineScore;
    if (diff >= 5) return CognitiveStatus.sharp;
    if (diff >= -5) return CognitiveStatus.normal;
    if (diff >= -15) return CognitiveStatus.tired;
    if (diff >= -25) return CognitiveStatus.blurry;
    return CognitiveStatus.overloaded;
  }
}

/// Výsledek reaction time testu
class ReactionTimeResult {
  final List<int> reactionTimesMs;
  final int averageMs;
  final int bestMs;
  final int worstMs;
  final int score; // 0-100

  ReactionTimeResult({
    required this.reactionTimesMs,
    required this.averageMs,
    required this.bestMs,
    required this.worstMs,
    required this.score,
  });

  factory ReactionTimeResult.fromJson(Map<String, dynamic> json) {
    return ReactionTimeResult(
      reactionTimesMs: (json['reaction_times_ms'] as List).cast<int>(),
      averageMs: json['average_ms'],
      bestMs: json['best_ms'],
      worstMs: json['worst_ms'],
      score: json['score'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reaction_times_ms': reactionTimesMs,
      'average_ms': averageMs,
      'best_ms': bestMs,
      'worst_ms': worstMs,
      'score': score,
    };
  }
}

/// Výsledek memory flash testu
class MemoryFlashResult {
  final int totalAttempts;
  final int correctAnswers;
  final int score; // 0-100

  MemoryFlashResult({
    required this.totalAttempts,
    required this.correctAnswers,
    required this.score,
  });

  double get accuracy => totalAttempts > 0 ? correctAnswers / totalAttempts : 0;

  factory MemoryFlashResult.fromJson(Map<String, dynamic> json) {
    return MemoryFlashResult(
      totalAttempts: json['total_attempts'],
      correctAnswers: json['correct_answers'],
      score: json['score'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_attempts': totalAttempts,
      'correct_answers': correctAnswers,
      'score': score,
    };
  }
}

/// Výsledek pattern recognition testu
class PatternRecognitionResult {
  final int totalAttempts;
  final int correctAnswers;
  final int averageTimeMs;
  final int score; // 0-100

  PatternRecognitionResult({
    required this.totalAttempts,
    required this.correctAnswers,
    required this.averageTimeMs,
    required this.score,
  });

  double get accuracy => totalAttempts > 0 ? correctAnswers / totalAttempts : 0;

  factory PatternRecognitionResult.fromJson(Map<String, dynamic> json) {
    return PatternRecognitionResult(
      totalAttempts: json['total_attempts'],
      correctAnswers: json['correct_answers'],
      averageTimeMs: json['average_time_ms'],
      score: json['score'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_attempts': totalAttempts,
      'correct_answers': correctAnswers,
      'average_time_ms': averageTimeMs,
      'score': score,
    };
  }
}

/// Výsledek jednoho cognitive testu
class CognitiveTestResult {
  final String? id;
  final String userId;
  final DateTime timestamp;
  final ReactionTimeResult reactionTime;
  final MemoryFlashResult memoryFlash;
  final PatternRecognitionResult patternRecognition;
  final int totalScore; // 0-100
  final CognitiveStatus status;

  CognitiveTestResult({
    this.id,
    required this.userId,
    DateTime? timestamp,
    required this.reactionTime,
    required this.memoryFlash,
    required this.patternRecognition,
    required this.totalScore,
    required this.status,
  }) : timestamp = timestamp ?? DateTime.now();

  factory CognitiveTestResult.fromJson(Map<String, dynamic> json) {
    return CognitiveTestResult(
      id: json['id'],
      userId: json['user_id'],
      timestamp: DateTime.parse(json['timestamp']),
      reactionTime: ReactionTimeResult.fromJson(json['reaction_time']),
      memoryFlash: MemoryFlashResult.fromJson(json['memory_flash']),
      patternRecognition:
          PatternRecognitionResult.fromJson(json['pattern_recognition']),
      totalScore: json['total_score'],
      status: CognitiveStatusExtension.fromString(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'reaction_time': reactionTime.toJson(),
      'memory_flash': memoryFlash.toJson(),
      'pattern_recognition': patternRecognition.toJson(),
      'total_score': totalScore,
      'status': status.name,
    };
  }

  /// Vypočítá celkový score z jednotlivých testů
  static int calculateTotalScore({
    required ReactionTimeResult reactionTime,
    required MemoryFlashResult memoryFlash,
    required PatternRecognitionResult patternRecognition,
  }) {
    // Váhy pro jednotlivé testy
    const reactionWeight = 0.35;
    const memoryWeight = 0.35;
    const patternWeight = 0.30;

    final weighted = (reactionTime.score * reactionWeight) +
        (memoryFlash.score * memoryWeight) +
        (patternRecognition.score * patternWeight);

    return weighted.round().clamp(0, 100);
  }
}

/// Baseline uživatele (průměr posledních 7 testů)
class CognitiveBaseline {
  final String? id;
  final String userId;
  final int averageScore;
  final int averageReactionMs;
  final double averageMemoryAccuracy; // 0.0-1.0
  final double averagePatternAccuracy; // 0.0-1.0
  final int totalTests;
  final DateTime lastUpdated;

  CognitiveBaseline({
    this.id,
    required this.userId,
    required this.averageScore,
    required this.averageReactionMs,
    required this.averageMemoryAccuracy,
    required this.averagePatternAccuracy,
    required this.totalTests,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory CognitiveBaseline.fromJson(Map<String, dynamic> json) {
    return CognitiveBaseline(
      id: json['id'],
      userId: json['user_id'],
      averageScore: json['average_score'],
      averageReactionMs: json['average_reaction_ms'],
      averageMemoryAccuracy: (json['average_memory_accuracy'] as num).toDouble(),
      averagePatternAccuracy:
          (json['average_pattern_accuracy'] as num).toDouble(),
      totalTests: json['total_tests'],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'average_score': averageScore,
      'average_reaction_ms': averageReactionMs,
      'average_memory_accuracy': averageMemoryAccuracy,
      'average_pattern_accuracy': averagePatternAccuracy,
      'total_tests': totalTests,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  CognitiveBaseline copyWith({
    String? id,
    String? userId,
    int? averageScore,
    int? averageReactionMs,
    double? averageMemoryAccuracy,
    double? averagePatternAccuracy,
    int? totalTests,
    DateTime? lastUpdated,
  }) {
    return CognitiveBaseline(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      averageScore: averageScore ?? this.averageScore,
      averageReactionMs: averageReactionMs ?? this.averageReactionMs,
      averageMemoryAccuracy:
          averageMemoryAccuracy ?? this.averageMemoryAccuracy,
      averagePatternAccuracy:
          averagePatternAccuracy ?? this.averagePatternAccuracy,
      totalTests: totalTests ?? this.totalTests,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
