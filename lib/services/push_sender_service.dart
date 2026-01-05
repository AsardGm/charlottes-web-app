import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sluzba pro odesilani push notifikaci z aplikace
///
/// Vola Edge Function send-push pro odeslani notifikace konkretnimu uzivateli.
class PushSenderService {
  static final PushSenderService _instance = PushSenderService._internal();
  static PushSenderService get instance => _instance;

  PushSenderService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;


  /// Odesle push notifikaci uzivateli
  ///
  /// [userId] - ID prijemce
  /// [type] - Typ notifikace (like, comment, follow, chat, post)
  /// [actorName] - Jmeno aktora (kdo akci provedl)
  /// [postTitle] - Titulek/obsah prispevku (volitelne)
  /// [messagePreview] - Nahled zpravy (volitelne)
  /// [data] - Extra data (post_id, conversation_id, atd.)
  Future<void> sendNotification({
    required String userId,
    required String type,
    String? actorName,
    String? postTitle,
    String? messagePreview,
    Map<String, String>? data,
  }) async {
    // Neposilej notifikaci sam sobe
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null || currentUserId == userId) {
      return;
    }

    try {
      final payload = <String, dynamic>{
        'user_id': userId,
        'type': type,
      };

      if (actorName != null) {
        payload['actor_name'] = actorName;
      }

      if (postTitle != null) {
        payload['post_title'] = postTitle;
      }

      if (messagePreview != null) {
        payload['message_preview'] = messagePreview;
      }

      if (data != null && data.isNotEmpty) {
        payload['data'] = data;
      }

      // Volej Edge Function pres Supabase SDK (automaticky prida JWT)
      final response = await _supabase.functions.invoke(
        'send-push',
        body: payload,
      );

      // Detailni log payload pro DevTools
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('[PushSender] Sending notification:');
      debugPrint('  Type: $type');
      debugPrint('  To user: $userId');
      if (actorName != null) debugPrint('  Actor: $actorName');
      if (postTitle != null) debugPrint('  Post: $postTitle');
      if (messagePreview != null) debugPrint('  Message: $messagePreview');
      if (data != null) debugPrint('  Data: $data');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (response.status == 200 || response.status == 201) {
        debugPrint('[PushSender] ✅ Notification sent successfully');
        debugPrint('[PushSender] Response: ${response.data}');
      } else {
        debugPrint(
            '[PushSender] ❌ Failed: ${response.status} ${response.data}');
      }
    } catch (e) {
      // Neblokuj operaci pokud push selze
      debugPrint('[PushSender] Failed to send notification: $e');
    }
  }

  /// Odesle notifikaci o novem liku
  Future<void> sendLikeNotification({
    required String postAuthorId,
    required String postId,
    required String postContent,
  }) async {
    final actorName = await _getCurrentUserName();

    await sendNotification(
      userId: postAuthorId,
      type: 'like',
      actorName: actorName,
      postTitle: _truncate(postContent, 100),
      data: {
        'post_id': postId,
        'actor_id': _supabase.auth.currentUser!.id,
      },
    );
  }

  /// Odesle notifikaci o novem komentari
  Future<void> sendCommentNotification({
    required String postAuthorId,
    required String postId,
    required String postContent,
    required String commentContent,
    required String commentId,
  }) async {
    final actorName = await _getCurrentUserName();

    await sendNotification(
      userId: postAuthorId,
      type: 'comment',
      actorName: actorName,
      postTitle: _truncate(postContent, 100),
      messagePreview: _truncate(commentContent, 100),
      data: {
        'post_id': postId,
        'comment_id': commentId,
        'actor_id': _supabase.auth.currentUser!.id,
      },
    );
  }

  /// Odesle notifikaci o novem sledujicim
  Future<void> sendFollowNotification({
    required String followedUserId,
  }) async {
    final actorName = await _getCurrentUserName();

    await sendNotification(
      userId: followedUserId,
      type: 'follow',
      actorName: actorName,
      data: {
        'actor_id': _supabase.auth.currentUser!.id,
      },
    );
  }

  /// Odesle notifikaci o nove zprave
  Future<void> sendChatNotification({
    required String recipientId,
    required String conversationId,
    required String messageContent,
  }) async {
    final actorName = await _getCurrentUserName();

    await sendNotification(
      userId: recipientId,
      type: 'chat',
      actorName: actorName,
      messagePreview: _truncate(messageContent, 100),
      data: {
        'conversation_id': conversationId,
        'actor_id': _supabase.auth.currentUser!.id,
      },
    );
  }

  /// Odesle notifikaci o novem prispevku sledujicim
  Future<void> sendPostNotification({
    required String followerId,
    required String postId,
    required String postContent,
  }) async {
    final actorName = await _getCurrentUserName();

    await sendNotification(
      userId: followerId,
      type: 'post',
      actorName: actorName,
      postTitle: _truncate(postContent, 100),
      data: {
        'post_id': postId,
        'actor_id': _supabase.auth.currentUser!.id,
      },
    );
  }

  /// Ziska jmeno aktualniho uzivatele z profilu
  Future<String> _getCurrentUserName() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 'Uzivatel';

    try {
      final response = await _supabase
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return 'Uzivatel';

      final username = response['username'] as String?;

      return username ?? 'Uzivatel';
    } catch (e) {
      debugPrint('[PushSender] Error getting user name: $e');
      return 'Uzivatel';
    }
  }

  /// Zkrati text na max delku
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}
