class UserSettingsModel {
  final String id;
  final String userId;
  final String theme;
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool showOnlineStatus;
  final String allowMessagesFrom;
  final String language;
  final DateTime updatedAt;

  UserSettingsModel({
    required this.id,
    required this.userId,
    this.theme = 'dark',
    this.notificationsEnabled = true,
    this.emailNotifications = false,
    this.showOnlineStatus = true,
    this.allowMessagesFrom = 'everyone',
    this.language = 'cs',
    required this.updatedAt,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      theme: json['theme'] as String? ?? 'dark',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      emailNotifications: json['email_notifications'] as bool? ?? false,
      showOnlineStatus: json['show_online_status'] as bool? ?? true,
      allowMessagesFrom: json['allow_messages_from'] as String? ?? 'everyone',
      language: json['language'] as String? ?? 'cs',
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'theme': theme,
      'notifications_enabled': notificationsEnabled,
      'email_notifications': emailNotifications,
      'show_online_status': showOnlineStatus,
      'allow_messages_from': allowMessagesFrom,
      'language': language,
    };
  }

  UserSettingsModel copyWith({
    String? theme,
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? showOnlineStatus,
    String? allowMessagesFrom,
    String? language,
  }) {
    return UserSettingsModel(
      id: id,
      userId: userId,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowMessagesFrom: allowMessagesFrom ?? this.allowMessagesFrom,
      language: language ?? this.language,
      updatedAt: DateTime.now(),
    );
  }
}
