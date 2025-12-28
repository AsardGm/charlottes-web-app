class TagModel {
  final String id;
  final String name;
  final String slug;
  final int postCount;
  final DateTime createdAt;

  TagModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.postCount,
    required this.createdAt,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      postCount: json['post_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'post_count': postCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
