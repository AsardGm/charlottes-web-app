class AppConstants {
  static const String appName = "Buds and Buddies";

  // User roles
  static const String roleMember = 'member';
  static const String roleAdmin = 'admin';

  // Reaction types
  static const List<String> reactionTypes = [
    'like',
    'love',
    'laugh',
    'wow',
    'sad',
    'angry',
  ];

  // Reaction emojis
  static const Map<String, String> reactionEmojis = {
    'like': '👍',
    'love': '❤️',
    'laugh': '😂',
    'wow': '😮',
    'sad': '😢',
    'angry': '😠',
  };
}
