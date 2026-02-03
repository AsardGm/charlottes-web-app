import 'user_model.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type;

  // Social notification fields (legacy)
  final String? actorId;
  final String? postId;
  final String? commentId;
  final UserModel? actor;

  // Common fields
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Extended fields for system notifications
  final String? icon;
  final String? color;
  final String? actionRoute;
  final String? actionLabel;
  final bool pushSent;
  final DateTime? pushSentAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    this.actorId,
    this.postId,
    this.commentId,
    this.actor,
    required this.title,
    this.body,
    this.data = const {},
    required this.isRead,
    this.readAt,
    required this.createdAt,
    DateTime? updatedAt,
    this.icon,
    this.color,
    this.actionRoute,
    this.actionLabel,
    this.pushSent = false,
    this.pushSentAt,
  }) : updatedAt = updatedAt ?? createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      actorId: json['actor_id'] as String?,
      postId: json['post_id'] as String?,
      commentId: json['comment_id'] as String?,
      actor: json['profiles'] != null
          ? UserModel.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
      title: json['title'] as String,
      body: json['body'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String),
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      actionRoute: json['action_route'] as String?,
      actionLabel: json['action_label'] as String?,
      pushSent: json['push_sent'] as bool? ?? false,
      pushSentAt: json['push_sent_at'] != null
          ? DateTime.parse(json['push_sent_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'actor_id': actorId,
      'post_id': postId,
      'comment_id': commentId,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'icon': icon,
      'color': color,
      'action_route': actionRoute,
      'action_label': actionLabel,
      'push_sent': pushSent,
      'push_sent_at': pushSentAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    bool? isRead,
    DateTime? readAt,
    bool? pushSent,
    DateTime? pushSentAt,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      actorId: actorId,
      postId: postId,
      commentId: commentId,
      actor: actor,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      icon: icon,
      color: color,
      actionRoute: actionRoute,
      actionLabel: actionLabel,
      pushSent: pushSent ?? this.pushSent,
      pushSentAt: pushSentAt ?? this.pushSentAt,
    );
  }

  /// Get relative time string
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'právě teď';
    } else if (difference.inMinutes < 60) {
      return 'před ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'před ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'před ${difference.inDays}d';
    } else {
      return 'před ${(difference.inDays / 7).floor()}t';
    }
  }

  String get iconName {
    // If icon is explicitly set, use it
    if (icon != null) return icon!;

    // Otherwise determine from type
    switch (type) {
      // System notifications
      case 'weekly_report_ready':
        return 'assignment';
      case 'tbreak_reminder':
      case 'tbreak_milestone':
      case 'tbreak_completed':
        return 'emoji_events';
      case 'post_check_reminder':
        return 'psychology';
      case 'harm_reduction_alert':
        return 'warning';
      case 'achievement_unlocked':
        return 'stars';
      case 'cognitive_decline':
        return 'trending_down';

      // Social notifications
      case 'like':
      case 'social_like':
        return 'thumb_up';
      case 'comment':
      case 'social_comment':
        return 'chat_bubble';
      case 'mention':
        return 'alternate_email';
      case 'follow':
      case 'social_follow':
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

