import 'package:share_plus/share_plus.dart';
import '../models/post_model.dart';
import '../utils/haptic_utils.dart';

/// Service pro sdílení obsahu
///
/// Poskytuje nativní sdílení na mobilních platformách
/// a web share API na webu.
class ShareService {
  ShareService._();

  /// Sdílí příspěvek
  static Future<void> sharePost(PostModel post, {String? baseUrl}) async {
    HapticUtils.lightImpact();

    final url = baseUrl ?? 'https://budsandbuddies.app';
    final postUrl = '$url/post/${post.id}';

    final text = '''
${post.author?.username ?? 'Uzivatel'} napsal na Buds and Buddies:

"${_truncateText(post.content, 200)}"

$postUrl
''';

    await _share(text: text, subject: 'Prispevek z Buds and Buddies');
  }

  /// Sdílí profil uživatele
  static Future<void> shareProfile({
    required String username,
    required String userId,
    String? bio,
    String? baseUrl,
  }) async {
    HapticUtils.lightImpact();

    final url = baseUrl ?? 'https://budsandbuddies.app';
    final profileUrl = '$url/profile/$userId';

    final text = '''
Podivej se na profil uzivatele @$username na Buds and Buddies!

${bio != null ? '"$bio"\n\n' : ''}$profileUrl
''';

    await _share(text: text, subject: 'Profil @$username');
  }

  /// Sdílí odkaz na aplikaci
  static Future<void> shareApp({String? baseUrl}) async {
    HapticUtils.lightImpact();

    final url = baseUrl ?? 'https://budsandbuddies.app';

    const text = '''
Pripoj se ke komunite Buds and Buddies! 🌿

Sdilej zkusenosti, ziskavej odznaky a poznávej dalsi pratele.
''';

    await _share(text: '$text\n$url', subject: 'Buds and Buddies - Komunita');
  }

  /// Sdílí text s URL
  static Future<void> shareText({
    required String text,
    String? subject,
    String? url,
  }) async {
    HapticUtils.lightImpact();

    final shareText = url != null ? '$text\n\n$url' : text;
    await _share(text: shareText, subject: subject);
  }

  /// Interní metoda pro sdílení
  static Future<void> _share({
    required String text,
    String? subject,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
      ),
    );
  }

  /// Zkrátí text na maximální délku
  static String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
