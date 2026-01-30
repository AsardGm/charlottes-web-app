/// Typ udalosti na timeline
enum TimelineEventType {
  note,
  photo,
  phaseChange,
  milestone,
  water,
  feed,
  transplant,
  training,
  issue,
  harvest;

  String get label {
    switch (this) {
      case TimelineEventType.note:
        return 'Poznamka';
      case TimelineEventType.photo:
        return 'Fotka';
      case TimelineEventType.phaseChange:
        return 'Zmena faze';
      case TimelineEventType.milestone:
        return 'Milnik';
      case TimelineEventType.water:
        return 'Zalevani';
      case TimelineEventType.feed:
        return 'Hnojeni';
      case TimelineEventType.transplant:
        return 'Presazeni';
      case TimelineEventType.training:
        return 'Training';
      case TimelineEventType.issue:
        return 'Problem';
      case TimelineEventType.harvest:
        return 'Sklizen';
    }
  }

  String get icon {
    switch (this) {
      case TimelineEventType.note:
        return '📝';
      case TimelineEventType.photo:
        return '📸';
      case TimelineEventType.phaseChange:
        return '🔄';
      case TimelineEventType.milestone:
        return '⭐';
      case TimelineEventType.water:
        return '💧';
      case TimelineEventType.feed:
        return '🧪';
      case TimelineEventType.transplant:
        return '🪴';
      case TimelineEventType.training:
        return '✂️';
      case TimelineEventType.issue:
        return '⚠️';
      case TimelineEventType.harvest:
        return '🎉';
    }
  }

  /// Prevod z DB snake_case na enum
  static TimelineEventType fromString(String value) {
    switch (value) {
      case 'phase_change':
        return TimelineEventType.phaseChange;
      default:
        return TimelineEventType.values.firstWhere(
          (e) => e.name == value,
          orElse: () => TimelineEventType.note,
        );
    }
  }

  /// Prevod na DB snake_case
  String toDbString() {
    switch (this) {
      case TimelineEventType.phaseChange:
        return 'phase_change';
      default:
        return name;
    }
  }
}

/// Typ milniku
enum MilestoneType {
  firstLeaves,
  firstPistils,
  trichomeCloudy,
  trichomeAmber,
  harvestReady,
  custom;

  String get label {
    switch (this) {
      case MilestoneType.firstLeaves:
        return 'Prvni prave listy';
      case MilestoneType.firstPistils:
        return 'Prvni pistily';
      case MilestoneType.trichomeCloudy:
        return 'Trichomy mlecne';
      case MilestoneType.trichomeAmber:
        return 'Trichomy jantarove';
      case MilestoneType.harvestReady:
        return 'Pripraveno ke sklizni';
      case MilestoneType.custom:
        return 'Vlastni milnik';
    }
  }

  static MilestoneType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'first_leaves':
        return MilestoneType.firstLeaves;
      case 'first_pistils':
        return MilestoneType.firstPistils;
      case 'trichome_cloudy':
        return MilestoneType.trichomeCloudy;
      case 'trichome_amber':
        return MilestoneType.trichomeAmber;
      case 'harvest_ready':
        return MilestoneType.harvestReady;
      case 'custom':
        return MilestoneType.custom;
      default:
        return null;
    }
  }

  String toDbString() {
    switch (this) {
      case MilestoneType.firstLeaves:
        return 'first_leaves';
      case MilestoneType.firstPistils:
        return 'first_pistils';
      case MilestoneType.trichomeCloudy:
        return 'trichome_cloudy';
      case MilestoneType.trichomeAmber:
        return 'trichome_amber';
      case MilestoneType.harvestReady:
        return 'harvest_ready';
      case MilestoneType.custom:
        return 'custom';
    }
  }
}

/// Model timeline zaznamu
class LabTimelineEntryModel {
  final String id;
  final String growId;
  final String userId;
  final int dayNumber;
  final TimelineEventType eventType;
  final MilestoneType? milestoneType;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? phaseAtTime;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  LabTimelineEntryModel({
    required this.id,
    required this.growId,
    required this.userId,
    required this.dayNumber,
    this.eventType = TimelineEventType.note,
    this.milestoneType,
    this.title,
    this.description,
    this.imageUrl,
    this.phaseAtTime,
    this.metadata,
    required this.createdAt,
  });

  factory LabTimelineEntryModel.fromJson(Map<String, dynamic> json) {
    return LabTimelineEntryModel(
      id: json['id'] as String,
      growId: json['grow_id'] as String,
      userId: json['user_id'] as String,
      dayNumber: json['day_number'] as int? ?? 1,
      eventType: TimelineEventType.fromString(json['event_type'] as String? ?? 'note'),
      milestoneType: MilestoneType.fromString(json['milestone_type'] as String?),
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      phaseAtTime: json['phase_at_time'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grow_id': growId,
      'user_id': userId,
      'day_number': dayNumber,
      'event_type': eventType.toDbString(),
      'milestone_type': milestoneType?.toDbString(),
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'phase_at_time': phaseAtTime,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'grow_id': growId,
      'user_id': userId,
      'day_number': dayNumber,
      'event_type': eventType.toDbString(),
      'milestone_type': milestoneType?.toDbString(),
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'phase_at_time': phaseAtTime,
      'metadata': metadata,
    };
  }

  LabTimelineEntryModel copyWith({
    String? id,
    String? growId,
    String? userId,
    int? dayNumber,
    TimelineEventType? eventType,
    MilestoneType? milestoneType,
    String? title,
    String? description,
    String? imageUrl,
    String? phaseAtTime,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return LabTimelineEntryModel(
      id: id ?? this.id,
      growId: growId ?? this.growId,
      userId: userId ?? this.userId,
      dayNumber: dayNumber ?? this.dayNumber,
      eventType: eventType ?? this.eventType,
      milestoneType: milestoneType ?? this.milestoneType,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      phaseAtTime: phaseAtTime ?? this.phaseAtTime,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
