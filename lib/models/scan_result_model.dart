/// Model výsledku AI skenování
///
/// Obsahuje všechny informace z AI analýzy včetně
/// identifikované odrůdy a edukativních informací.
class ScanResultModel {
  final String id;
  final String userId;
  final String imageUrl;
  final bool identified;
  final String? strainName;
  final String? strainType; // 'indica', 'sativa', 'hybrid'
  final double? confidence; // 0-100
  final ScanCharacteristics? characteristics;
  final ScanEducation? education;
  final HealthAssessment? healthAssessment;
  final bool isFavorite;
  final DateTime createdAt;
  final Map<String, dynamic>? rawAiResponse;

  ScanResultModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.identified,
    this.strainName,
    this.strainType,
    this.confidence,
    this.characteristics,
    this.education,
    this.healthAssessment,
    this.isFavorite = false,
    required this.createdAt,
    this.rawAiResponse,
  });

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    final aiResponse = json['ai_response'] as Map<String, dynamic>?;

    return ScanResultModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String,
      identified: aiResponse?['identified'] as bool? ?? false,
      strainName: json['identified_strain'] as String?,
      strainType: json['strain_type'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      characteristics: aiResponse?['characteristics'] != null
          ? ScanCharacteristics.fromJson(
              aiResponse!['characteristics'] as Map<String, dynamic>)
          : null,
      education: aiResponse?['education'] != null
          ? ScanEducation.fromJson(
              aiResponse!['education'] as Map<String, dynamic>)
          : null,
      healthAssessment: aiResponse?['health_assessment'] != null
          ? HealthAssessment.fromJson(
              aiResponse!['health_assessment'] as Map<String, dynamic>)
          : null,
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      rawAiResponse: aiResponse,
    );
  }

  /// Vytvoří model z AI odpovědi (pro nový sken)
  factory ScanResultModel.fromAiResponse({
    required String userId,
    required String imageUrl,
    required Map<String, dynamic> aiResponse,
  }) {
    return ScanResultModel(
      id: '', // Bude přiřazeno databází
      userId: userId,
      imageUrl: imageUrl,
      identified: aiResponse['identified'] as bool? ?? false,
      strainName: aiResponse['strain_name'] as String?,
      strainType: aiResponse['strain_type'] as String?,
      confidence: (aiResponse['confidence'] as num?)?.toDouble(),
      characteristics: aiResponse['characteristics'] != null
          ? ScanCharacteristics.fromJson(
              aiResponse['characteristics'] as Map<String, dynamic>)
          : null,
      education: aiResponse['education'] != null
          ? ScanEducation.fromJson(
              aiResponse['education'] as Map<String, dynamic>)
          : null,
      healthAssessment: aiResponse['health_assessment'] != null
          ? HealthAssessment.fromJson(
              aiResponse['health_assessment'] as Map<String, dynamic>)
          : null,
      isFavorite: false,
      createdAt: DateTime.now(),
      rawAiResponse: aiResponse,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'ai_response': rawAiResponse,
      'identified_strain': strainName,
      'strain_type': strainType,
      'confidence': confidence,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Pro insert do databáze (bez id)
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'image_url': imageUrl,
      'ai_response': rawAiResponse,
      'identified_strain': strainName,
      'strain_type': strainType,
      'confidence': confidence,
      'is_favorite': isFavorite,
    };
  }

  /// Vrátí lokalizovaný typ
  String get typeLocalized {
    switch (strainType) {
      case 'indica':
        return 'Indica';
      case 'sativa':
        return 'Sativa';
      case 'hybrid':
        return 'Hybrid';
      default:
        return 'Neznámý';
    }
  }

  /// Vrátí confidence jako procenta
  String get confidencePercent {
    if (confidence == null) return 'N/A';
    return '${confidence!.toStringAsFixed(0)}%';
  }

  ScanResultModel copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    bool? identified,
    String? strainName,
    String? strainType,
    double? confidence,
    ScanCharacteristics? characteristics,
    ScanEducation? education,
    HealthAssessment? healthAssessment,
    bool? isFavorite,
    DateTime? createdAt,
    Map<String, dynamic>? rawAiResponse,
  }) {
    return ScanResultModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      identified: identified ?? this.identified,
      strainName: strainName ?? this.strainName,
      strainType: strainType ?? this.strainType,
      confidence: confidence ?? this.confidence,
      characteristics: characteristics ?? this.characteristics,
      education: education ?? this.education,
      healthAssessment: healthAssessment ?? this.healthAssessment,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      rawAiResponse: rawAiResponse ?? this.rawAiResponse,
    );
  }
}

