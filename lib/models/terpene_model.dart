/// Model terpenu pro Brain Map
///
/// Reprezentuje jeden terpen s jeho vlastnostmi,
/// efekty a komunitními zkušenostmi.
class TerpeneModel {
  final String id;
  final String name;
  final String slug;
  final String chemicalFormula;
  final String description;
  final String aroma;
  final String color; // Hex barva pro vizualizaci
  final List<String> moods; // Nálady které vyvolává
  final List<String> effects; // Typické efekty
  final List<String> benefits; // Kdy se hodí
  final List<String> cautions; // Kdy ne / opatrně
  final List<String> naturalSources; // Kde se vyskytuje v přírodě
  final double boilingPoint; // Bod varu v °C
  final String brainRegion; // Oblast mozku kterou ovlivňuje
  final DateTime createdAt;

  TerpeneModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.chemicalFormula,
    required this.description,
    required this.aroma,
    required this.color,
    this.moods = const [],
    this.effects = const [],
    this.benefits = const [],
    this.cautions = const [],
    this.naturalSources = const [],
    required this.boilingPoint,
    required this.brainRegion,
    required this.createdAt,
  });

  factory TerpeneModel.fromJson(Map<String, dynamic> json) {
    return TerpeneModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      chemicalFormula: json['chemical_formula'] as String? ?? '',
      description: json['description'] as String? ?? '',
      aroma: json['aroma'] as String? ?? '',
      color: json['color'] as String? ?? '#00D4FF',
      moods: _parseList(json['moods']),
      effects: _parseList(json['effects']),
      benefits: _parseList(json['benefits']),
      cautions: _parseList(json['cautions']),
      naturalSources: _parseList(json['natural_sources']),
      boilingPoint: (json['boiling_point'] as num?)?.toDouble() ?? 0,
      brainRegion: json['brain_region'] as String? ?? 'limbic',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'chemical_formula': chemicalFormula,
      'description': description,
      'aroma': aroma,
      'color': color,
      'moods': moods,
      'effects': effects,
      'benefits': benefits,
      'cautions': cautions,
      'natural_sources': naturalSources,
      'boiling_point': boilingPoint,
      'brain_region': brainRegion,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Komunitní zkušenost s terpenem
class TerpeneExperienceModel {
  final String id;
  final String terpeneId;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final String content;
  final int rating; // 1-5
  final List<String> tags;
  final int helpfulCount;
  final DateTime createdAt;

  TerpeneExperienceModel({
    required this.id,
    required this.terpeneId,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.content,
    required this.rating,
    this.tags = const [],
    this.helpfulCount = 0,
    required this.createdAt,
  });

  factory TerpeneExperienceModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return TerpeneExperienceModel(
      id: json['id'] as String,
      terpeneId: json['terpene_id'] as String,
      userId: json['user_id'] as String,
      userName: profile?['username'] as String?,
      userAvatar: profile?['avatar_url'] as String?,
      content: json['content'] as String,
      rating: json['rating'] as int? ?? 3,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      helpfulCount: json['helpful_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
