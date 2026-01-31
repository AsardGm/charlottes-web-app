import 'package:flutter/foundation.dart';

/// Role v konverzaci s Charlotte
enum MessageRole {
  user,
  charlotte,
  system,
}

/// Jednotlivá zpráva v konverzaci s Charlotte
@immutable
class CharlotteMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isTyping; // Pro typing indicator

  const CharlotteMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isTyping = false,
  });

  factory CharlotteMessage.user(String content) {
    return CharlotteMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory CharlotteMessage.charlotte(String content, {bool isTyping = false}) {
    return CharlotteMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.charlotte,
      content: content,
      timestamp: DateTime.now(),
      isTyping: isTyping,
    );
  }

  factory CharlotteMessage.system(String content) {
    return CharlotteMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.system,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  CharlotteMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? isTyping,
  }) {
    return CharlotteMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isTyping': isTyping,
    };
  }

  factory CharlotteMessage.fromJson(Map<String, dynamic> json) {
    return CharlotteMessage(
      id: json['id'],
      role: MessageRole.values.firstWhere((e) => e.name == json['role']),
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isTyping: json['isTyping'] ?? false,
    );
  }
}

/// Konverzační session s Charlotte
@immutable
class CharlotteConversation {
  final String id;
  final List<CharlotteMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? title; // Auto-generated summary

  const CharlotteConversation({
    required this.id,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.title,
  });

  static CharlotteConversation empty() {
    final now = DateTime.now();
    return CharlotteConversation(
      id: now.millisecondsSinceEpoch.toString(),
      messages: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  CharlotteConversation addMessage(CharlotteMessage message) {
    return copyWith(
      messages: [...messages, message],
      updatedAt: DateTime.now(),
    );
  }

  CharlotteConversation updateLastMessage(CharlotteMessage message) {
    if (messages.isEmpty) return this;
    final updated = [...messages];
    updated[updated.length - 1] = message;
    return copyWith(messages: updated, updatedAt: DateTime.now());
  }

  CharlotteConversation copyWith({
    String? id,
    List<CharlotteMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
  }) {
    return CharlotteConversation(
      id: id ?? this.id,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'title': title,
    };
  }

  factory CharlotteConversation.fromJson(Map<String, dynamic> json) {
    return CharlotteConversation(
      id: json['id'],
      messages: (json['messages'] as List)
          .map((m) => CharlotteMessage.fromJson(m))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      title: json['title'],
    );
  }
}

/// User context pro Charlotte - všechny relevantní data
@immutable
class CharlotteUserContext {
  // From Smart Onboarding
  final String? userRole;
  final String? experienceLevel;
  final List<String> interests;
  final List<String> goals;

  // Recent activity summary
  final int? recentConsumptionCount;
  final String? lastConsumptionStrain;
  final double? averageCognitiveScore;
  final int? activeGrowsCount;

  // User name
  final String? userName;

  const CharlotteUserContext({
    this.userRole,
    this.experienceLevel,
    this.interests = const [],
    this.goals = const [],
    this.recentConsumptionCount,
    this.lastConsumptionStrain,
    this.averageCognitiveScore,
    this.activeGrowsCount,
    this.userName,
  });

  static const CharlotteUserContext empty = CharlotteUserContext();

  /// Vytvoří system prompt pro Charlotte na základě user contextu
  String buildSystemPrompt() {
    final buffer = StringBuffer();

    buffer.writeln('You are Charlotte, a friendly AI assistant in a cannabis wellness app called "Charlotte\'s Web".');
    buffer.writeln('You help users with cannabis education, harm reduction, consumption tracking, and growing advice.');
    buffer.writeln('You are warm, supportive, knowledgeable, and never judgmental.');
    buffer.writeln();
    buffer.writeln('Current user context:');

    if (userName != null) {
      buffer.writeln('- User name: $userName');
    }

    if (userRole != null) {
      buffer.writeln('- Role: $userRole');
    }

    if (experienceLevel != null) {
      buffer.writeln('- Experience level: $experienceLevel');
    }

    if (interests.isNotEmpty) {
      buffer.writeln('- Interests: ${interests.join(", ")}');
    }

    if (goals.isNotEmpty) {
      buffer.writeln('- Goals: ${goals.join(", ")}');
    }

    if (recentConsumptionCount != null && recentConsumptionCount! > 0) {
      buffer.writeln('- Recent consumption: $recentConsumptionCount sessions tracked');
    }

    if (lastConsumptionStrain != null) {
      buffer.writeln('- Last strain: $lastConsumptionStrain');
    }

    if (averageCognitiveScore != null) {
      buffer.writeln('- Average cognitive score: ${averageCognitiveScore!.toStringAsFixed(1)}/10');
    }

    if (activeGrowsCount != null && activeGrowsCount! > 0) {
      buffer.writeln('- Active grows: $activeGrowsCount');
    }

    buffer.writeln();
    buffer.writeln('Guidelines:');
    buffer.writeln('- Keep responses concise and friendly (2-4 sentences usually)');
    buffer.writeln('- Use Czech language');
    buffer.writeln('- Reference their tracked data when relevant');
    buffer.writeln('- Offer harm reduction advice when appropriate');
    buffer.writeln('- Suggest app features they might not know about');
    buffer.writeln('- Use emojis occasionally 🌿');

    return buffer.toString();
  }
}
