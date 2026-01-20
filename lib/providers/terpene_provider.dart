import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/terpene_model.dart';
import '../services/terpene_service.dart';

/// Provider pro TerpeneService
final terpeneServiceProvider = Provider<TerpeneService>((ref) => TerpeneService());

/// Provider pro seznam všech terpenů
final terpenesProvider = FutureProvider<List<TerpeneModel>>((ref) async {
  return await ref.read(terpeneServiceProvider).getTerpenes();
});

/// Provider pro konkrétní terpen podle slug
final terpeneBySlugProvider =
    FutureProvider.family<TerpeneModel?, String>((ref, slug) async {
  return await ref.read(terpeneServiceProvider).getTerpeneBySlug(slug);
});

/// Provider pro zkušenosti k terpenu
final terpeneExperiencesProvider =
    FutureProvider.family<List<TerpeneExperienceModel>, String>((ref, terpeneId) async {
  return await ref.read(terpeneServiceProvider).getExperiences(terpeneId);
});

/// Provider pro průměrné hodnocení terpenu
final terpeneRatingProvider =
    FutureProvider.family<double, String>((ref, terpeneId) async {
  return await ref.read(terpeneServiceProvider).getAverageRating(terpeneId);
});

/// Provider pro počet zkušeností
final terpeneExperienceCountProvider =
    FutureProvider.family<int, String>((ref, terpeneId) async {
  return await ref.read(terpeneServiceProvider).getExperienceCount(terpeneId);
});

/// Notifier pro vybraný terpen v brain map
class SelectedTerpeneNotifier extends Notifier<TerpeneModel?> {
  @override
  TerpeneModel? build() => null;

  void select(TerpeneModel? terpene) {
    state = terpene;
  }

  void clear() {
    state = null;
  }
}

/// Provider pro vybraný terpen v brain map
final selectedTerpeneProvider =
    NotifierProvider<SelectedTerpeneNotifier, TerpeneModel?>(() {
  return SelectedTerpeneNotifier();
});
