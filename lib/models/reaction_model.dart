class ReactionModel {
  final String id;
  final String postId;
  final String userId;
  final String type;
  final DateTime createdAt;

  ReactionModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.type,
    required this.createdAt,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ReactionModel copyWith({
    String? id,
    String? postId,
    String? userId,
    String? type,
    DateTime? createdAt,
  }) {
    return ReactionModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
