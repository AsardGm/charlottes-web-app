import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lab/lab_grow_model.dart';
import '../models/lab/lab_timeline_model.dart';
import '../models/lab/lab_nutrient_model.dart';
import '../models/lab/lab_diagnostic_model.dart';
import '../services/lab_service.dart';
import '../services/lab_ai_service.dart';

/// Provider pro LabService
final labServiceProvider = Provider<LabService>((ref) => LabService());

/// Provider pro LabAiService
final labAiServiceProvider = Provider<LabAiService>((ref) => LabAiService());

// ==================== GROWS ====================

/// Provider pro vsechny grows
final labGrowsProvider = FutureProvider<List<LabGrowModel>>((ref) async {
  return await ref.read(labServiceProvider).getGrows();
});

/// Provider pro aktivni grows
final labActiveGrowsProvider = FutureProvider<List<LabGrowModel>>((ref) async {
  return await ref.read(labServiceProvider).getGrows(activeOnly: true);
});

/// Provider pro aktivni grow (posledni)
final labActiveGrowProvider = FutureProvider<LabGrowModel?>((ref) async {
  return await ref.read(labServiceProvider).getActiveGrow();
});

/// Provider pro konkretni grow podle ID
final labGrowByIdProvider =
    FutureProvider.family<LabGrowModel?, String>((ref, growId) async {
  return await ref.read(labServiceProvider).getGrowById(growId);
});

// ==================== TIMELINE ====================

/// Provider pro timeline zaznamy growu
final labTimelineProvider =
    FutureProvider.family<List<LabTimelineEntryModel>, String>((ref, growId) async {
  return await ref.read(labServiceProvider).getTimelineEntries(growId);
});

// ==================== NUTRIENTS ====================

/// Provider pro nutrient logy growu
final labNutrientLogsProvider =
    FutureProvider.family<List<LabNutrientLogModel>, String>((ref, growId) async {
  return await ref.read(labServiceProvider).getNutrientLogs(growId);
});

// ==================== DIAGNOSTIKY ====================

/// Provider pro diagnostiky growu
final labDiagnosticsProvider =
    FutureProvider.family<List<LabDiagnosticModel>, String>((ref, growId) async {
  return await ref.read(labServiceProvider).getDiagnostics(growId);
});

// ==================== FEEDING SCHEDULES ====================

/// Provider pro feeding schedules
final labFeedingSchedulesProvider =
    FutureProvider<List<FeedingScheduleModel>>((ref) async {
  return await ref.read(labServiceProvider).getFeedingSchedules();
});

// ==================== GROW NOTIFIER ====================

/// Stav grow operaci
class LabGrowState {
  final bool isLoading;
  final String? errorMessage;
  final LabGrowModel? lastCreated;

  const LabGrowState({
    this.isLoading = false,
    this.errorMessage,
    this.lastCreated,
  });

  bool get hasError => errorMessage != null;

  LabGrowState copyWith({
    bool? isLoading,
    String? errorMessage,
    LabGrowModel? lastCreated,
    bool clearError = false,
  }) {
    return LabGrowState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastCreated: lastCreated ?? this.lastCreated,
    );
  }
}

/// Notifier pro spravu grows
class LabGrowNotifier extends Notifier<LabGrowState> {
  late LabService _service;

  @override
  LabGrowState build() {
    _service = ref.read(labServiceProvider);
    return const LabGrowState();
  }

  /// Vytvori novy grow
  Future<LabGrowModel?> createGrow({
    required String name,
    String? strainName,
    GrowPhase phase = GrowPhase.germination,
    DateTime? startDate,
    GrowEnvironment? environment,
    GrowMedium? medium,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final userId = _service.currentUserId;
      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Uzivatel neni prihlasen',
        );
        return null;
      }

      final grow = LabGrowModel(
        id: '',
        userId: userId,
        name: name,
        strainName: strainName,
        phase: phase,
        startDate: startDate ?? DateTime.now(),
        environment: environment,
        medium: medium,
        notes: notes,
        createdAt: DateTime.now(),
      );

      final created = await _service.createGrow(grow);

      state = state.copyWith(isLoading: false, lastCreated: created);

      // Invaliduj seznamy
      ref.invalidate(labGrowsProvider);
      ref.invalidate(labActiveGrowsProvider);
      ref.invalidate(labActiveGrowProvider);

