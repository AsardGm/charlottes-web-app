import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation_model.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

/// Provider pro seznam konverzací
final conversationsProvider =
    FutureProvider<List<ConversationModel>>((ref) async {
  final chatService = ref.read(chatServiceProvider);
  return await chatService.getConversations();
});

/// Provider pro zprávy v konverzaci
final messagesProvider = FutureProvider.family<List<MessageModel>, String>(
    (ref, conversationId) async {
  final chatService = ref.read(chatServiceProvider);
  return await chatService.getMessages(conversationId);
});

/// Notifier pro chat operace
class ChatNotifier extends Notifier<AsyncValue<void>> {
  late ChatService _chatService;

  ChatService get chatService => _chatService;

  @override
  AsyncValue<void> build() {
    _chatService = ref.read(chatServiceProvider);
    return const AsyncValue.data(null);
  }

  /// Inicializuje šifrovací klíče
  Future<void> initializeKeys() async {
    state = const AsyncValue.loading();
    try {
      await _chatService.initializeUserKeys();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Odešle zprávu
  Future<MessageModel?> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
    String? replyToId,
  }) async {
    try {
      final message = await _chatService.sendMessage(
        conversationId: conversationId,
        content: content,
        messageType: messageType,
        replyToId: replyToId,
      );
      // Refresh messages
      ref.invalidate(messagesProvider(conversationId));
      return message;
    } catch (e) {
      rethrow;
    }
  }

  /// Smaže zprávu
  Future<void> deleteMessage(String messageId, String conversationId) async {
    try {
      await _chatService.deleteMessage(messageId);
      ref.invalidate(messagesProvider(conversationId));
    } catch (e) {
      rethrow;
    }
  }

  /// Přidá reakci
  Future<void> addReaction(
      String messageId, String emoji, String conversationId) async {
    try {
      await _chatService.addReaction(messageId, emoji);
      ref.invalidate(messagesProvider(conversationId));
    } catch (e) {
      rethrow;
    }
  }

  /// Označí jako přečtené
  Future<void> markAsRead(String messageId) async {
    try {
      await _chatService.markAsRead(messageId);
    } catch (e) {
      // Ignoruj chyby při označování
    }
  }

  /// Vytvoří skupinový chat
  Future<String?> createGroup({
    required String name,
    String? description,
    required List<String> memberIds,
  }) async {
    try {
      final conversationId = await _chatService.createGroupConversation(
        name: name,
        description: description,
        memberIds: memberIds,
      );
      ref.invalidate(conversationsProvider);
      return conversationId;
    } catch (e) {
      rethrow;
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, AsyncValue<void>>(() {
  return ChatNotifier();
});

/// Provider pro real-time stream zpráv
final messageStreamProvider =
    StreamProvider.family<MessageModel, String>((ref, conversationId) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.messagesStream(conversationId);
});
