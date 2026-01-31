import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/charlotte_message_model.dart';
import '../models/user_preferences_model.dart';

/// Service pro komunikaci s Charlotte AI (Claude API)
class CharlotteAIService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';

  // TODO: Přesunout do ENV nebo Supabase secrets
  static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY_HERE';
  static const String _model = 'claude-3-5-sonnet-20241022';

  /// Odeslat zprávu Charlotte a získat odpověď
  Future<String> sendMessage({
    required String userMessage,
    required CharlotteUserContext context,
    List<CharlotteMessage>? conversationHistory,
  }) async {
    try {
      // Build messages array pro Claude API
      final messages = _buildMessagesArray(userMessage, conversationHistory);

      // Build system prompt s user contextem
      final systemPrompt = context.buildSystemPrompt();

      // API request
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'system': systemPrompt,
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        return content;
      } else {
        throw Exception('Charlotte AI error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get Charlotte response: $e');
    }
  }

  /// Streamovaná odpověď (pro typing effect)
  Stream<String> sendMessageStreamed({
    required String userMessage,
    required CharlotteUserContext context,
    List<CharlotteMessage>? conversationHistory,
  }) async* {
    // Pro zjednodušení zatím vrátíme celou odpověď najednou
    // TODO: Implementovat streaming s Server-Sent Events
    final response = await sendMessage(
      userMessage: userMessage,
      context: context,
      conversationHistory: conversationHistory,
    );

    // Simulace typing efektu - po slovech
    final words = response.split(' ');
    for (int i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (i == 0) {
        yield words[i];
      } else {
        yield ' ${words[i]}';
      }
    }
  }

  /// Vytvoří messages array pro Claude API
  List<Map<String, String>> _buildMessagesArray(
    String currentMessage,
    List<CharlotteMessage>? history,
  ) {
    final messages = <Map<String, String>>[];

    // Přidat conversation history (pouze user a charlotte, ne system)
    if (history != null) {
      for (final msg in history) {
        if (msg.role == MessageRole.user) {
          messages.add({'role': 'user', 'content': msg.content});
        } else if (msg.role == MessageRole.charlotte) {
          messages.add({'role': 'assistant', 'content': msg.content});
        }
      }
    }

    // Přidat aktuální user message
    messages.add({'role': 'user', 'content': currentMessage});

    return messages;
  }

  /// Vytvoří user context z různých zdrojů dat
  Future<CharlotteUserContext> buildUserContext({
    UserPreferences? preferences,
    String? userName,
    // TODO: Přidat další zdroje dat když budou dostupné
    // List<ConsumptionLog>? recentConsumption,
    // List<CognitiveScore>? cognitiveScores,
    // List<Grow>? activeGrows,
  }) async {
    return CharlotteUserContext(
      userName: userName,
      userRole: preferences?.role?.displayName,
      experienceLevel: preferences?.experienceLevel?.displayName,
      interests: preferences?.interests.map((i) => i.displayName).toList() ?? [],
      goals: preferences?.goals.map((g) => g.displayName).toList() ?? [],
      // TODO: Přidat další context data
      // recentConsumptionCount: recentConsumption?.length,
      // lastConsumptionStrain: recentConsumption?.firstOrNull?.strainName,
      // averageCognitiveScore: _calculateAverageCognitiveScore(cognitiveScores),
      // activeGrowsCount: activeGrows?.length,
    );
  }

  /// Generuje uvítací zprávu Charlotte na základě user contextu
  String generateWelcomeMessage(CharlotteUserContext context) {
    final name = context.userName ?? 'tam';

    if (context.userRole != null) {
      final role = context.userRole!.toLowerCase();

      if (role.contains('grower') || role.contains('pěstitel')) {
        return 'Ahoj $name! 🌿 Jsem Charlotte, tvoje AI asistentka. Vidím, že pěstuješ - rád/a ti pomůžu s radami k pěstování, genetice nebo čemukoli dalšímu!';
      } else if (role.contains('learner') || role.contains('student')) {
        return 'Ahoj $name! 📚 Vítej, jsem Charlotte. Ráda ti pomohu se učit o konopí, kanabinoidech, terpenech a harm reduction. Co tě zajímá?';
      } else if (role.contains('consumer') || role.contains('konzument')) {
        return 'Ahoj $name! 👋 Jsem Charlotte, tvoje AI průvodkyně. Pomůžu ti trackovat konzumaci, porozumět strainům a jejich efektům. V čem můžu pomoct?';
      }
    }

    return 'Ahoj $name! 🕷️ Jsem Charlotte, tvoje AI asistentka v Charlotte\'s Web. Můžu ti pomoct s čímkoli kolem konopí - od harm reduction přes trackování až po rady k pěstování. Co tě zajímá?';
  }

  /// Suggesty pro rychlé otázky (podle user contextu)
  List<String> getSuggestedQuestions(CharlotteUserContext context) {
    final suggestions = <String>[];

    if (context.interests.any((i) => i.contains('Genetika') || i.contains('Genetics'))) {
      suggestions.add('Jaké jsou nejlepší genetiky pro začátečníky?');
    }

    if (context.interests.any((i) => i.contains('Terpeny') || i.contains('Terpenes'))) {
      suggestions.add('Jak terpeny ovlivňují efekt?');
    }

    if (context.goals.any((g) => g.contains('grow') || g.contains('pěst'))) {
      suggestions.add('Jaké jsou základy hydroponiky?');
    }

    if (context.goals.any((g) => g.contains('track') || g.contains('sledovat'))) {
      suggestions.add('Jak správně trackovat konzumaci?');
    }

    // Default suggestions
    if (suggestions.isEmpty) {
      suggestions.addAll([
        'Co je harm reduction?',
        'Jaký je rozdíl mezi Indica a Sativa?',
        'Jak začít s pěstováním?',
      ]);
    }

    return suggestions.take(3).toList();
  }
}
