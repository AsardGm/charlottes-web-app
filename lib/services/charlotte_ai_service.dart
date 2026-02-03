import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/charlotte_message_model.dart';
import '../models/user_preferences_model.dart';
import '../models/consumption_insights_model.dart';
import '../models/cognitive_insights_model.dart';
import 'consumption_insights_service.dart';
import 'cognitive_insights_service.dart';
import 'tbreak_service.dart';

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
    String? userId,
    ConsumptionInsights? consumptionInsights,
    CognitiveInsights? cognitiveInsights,
  }) async {
    // Fetch consumption insights if not provided and userId available
    ConsumptionInsights? consumptionData = consumptionInsights;
    if (consumptionData == null && userId != null) {
      try {
        final insightsService = ConsumptionInsightsService();
        consumptionData = await insightsService.generateInsights(userId);
      } catch (e) {
        // Ignore errors, continue without consumption data
        consumptionData = null;
      }
    }

    // Fetch cognitive insights if not provided and userId available
    CognitiveInsights? cognitiveData = cognitiveInsights;
    if (cognitiveData == null && userId != null) {
      try {
        final cognitiveService = CognitiveInsightsService();
        cognitiveData = await cognitiveService.generateInsights(userId);
      } catch (e) {
        // Ignore errors, continue without cognitive data
        cognitiveData = null;
      }
    }

    return CharlotteUserContext(
      userName: userName,
      userRole: preferences?.role?.displayName,
      experienceLevel: preferences?.experienceLevel?.displayName,
      interests: preferences?.interests.map((i) => i.displayName).toList() ?? [],
      goals: preferences?.goals.map((g) => g.displayName).toList() ?? [],
      recentConsumptionCount: consumptionData?.last7DaysSessions,
      lastConsumptionStrain: consumptionData?.lastConsumptionStrain,
      averageCognitiveScore: cognitiveData?.currentScore ?? cognitiveData?.averageScore,
      activeGrowsCount: null, // TODO: Add when grow tracking is available
      cognitiveTrend: cognitiveData?.trend.displayName,
      cognitiveTrendPercentage: cognitiveData?.trendPercentage,
      cognitiveWarnings: cognitiveData?.warnings ?? [],
      hasCognitiveDecline: cognitiveData?.isSignificantDecline ?? false,
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

  /// Harm Reduction: Analyze user patterns and suggest T-break if needed
  Future<Map<String, dynamic>> analyzeHarmReductionNeeds(String userId) async {
    final recommendations = <String>[];
    var needsTBreak = false;
    var reason = '';
    var severity = 'low';

    try {
      // Check consumption frequency (last 30 days)
      final consumptionService = ConsumptionInsightsService();
      final insights = await consumptionService.generateInsights(userId);

      if (insights == null) {
        return {
          'needsTBreak': needsTBreak,
          'reason': reason,
          'severity': severity,
          'recommendations': recommendations,
        };
      }

      // Check 1: Daily use for extended period
      if (insights.last7DaysSessions >= 6) {
        // User is consuming almost daily
        final last30Days = await _getConsumptionCount(userId, 30);
        if (last30Days >= 25) {
          needsTBreak = true;
          reason = 'Denní užívání po 30+ dní - tolerance pravděpodobně vysoká';
          severity = 'high';
          recommendations.addAll([
            'Zvažuj T-break 2-4 týdny pro reset tolerance',
            'Vysoká frekvence zvyšuje riziko závislosti',
            'Tvoje tolerance je pravděpodobně velmi vysoká - platíš víc za menší efekt',
          ]);
        } else if (last30Days >= 15) {
          needsTBreak = true;
          reason = 'Častá konzumace - doporučuji preventivní T-break';
          severity = 'medium';
          recommendations.addAll([
            'T-break 1-2 týdny pomůže udržet toleranci nízkou',
            'Prevention is better than cure',
            'Ušetříš peníze a užiješ si to víc',
          ]);
        }
      }

      // Check 2: Check for active T-break
      final tbreakService = TBreakService();
      final activeBreak = await tbreakService.getActiveToleranceBreak(userId);

      if (activeBreak != null) {
        needsTBreak = false;
        reason = 'Již máš aktivní T-break - skvělá práce! 💪';
        severity = 'low';
        recommendations.clear();
        recommendations.addAll([
          'Pokračuj v T-breaku - den ${activeBreak.daysCompleted}/${activeBreak.targetDays}',
          activeBreak.getEncouragementMessage(),
        ]);
      }

      // Check 3: Cognitive decline correlation
      final cognitiveService = CognitiveInsightsService();
      final cognitiveInsights = await cognitiveService.generateInsights(userId);

      if (cognitiveInsights != null && cognitiveInsights.isSignificantDecline) {
        needsTBreak = true;
        severity = 'high';
        recommendations.add(
          '⚠️ Cognitive performance klesá - T-break může pomoct',
        );
      }

      // Check 4: Long time without T-break
      final lastBreak = await _getLastCompletedTBreak(userId);
      if (lastBreak != null) {
        final daysSinceBreak = DateTime.now().difference(lastBreak).inDays;
        if (daysSinceBreak > 90 && !needsTBreak) {
          needsTBreak = true;
          reason = '3+ měsíce bez T-breaku';
          severity = 'medium';
          recommendations.add(
            'Poslední T-break byl před $daysSinceBreak dny - zvažuj další',
          );
        }
      } else if (insights.last7DaysSessions > 0) {
        // User consumes but never did T-break
        recommendations.add(
          'Nikdy jsi neudělal T-break - zkus to, uvidíš rozdíl!',
        );
      }
    } catch (e) {
      // Silent fail - harm reduction is advisory, not critical
    }

    return {
      'needsTBreak': needsTBreak,
      'reason': reason,
      'severity': severity,
      'recommendations': recommendations,
    };
  }

  /// Get consumption count for last N days
  Future<int> _getConsumptionCount(String userId, int days) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final response = await Supabase.instance.client
          .from('consumption_logs')
          .select('id')
          .eq('user_id', userId)
          .gte('timestamp', since.toIso8601String())
          .count();

      return response.count;
    } catch (e) {
      return 0;
    }
  }

  /// Get date of last completed T-break
  Future<DateTime?> _getLastCompletedTBreak(String userId) async {
    try {
      final tbreakService = TBreakService();
      final breaks = await tbreakService.getToleranceBreakHistory(userId);

      final completedBreaks = breaks
          .where((b) => b.completedDate != null)
          .toList()
        ..sort((a, b) => b.completedDate!.compareTo(a.completedDate!));

      return completedBreaks.isNotEmpty ? completedBreaks.first.completedDate : null;
    } catch (e) {
      return null;
    }
  }

  /// Generate proactive harm reduction message for Charlotte
  Future<String?> generateHarmReductionAlert(String userId) async {
    final analysis = await analyzeHarmReductionNeeds(userId);

    if (!analysis['needsTBreak']) return null;

    final severity = analysis['severity'];
    final reason = analysis['reason'];
    final recommendations = analysis['recommendations'] as List<String>;

    String emoji;
    String urgency;

    switch (severity) {
      case 'high':
        emoji = '🚨';
        urgency = 'důležité';
        break;
      case 'medium':
        emoji = '⚠️';
        urgency = 'doporučení';
        break;
      default:
        emoji = '💡';
        urgency = 'tip';
    }

    final message = StringBuffer();
    message.writeln('$emoji **Harm Reduction $urgency**\n');
    message.writeln(reason);
    message.writeln();

    for (final rec in recommendations) {
      message.writeln('• $rec');
    }

    message.writeln('\nChceš začít T-break? Najdeš ho v Lab → T-BREAK modulu.');

    return message.toString();
  }
}
