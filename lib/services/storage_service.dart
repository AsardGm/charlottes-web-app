import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

/// Služba pro práci se soubory (obrázky)
///
/// Umožňuje vybírat obrázky z galerie/fotoaparátu
/// a nahrávat je do Supabase Storage.
class StorageService {
  /// Supabase klient
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Image picker pro výběr obrázků
  final ImagePicker _picker = ImagePicker();

  /// Název bucketu v Supabase Storage
  static const String _bucketName = 'verejny';

  /// Vybere obrázek z galerie nebo fotoaparátu
  ///
  /// Automaticky zmenší obrázek na max 1920px a komprimuje na 85%.
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    return await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
  }

  /// Nahraje obrázek příspěvku
  ///
  /// Vrací veřejnou URL nahraného obrázku.
  Future<String?> uploadPostImage(XFile file) async {
    final userId = _supabase.auth.currentUser!.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = file.path.split('.').last;
    final path = 'posts/$userId/$timestamp.$extension';

    await _supabase.storage.from(_bucketName).upload(
          path,
          File(file.path),
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    return _supabase.storage.from(_bucketName).getPublicUrl(path);
  }

  /// Nahraje avatar uživatele
  ///
  /// Vrací veřejnou URL nahraného avataru.
  Future<String?> uploadAvatar(XFile file) async {
    final userId = _supabase.auth.currentUser!.id;
    final extension = file.path.split('.').last;
    final path = 'avatars/$userId.$extension';

    await _supabase.storage.from(_bucketName).upload(
          path,
          File(file.path),
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    return _supabase.storage.from(_bucketName).getPublicUrl(path);
  }

  /// Smaže obrázek ze storage
  ///
  /// Přijímá veřejnou URL obrázku a extrahuje cestu pro smazání.
  Future<void> deleteImage(String url) async {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final path = pathSegments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from(_bucketName).remove([path]);
      }
    } catch (_) {
      // Ignoruj chyby při mazání
    }
  }
}
