import 'package:flutter/material.dart';

/// Rarita karty
enum CardRarity {
  common,
  rare,
  exotic,
  legend,
}

/// Rozsireni pro CardRarity
extension CardRarityExtension on CardRarity {
  String get name {
    switch (this) {
      case CardRarity.common:
        return 'Common';
      case CardRarity.rare:
        return 'Rare';
      case CardRarity.exotic:
        return 'Exotic';
      case CardRarity.legend:
        return 'Legend';
    }
  }

  String get nameCz {
    switch (this) {
      case CardRarity.common:
        return 'Bezna';
      case CardRarity.rare:
        return 'Vzacna';
      case CardRarity.exotic:
        return 'Exoticka';
      case CardRarity.legend:
        return 'Legendární';
    }
  }

  Color get color {
    switch (this) {
      case CardRarity.common:
        return const Color(0xFF9E9E9E);
      case CardRarity.rare:
        return const Color(0xFF2196F3);
      case CardRarity.exotic:
        return const Color(0xFF9C27B0);
      case CardRarity.legend:
        return const Color(0xFFFFD700);
    }
  }

  Color get glowColor {
    switch (this) {
      case CardRarity.common:
        return const Color(0xFF9E9E9E).withAlpha(100);
      case CardRarity.rare:
        return const Color(0xFF2196F3).withAlpha(150);
      case CardRarity.exotic:
        return const Color(0xFF9C27B0).withAlpha(150);
      case CardRarity.legend:
        return const Color(0xFFFFD700).withAlpha(200);
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case CardRarity.common:
        return [const Color(0xFF424242), const Color(0xFF616161)];
      case CardRarity.rare:
        return [const Color(0xFF1565C0), const Color(0xFF42A5F5)];
      case CardRarity.exotic:
        return [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)];
      case CardRarity.legend:
        return [const Color(0xFFFF8F00), const Color(0xFFFFD54F)];
    }
  }

  int get xpValue {
    switch (this) {
      case CardRarity.common:
        return 10;
      case CardRarity.rare:
        return 25;
      case CardRarity.exotic:
        return 50;
      case CardRarity.legend:
        return 100;
    }
  }
}

/// Model pro Strain Card
class StrainCard {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final CardRarity rarity;
  final StrainType type;
  final int thcPercent;
  final int cbdPercent;
  final List<String> effects;
  final List<String> flavors;
  final String? origin;
  final DateTime releasedAt;
  final int totalCards; // Kolik existuje v obehu
  final int? cardNumber; // Cislo teto konkretni karty

  const StrainCard({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.rarity,
    required this.type,
    required this.thcPercent,
    required this.cbdPercent,
    required this.effects,
    required this.flavors,
    this.origin,
    required this.releasedAt,
    this.totalCards = 0,
    this.cardNumber,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'rarity': rarity.name,
        'type': type.name,
        'thc_percent': thcPercent,
        'cbd_percent': cbdPercent,
        'effects': effects,
        'flavors': flavors,
        'origin': origin,
        'released_at': releasedAt.toIso8601String(),
        'total_cards': totalCards,
        'card_number': cardNumber,
      };

  factory StrainCard.fromJson(Map<String, dynamic> json) {
    return StrainCard(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      rarity: CardRarity.values.firstWhere(
        (r) => r.name == json['rarity'],
        orElse: () => CardRarity.common,
      ),
      type: StrainType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => StrainType.hybrid,
      ),
      thcPercent: json['thc_percent'] as int? ?? 0,
      cbdPercent: json['cbd_percent'] as int? ?? 0,
      effects: List<String>.from(json['effects'] ?? []),
      flavors: List<String>.from(json['flavors'] ?? []),
      origin: json['origin'] as String?,
      releasedAt: DateTime.parse(json['released_at'] as String),
      totalCards: json['total_cards'] as int? ?? 0,
      cardNumber: json['card_number'] as int?,
    );
  }
}

/// Typ strainu
enum StrainType {
  indica,
  sativa,
  hybrid,
}

extension StrainTypeExtension on StrainType {
  String get name {
    switch (this) {
      case StrainType.indica:
        return 'indica';
      case StrainType.sativa:
        return 'sativa';
      case StrainType.hybrid:
        return 'hybrid';
    }
  }

  String get displayName {
    switch (this) {
      case StrainType.indica:
        return 'Indica';
      case StrainType.sativa:
        return 'Sativa';
      case StrainType.hybrid:
        return 'Hybrid';
    }
  }

  Color get color {
    switch (this) {
      case StrainType.indica:
        return const Color(0xFF7B1FA2);
      case StrainType.sativa:
        return const Color(0xFFFF9800);
      case StrainType.hybrid:
        return const Color(0xFF4CAF50);
    }
  }
}

/// Model pro sbírku karet uživatele
class UserCardCollection {
  final String oderId;
  final String oderId2;
  final String cardId;
  final DateTime collectedAt;
  final int? cardNumber;
  final bool isFavorite;

  const UserCardCollection({
    required this.oderId,
    required this.oderId2,
    required this.cardId,
    required this.collectedAt,
    this.cardNumber,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
        'user_id': oderId,
        'card_id': cardId,
        'collected_at': collectedAt.toIso8601String(),
        'card_number': cardNumber,
        'is_favorite': isFavorite,
      };

  factory UserCardCollection.fromJson(Map<String, dynamic> json) {
    return UserCardCollection(
      oderId: json['user_id'] as String,
      oderId2: json['user_id'] as String,
      cardId: json['card_id'] as String,
      collectedAt: DateTime.parse(json['collected_at'] as String),
      cardNumber: json['card_number'] as int?,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }
}
