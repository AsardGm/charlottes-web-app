import 'user_model.dart';
import 'comment_model.dart';
import 'reaction_model.dart';
import 'category_model.dart';
import 'thread_type_model.dart';

/// Model příspěvku (vlákna)
///
/// Reprezentuje příspěvek na zdi včetně komentářů,
/// reakcí a metadat vlákna.
class PostModel {
  /// Unikátní ID příspěvku
  final String id;

  /// ID autora příspěvku
  final String authorId;

  /// ID kategorie (volitelné)
  final String? categoryId;

  /// ID typu vlákna (diskuze, otázka, oznámení)
  final String? threadTypeId;

  /// Textový obsah příspěvku
  final String content;

  /// URL přiloženého obrázku
  final String? imageUrl;

  /// Stav vlákna: 'open', 'resolved', 'locked'
  final String status;

  /// Deadline pro vyřešení (u otázek)
  final DateTime? deadline;

  /// Datum vyřešení
  final DateTime? resolvedAt;

  /// ID uživatele který vyřešil
  final String? resolvedBy;

  /// Je příspěvek připnutý nahoře?
  final bool isPinned;

  /// Počet zobrazení
  final int viewCount;

  /// ID přijaté odpovědi (u otázek)
  final String? acceptedCommentId;

  /// Datum vytvoření
  final DateTime createdAt;

  /// Datum poslední úpravy
  final DateTime updatedAt;

  // === Relační data ===

  /// Autor příspěvku
  final UserModel? author;

  /// Kategorie
  final CategoryModel? category;

  /// Typ vlákna
  final ThreadTypeModel? threadType;

  /// Seznam komentářů
  final List<CommentModel> comments;

  /// Seznam reakcí
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

  // === Počítané hodnoty ===

  /// Počet komentářů
  int get commentCount => comments.length;

  /// Počty reakcí podle typu
  Map<String, int> get reactionCounts {
    final counts = <String, int>{};
    for (final reaction in reactions) {
      counts[reaction.type] = (counts[reaction.type] ?? 0) + 1;
    }
    return counts;
  }

  /// Celkový počet reakcí
  int get totalReactions => reactions.length;

  /// Reagoval uživatel na příspěvek?
  bool hasUserReacted(String userId) {
    return reactions.any((r) => r.userId == userId);
  }

  /// Získá typ reakce uživatele
  String? getUserReactionType(String userId) {
    try {
      return reactions.firstWhere((r) => r.userId == userId).type;
    } catch (_) {
      return null;
    }
  }

  // === Stav vlákna ===

  /// Získá stav vlákna jako enum
  ThreadStatus get threadStatus => ThreadStatus.fromString(status);

  /// Je vlákno otevřené?
  bool get isOpen => status == 'open';

  /// Je vlákno vyřešené?
  bool get isResolved => status == 'resolved';

  /// Je vlákno zamčené?
  bool get isLocked => status == 'locked';

  // === Deadline ===

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

  // === Přijatá odpověď ===

  /// Má přijatou odpověď?
  bool get hasAcceptedAnswer => acceptedCommentId != null;

  /// Je tento komentář přijatá odpověď?
  bool isAcceptedAnswer(String commentId) {
    return acceptedCommentId == commentId;
  }

  // === Serializace ===

  /// Vytvoří model z JSON dat (z Supabase)
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

  /// Převede model na JSON pro uložení
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

  /// Vytvoří kopii s upravenými hodnotami
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
