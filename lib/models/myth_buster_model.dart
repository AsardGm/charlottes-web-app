/// Model pro Genetic Myth Buster - edukační quiz
class CannabisMyth {
  final String id;
  final String mythStatement;
  final bool isTrue; // true = skutečně pravda, false = mýtus
  final String reality;
  final String explanation;
  final MythCategory category;
  final int xpReward;

  const CannabisMyth({
    required this.id,
    required this.mythStatement,
    required this.isTrue,
    required this.reality,
    required this.explanation,
    required this.category,
    this.xpReward = 10,
  });
}

enum MythCategory {
  genetics, // Indica/Sativa mýty
  compounds, // THC/CBD/terpeny
  effects, // Účinky
  consumption, // Metody užití
}

extension MythCategoryExtension on MythCategory {
  String get label {
    switch (this) {
      case MythCategory.genetics:
        return 'GENETIKA';
      case MythCategory.compounds:
        return 'SLOŽENÍ';
      case MythCategory.effects:
        return 'ÚČINKY';
      case MythCategory.consumption:
        return 'KONZUMACE';
    }
  }

  String get emoji {
    switch (this) {
      case MythCategory.genetics:
        return '🧬';
      case MythCategory.compounds:
        return '⚗️';
      case MythCategory.effects:
        return '🧠';
      case MythCategory.consumption:
        return '💨';
    }
  }
}