      return created;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Nepodařilo se vytvořit grow: $e',
      );
      return null;
    }
  }

  /// Zmeni fazi growu
  Future<void> changePhase(String growId, GrowPhase newPhase) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.changePhase(growId, newPhase);

      state = state.copyWith(isLoading: false);

      // Invaliduj
      ref.invalidate(labGrowByIdProvider(growId));
      ref.invalidate(labGrowsProvider);
      ref.invalidate(labActiveGrowsProvider);
      ref.invalidate(labActiveGrowProvider);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Chyba pri zmene faze: $e',
      );
    }
  }

  /// Smaze grow
  Future<void> deleteGrow(String growId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.deleteGrow(growId);

      state = state.copyWith(isLoading: false);

      ref.invalidate(labGrowsProvider);
      ref.invalidate(labActiveGrowsProvider);
      ref.invalidate(labActiveGrowProvider);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Chyba pri mazani: $e',
      );
    }
  }
}

/// Provider pro grow notifier
final labGrowNotifierProvider =
    NotifierProvider<LabGrowNotifier, LabGrowState>(() => LabGrowNotifier());

// ==================== TIMELINE NOTIFIER ====================

/// Notifier pro spravu timeline
class LabTimelineNotifier extends Notifier<LabGrowState> {
  late LabService _service;

  @override
  LabGrowState build() {
    _service = ref.read(labServiceProvider);
    return const LabGrowState();
  }

  /// Prida timeline zaznam
  Future<LabTimelineEntryModel?> addEntry({
    required String growId,
    required int dayNumber,
    TimelineEventType eventType = TimelineEventType.note,
    MilestoneType? milestoneType,
    String? title,
    String? description,
    String? imageUrl,
    String? phaseAtTime,
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final userId = _service.currentUserId;
      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Uzivatel neni prihlasen',
        );
        return null;
      }

      final entry = LabTimelineEntryModel(
        id: '',
        growId: growId,
        userId: userId,
        dayNumber: dayNumber,
        eventType: eventType,
        milestoneType: milestoneType,
        title: title,
        description: description,
        imageUrl: imageUrl,
        phaseAtTime: phaseAtTime,
        metadata: metadata,
        createdAt: DateTime.now(),
      );

      final created = await _service.addTimelineEntry(entry);

      state = state.copyWith(isLoading: false);

      ref.invalidate(labTimelineProvider(growId));

      return created;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Chyba pri pridavani zaznamu: $e',
      );
      return null;
    }
  }

  /// Smaze timeline zaznam
  Future<void> deleteEntry(String entryId, String growId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.deleteTimelineEntry(entryId);
      state = state.copyWith(isLoading: false);
      ref.invalidate(labTimelineProvider(growId));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Chyba pri mazani: $e',
      );
    }
  }
}

/// Provider pro timeline notifier
final labTimelineNotifierProvider =
    NotifierProvider<LabTimelineNotifier, LabGrowState>(() => LabTimelineNotifier());

// ==================== NUTRIENT NOTIFIER ====================

/// Notifier pro spravu nutrients
class LabNutrientNotifier extends Notifier<LabGrowState> {
  late LabService _service;

  @override
  LabGrowState build() {
    _service = ref.read(labServiceProvider);
    return const LabGrowState();
  }

  /// Prida nutrient log
  Future<LabNutrientLogModel?> addLog({
    required String growId,
    required int dayNumber,
    double? phValue,
    double? ecValue,
    double? ppmValue,
    int? waterAmountMl,
    double? temperature,
    double? humidity,
    List<NutrientEntry>? nutrients,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final userId = _service.currentUserId;
      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Uzivatel neni prihlasen',
        );
        return null;
      }

      final log = LabNutrientLogModel(
        id: '',
        growId: growId,
        userId: userId,
        dayNumber: dayNumber,
        phValue: phValue,
        ecValue: ecValue,
        ppmValue: ppmValue,
        waterAmountMl: waterAmountMl,
        temperature: temperature,
        humidity: humidity,
        nutrients: nutrients ?? [],
        notes: notes,
        createdAt: DateTime.now(),
      );

      final created = await _service.addNutrientLog(log);

      state = state.copyWith(isLoading: false);

      ref.invalidate(labNutrientLogsProvider(growId));

      return created;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Chyba pri pridavani logu: $e',
      );
      return null;
    }
  }

  /// Smaze nutrient log
  Future<void> deleteLog(String logId, String growId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.deleteNutrientLog(logId);
      state = state.copyWith(isLoading: false);
      ref.invalidate(labNutrientLogsProvider(growId));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Chyba pri mazani: $e',
      );
    }
  }
}

/// Provider pro nutrient notifier
final labNutrientNotifierProvider =
    NotifierProvider<LabNutrientNotifier, LabGrowState>(() => LabNutrientNotifier());
