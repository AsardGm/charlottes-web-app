import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/charlotte_message_model.dart';
import '../services/charlotte_ai_service.dart';
import 'personalization_provider.dart';
import 'auth_provider.dart';

/// Provider pro CharlotteAIService instance
final charlotteAIServiceProvider = Provider<CharlotteAIService>((ref) {
  return CharlotteAIService();
});

/// Provider pro aktuální konverzaci s Charlotte
class CharlotteConversationNotifier extends Notifier<CharlotteConversation> {
  @override
  CharlotteConversation build() {
    _initializeConversation();
    return CharlotteConversation.empty();
  }

  CharlotteAIService get _service => ref.read(charlotteAIServiceProvider);

  /// Inicializace konverzace s uvítací zprávou
  Future<void> _initializeConversation() async {
    final context = await _buildUserContext();
    final welcomeMessage = _service.generateWelcomeMessage(context);

    state = state.addMessage(
      CharlotteMessage.charlotte(welcomeMessage),
    );
  }

  /// Pošle user message a získá odpověď od Charlotte
  Future<void> sendMessage(String userMessage) async {
    // Přidat user message do konverzace
    state = state.addMessage(CharlotteMessage.user(userMessage));

    // Přidat typing indicator
    state = state.addMessage(
      CharlotteMessage.charlotte('', isTyping: true),
    );

    try {
      // Build user context
      final context = await _buildUserContext();

      // Get response from Charlotte
      final response = await _service.sendMessage(
        userMessage: userMessage,
        context: context,
        conversationHistory: state.messages,
      );

      // Replace typing indicator s real response
      final charlotteMessage = CharlotteMessage.charlotte(response);
      state = state.updateLastMessage(charlotteMessage);
    } catch (e) {
      // Error handling - nahradit typing indicator error zprávou
      final errorMessage = CharlotteMessage.charlotte(
        'Omlouvám se, ale momentálně mám technické potíže. Zkus to prosím za chvíli znovu. 🙏',
      );
      state = state.updateLastMessage(errorMessage);
    }
  }

  /// Smaže konverzaci a začne novou
  Future<void> clearConversation() async {
    state = CharlotteConversation.empty();
    await _initializeConversation();
  }

  /// Build user context ze všech dostupných zdrojů
  Future<CharlotteUserContext> _buildUserContext() async {
    final preferences = await ref.read(userPreferencesProvider.future);
    final user = await ref.read(currentUserProvider.future);

    return await _service.buildUserContext(
      preferences: preferences,
      userName: user?.username ?? user?.email?.split('@').first,
    );
  }
}

final charlotteConversationProvider =
    NotifierProvider<CharlotteConversationNotifier, CharlotteConversation>(() {
  return CharlotteConversationNotifier();
});

/// Provider pro suggested questions (podle user contextu)
final suggestedQuestionsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(charlotteAIServiceProvider);
  final preferences = await ref.read(userPreferencesProvider.future);
  final user = await ref.read(currentUserProvider.future);

  final context = await service.buildUserContext(
    preferences: preferences,
    userName: user?.username ?? user?.email?.split('@').first,
  );

  return service.getSuggestedQuestions(context);
});

/// Provider pro typing state (je Charlotte právě typing?)
final isCharlotteTypingProvider = Provider<bool>((ref) {
  final conversation = ref.watch(charlotteConversationProvider);
  if (conversation.messages.isEmpty) return false;
  return conversation.messages.last.isTyping;
});
