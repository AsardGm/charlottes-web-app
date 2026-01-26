import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/strain_model.dart';
import '../models/scan_result_model.dart';
import '../services/strain_service.dart';
import '../services/strain_scanner_service.dart';

/// Provider pro StrainService
final strainServiceProvider = Provider<StrainService>((ref) => StrainService());

/// Provider pro StrainScannerService
final strainScannerServiceProvider =
    Provider<StrainScannerService>((ref) => StrainScannerService());

/// Provider pro seznam odrůd z katalogu
final strainsProvider = FutureProvider<List<StrainModel>>((ref) async {
  return await ref.read(strainServiceProvider).getStrains();
});

/// Provider pro konkrétní odrůdu podle slug
final strainBySlugProvider =
    FutureProvider.family<StrainModel?, String>((ref, slug) async {
  return await ref.read(strainServiceProvider).getStrainBySlug(slug);
});

/// Stav skenování
enum ScanState {
  idle,
  pickingImage,
  uploading,
  analyzing,
  complete,
  error,
}

/// Model stavu skeneru
class ScannerState {
  final ScanState state;
  final XFile? selectedImage;
  final ScanResultModel? result;
  final String? errorMessage;
  final double progress;

  const ScannerState({
    this.state = ScanState.idle,
    this.selectedImage,
    this.result,
    this.errorMessage,
    this.progress = 0,
  });

  bool get isLoading =>
      state == ScanState.pickingImage ||
      state == ScanState.uploading ||
      state == ScanState.analyzing;

  bool get hasError => state == ScanState.error;

  bool get hasResult => state == ScanState.complete && result != null;

  ScannerState copyWith({
    ScanState? state,
    XFile? selectedImage,
    ScanResultModel? result,
    String? errorMessage,
    double? progress,
    bool clearImage = false,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ScannerState(
      state: state ?? this.state,
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      progress: progress ?? this.progress,
    );
  }
}

/// Notifier pro skener
class ScannerNotifier extends Notifier<ScannerState> {
  late StrainService _strainService;

  @override
  ScannerState build() {
    _strainService = ref.read(strainServiceProvider);
    return const ScannerState();
  }

  /// Vybere obrázek z galerie
  Future<void> pickFromGallery() async {
    state = state.copyWith(
      state: ScanState.pickingImage,
      clearError: true,
      clearResult: true,
    );

    try {
      final image = await _strainService.pickImageFromGallery();
      if (image != null) {
        state = state.copyWith(
          state: ScanState.idle,
          selectedImage: image,
        );
      } else {
        state = state.copyWith(state: ScanState.idle);
      }
    } catch (e) {
      state = state.copyWith(
        state: ScanState.error,
        errorMessage: 'Nepodařilo se vybrat obrázek: $e',
      );
    }
  }

  /// Vyfotí obrázek
  Future<void> takePhoto() async {
    state = state.copyWith(
      state: ScanState.pickingImage,
      clearError: true,
      clearResult: true,
    );

    try {
      final image = await _strainService.takePhoto();
      if (image != null) {
        state = state.copyWith(
          state: ScanState.idle,
          selectedImage: image,
        );
      } else {
        state = state.copyWith(state: ScanState.idle);
      }
    } catch (e) {
      state = state.copyWith(
        state: ScanState.error,
        errorMessage: 'Nepodařilo se vyfotit: $e',
      );
    }
  }

  /// Nastaví obrázek z XFile (pro camera scanner screen)
  Future<void> setImageFromFile(XFile file) async {
    state = state.copyWith(
      state: ScanState.idle,
      selectedImage: file,
      clearError: true,
      clearResult: true,
    );
  }

