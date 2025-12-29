import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_settings_model.dart';
import '../services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final userSettingsProvider = FutureProvider<UserSettingsModel?>((ref) async {
  return ref.read(settingsServiceProvider).getSettings();
});

final themeModeProvider = Provider<String>((ref) {
  final settings = ref.watch(userSettingsProvider);
  return settings.when(
    data: (s) => s?.theme ?? 'dark',
    loading: () => 'dark',
    error: (_, _) => 'dark',
  );
});

class SettingsNotifier extends Notifier<AsyncValue<UserSettingsModel?>> {
  late SettingsService _service;

  @override
  AsyncValue<UserSettingsModel?> build() {
    _service = ref.read(settingsServiceProvider);
    _loadSettings();
    return const AsyncValue.loading();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _service.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadSettings();
  }

  Future<void> setTheme(String theme) async {
    try {
      final updated = await _service.setTheme(theme);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final updated = await _service.setNotificationsEnabled(enabled);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setAllowMessagesFrom(String value) async {
    try {
      final updated = await _service.setAllowMessagesFrom(value);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setShowOnlineStatus(bool visible) async {
    try {
      final updated = await _service.setShowOnlineStatus(visible);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings(Map<String, dynamic> updates) async {
    try {
      final updated = await _service.updateSettings(updates);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, AsyncValue<UserSettingsModel?>>(() {
  return SettingsNotifier();
});
