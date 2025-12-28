import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/thread_type_model.dart';
import '../services/thread_type_service.dart';

final threadTypeServiceProvider =
    Provider<ThreadTypeService>((ref) => ThreadTypeService());

final threadTypesProvider = FutureProvider<List<ThreadTypeModel>>((ref) async {
  return await ref.read(threadTypeServiceProvider).getThreadTypes();
});

/// Provider pro vybraný typ vlákna při vytváření
class SelectedThreadTypeNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? threadTypeId) {
    state = threadTypeId;
  }

  void clear() {
    state = null;
  }
}

final selectedThreadTypeProvider =
    NotifierProvider<SelectedThreadTypeNotifier, String?>(() {
  return SelectedThreadTypeNotifier();
});

/// Provider pro filtrování podle stavu
class StatusFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? status) {
    state = status;
  }

  void clear() {
    state = null;
  }
}

final statusFilterProvider =
    NotifierProvider<StatusFilterNotifier, String?>(() {
  return StatusFilterNotifier();
});
