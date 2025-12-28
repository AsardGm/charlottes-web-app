import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  static const String _bucketName = 'verejny';

  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    return await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
  }

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
      // Ignore delete errors
    }
  }
}
