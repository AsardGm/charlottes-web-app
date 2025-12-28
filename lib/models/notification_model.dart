import 'user_model.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String? actorId;
  final String? postId;
  final String? commentId;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final UserModel? actor;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    this.actorId,
    this.postId,
    this.commentId,
    required this.title,
    this.body,
    this.data = const {},
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.actor,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      actorId: json['actor_id'] as String?,
      postId: json['post_id'] as String?,
      commentId: json['comment_id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      actor: json['profiles'] != null
          ? UserModel.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  NotificationModel copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      actorId: actorId,
      postId: postId,
      commentId: commentId,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      actor: actor,
    );
  }

  String get iconName {
    switch (type) {
      case 'like':
        return 'thumb_up';
      case 'comment':
        return 'chat_bubble';
      case 'mention':
        return 'alternate_email';
      case 'follow':
        return 'person_add';
      case 'reply':
        return 'reply';
      case 'post':
        return 'article';
      case 'chat':
        return 'message';
      case 'system':
      default:
        return 'notifications';
    }
  }
}
