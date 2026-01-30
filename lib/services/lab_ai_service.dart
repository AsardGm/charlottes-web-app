import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/lab/lab_diagnostic_model.dart';

/// AI diagnosticka sluzba pro Lab - Oci Arasaky modul
///
/// Pouziva Gemini Vision API pro analyzu fotek rostlin.
/// Podporuje 4 typy diagnostiky: deficiency, trichome, health, pest.
class LabAiService {
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _model = 'gemini-1.5-flash-latest';

  /// Systemovy prompt pro diagnostiku
  static const String _systemPrompt = '''
Jsi expert botanik specializujici se na diagnostiku rostlin konopi (Cannabis).
Tvym ukolem je analyzovat fotky rostlin a poskytnout presnou diagnostiku.

DULEZITE POKYNY:
1. Analyzuj POUZE rostlinu na obrazku
2. Pokud na obrazku neni rostlina, vrat "diagnosis": "Na obrazku neni rostlina"
3. Bud presny a konkretni v diagnoze
4. Doporuceni musi byt prakticka a proveditelna
5. Odpovidej VZDY v cestine
6. Severity urcuj objektivne podle zavaznosti problemu

Odpovidej VZDY v tomto JSON formatu:
{
  "diagnosis": "Popis diagnozy - co jsi zjistil",
  "severity": "low/medium/high/critical",
  "confidence": 0-100,
  "recommendations": ["Doporuceni 1", "Doporuceni 2", "Doporuceni 3"],
  "details": {
    "identified_issues": ["Problem 1", "Problem 2"],
    "affected_areas": "Popis postizenych casti",
    "progression": "Jak se problem vyviji",
    "urgency": "Jak rychle je treba jednat"
  }
}
''';

  /// Analyzuje obrazek rostliny podle typu diagnostiky
  Future<Map<String, dynamic>> analyzeImage({
    required Uint8List imageBytes,
    required DiagnosticType diagnosticType,
  }) async {
    if (!ApiConfig.hasGeminiKey) {
      throw LabAiException(
        'Gemini API klic neni nastaven',
        code: 'missing_api_key',
      );
    }

    final base64Image = base64Encode(imageBytes);

    final url =
        '$_geminiBaseUrl/$_model:generateContent?key=${ApiConfig.geminiApiKey}';

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': _systemPrompt},
            {'text': diagnosticType.prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 2048,
        'responseMimeType': 'application/json',
      }
    };

    try {
      // ignore: avoid_print
      print('[LabAI] Odesilam ${diagnosticType.name} analyzu na Gemini...');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // ignore: avoid_print
      print('[LabAI] Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['error']?['message'] ?? 'Neznama chyba API';
        throw LabAiException(
          'Chyba Gemini API: $errorMessage',
          code: 'api_error',
          statusCode: response.statusCode,
        );
      }

      final responseBody = jsonDecode(response.body);
      final content =
          responseBody['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (content == null) {
        throw LabAiException(
          'Prazdna odpoved od AI',
          code: 'empty_response',
        );
      }

      final aiResponse = jsonDecode(content) as Map<String, dynamic>;

      // ignore: avoid_print
      print('[LabAI] Diagnoza: ${aiResponse['diagnosis']}');

      return aiResponse;
    } on FormatException catch (e) {
      throw LabAiException(
        'Chyba pri parsovani odpovedi: ${e.message}',
        code: 'parse_error',
      );
    } on http.ClientException catch (e) {
      throw LabAiException(
        'Chyba site: ${e.message}',
        code: 'network_error',
      );
    }
  }

  /// Parsuje AI odpoved do strukturovanych dat pro LabDiagnosticModel
  DiagnosticResult parseResponse(Map<String, dynamic> aiResponse) {
    return DiagnosticResult(
      diagnosis: aiResponse['diagnosis'] as String? ?? 'AI analyza nedostupna',
      severity: DiagnosticSeverity.fromString(
              aiResponse['severity'] as String?) ??
          DiagnosticSeverity.low,
      confidence: (aiResponse['confidence'] as num?)?.toDouble() ?? 0,
      recommendations: (aiResponse['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rawResponse: aiResponse,
    );
  }
}

/// Strukturovany vysledek AI diagnostiky
class DiagnosticResult {
  final String diagnosis;
  final DiagnosticSeverity severity;
  final double confidence;
  final List<String> recommendations;
  final Map<String, dynamic> rawResponse;

  const DiagnosticResult({
    required this.diagnosis,
    required this.severity,
    required this.confidence,
    required this.recommendations,
    required this.rawResponse,
  });
}

/// Vyjimka pro chyby AI sluzby
class LabAiException implements Exception {
  final String message;
  final String code;
  final int? statusCode;

  LabAiException(
    this.message, {
    required this.code,
    this.statusCode,
  });

  @override
  String toString() => message;

  bool get isConfigError => code == 'missing_api_key';
  bool get isNetworkError => code == 'network_error';
  bool get isApiError => code == 'api_error';
}
