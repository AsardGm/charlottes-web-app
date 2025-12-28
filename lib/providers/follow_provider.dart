import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/follow_service.dart';

final followServiceProvider = Provider<FollowService>((ref) {
  return FollowService();
});

final followersProvider = FutureProvider.family<List<UserModel>, String?>((ref, userId) async {
  return ref.read(followServiceProvider).getFollowers(userId: userId);
});

final followingProvider = FutureProvider.family<List<UserModel>, String?>((ref, userId) async {
  return ref.read(followServiceProvider).getFollowing(userId: userId);
});

final isFollowingProvider = FutureProvider.family<bool, String>((ref, userId) async {
  return ref.read(followServiceProvider).isFollowing(userId);
});

class FollowNotifier extends Notifier<void> {
  late FollowService _service;

  @override
  void build() {
    _service = ref.read(followServiceProvider);
  }

  Future<bool> toggleFollow(String userId) async {
    final isNowFollowing = await _service.toggleFollow(userId);

    // Invalidate related providers
    ref.invalidate(isFollowingProvider(userId));
    ref.invalidate(followersProvider(userId));
    ref.invalidate(followingProvider(null)); // Current user's following list

    return isNowFollowing;
  }

  Future<void> follow(String userId) async {
    await _service.follow(userId);

    ref.invalidate(isFollowingProvider(userId));
    ref.invalidate(followersProvider(userId));
    ref.invalidate(followingProvider(null));
  }

  Future<void> unfollow(String userId) async {
    await _service.unfollow(userId);

    ref.invalidate(isFollowingProvider(userId));
    ref.invalidate(followersProvider(userId));
    ref.invalidate(followingProvider(null));
  }
}

final followNotifierProvider = NotifierProvider<FollowNotifier, void>(() {
  return FollowNotifier();
});
