/// Faze rustu rostliny
enum GrowPhase {
  germination,
  seedling,
  vegetative,
  flowering,
  harvest,
  drying,
  curing,
  completed;

  String get label {
    switch (this) {
      case GrowPhase.germination:
        return 'Kliceni';
      case GrowPhase.seedling:
        return 'Sazenec';
      case GrowPhase.vegetative:
        return 'Vegetace';
      case GrowPhase.flowering:
        return 'Kveteni';
      case GrowPhase.harvest:
        return 'Sklizen';
      case GrowPhase.drying:
        return 'Suseni';
      case GrowPhase.curing:
        return 'Dozravani';
      case GrowPhase.completed:
        return 'Dokonceno';
    }
  }

  String get icon {
    switch (this) {
      case GrowPhase.germination:
        return '🌱';
      case GrowPhase.seedling:
        return '🌿';
      case GrowPhase.vegetative:
        return '🪴';
      case GrowPhase.flowering:
        return '🌸';
      case GrowPhase.harvest:
        return '✂️';
      case GrowPhase.drying:
        return '🌬️';
      case GrowPhase.curing:
        return '🫙';
      case GrowPhase.completed:
        return '✅';
    }
  }

  static GrowPhase fromString(String value) {
    return GrowPhase.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GrowPhase.germination,
    );
  }
}

/// Typ prostredi
enum GrowEnvironment {
  indoor,
  outdoor,
  greenhouse;

  String get label {
    switch (this) {
      case GrowEnvironment.indoor:
        return 'Indoor';
      case GrowEnvironment.outdoor:
        return 'Outdoor';
      case GrowEnvironment.greenhouse:
        return 'Sklenık';
    }
  }

  static GrowEnvironment? fromString(String? value) {
    if (value == null) return null;
    return GrowEnvironment.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GrowEnvironment.indoor,
    );
  }
}

/// Typ media
enum GrowMedium {
  soil,
  coco,
  hydro,
  aero,
  dwc;

  String get label {
    switch (this) {
      case GrowMedium.soil:
        return 'Zemina';
      case GrowMedium.coco:
        return 'Kokos';
      case GrowMedium.hydro:
        return 'Hydroponie';
      case GrowMedium.aero:
        return 'Aeroponie';
      case GrowMedium.dwc:
        return 'DWC';
    }
  }

  static GrowMedium? fromString(String? value) {
    if (value == null) return null;
    return GrowMedium.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GrowMedium.soil,
    );
  }
}

/// Model grow zaznamu
class LabGrowModel {
  final String id;
  final String userId;
  final String name;
  final String? strainName;
  final GrowPhase phase;
  final DateTime startDate;
  final DateTime? endDate;
  final GrowEnvironment? environment;
  final GrowMedium? medium;
  final String? notes;
  final String? coverImageUrl;
  final bool isActive;
  final bool isBurner;
  final bool isLocalOnly;
  final DateTime createdAt;
  final DateTime? updatedAt;

  LabGrowModel({
    required this.id,
    required this.userId,
    required this.name,
    this.strainName,
    this.phase = GrowPhase.germination,
    required this.startDate,
    this.endDate,
    this.environment,
    this.medium,
    this.notes,
    this.coverImageUrl,
    this.isActive = true,
    this.isBurner = false,
    this.isLocalOnly = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Pocet dni od zacatku
  int get dayCount {
    final end = endDate ?? DateTime.now();
    return end.difference(startDate).inDays + 1;
  }

  factory LabGrowModel.fromJson(Map<String, dynamic> json) {
    return LabGrowModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      strainName: json['strain_name'] as String?,
      phase: GrowPhase.fromString(json['phase'] as String? ?? 'germination'),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      environment: GrowEnvironment.fromString(json['environment'] as String?),
      medium: GrowMedium.fromString(json['medium'] as String?),
      notes: json['notes'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isBurner: json['is_burner'] as bool? ?? false,
      isLocalOnly: json['is_local_only'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'strain_name': strainName,
      'phase': phase.name,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'environment': environment?.name,
      'medium': medium?.name,
      'notes': notes,
      'cover_image_url': coverImageUrl,
      'is_active': isActive,
      'is_burner': isBurner,
      'is_local_only': isLocalOnly,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// JSON pro INSERT (bez id a timestamps)
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'name': name,
      'strain_name': strainName,
      'phase': phase.name,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'environment': environment?.name,
      'medium': medium?.name,
      'notes': notes,
      'cover_image_url': coverImageUrl,
      'is_active': isActive,
      'is_burner': isBurner,
      'is_local_only': isLocalOnly,
    };
  }

  LabGrowModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? strainName,
    GrowPhase? phase,
    DateTime? startDate,
    DateTime? endDate,
    GrowEnvironment? environment,
    GrowMedium? medium,
    String? notes,
    String? coverImageUrl,
    bool? isActive,
    bool? isBurner,
    bool? isLocalOnly,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LabGrowModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      strainName: strainName ?? this.strainName,
      phase: phase ?? this.phase,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      environment: environment ?? this.environment,
      medium: medium ?? this.medium,
      notes: notes ?? this.notes,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isActive: isActive ?? this.isActive,
      isBurner: isBurner ?? this.isBurner,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
