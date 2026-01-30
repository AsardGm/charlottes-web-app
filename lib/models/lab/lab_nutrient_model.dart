/// Model nutrient zaznamu (Alchymista)
class LabNutrientLogModel {
  final String id;
  final String growId;
  final String userId;
  final int dayNumber;
  final double? phValue;
  final double? ecValue;
  final double? ppmValue;
  final int? waterAmountMl;
  final double? temperature;
  final double? humidity;
  final List<NutrientEntry> nutrients;
  final String? notes;
  final DateTime createdAt;

  LabNutrientLogModel({
    required this.id,
    required this.growId,
    required this.userId,
    required this.dayNumber,
    this.phValue,
    this.ecValue,
    this.ppmValue,
    this.waterAmountMl,
    this.temperature,
    this.humidity,
    this.nutrients = const [],
    this.notes,
    required this.createdAt,
  });

  factory LabNutrientLogModel.fromJson(Map<String, dynamic> json) {
    List<NutrientEntry> nutrientsList = [];
    if (json['nutrients'] != null) {
      final nutrientsData = json['nutrients'];
      if (nutrientsData is List) {
        nutrientsList = nutrientsData
            .map((e) => NutrientEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    return LabNutrientLogModel(
      id: json['id'] as String,
      growId: json['grow_id'] as String,
      userId: json['user_id'] as String,
      dayNumber: json['day_number'] as int? ?? 1,
      phValue: (json['ph_value'] as num?)?.toDouble(),
      ecValue: (json['ec_value'] as num?)?.toDouble(),
      ppmValue: (json['ppm_value'] as num?)?.toDouble(),
      waterAmountMl: json['water_amount_ml'] as int?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      nutrients: nutrientsList,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grow_id': growId,
      'user_id': userId,
      'day_number': dayNumber,
      'ph_value': phValue,
      'ec_value': ecValue,
      'ppm_value': ppmValue,
      'water_amount_ml': waterAmountMl,
      'temperature': temperature,
      'humidity': humidity,
      'nutrients': nutrients.map((e) => e.toJson()).toList(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'grow_id': growId,
      'user_id': userId,
      'day_number': dayNumber,
      'ph_value': phValue,
      'ec_value': ecValue,
      'ppm_value': ppmValue,
      'water_amount_ml': waterAmountMl,
      'temperature': temperature,
      'humidity': humidity,
      'nutrients': nutrients.map((e) => e.toJson()).toList(),
      'notes': notes,
    };
  }

  LabNutrientLogModel copyWith({
    String? id,
    String? growId,
    String? userId,
    int? dayNumber,
    double? phValue,
    double? ecValue,
    double? ppmValue,
    int? waterAmountMl,
    double? temperature,
    double? humidity,
    List<NutrientEntry>? nutrients,
    String? notes,
    DateTime? createdAt,
  }) {
    return LabNutrientLogModel(
      id: id ?? this.id,
      growId: growId ?? this.growId,
      userId: userId ?? this.userId,
      dayNumber: dayNumber ?? this.dayNumber,
      phValue: phValue ?? this.phValue,
      ecValue: ecValue ?? this.ecValue,
      ppmValue: ppmValue ?? this.ppmValue,
      waterAmountMl: waterAmountMl ?? this.waterAmountMl,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      nutrients: nutrients ?? this.nutrients,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Jednotlivy nutrient zaznam
class NutrientEntry {
  final String name;
  final double mlPerLiter;
  final String? brand;

  NutrientEntry({
    required this.name,
    required this.mlPerLiter,
    this.brand,
  });

  factory NutrientEntry.fromJson(Map<String, dynamic> json) {
    return NutrientEntry(
      name: json['name'] as String,
      mlPerLiter: (json['ml_per_l'] as num?)?.toDouble() ?? 0,
      brand: json['brand'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ml_per_l': mlPerLiter,
      if (brand != null) 'brand': brand,
    };
  }
}

/// Model feeding schedule (prednastaveny recept)
class FeedingScheduleModel {
  final String id;
  final String? userId;
  final String name;
  final String? description;
  final String? brand;
  final bool isPublic;
  final bool isSystem;
  final Map<String, dynamic> scheduleData;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FeedingScheduleModel({
    required this.id,
    this.userId,
    required this.name,
    this.description,
    this.brand,
    this.isPublic = false,
    this.isSystem = false,
    required this.scheduleData,
    required this.createdAt,
    this.updatedAt,
  });

  /// Ziska tydny z schedule_data
  List<Map<String, dynamic>> get weeks {
    final weeksList = scheduleData['weeks'];
    if (weeksList is List) {
      return weeksList.cast<Map<String, dynamic>>();
    }
    return [];
  }

  factory FeedingScheduleModel.fromJson(Map<String, dynamic> json) {
    return FeedingScheduleModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      brand: json['brand'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      isSystem: json['is_system'] as bool? ?? false,
      scheduleData: json['schedule_data'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'brand': brand,
      'is_public': isPublic,
      'is_system': isSystem,
      'schedule_data': scheduleData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'name': name,
      'description': description,
      'brand': brand,
      'is_public': isPublic,
      'schedule_data': scheduleData,
    };
  }

  FeedingScheduleModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? brand,
    bool? isPublic,
    bool? isSystem,
    Map<String, dynamic>? scheduleData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeedingScheduleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      isPublic: isPublic ?? this.isPublic,
      isSystem: isSystem ?? this.isSystem,
      scheduleData: scheduleData ?? this.scheduleData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
