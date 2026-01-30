import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wiki_article_model.dart';
import '../data/wiki_data.dart';

/// Vsechny wiki clanky
final wikiArticlesProvider = Provider<List<WikiArticleModel>>((ref) {
  return kWikiArticles;
});

/// Stav wiki filtru (search + kategorie)
class WikiFilterState {
  final String query;
  final WikiCategory? category;

  const WikiFilterState({this.query = '', this.category});

  WikiFilterState copyWith({String? query, WikiCategory? Function()? category}) {
    return WikiFilterState(
      query: query ?? this.query,
      category: category != null ? category() : this.category,
    );
  }
}

class WikiFilterNotifier extends Notifier<WikiFilterState> {
  @override
  WikiFilterState build() => const WikiFilterState();

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setCategory(WikiCategory? category) {
    state = state.copyWith(category: () => category);
  }

  void clear() {
    state = const WikiFilterState();
  }
}

final wikiFilterProvider =
    NotifierProvider<WikiFilterNotifier, WikiFilterState>(
  WikiFilterNotifier.new,
);

/// Filtrovane clanky podle search + kategorie
final wikiFilteredArticlesProvider = Provider<List<WikiArticleModel>>((ref) {
  final articles = ref.watch(wikiArticlesProvider);
  final filter = ref.watch(wikiFilterProvider);
  final query = filter.query.toLowerCase();
  final category = filter.category;

  var filtered = articles;

  if (category != null) {
    filtered = filtered.where((a) => a.category == category).toList();
  }

  if (query.isNotEmpty) {
    filtered = filtered.where((a) {
      return a.title.toLowerCase().contains(query) ||
          a.summary.toLowerCase().contains(query) ||
          a.tags.any((t) => t.contains(query));
    }).toList();
  }

  return filtered;
});

/// Clanek podle slug
final wikiArticleBySlugProvider =
    Provider.family<WikiArticleModel?, String>((ref, slug) {
  final articles = ref.watch(wikiArticlesProvider);
  try {
    return articles.firstWhere((a) => a.slug == slug);
  } catch (_) {
    return null;
  }
});

/// Souvisejici clanky
final wikiRelatedArticlesProvider =
    Provider.family<List<WikiArticleModel>, String>((ref, slug) {
  final article = ref.watch(wikiArticleBySlugProvider(slug));
  if (article == null) return [];
  final articles = ref.watch(wikiArticlesProvider);
  return articles.where((a) => article.relatedSlugs.contains(a.slug)).toList();
});
