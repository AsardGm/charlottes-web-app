import 'user_model.dart';
import 'comment_model.dart';
import 'reaction_model.dart';
import 'category_model.dart';
import 'thread_type_model.dart';

class PostModel {
  final String id;
  final String authorId;
  final String? categoryId;
  final String? threadTypeId;
  final String content;
  final String? imageUrl;
  final String status;
  final DateTime? deadline;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final bool isPinned;
  final int viewCount;
  final String? acceptedCommentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? author;
  final CategoryModel? category;
  final ThreadTypeModel? threadType;
  final List<CommentModel> comments;
  final List<ReactionModel> reactions;

  PostModel({
    required this.id,
    required this.authorId,
    this.categoryId,
    this.threadTypeId,
    required this.content,
    this.imageUrl,
    this.status = 'open',
    this.deadline,
    this.resolvedAt,
    this.resolvedBy,
    this.isPinned = false,
    this.viewCount = 0,
    this.acceptedCommentId,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.category,
    this.threadType,
    this.comments = const [],
    this.reactions = const [],
  });

  int get commentCount => comments.length;

  Map<String, int> get reactionCounts {
    final counts = <String, int>{};
    for (final reaction in reactions) {
      counts[reaction.type] = (counts[reaction.type] ?? 0) + 1;
    }
    return counts;
  }

  int get totalReactions => reactions.length;

  bool hasUserReacted(String userId) {
    return reactions.any((r) => r.userId == userId);
  }

  String? getUserReactionType(String userId) {
    try {
      return reactions.firstWhere((r) => r.userId == userId).type;
    } catch (_) {
      return null;
    }
  }

  /// Získá stav vlákna jako enum
  ThreadStatus get threadStatus => ThreadStatus.fromString(status);

  /// Je vlákno otevřené?
  bool get isOpen => status == 'open';

  /// Je vlákno vyřešené?
  bool get isResolved => status == 'resolved';

  /// Je vlákno zamčené?
  bool get isLocked => status == 'locked';

  /// Má vlákno deadline?
  bool get hasDeadline => deadline != null;

  /// Je deadline prošlý?
  bool get isOverdue {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!) && !isResolved;
  }

  /// Počet dní do deadline
  int? get daysUntilDeadline {
    if (deadline == null) return null;
    return deadline!.difference(DateTime.now()).inDays;
  }

  /// Má přijatou odpověď?
  bool get hasAcceptedAnswer => acceptedCommentId != null;

  /// Je komentář přijatá odpověď?
  bool isAcceptedAnswer(String commentId) {
    return acceptedCommentId == commentId;
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      categoryId: json['category_id'] as String?,
      threadTypeId: json['thread_type_id'] as String?,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String? ?? 'open',
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      viewCount: json['view_count'] as int? ?? 0,
      acceptedCommentId: json['accepted_comment_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      author: json['profiles'] != null
          ? UserModel.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
      category: json['categories'] != null
          ? CategoryModel.fromJson(json['categories'] as Map<String, dynamic>)
          : null,
      threadType: json['thread_types'] != null
          ? ThreadTypeModel.fromJson(
              json['thread_types'] as Map<String, dynamic>)
          : null,
      comments: (json['comments'] as List<dynamic>?)
              ?.map((c) => CommentModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map((r) => ReactionModel.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'category_id': categoryId,
      'thread_type_id': threadTypeId,
      'content': content,
      'image_url': imageUrl,
      'status': status,
      'deadline': deadline?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'is_pinned': isPinned,
      'view_count': viewCount,
      'accepted_comment_id': acceptedCommentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PostModel copyWith({
    String? id,
    String? authorId,
    String? categoryId,
    String? threadTypeId,
    String? content,
    String? imageUrl,
    String? status,
    DateTime? deadline,
    DateTime? resolvedAt,
    String? resolvedBy,
    bool? isPinned,
    int? viewCount,
    String? acceptedCommentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? author,
    CategoryModel? category,
    ThreadTypeModel? threadType,
    List<CommentModel>? comments,
    List<ReactionModel>? reactions,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      categoryId: categoryId ?? this.categoryId,
      threadTypeId: threadTypeId ?? this.threadTypeId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      isPinned: isPinned ?? this.isPinned,
      viewCount: viewCount ?? this.viewCount,
      acceptedCommentId: acceptedCommentId ?? this.acceptedCommentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
      category: category ?? this.category,
      threadType: threadType ?? this.threadType,
      comments: comments ?? this.comments,
      reactions: reactions ?? this.reactions,
    );
  }
}
