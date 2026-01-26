import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/scan_result_model.dart';

/// Služba pro skenování rostlin pomocí Google Gemini Vision API
///
/// Analyzuje fotky rostlin a vrací edukativní informace
/// o identifikované odrůdě.
class StrainScannerService {
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _model = 'gemini-1.5-flash-latest'; // Revert na stabilní verzi (2.5 API zatím asi nejede)

  /// Systémový prompt pro AI
  static const String _systemPrompt = '''
Jsi expert botanik specializující se na identifikaci rostlin konopí (Cannabis).
Tvým úkolem je analyzovat fotky rostlin a poskytnout edukativní informace.

DŮLEŽITÉ POKYNY:
1. Analyzuj pouze rostliny - pokud na obrázku není rostlina, vrať identified: false
2. Pokud rostlina není konopí, stále ji analyzuj a popiš, ale uveď že to není Cannabis
3. U konopí se snaž identifikovat konkrétní odrůdu podle charakteristik
4. Vždy poskytni edukativní informace - genetika, účinky, pěstování
5. Zhodnoť zdravotní stav rostliny pokud je viditelný
6. Odpovídej POUZE v češtině
7. Buď objektivní a vzdělávací, ne propagační

Odpovídej VŽDY v tomto JSON formátu:
{
  "identified": true/false,
  "is_cannabis": true/false,
  "strain_name": "Název odrůdy nebo 'Neznámá' pokud nelze určit",
  "strain_type": "indica/sativa/hybrid/unknown",
  "confidence": 0-100,
  "characteristics": {
    "leaf_shape": "Popis tvaru listů",
    "structure": "Popis struktury rostliny",
    "color": "Popis barvy",
    "trichomes": "Popis trichomů pokud viditelné",
    "buds": "Popis květů pokud viditelné"
  },
  "education": {
    "genetics": "Rodičovské odrůdy pokud známé",
    "thc_range": "Rozsah THC v %",
    "cbd_range": "Rozsah CBD v %",
    "effects": ["seznam", "účinků"],
    "flavors": ["seznam", "chutí", "a", "vůní"],
    "grow_difficulty": "easy/medium/hard",
    "flowering_time": "Doba květu",
    "tips": ["Tip 1 pro pěstování", "Tip 2"],
    "medical_uses": "Potenciální medicinální využití",
    "history": "Krátká historie odrůdy"
  },
  "health_assessment": {
    "status": "healthy/warning/critical",
    "issues": ["seznam problémů pokud nějaké"],
    "recommendations": ["doporučení pro zlepšení"]
  },
  "general_info": "Pokud to není Cannabis, zde uveď obecné info o rostlině"
}
''';

  /// Analyzuje obrázek rostliny
  ///
  /// Přijímá obrázek jako Uint8List (bytes) a vrací strukturovanou odpověď.
  /// Vyhodí výjimku pokud API selže nebo není nakonfigurováno.
  Future<Map<String, dynamic>> analyzeImage(Uint8List imageBytes) async {
    // Kontrola API klíče
    if (!ApiConfig.hasGeminiKey) {
      throw StrainScannerException(
        'Gemini API klíč není nastaven. Kontaktujte správce aplikace.',
        code: 'missing_api_key',
      );
    }

    // Konverze obrázku na base64
    final base64Image = base64Encode(imageBytes);

    // Sestavení requestu pro Gemini
    final url =
        '$_geminiBaseUrl/$_model:generateContent?key=${ApiConfig.geminiApiKey}';

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': _systemPrompt},
            {
              'text':
                  'Analyzuj tuto rostlinu a poskytni edukativní informace ve formátu JSON. Pokud je to konopí, pokus se identifikovat odrůdu.'
            },
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
        'temperature': 0.4,
        'maxOutputTokens': 2048,
        'responseMimeType': 'application/json',
      }
    };

    try {
      // ignore: avoid_print
      print('[StrainScanner] Odesílám request na Gemini...');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // ignore: avoid_print
      print('[StrainScanner] Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['error']?['message'] ?? 'Neznámá chyba API';
        throw StrainScannerException(
          'Chyba Gemini API: $errorMessage',
          code: 'api_error',
          statusCode: response.statusCode,
        );
      }

      final responseBody = jsonDecode(response.body);
      final content =
          responseBody['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (content == null) {
        throw StrainScannerException(
          'Prázdná odpověď od AI',
          code: 'empty_response',
        );
      }

      // Parse JSON odpovědi
      final aiResponse = jsonDecode(content) as Map<String, dynamic>;

      // ignore: avoid_print
      print('[StrainScanner] AI identifikovala: ${aiResponse['strain_name']}');

      return aiResponse;
    } on FormatException catch (e) {
      throw StrainScannerException(
        'Chyba při parsování odpovědi: ${e.message}',
        code: 'parse_error',
      );
    } on http.ClientException catch (e) {
      throw StrainScannerException(
        'Chyba sítě: ${e.message}',
        code: 'network_error',
      );
    }
  }

  /// Analyzuje obrázek a vrací ScanResultModel
  ///
  /// Kombinuje AI analýzu s metadaty pro uložení.
  Future<ScanResultModel> scanAndCreateResult({
    required String userId,
    required String imageUrl,
    required Uint8List imageBytes,
  }) async {
    final aiResponse = await analyzeImage(imageBytes);

    return ScanResultModel.fromAiResponse(
      userId: userId,
      imageUrl: imageUrl,
      aiResponse: aiResponse,
    );
  }
}

/// Výjimka pro chyby skeneru
class StrainScannerException implements Exception {
  final String message;
  final String code;
  final int? statusCode;

  StrainScannerException(
    this.message, {
    required this.code,
    this.statusCode,
  });

  @override
  String toString() => message;

  /// Je to chyba konfigurace?
  bool get isConfigError => code == 'missing_api_key';

  /// Je to chyba sítě?
  bool get isNetworkError => code == 'network_error';

  /// Je to chyba API?
  bool get isApiError => code == 'api_error';
}
