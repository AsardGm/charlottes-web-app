import 'user_model.dart';

class ConversationModel {
  final String id;
  final String type; // 'direct' or 'group'
  final String? name;
  final String? description;
  final String? avatarUrl;
  final bool isEncrypted;
  final int disappearingMessagesTtl;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ConversationParticipant> participants;
  final MessageModel? lastMessage;
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.type,
    this.name,
    this.description,
    this.avatarUrl,
    this.isEncrypted = true,
    this.disappearingMessagesTtl = 0,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.participants = const [],
    this.lastMessage,
    this.unreadCount = 0,
  });

  bool get isDirect => type == 'direct';
  bool get isGroup => type == 'group';
  bool get hasDisappearingMessages => disappearingMessagesTtl > 0;

  /// Pro direct chaty - získá druhého účastníka
  ConversationParticipant? getOtherParticipant(String currentUserId) {
    if (!isDirect) return null;
    try {
      return participants.firstWhere((p) => p.userId != currentUserId);
    } catch (_) {
      return null;
    }
  }

  /// Název konverzace - pro direct chat jméno druhého účastníka
  String getDisplayName(String currentUserId) {
    if (isGroup) return name ?? 'Skupina';
    final other = getOtherParticipant(currentUserId);
    return other?.user?.username ?? 'Neznamy';
  }

  /// Avatar - pro direct chat avatar druhého účastníka
  String? getDisplayAvatar(String currentUserId) {
    if (isGroup) return avatarUrl;
    final other = getOtherParticipant(currentUserId);
    return other?.user?.avatarUrl;
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'direct',
      name: json['name'] as String?,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isEncrypted: json['is_encrypted'] as bool? ?? true,
      disappearingMessagesTtl: json['disappearing_messages_ttl'] as int? ?? 0,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      participants: (json['conversation_participants'] as List<dynamic>?)
              ?.map((p) =>
                  ConversationParticipant.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
      'is_encrypted': isEncrypted,
      'disappearing_messages_ttl': disappearingMessagesTtl,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ConversationParticipant {
  final String id;
  final String conversationId;
  final String userId;
  final String role;
  final String? encryptedSessionKey;
  final bool isMuted;
  final DateTime? lastReadAt;
  final DateTime joinedAt;
  final UserModel? user;

  const ConversationParticipant({
    required this.id,
    required this.conversationId,
    required this.userId,
    this.role = 'member',
    this.encryptedSessionKey,
    this.isMuted = false,
    this.lastReadAt,
    required this.joinedAt,
    this.user,
  });

  bool get isAdmin => role == 'admin';

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      encryptedSessionKey: json['encrypted_session_key'] as String?,
      isMuted: json['is_muted'] as bool? ?? false,
      lastReadAt: json['last_read_at'] != null
          ? DateTime.parse(json['last_read_at'] as String)
          : null,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      user: json['profiles'] != null
          ? UserModel.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String encryptedContent;
  final String iv;
  final String messageType;
  final Map<String, dynamic> metadata;
  final String? replyToId;
  final String? forwardedFromId;
  final DateTime? expiresAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime? editedAt;
  final UserModel? sender;
  final List<MessageReaction> reactions;
  final List<MessageReceipt> receipts;

  // Dešifrovaný obsah (pouze v paměti, nikdy se neukládá)
  String? decryptedContent;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.encryptedContent,
    required this.iv,
    this.messageType = 'text',
    this.metadata = const {},
    this.replyToId,
    this.forwardedFromId,
    this.expiresAt,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    this.editedAt,
    this.sender,
    this.reactions = const [],
    this.receipts = const [],
    this.decryptedContent,
  });

  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isFile => messageType == 'file';
  bool get isVoice => messageType == 'voice';
  bool get isSystem => messageType == 'system';
  bool get isEdited => editedAt != null;
  bool get isReply => replyToId != null;
  bool get isForwarded => forwardedFromId != null;
  bool get willExpire => expiresAt != null;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      encryptedContent: json['encrypted_content'] as String,
      iv: json['iv'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      replyToId: json['reply_to_id'] as String?,
      forwardedFromId: json['forwarded_from_id'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      sender: json['profiles'] != null
          ? UserModel.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
      reactions: (json['message_reactions'] as List<dynamic>?)
              ?.map((r) => MessageReaction.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      receipts: (json['message_receipts'] as List<dynamic>?)
              ?.map((r) => MessageReceipt.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'encrypted_content': encryptedContent,
      'iv': iv,
      'message_type': messageType,
      'metadata': metadata,
      'reply_to_id': replyToId,
      'forwarded_from_id': forwardedFromId,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? decryptedContent,
    List<MessageReaction>? reactions,
    List<MessageReceipt>? receipts,
  }) {
    return MessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      encryptedContent: encryptedContent,
      iv: iv,
      messageType: messageType,
      metadata: metadata,
      replyToId: replyToId,
      forwardedFromId: forwardedFromId,
      expiresAt: expiresAt,
      isDeleted: isDeleted,
      deletedAt: deletedAt,
      createdAt: createdAt,
      editedAt: editedAt,
      sender: sender,
      reactions: reactions ?? this.reactions,
      receipts: receipts ?? this.receipts,
      decryptedContent: decryptedContent ?? this.decryptedContent,
    );
  }
}

class MessageReaction {
  final String id;
  final String messageId;
  final String userId;
  final String emoji;
  final DateTime createdAt;

  const MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      userId: json['user_id'] as String,
      emoji: json['emoji'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class MessageReceipt {
  final String id;
  final String messageId;
  final String userId;
  final String status; // 'delivered' or 'read'
  final DateTime timestamp;

  const MessageReceipt({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.status,
    required this.timestamp,
  });

  bool get isDelivered => status == 'delivered';
  bool get isRead => status == 'read';

  factory MessageReceipt.fromJson(Map<String, dynamic> json) {
    return MessageReceipt(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
