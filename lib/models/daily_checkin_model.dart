enum BodyState { ok, anxious, heavy, clear }

extension BodyStateExtension on BodyState {
  String get label {
    switch (this) {
      case BodyState.ok: return 'OK';
      case BodyState.anxious: return 'Anxious';
      case BodyState.heavy: return 'Heavy';
      case BodyState.clear: return 'Clear';
    }
  }

  String get emoji {
    switch (this) {
      case BodyState.ok: return '👍';
      case BodyState.anxious: return '😰';
      case BodyState.heavy: return '😮‍💨';
      case BodyState.clear: return '✨';
    }
  }

  static BodyState fromString(String value) {
    return BodyState.values.firstWhere((e) => e.name == value, orElse: () => BodyState.ok);
  }
}

class DailyCheckin {
  final String? id;
  final String userId;
  final int mood;
  final int energy;
  final int focus;
  final BodyState bodyState;
  final bool? plantContact;
  final String? strainId;
  final String? notes;
  final String? insight;
  final DateTime createdAt;

  DailyCheckin({
    this.id,
    required this.userId,
    required this.mood,
    required this.energy,
    required this.focus,
    required this.bodyState,
    this.plantContact,
    this.strainId,
    this.notes,
    this.insight,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory DailyCheckin.fromJson(Map<String, dynamic> json) {
    return DailyCheckin(
      id: json['id'],
      userId: json['user_id'],
      mood: json['mood'],
      energy: json['energy'],
      focus: json['focus'],
      bodyState: BodyStateExtension.fromString(json['body_state']),
      plantContact: json['plant_contact'],
      strainId: json['strain_id'],
      notes: json['notes'],
      insight: json['insight'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'mood': mood,
      'energy': energy,
      'focus': focus,
      'body_state': bodyState.name,
      'plant_contact': plantContact,
      'strain_id': strainId,
      'notes': notes,
      'insight': insight,
      'created_at': createdAt.toIso8601String(),
    };
  }

  DailyCheckin copyWith({
    String? id,
    String? userId,
    int? mood,
    int? energy,
    int? focus,
    BodyState? bodyState,
    bool? plantContact,
    String? strainId,
    String? notes,
    String? insight,
    DateTime? createdAt,
  }) {
    return DailyCheckin(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      focus: focus ?? this.focus,
      bodyState: bodyState ?? this.bodyState,
      plantContact: plantContact ?? this.plantContact,
      strainId: strainId ?? this.strainId,
      notes: notes ?? this.notes,
      insight: insight ?? this.insight,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
