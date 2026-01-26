/// Model odrůdy rostliny
///
/// Reprezentuje jednu odrůdu v katalogu s edukativními informacemi.
class StrainModel {
  final String id;
  final String name;
  final String? slug;
  final String? type; // 'indica', 'sativa', 'hybrid'
  final double? thcMin;
  final double? thcMax;
  final double? cbdMin;
  final double? cbdMax;
  final List<String> effects;
  final List<String> flavors;
  final String? description;
  final String? genetics;
  final String? growDifficulty; // 'easy', 'medium', 'hard'
  final int? growTimeWeeks;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  StrainModel({
    required this.id,
    required this.name,
    this.slug,
    this.type,
    this.thcMin,
    this.thcMax,
    this.cbdMin,
    this.cbdMax,
    this.effects = const [],
    this.flavors = const [],
    this.description,
    this.genetics,
    this.growDifficulty,
    this.growTimeWeeks,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory StrainModel.fromJson(Map<String, dynamic> json) {
    return StrainModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      type: json['type'] as String?,
      thcMin: (json['thc_min'] as num?)?.toDouble(),
      thcMax: (json['thc_max'] as num?)?.toDouble(),
      cbdMin: (json['cbd_min'] as num?)?.toDouble(),
      cbdMax: (json['cbd_max'] as num?)?.toDouble(),
      effects: (json['effects'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      flavors: (json['flavors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      description: json['description'] as String?,
      genetics: json['genetics'] as String?,
      growDifficulty: json['grow_difficulty'] as String?,
      growTimeWeeks: json['grow_time_weeks'] as int?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'type': type,
      'thc_min': thcMin,
      'thc_max': thcMax,
      'cbd_min': cbdMin,
      'cbd_max': cbdMax,
      'effects': effects,
      'flavors': flavors,
      'description': description,
      'genetics': genetics,
      'grow_difficulty': growDifficulty,
      'grow_time_weeks': growTimeWeeks,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Vrátí THC rozsah jako string (např. "17-24%")
  String get thcRange {
    if (thcMin == null && thcMax == null) return 'N/A';
    if (thcMin == thcMax) return '${thcMin?.toStringAsFixed(0)}%';
    return '${thcMin?.toStringAsFixed(0)}-${thcMax?.toStringAsFixed(0)}%';
  }

  /// Vrátí CBD rozsah jako string
  String get cbdRange {
    if (cbdMin == null && cbdMax == null) return 'N/A';
    if (cbdMin == cbdMax) return '${cbdMin?.toStringAsFixed(1)}%';
    return '${cbdMin?.toStringAsFixed(1)}-${cbdMax?.toStringAsFixed(1)}%';
  }

  /// Vrátí lokalizovaný typ
  String get typeLocalized {
    switch (type) {
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

  /// Vrátí lokalizovanou obtížnost pěstování
  String get growDifficultyLocalized {
    switch (growDifficulty) {
      case 'easy':
        return 'Snadné';
      case 'medium':
        return 'Střední';
      case 'hard':
        return 'Náročné';
      default:
        return 'Neznámá';
    }
  }

  StrainModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? type,
    double? thcMin,
    double? thcMax,
    double? cbdMin,
    double? cbdMax,
    List<String>? effects,
    List<String>? flavors,
    String? description,
    String? genetics,
    String? growDifficulty,
    int? growTimeWeeks,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StrainModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      type: type ?? this.type,
      thcMin: thcMin ?? this.thcMin,
      thcMax: thcMax ?? this.thcMax,
      cbdMin: cbdMin ?? this.cbdMin,
      cbdMax: cbdMax ?? this.cbdMax,
      effects: effects ?? this.effects,
      flavors: flavors ?? this.flavors,
      description: description ?? this.description,
      genetics: genetics ?? this.genetics,
      growDifficulty: growDifficulty ?? this.growDifficulty,
      growTimeWeeks: growTimeWeeks ?? this.growTimeWeeks,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
