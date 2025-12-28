import 'package:flutter/material.dart';

class ThreadTypeModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String icon;
  final String color;
  final List<String> allowedRoles;
  final bool canBeResolved;
  final bool hasDeadline;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  const ThreadTypeModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.icon,
    required this.color,
    required this.allowedRoles,
    required this.canBeResolved,
    required this.hasDeadline,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
  });

  factory ThreadTypeModel.fromJson(Map<String, dynamic> json) {
    return ThreadTypeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String,
      color: json['color'] as String,
      allowedRoles: (json['allowed_roles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          ['member', 'core', 'admin'],
      canBeResolved: json['can_be_resolved'] as bool? ?? false,
      hasDeadline: json['has_deadline'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
      'color': color,
      'allowed_roles': allowedRoles,
      'can_be_resolved': canBeResolved,
      'has_deadline': hasDeadline,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Color get colorValue {
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF8B5CF6);
    }
  }

  IconData get iconData {
    switch (icon) {
      case 'forum':
        return Icons.forum_rounded;
      case 'help':
        return Icons.help_rounded;
      case 'build':
        return Icons.build_rounded;
      case 'lightbulb':
        return Icons.lightbulb_rounded;
      case 'campaign':
        return Icons.campaign_rounded;
      case 'question_answer':
        return Icons.question_answer_rounded;
      case 'announcement':
        return Icons.announcement_rounded;
      default:
        return Icons.tag_rounded;
    }
  }

  /// Emoji ikona pro zobrazení v UI
  String get emoji {
    switch (slug) {
      case 'discussion':
        return '🧵';
      case 'question':
        return '❓';
      case 'case':
        return '🛠';
      case 'proposal':
        return '🚀';
      case 'announcement':
        return '📢';
      default:
        return '💬';
    }
  }

  /// Zkontroluje zda daná role může vytvořit tento typ vlákna
  bool canRoleCreate(String role) {
    return allowedRoles.contains(role);
  }
}

/// Stav vlákna/příspěvku
enum ThreadStatus {
  open('open', 'Otevřeno', Icons.radio_button_unchecked, Color(0xFF22C55E)),
  resolved('resolved', 'Vyřešeno', Icons.check_circle, Color(0xFF3B82F6)),
  locked('locked', 'Zamčeno', Icons.lock, Color(0xFF6B7280));

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const ThreadStatus(this.value, this.label, this.icon, this.color);

  static ThreadStatus fromString(String value) {
    return ThreadStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ThreadStatus.open,
    );
  }
}
