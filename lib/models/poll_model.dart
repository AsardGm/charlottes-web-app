/// Model pro anketu
class PollModel {
  final String id;
  final String conversationId;
  final String? messageId;
  final String createdBy;
  final String question;
  final String pollType; // 'single' or 'multiple'
  final bool isAnonymous;
  final bool allowsAddOptions;
  final DateTime? expiresAt;
  final bool isClosed;
  final DateTime createdAt;
  final List<PollOption> options;
  final List<PollVote> votes;

  PollModel({
    required this.id,
    required this.conversationId,
    this.messageId,
    required this.createdBy,
    required this.question,
    required this.pollType,
    required this.isAnonymous,
    required this.allowsAddOptions,
    this.expiresAt,
    required this.isClosed,
    required this.createdAt,
    this.options = const [],
    this.votes = const [],
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      messageId: json['message_id'] as String?,
      createdBy: json['created_by'] as String,
      question: json['question'] as String,
      pollType: json['poll_type'] as String? ?? 'single',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      allowsAddOptions: json['allows_add_options'] as bool? ?? false,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isClosed: json['is_closed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      options: (json['poll_options'] as List<dynamic>?)
              ?.map((o) => PollOption.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
      votes: (json['poll_votes'] as List<dynamic>?)
              ?.map((v) => PollVote.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Získá počet hlasů pro danou možnost
  int getVoteCount(String optionId) {
    return votes.where((v) => v.optionId == optionId).length;
  }

  /// Zkontroluje, zda uživatel hlasoval pro danou možnost
  bool hasUserVoted(String userId, String optionId) {
    return votes.any((v) => v.userId == userId && v.optionId == optionId);
  }

  /// Získá celkový počet hlasů
  int get totalVotes => votes.length;

  /// Zkontroluje, zda anketa vypršela
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Zkontroluje, zda je anketa aktivní
  bool get isActive => !isClosed && !isExpired;
}

/// Možnost v anketě
class PollOption {
  final String id;
  final String pollId;
  final String optionText;
  final String? addedBy;
  final DateTime createdAt;

  PollOption({
    required this.id,
    required this.pollId,
    required this.optionText,
    this.addedBy,
    required this.createdAt,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as String,
      pollId: json['poll_id'] as String,
      optionText: json['option_text'] as String,
      addedBy: json['added_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Hlas v anketě
class PollVote {
  final String id;
  final String pollId;
  final String optionId;
  final String userId;
  final DateTime createdAt;

  PollVote({
    required this.id,
    required this.pollId,
    required this.optionId,
    required this.userId,
    required this.createdAt,
  });

  factory PollVote.fromJson(Map<String, dynamic> json) {
    return PollVote(
      id: json['id'] as String,
      pollId: json['poll_id'] as String,
      optionId: json['option_id'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
