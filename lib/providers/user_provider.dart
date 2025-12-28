import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

class UsersNotifier extends Notifier<AsyncValue<List<UserModel>>> {
  late AdminService _adminService;

  @override
  AsyncValue<List<UserModel>> build() {
    _adminService = ref.read(adminServiceProvider);
    _loadInitial();
    return const AsyncValue.loading();
  }

  Future<void> _loadInitial() async {
    await loadUsers();
  }

  Future<void> loadUsers() async {
    state = const AsyncValue.loading();
    try {
      final users = await _adminService.getAllUsers();
      state = AsyncValue.data(users);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      await _adminService.blockUser(userId);
      _updateUserInList(userId, (user) => user.copyWith(isBlocked: true));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      await _adminService.unblockUser(userId);
      _updateUserInList(userId, (user) => user.copyWith(isBlocked: false));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> makeAdmin(String userId) async {
    try {
      await _adminService.makeAdmin(userId);
      _updateUserInList(userId, (user) => user.copyWith(role: 'admin'));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> makeMember(String userId) async {
    try {
      await _adminService.makeMember(userId);
      _updateUserInList(userId, (user) => user.copyWith(role: 'member'));
    } catch (e) {
      rethrow;
    }
  }

  void _updateUserInList(String userId, UserModel Function(UserModel) update) {
    final currentUsers = state.value ?? [];
    final index = currentUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final newList = [...currentUsers];
      newList[index] = update(currentUsers[index]);
      state = AsyncValue.data(newList);
    }
  }
}

final usersProvider =
    NotifierProvider<UsersNotifier, AsyncValue<List<UserModel>>>(() {
  return UsersNotifier();
});

final statsProvider = FutureProvider<Map<String, int>>((ref) async {
  return await ref.read(adminServiceProvider).getStats();
});
