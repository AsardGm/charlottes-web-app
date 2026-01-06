import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/block_service.dart';
import '../models/user_model.dart';

/// Provider pro BlockService
final blockServiceProvider = Provider<BlockService>((ref) => BlockService());

/// Provider pro kontrolu, zda je uzivatel zablokovany
final isBlockedProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final service = ref.read(blockServiceProvider);
  return service.isBlocked(userId);
});

/// Provider pro kontrolu vzajemneho blokovani
final isMutuallyBlockedProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final service = ref.read(blockServiceProvider);
  return service.isMutuallyBlocked(userId);
});

/// Provider pro seznam zablokovaných uzivatelu
final blockedUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final service = ref.read(blockServiceProvider);
  return service.getBlockedUsers();
});

/// Provider pro pocet zablokovaných uzivatelu
final blockedUsersCountProvider = FutureProvider<int>((ref) async {
  final service = ref.read(blockServiceProvider);
  return service.getBlockedUsersCount();
});

/// Provider pro vsechna blokovana ID (pro filtrovani)
final allBlockedIdsProvider = FutureProvider<Set<String>>((ref) async {
  final service = ref.read(blockServiceProvider);
  return service.getAllBlockedIds();
});

/// Notifier pro spravu blokovani
class BlockNotifier extends Notifier<void> {
  late BlockService _service;

  @override
  void build() {
    _service = ref.read(blockServiceProvider);
  }

  /// Invaliduje vsechny related providery
  void _invalidateAll(String userId) {
    ref.invalidate(isBlockedProvider(userId));
    ref.invalidate(isMutuallyBlockedProvider(userId));
    ref.invalidate(blockedUsersProvider);
    ref.invalidate(blockedUsersCountProvider);
    ref.invalidate(allBlockedIdsProvider);
  }

  /// Zablokuje uzivatele
  Future<void> blockUser(String userId) async {
    await _service.blockUser(userId);
    _invalidateAll(userId);
  }

  /// Odblokuje uzivatele
  Future<void> unblockUser(String userId) async {
    await _service.unblockUser(userId);
    _invalidateAll(userId);
  }

  /// Prepne stav blokovani
  Future<bool> toggleBlock(String userId) async {
    final isNowBlocked = await _service.toggleBlock(userId);
    _invalidateAll(userId);
    return isNowBlocked;
  }
}

final blockNotifierProvider = NotifierProvider<BlockNotifier, void>(() {
  return BlockNotifier();
});
