import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/follow_request_model.dart';
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

/// Provider pro stav sledování (following, requested, not_following)
final followStatusProvider = FutureProvider.family<FollowStatus, String>((ref, userId) async {
  return ref.read(followServiceProvider).getFollowStatus(userId);
});

/// Provider pro čekající žádosti o sledování
final pendingFollowRequestsProvider = FutureProvider<List<FollowRequestModel>>((ref) async {
  return ref.read(followServiceProvider).getPendingRequests();
});

/// Provider pro počet čekajících žádostí
final pendingRequestsCountProvider = FutureProvider<int>((ref) async {
  return ref.read(followServiceProvider).getPendingRequestsCount();
});

/// Provider pro kontrolu, zda je uživatel soukromý
final isUserPrivateProvider = FutureProvider.family<bool, String>((ref, userId) async {
  return ref.read(followServiceProvider).isUserPrivate(userId);
});

class FollowNotifier extends Notifier<void> {
  late FollowService _service;

  @override
  void build() {
    _service = ref.read(followServiceProvider);
  }

  /// Invaliduje všechny related providery
  void _invalidateAll(String userId) {
    ref.invalidate(isFollowingProvider(userId));
    ref.invalidate(followStatusProvider(userId));
    ref.invalidate(followersProvider(userId));
    ref.invalidate(followingProvider(null));
    ref.invalidate(pendingFollowRequestsProvider);
    ref.invalidate(pendingRequestsCountProvider);
  }

  Future<bool> toggleFollow(String userId) async {
    final isNowFollowing = await _service.toggleFollow(userId);
    _invalidateAll(userId);
    return isNowFollowing;
  }

  /// Přepne stav sledování s podporou soukromých účtů
  Future<FollowStatus> toggleFollowOrRequest(String userId) async {
    final newStatus = await _service.toggleFollowOrRequest(userId);
    _invalidateAll(userId);
    return newStatus;
  }

  Future<void> follow(String userId) async {
    await _service.follow(userId);
    _invalidateAll(userId);
  }

  Future<void> unfollow(String userId) async {
    await _service.unfollow(userId);
    _invalidateAll(userId);
  }

  /// Odešle žádost o sledování
  Future<void> sendFollowRequest(String userId) async {
    await _service.sendFollowRequest(userId);
    _invalidateAll(userId);
  }

  /// Zruší odeslanou žádost
  Future<void> cancelFollowRequest(String userId) async {
    await _service.cancelFollowRequest(userId);
    _invalidateAll(userId);
  }

  /// Přijme žádost o sledování
  Future<void> acceptFollowRequest(String requesterId) async {
    await _service.acceptFollowRequest(requesterId);
    _invalidateAll(requesterId);
  }

  /// Odmítne žádost o sledování
  Future<void> rejectFollowRequest(String requesterId) async {
    await _service.rejectFollowRequest(requesterId);
    _invalidateAll(requesterId);
  }
}

final followNotifierProvider = NotifierProvider<FollowNotifier, void>(() {
  return FollowNotifier();
});
