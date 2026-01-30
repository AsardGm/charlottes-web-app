enum NewsCategory {
  legislation,
  science,
  culture,
  industry,
}

extension NewsCategoryExt on NewsCategory {
  String get label {
    switch (this) {
      case NewsCategory.legislation: return '⚖️ Legislativa';
      case NewsCategory.science: return '🔬 Věda';
      case NewsCategory.culture: return '🎭 Kultura';
      case NewsCategory.industry: return '🏭 Industry';
    }
  }

  String get emoji {
    switch (this) {
      case NewsCategory.legislation: return '⚖️';
      case NewsCategory.science: return '🔬';
      case NewsCategory.culture: return '🎭';
      case NewsCategory.industry: return '🏭';
    }
  }
}

enum NewsRegion { cz, eu, world }

extension NewsRegionExt on NewsRegion {
  String get label {
    switch (this) {
      case NewsRegion.cz: return '🇨🇿 CZ';
      case NewsRegion.eu: return '🇪🇺 EU';
      case NewsRegion.world: return '🌍 World';
    }
  }
}

class NewsArticleModel {
  final String id;
  final String title;
  final String tldr;
  final String whyItMatters;
  final String content;
  final NewsCategory category;
  final NewsRegion region;
  final String source;
  final String? sourceUrl;
  final String? imageUrl;
  final DateTime publishedAt;
  final int readTimeMinutes;
  final int xpReward;
  final List<String> tags;
  final bool isVerified;
  final int views;
  final int saves;

  NewsArticleModel({
    required this.id,
    required this.title,
    required this.tldr,
    required this.whyItMatters,
    required this.content,
    required this.category,
    required this.region,
    required this.source,
    this.sourceUrl,
    this.imageUrl,
    required this.publishedAt,
    this.readTimeMinutes = 3,
    this.xpReward = 15,
    this.tags = const [],
    this.isVerified = true,
    this.views = 0,
    this.saves = 0,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(publishedAt);
    if (diff.inDays > 0) return 'před ${diff.inDays}d';
    if (diff.inHours > 0) return 'před ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'před ${diff.inMinutes}m';
    return 'teď';
  }
}