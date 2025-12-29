import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Web stub implementace pro práci se soubory
/// Na webu používáme blob URLs a fetch API
class VoiceFileHelper {
  /// Na webu není potřeba cesta - vrátí prázdný string
  static Future<String> getRecordingPath() async {
    return '';
  }

  /// Načte blob URL jako bytes pomocí HTTP
  static Future<Uint8List> readBlobAsBytes(String blobUrl) async {
    final response = await http.get(Uri.parse(blobUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Nepodařilo se načíst nahrávku');
  }

  /// Na webu tato metoda není potřeba
  static Future<Uint8List> readFileAsBytes(String path) async {
    throw UnsupportedError('File operations not supported on web');
  }

  /// Na webu není co mazat
  static Future<void> deleteFile(String path) async {
    // No-op na webu
  }
}
