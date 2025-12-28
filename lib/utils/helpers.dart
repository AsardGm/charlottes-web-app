import 'package:timeago/timeago.dart' as timeago;

class Helpers {
  static String formatTimeAgo(DateTime dateTime) {
    return timeago.format(dateTime, locale: 'cs');
  }

  static String formatDate(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
  }

  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
