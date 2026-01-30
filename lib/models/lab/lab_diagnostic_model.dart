/// Typ AI diagnostiky
enum DiagnosticType {
  deficiency,
  trichome,
  health,
  pest;

  String get label {
    switch (this) {
      case DiagnosticType.deficiency:
        return 'Nedostatek zivin';
      case DiagnosticType.trichome:
        return 'Trichomy';
      case DiagnosticType.health:
        return 'Celkove zdravi';
      case DiagnosticType.pest:
        return 'Skudci';
    }
  }

  String get icon {
    switch (this) {
      case DiagnosticType.deficiency:
        return '🍂';
      case DiagnosticType.trichome:
        return '🔬';
      case DiagnosticType.health:
        return '💚';
      case DiagnosticType.pest:
        return '🐛';
    }
  }

  String get prompt {
    switch (this) {
      case DiagnosticType.deficiency:
        return 'Analyze this plant photo for nutrient deficiencies. Identify specific deficiencies (nitrogen, phosphorus, potassium, calcium, magnesium, iron, etc.), rate severity (low/medium/high/critical), and provide treatment recommendations. Respond in Czech.';
      case DiagnosticType.trichome:
        return 'Analyze this close-up photo of trichomes. Determine the ratio of clear, cloudy, and amber trichomes. Estimate harvest readiness. Respond in Czech.';
      case DiagnosticType.health:
        return 'Analyze this plant photo for overall health assessment. Check for signs of overwatering, underwatering, light stress, heat stress, nutrient burn, or other issues. Rate overall health on a scale. Respond in Czech.';
      case DiagnosticType.pest:
        return 'Analyze this plant photo for pest or disease identification. Look for signs of spider mites, thrips, aphids, fungus gnats, powdery mildew, bud rot, or other pests/diseases. Provide treatment recommendations. Respond in Czech.';
    }
  }

  static DiagnosticType fromString(String value) {
    return DiagnosticType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DiagnosticType.health,
    );
  }
}

/// Zavaznost diagnostiky
enum DiagnosticSeverity {
  low,
  medium,
  high,
  critical;

  String get label {
    switch (this) {
      case DiagnosticSeverity.low:
        return 'Nizka';
      case DiagnosticSeverity.medium:
        return 'Stredni';
      case DiagnosticSeverity.high:
        return 'Vysoka';
      case DiagnosticSeverity.critical:
        return 'Kriticka';
    }
  }

  static DiagnosticSeverity? fromString(String? value) {
    if (value == null) return null;
    return DiagnosticSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DiagnosticSeverity.low,
    );
  }
}

/// Model AI diagnostiky
class LabDiagnosticModel {
  final String id;
  final String growId;
  final String userId;
  final DiagnosticType diagnosticType;
  final String imageUrl;
  final Map<String, dynamic>? aiResponse;
  final DiagnosticSeverity? severity;
  final String? diagnosis;
  final List<String> recommendations;
  final double? confidence;
  final DateTime createdAt;

  LabDiagnosticModel({
    required this.id,
    required this.growId,
    required this.userId,
    required this.diagnosticType,
    required this.imageUrl,
    this.aiResponse,
    this.severity,
    this.diagnosis,
    this.recommendations = const [],
    this.confidence,
    required this.createdAt,
  });

  factory LabDiagnosticModel.fromJson(Map<String, dynamic> json) {
    return LabDiagnosticModel(
      id: json['id'] as String,
      growId: json['grow_id'] as String,
      userId: json['user_id'] as String,
      diagnosticType: DiagnosticType.fromString(json['diagnostic_type'] as String? ?? 'health'),
      imageUrl: json['image_url'] as String,
      aiResponse: json['ai_response'] as Map<String, dynamic>?,
      severity: DiagnosticSeverity.fromString(json['severity'] as String?),
      diagnosis: json['diagnosis'] as String?,
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      confidence: (json['confidence'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grow_id': growId,
      'user_id': userId,
      'diagnostic_type': diagnosticType.name,
      'image_url': imageUrl,
      'ai_response': aiResponse,
      'severity': severity?.name,
      'diagnosis': diagnosis,
      'recommendations': recommendations,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'grow_id': growId,
      'user_id': userId,
      'diagnostic_type': diagnosticType.name,
      'image_url': imageUrl,
      'ai_response': aiResponse,
      'severity': severity?.name,
      'diagnosis': diagnosis,
      'recommendations': recommendations,
      'confidence': confidence,
    };
  }

  LabDiagnosticModel copyWith({
    String? id,
    String? growId,
    String? userId,
    DiagnosticType? diagnosticType,
    String? imageUrl,
    Map<String, dynamic>? aiResponse,
    DiagnosticSeverity? severity,
    String? diagnosis,
    List<String>? recommendations,
    double? confidence,
    DateTime? createdAt,
  }) {
    return LabDiagnosticModel(
      id: id ?? this.id,
      growId: growId ?? this.growId,
      userId: userId ?? this.userId,
      diagnosticType: diagnosticType ?? this.diagnosticType,
      imageUrl: imageUrl ?? this.imageUrl,
      aiResponse: aiResponse ?? this.aiResponse,
      severity: severity ?? this.severity,
      diagnosis: diagnosis ?? this.diagnosis,
      recommendations: recommendations ?? this.recommendations,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