  /// Spustí skenování vybraného obrázku
  Future<void> scan() async {
    if (state.selectedImage == null) {
      state = state.copyWith(
        state: ScanState.error,
        errorMessage: 'Nejprve vyberte obrázek',
      );
      return;
    }

    state = state.copyWith(
      state: ScanState.uploading,
      progress: 0.2,
      clearError: true,
    );

    try {
      // Fáze 1: Nahrávání
      state = state.copyWith(progress: 0.4);

      // Fáze 2: AI analýza
      state = state.copyWith(
        state: ScanState.analyzing,
        progress: 0.6,
      );

      final result = await _strainService.scanImage(state.selectedImage!);

      state = state.copyWith(
        state: ScanState.complete,
        result: result,
        progress: 1.0,
      );

      // Invalidovat historii
      ref.invalidate(scanHistoryProvider);
    } on StrainScannerException catch (e) {
      state = state.copyWith(
        state: ScanState.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        state: ScanState.error,
        errorMessage: 'Chyba při skenování: $e',
      );
    }
  }

  /// Resetuje stav skeneru
  void reset() {
    state = const ScannerState();
  }

  /// Vyčistí pouze vybraný obrázek
  void clearImage() {
    state = state.copyWith(
      state: ScanState.idle,
      clearImage: true,
      clearResult: true,
    );
  }
}

/// Provider pro skener
final scannerProvider =
    NotifierProvider<ScannerNotifier, ScannerState>(() => ScannerNotifier());

/// Provider pro historii skenů
final scanHistoryProvider = FutureProvider<List<ScanResultModel>>((ref) async {
  return await ref.read(strainServiceProvider).getScanHistory();
});

/// Provider pro oblíbené skeny
final favoriteScanHistoryProvider =
    FutureProvider<List<ScanResultModel>>((ref) async {
  return await ref.read(strainServiceProvider).getScanHistory(favoritesOnly: true);
});

/// Provider pro konkrétní sken podle ID
final scanByIdProvider =
    FutureProvider.family<ScanResultModel?, String>((ref, id) async {
  return await ref.read(strainServiceProvider).getScanById(id);
});

/// Provider pro počet skenů
final scanCountProvider = FutureProvider<int>((ref) async {
  return await ref.read(strainServiceProvider).getScanCount();
});

/// Provider pro počet oblíbených
final favoriteScanCountProvider = FutureProvider<int>((ref) async {
  return await ref.read(strainServiceProvider).getFavoriteCount();
});

/// Notifier pro správu historie skenů (toggle favorite, delete)
class ScanHistoryNotifier extends Notifier<AsyncValue<List<ScanResultModel>>> {
  late StrainService _strainService;

  @override
  AsyncValue<List<ScanResultModel>> build() {
    _strainService = ref.read(strainServiceProvider);
    _loadHistory();
    return const AsyncValue.loading();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _strainService.getScanHistory();
      state = AsyncValue.data(history);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadHistory();
  }

  Future<void> toggleFavorite(String scanId) async {
    try {
      final updated = await _strainService.toggleFavorite(scanId);

      final currentList = state.value ?? [];
      final index = currentList.indexWhere((s) => s.id == scanId);
      if (index != -1) {
        final newList = [...currentList];
        newList[index] = updated;
        state = AsyncValue.data(newList);
      }

      // Invalidovat counts
      ref.invalidate(scanCountProvider);
      ref.invalidate(favoriteScanCountProvider);
    } catch (e) {
      // ignore: avoid_print
      print('[ScanHistory] Chyba při toggle favorite: $e');
    }
  }

  Future<void> deleteScan(String scanId) async {
    try {
      await _strainService.deleteScan(scanId);

      final currentList = state.value ?? [];
      state = AsyncValue.data(
        currentList.where((s) => s.id != scanId).toList(),
      );

      // Invalidovat counts
      ref.invalidate(scanCountProvider);
      ref.invalidate(favoriteScanCountProvider);
    } catch (e) {
      // ignore: avoid_print
      print('[ScanHistory] Chyba při mazání: $e');
    }
  }
}

/// Provider pro správu historie
final scanHistoryNotifierProvider = NotifierProvider<ScanHistoryNotifier,
    AsyncValue<List<ScanResultModel>>>(() => ScanHistoryNotifier());
