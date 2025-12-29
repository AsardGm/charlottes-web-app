import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Nativní implementace pro práci se soubory (iOS, Android, desktop)
class VoiceFileHelper {
  /// Získá cestu pro dočasný soubor nahrávky
  static Future<String> getRecordingPath() async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  /// Na nativních platformách tato metoda není potřeba
  static Future<Uint8List> readBlobAsBytes(String blobUrl) async {
    throw UnsupportedError('Blob operations not supported on native platforms');
  }

  /// Načte soubor jako bytes
  static Future<Uint8List> readFileAsBytes(String path) async {
    final file = File(path);
    return await file.readAsBytes();
  }

  /// Smaže soubor
  static Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
