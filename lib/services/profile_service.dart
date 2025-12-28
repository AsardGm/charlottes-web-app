import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Získá profil uživatele
  Future<UserModel?> getProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  /// Aktualizuje profil
  Future<UserModel> updateProfile({
    String? username,
    String? bio,
    String? website,
    String? location,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (username != null) updates['username'] = username;
    if (bio != null) updates['bio'] = bio;
    if (website != null) updates['website'] = website;
    if (location != null) updates['location'] = location;

    final response = await _supabase
        .from('profiles')
        .update(updates)
        .eq('id', currentUserId!)
        .select()
        .single();

    return UserModel.fromJson(response);
  }

  /// Nahraje avatar
  Future<String> uploadAvatar(Uint8List bytes, String fileName) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    final extension = fileName.split('.').last.toLowerCase();
    final path = 'avatars/$currentUserId.$extension';

    await _supabase.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$extension',
          ),
        );

    final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);

    // Aktualizuj profil s novou URL
    await _supabase
        .from('profiles')
        .update({'avatar_url': publicUrl})
        .eq('id', currentUserId!);

    return publicUrl;
  }

  /// Smaže avatar
  Future<void> deleteAvatar() async {
    if (currentUserId == null) return;

    // Najdi aktuální avatar
    final profile = await getProfile(currentUserId!);
    if (profile?.avatarUrl == null) return;

    // Smaž ze storage
    try {
      final uri = Uri.parse(profile!.avatarUrl!);
      final path = uri.pathSegments.last;
      await _supabase.storage.from('avatars').remove(['avatars/$path']);
    } catch (_) {
      // Ignoruj chyby při mazání ze storage
    }

    // Aktualizuj profil
    await _supabase
        .from('profiles')
        .update({'avatar_url': null})
        .eq('id', currentUserId!);
  }

  /// Zkontroluje dostupnost username
  Future<bool> isUsernameAvailable(String username) async {
    final response = await _supabase
        .from('profiles')
        .select('id')
        .eq('username', username)
        .neq('id', currentUserId ?? '')
        .maybeSingle();

    return response == null;
  }

  /// Získá statistiky profilu
  Future<ProfileStats> getProfileStats(String userId) async {
    final profile = await getProfile(userId);

    // Spočítej příspěvky
    final postsResponse = await _supabase
        .from('posts')
        .select('id')
        .eq('author_id', userId);

    return ProfileStats(
      followerCount: profile?.followerCount ?? 0,
      followingCount: profile?.followingCount ?? 0,
      postCount: (postsResponse as List).length,
    );
  }
}

class ProfileStats {
  final int followerCount;
  final int followingCount;
  final int postCount;

  ProfileStats({
    required this.followerCount,
    required this.followingCount,
    required this.postCount,
  });
}