/// Charakteristiky rostliny z AI analýzy
class ScanCharacteristics {
  final String? leafShape;
  final String? structure;
  final String? color;
  final String? trichomes;
  final String? buds;

  ScanCharacteristics({
    this.leafShape,
    this.structure,
    this.color,
    this.trichomes,
    this.buds,
  });

  factory ScanCharacteristics.fromJson(Map<String, dynamic> json) {
    return ScanCharacteristics(
      leafShape: json['leaf_shape'] as String?,
      structure: json['structure'] as String?,
      color: json['color'] as String?,
      trichomes: json['trichomes'] as String?,
      buds: json['buds'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leaf_shape': leafShape,
      'structure': structure,
      'color': color,
      'trichomes': trichomes,
      'buds': buds,
    };
  }
}

/// Edukativní informace o odrůdě
class ScanEducation {
  final String? genetics;
  final String? thcRange;
  final String? cbdRange;
  final List<String> effects;
  final List<String> flavors;
  final String? growDifficulty;
  final String? floweringTime;
  final List<String> tips;
  final String? medicalUses;
  final String? history;

  ScanEducation({
    this.genetics,
    this.thcRange,
    this.cbdRange,
    this.effects = const [],
    this.flavors = const [],
    this.growDifficulty,
    this.floweringTime,
    this.tips = const [],
    this.medicalUses,
    this.history,
  });

  factory ScanEducation.fromJson(Map<String, dynamic> json) {
    return ScanEducation(
      genetics: json['genetics'] as String?,
      thcRange: json['thc_range'] as String?,
      cbdRange: json['cbd_range'] as String?,
      effects: (json['effects'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      flavors: (json['flavors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      growDifficulty: json['grow_difficulty'] as String?,
      floweringTime: json['flowering_time'] as String?,
      tips:
          (json['tips'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      medicalUses: json['medical_uses'] as String?,
      history: json['history'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'genetics': genetics,
      'thc_range': thcRange,
      'cbd_range': cbdRange,
      'effects': effects,
      'flavors': flavors,
      'grow_difficulty': growDifficulty,
      'flowering_time': floweringTime,
      'tips': tips,
      'medical_uses': medicalUses,
      'history': history,
    };
  }

  /// Vrátí lokalizovanou obtížnost
  String get growDifficultyLocalized {
    switch (growDifficulty) {
      case 'easy':
        return 'Snadné';
      case 'medium':
        return 'Střední';
      case 'hard':
        return 'Náročné';
      default:
        return growDifficulty ?? 'Neznámá';
    }
  }
}

/// Hodnocení zdraví rostliny
class HealthAssessment {
  final String status; // 'healthy', 'warning', 'critical'
  final List<String> issues;
  final List<String> recommendations;

  HealthAssessment({
    required this.status,
    this.issues = const [],
    this.recommendations = const [],
  });

  factory HealthAssessment.fromJson(Map<String, dynamic> json) {
    return HealthAssessment(
      status: json['status'] as String? ?? 'unknown',
      issues: (json['issues'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'issues': issues,
      'recommendations': recommendations,
    };
  }

  /// Vrátí lokalizovaný status
  String get statusLocalized {
    switch (status) {
      case 'healthy':
        return 'Zdravá';
      case 'warning':
        return 'Vyžaduje pozornost';
      case 'critical':
        return 'Kritický stav';
      default:
        return 'Neznámý';
    }
  }

  /// Je rostlina zdravá?
  bool get isHealthy => status == 'healthy';
}
