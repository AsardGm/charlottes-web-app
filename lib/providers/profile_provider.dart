import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';
import 'auth_provider.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final profileProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  return ref.read(profileServiceProvider).getProfile(userId);
});

final profileStatsProvider = FutureProvider.family<ProfileStats, String>((ref, userId) async {
  return ref.read(profileServiceProvider).getProfileStats(userId);
});

class ProfileNotifier extends Notifier<AsyncValue<UserModel?>> {
  late ProfileService _service;

  @override
  AsyncValue<UserModel?> build() {
    _service = ref.read(profileServiceProvider);
    return const AsyncValue.data(null);
  }

  Future<void> loadProfile(String userId) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _service.getProfile(userId);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<UserModel> updateProfile({
    String? username,
    String? bio,
    String? website,
    String? location,
  }) async {
    try {
      final updated = await _service.updateProfile(
        username: username,
        bio: bio,
        website: website,
        location: location,
      );
      state = AsyncValue.data(updated);

      // Refresh auth provider
      ref.invalidate(currentUserProvider);

      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadAvatar(Uint8List bytes, String fileName) async {
    try {
      final url = await _service.uploadAvatar(bytes, fileName);

      // Refresh profile
      final userId = _service.currentUserId;
      if (userId != null) {
        await loadProfile(userId);
      }

      // Refresh auth provider
      ref.invalidate(currentUserProvider);

      return url;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAvatar() async {
    await _service.deleteAvatar();

    // Refresh profile
    final userId = _service.currentUserId;
    if (userId != null) {
      await loadProfile(userId);
    }

    // Refresh auth provider
    ref.invalidate(currentUserProvider);
  }

  Future<bool> isUsernameAvailable(String username) async {
    return _service.isUsernameAvailable(username);
  }
}

final profileNotifierProvider =
    NotifierProvider<ProfileNotifier, AsyncValue<UserModel?>>(() {
  return ProfileNotifier();
});
