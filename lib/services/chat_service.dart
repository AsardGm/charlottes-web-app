import 'dart:async';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation_model.dart';
import '../models/poll_model.dart';
import '../models/user_model.dart';
import 'encryption_service.dart';
import 'push_sender_service.dart';
import 'block_service.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EncryptionService _encryption = EncryptionService();
  final PushSenderService _pushSender = PushSenderService.instance;
  final BlockService _blockService = BlockService();

  // Cache pro session klíče konverzací
  final Map<String, SecretKey> _sessionKeys = {};

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ============================================
  // KLÍČE
  // ============================================

  /// Inicializuje klíče uživatele (volat při registraci/prvním přihlášení)
  Future<void> initializeUserKeys() async {
    final hasKeys = await _encryption.hasKeys();
    if (hasKeys) return;

    // Vygeneruj klíče
    final identityKey = await _encryption.generateIdentityKeyPair();
    final signedPrekey = await _encryption.generateSignedPrekey();
    final oneTimePrekeys = await _encryption.generateOneTimePrekeys(10);

    // Podepíši signed prekey pomocí identity klíče (Ed25519)
    final signedPrekeySignature = await _encryption.signData(
      Uint8List.fromList(signedPrekey.publicKey),
    );

    // Získej signing public key pro ověření
    final signingPublicKey = await _encryption.getSigningPublicKey();

    // Ulož veřejné klíče do databáze
    await _supabase.from('user_keys').upsert({
      'user_id': currentUserId,
      'identity_public_key': identityKey.publicKeyBase64,
      'signing_public_key': signingPublicKey,
      'signed_prekey_public': signedPrekey.publicKeyBase64,
      'signed_prekey_signature': signedPrekeySignature,
      'one_time_prekeys':
          oneTimePrekeys.map((k) => base64Encode(k)).toList(),
    });
  }

  /// Získá veřejné klíče uživatele
  Future<UserPublicKeys?> getUserPublicKeys(String userId) async {
    final response = await _supabase
        .from('user_keys')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserPublicKeys.fromJson(response);
  }

  // ============================================
  // KONVERZACE
  // ============================================

  /// Získá všechny konverzace uživatele
  Future<List<ConversationModel>> getConversations() async {
    if (currentUserId == null) {
      return [];
    }

    try {
      // Nejprve získej ID konverzací, kde je uživatel účastníkem
      final myConversations = await _supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', currentUserId!);

      final conversationIds = (myConversations as List)
          .map((c) => c['conversation_id'] as String)
          .toList();

      if (conversationIds.isEmpty) {
        return [];
      }

      // Pak načti konverzace s účastníky
      final response = await _supabase
          .from('conversations')
          .select('''
            *,
            conversation_participants(*, profiles(*))
          ''')
          .inFilter('id', conversationIds)
          .order('updated_at', ascending: false);

      if ((response as List).isEmpty) {
        return [];
      }

      final conversations = response
          .map((c) => ConversationModel.fromJson(c))
          .toList();

      // Načti poslední zprávu a spočítej nepřečtené pro každou konverzaci
      for (var i = 0; i < conversations.length; i++) {
        try {
          debugPrint('Loading last message for conversation: ${conversations[i].id}');
          final lastMessage = await _getLastMessage(conversations[i].id);
          debugPrint('Last message loaded: ${lastMessage?.decryptedContent ?? "null"}');
          final unreadCount = await _getUnreadCount(conversations[i].id, conversations[i].participants);

          conversations[i] = ConversationModel(
            id: conversations[i].id,
            type: conversations[i].type,
            name: conversations[i].name,
            description: conversations[i].description,
            avatarUrl: conversations[i].avatarUrl,
            isEncrypted: conversations[i].isEncrypted,
            disappearingMessagesTtl: conversations[i].disappearingMessagesTtl,
            createdBy: conversations[i].createdBy,
            createdAt: conversations[i].createdAt,
            updatedAt: conversations[i].updatedAt,
            participants: conversations[i].participants,
            lastMessage: lastMessage,
            unreadCount: unreadCount,
          );
        } catch (e) {
          debugPrint('Error loading conversation data: $e');
        }
      }

      return conversations;
    } catch (e) {
      // Vrať prázdný seznam pokud dojde k chybě
      debugPrint('getConversations ERROR: $e');
      return [];
    }
  }

  Future<MessageModel?> _getLastMessage(String conversationId) async {
    final response = await _supabase
        .from('messages')
        .select('*, profiles!messages_sender_id_fkey(*)')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    var message = MessageModel.fromJson(response);

    // Dešifruj zprávu pro náhled
    if (!message.isDeleted && message.encryptedContent.isNotEmpty && message.iv.isNotEmpty) {
      try {
        final sessionKey = await _getOrCreateSessionKey(conversationId);
        final decrypted = await _encryption.decryptMessage(
          ciphertext: message.encryptedContent,
          iv: message.iv,
          secretKey: sessionKey,
        );
        message = message.copyWith(decryptedContent: decrypted);
      } catch (e) {
        // Fallback text při selhání dešifrování
        message = message.copyWith(decryptedContent: '[Sifrovana zprava]');
      }
    }

    return message;
  }

  /// Spočítá počet nepřečtených zpráv v konverzaci
  Future<int> _getUnreadCount(String conversationId, List<ConversationParticipant> participants) async {
    if (currentUserId == null) return 0;

    try {
      // Najdi last_read_at pro aktuálního uživatele
      final myParticipant = participants.where((p) => p.userId == currentUserId).firstOrNull;
      final lastReadAt = myParticipant?.lastReadAt;

      // Spočítej zprávy od ostatních, které přišly po last_read_at
      if (lastReadAt != null) {
        final response = await _supabase
            .from('messages')
            .select('id')
            .eq('conversation_id', conversationId)
            .neq('sender_id', currentUserId!)
            .gt('created_at', lastReadAt.toIso8601String());
        return (response as List).length;
      } else {
        // Pokud není last_read_at, spočítej všechny zprávy od ostatních
        final response = await _supabase
            .from('messages')
            .select('id')
            .eq('conversation_id', conversationId)
            .neq('sender_id', currentUserId!);
        return (response as List).length;
      }
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Získá nebo vytvoří direct konverzaci s uživatelem
  ///
  /// Vyhodí výjimku, pokud je uživatel vzájemně zablokován.
  Future<String> getOrCreateDirectConversation(String otherUserId) async {
    // Zkontroluj vzájemné blokování
    final isMutuallyBlocked = await _blockService.isMutuallyBlocked(otherUserId);
    if (isMutuallyBlocked) {
      throw Exception('Nelze zahájit konverzaci se zablokovaným uživatelem');
    }

    final response = await _supabase.rpc(
      'get_or_create_direct_conversation',
      params: {'other_user_id': otherUserId},
    );

    final conversationId = response as String;
    return conversationId;
  }

  /// Vytvoří skupinovou konverzaci
  Future<String> createGroupConversation({
    required String name,
    String? description,
    required List<String> memberIds,
  }) async {
    // Vytvoř konverzaci
    final convResponse = await _supabase
        .from('conversations')
        .insert({
          'type': 'group',
          'name': name,
          'description': description,
          'created_by': currentUserId,
        })
        .select()
        .single();

    final conversationId = convResponse['id'] as String;

    // Přidej členy včetně sebe
    final allMembers = {...memberIds, currentUserId!};
    for (final memberId in allMembers) {
      await _supabase.from('conversation_participants').insert({
        'conversation_id': conversationId,
        'user_id': memberId,
        'role': memberId == currentUserId ? 'admin' : 'member',
      });
    }

    return conversationId;
  }

  /// Načte nebo vytvoří session key pro konverzaci
  /// Klíč je odvozen z conversation_id - deterministicky stejný pro všechny účastníky
  Future<SecretKey> _getOrCreateSessionKey(String conversationId) async {
    // Zkontroluj cache
    if (_sessionKeys.containsKey(conversationId)) {
      return _sessionKeys[conversationId]!;
    }

    // Odvoď klíč z conversation_id (deterministický - stejný pro všechny)
    // Použijeme HKDF pro odvození klíče z conversation_id
    final algorithm = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final secretKey = await algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(conversationId)),
      nonce: utf8.encode('charlotte-web-e2ee'),
      info: utf8.encode('chat-session-key'),
    );

    // Debug: log key derivation
    final keyBytes = await secretKey.extractBytes();
    debugPrint('Session key derived for conversation: $conversationId');
    debugPrint('Key hash: ${keyBytes.take(4).toList()}...');

    _sessionKeys[conversationId] = secretKey;
    return secretKey;
  }

  // ============================================
  // ZPRÁVY
  // ============================================

  /// Získá zprávy v konverzaci
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*, profiles!messages_sender_id_fkey(*)')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final messages = (response as List)
          .map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
          .toList();

      // Dešifruj zprávy
      final sessionKey = await _getOrCreateSessionKey(conversationId);
      final keyBytes = await sessionKey.extractBytes();
      debugPrint('DECRYPT: conversation=$conversationId, key_hash=${keyBytes.take(4).toList()}, messages=${messages.length}');

      for (var i = 0; i < messages.length; i++) {
        if (!messages[i].isDeleted) {
          try {
            debugPrint('DECRYPT msg ${messages[i].id}: len=${messages[i].encryptedContent.length}, iv=${messages[i].iv.length}');
            final decrypted = await _encryption.decryptMessage(
              ciphertext: messages[i].encryptedContent,
              iv: messages[i].iv,
              secretKey: sessionKey,
            );
            debugPrint('DECRYPT OK: ${decrypted.substring(0, decrypted.length > 30 ? 30 : decrypted.length)}');
            messages[i] = messages[i].copyWith(decryptedContent: decrypted);
          } catch (e) {
            // Desifrování selhalo - zobraz bezpecnou chybovou hlasku
            debugPrint('DECRYPT FAIL ${messages[i].id}: $e');

            // BEZPECNOST: Nikdy nepouzivame nesifrovaný obsah jako fallback
            // To by umoznilo utocnikovi obejit sifrovani
            messages[i] = messages[i].copyWith(
              decryptedContent: '[Nelze desifrovat zpravu]',
            );
          }
        }
      }

      return messages;
    } catch (e) {
      // Pokud query selže, vrať prázdný seznam
      return [];
    }
  }

  /// Odešle zprávu
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? replyToId,
    int? disappearingTtl,
  }) async {
    // Získej session key pro šifrování
    final sessionKey = await _getOrCreateSessionKey(conversationId);

    // Debug: log key při šifrování
    final keyBytes = await sessionKey.extractBytes();
    debugPrint('ENCRYPT: conversation=$conversationId, key_hash=${keyBytes.take(4).toList()}');

    // Zašifruj obsah
    final encrypted = await _encryption.encryptMessage(
      plaintext: content,
      secretKey: sessionKey,
    );

    debugPrint('ENCRYPT: ciphertext_len=${encrypted.ciphertext.length}, iv_len=${encrypted.iv.length}');

    // Vypočítej expiration
    DateTime? expiresAt;
    if (disappearingTtl != null && disappearingTtl > 0) {
      expiresAt = DateTime.now().add(Duration(seconds: disappearingTtl));
    }

    // Vlož do databáze
    final response = await _supabase
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': currentUserId,
          'encrypted_content': encrypted.ciphertext,
          'iv': encrypted.iv,
          'mac': '', // MAC je součástí ciphertext (AES-GCM), prázdný string pro kompatibilitu s DB
          'message_type': messageType,
          'metadata': metadata ?? {},
          'reply_to_id': replyToId,
          'expires_at': expiresAt?.toIso8601String(),
        })
        .select('*, profiles!messages_sender_id_fkey(*)')
        .single();

    // Aktualizuj timestamp konverzace
    await _supabase
        .from('conversations')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);

    final message = MessageModel.fromJson(response);

    // Posli push notifikace prijemcum
    _sendMessageNotifications(conversationId, content);

    return message.copyWith(decryptedContent: content);
  }

  /// Odesle push notifikace vsem prijemcum zpravy
  Future<void> _sendMessageNotifications(
    String conversationId,
    String messageContent,
  ) async {
    try {
      // Ziskej vsechny ucastniky konverzace krome sebe
      final participants = await _supabase
          .from('conversation_participants')
          .select('user_id')
          .eq('conversation_id', conversationId)
          .neq('user_id', currentUserId!);

      for (final p in participants as List) {
        final recipientId = p['user_id'] as String?;
        if (recipientId != null) {
          await _pushSender.sendChatNotification(
            recipientId: recipientId,
            conversationId: conversationId,
            messageContent: messageContent,
          );
        }
      }
    } catch (e) {
      // Ignoruj chyby - push neni kriticky
      debugPrint('Push notification error: $e');
    }
  }

  /// Nahraje obrázek do Storage a vrátí URL
  Future<String> uploadImage({
    required String conversationId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final storagePath = 'chat/$conversationId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _supabase.storage
        .from('chat-images')
        .uploadBinary(storagePath, fileBytes);

    final publicUrl = _supabase.storage
        .from('chat-images')
        .getPublicUrl(storagePath);

    return publicUrl;
  }

  /// Odešle obrázek jako zprávu
  Future<MessageModel> sendImageMessage({
    required String conversationId,
    required String imageUrl,
    String? caption,
  }) async {
    // Zašifruj URL (a případný popisek)
    final content = caption != null && caption.isNotEmpty
        ? '$imageUrl|$caption'
        : imageUrl;

    return sendMessage(
      conversationId: conversationId,
      content: content,
      messageType: 'image',
      metadata: {
        'image_url': imageUrl,
        'caption': caption,
      },
    );
  }

  /// Odešle hlasovou zprávu
  Future<MessageModel> sendVoiceMessage({
    required String conversationId,
    required String voiceUrl,
    required int durationSeconds,
  }) async {
    // Ukládá se ve formátu "url|duration" pro kompatibilitu s UI
    return sendMessage(
      conversationId: conversationId,
      content: '$voiceUrl|$durationSeconds',
      messageType: 'voice',
      metadata: {
        'voice_url': voiceUrl,
        'duration': durationSeconds,
      },
    );
  }

  /// Odešle zprávu s polohou
  Future<MessageModel> sendLocationMessage({
    required String conversationId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final content = '$latitude,$longitude${address != null ? '|$address' : ''}';
    return sendMessage(
      conversationId: conversationId,
      content: content,
      messageType: 'location',
      metadata: {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
    );
  }

  /// Nahraje soubor do Storage a vrátí URL
  Future<String> uploadFile({
    required String conversationId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final storagePath = 'chat/$conversationId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _supabase.storage
        .from('chat-files')
        .uploadBinary(storagePath, fileBytes);

    final publicUrl = _supabase.storage
        .from('chat-files')
        .getPublicUrl(storagePath);

    return publicUrl;
  }

  /// Odešle soubor jako zprávu
  Future<MessageModel> sendFileMessage({
    required String conversationId,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    required String mimeType,
  }) async {
    return sendMessage(
      conversationId: conversationId,
      content: fileUrl,
      messageType: 'file',
      metadata: {
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size': fileSize,
        'mime_type': mimeType,
      },
    );
  }

  /// Přepošle zprávu do jiné konverzace
  Future<MessageModel> forwardMessage({
    required String messageId,
    required String toConversationId,
  }) async {
    // Načti původní zprávu
    final original = await _supabase
        .from('messages')
        .select('*, profiles!messages_sender_id_fkey(*)')
        .eq('id', messageId)
        .single();

    final originalMessage = MessageModel.fromJson(original);

    // Dešifruj původní obsah
    final sessionKey = await _getOrCreateSessionKey(originalMessage.conversationId);
    String content;
    try {
      content = await _encryption.decryptMessage(
        ciphertext: originalMessage.encryptedContent,
        iv: originalMessage.iv,
        secretKey: sessionKey,
      );
    } catch (_) {
      content = originalMessage.encryptedContent;
    }

    // Zašifruj pro novou konverzaci
    final newSessionKey = await _getOrCreateSessionKey(toConversationId);
    final encrypted = await _encryption.encryptMessage(
      plaintext: content,
      secretKey: newSessionKey,
    );

    // Vlož přeposlanou zprávu
    final response = await _supabase
        .from('messages')
        .insert({
          'conversation_id': toConversationId,
          'sender_id': currentUserId,
          'encrypted_content': encrypted.ciphertext,
          'iv': encrypted.iv,
          'mac': '', // MAC je součástí ciphertext (AES-GCM)
          'message_type': originalMessage.messageType,
          'metadata': originalMessage.metadata,
          'forwarded_from_id': messageId,
          'original_sender_id': originalMessage.senderId,
        })
        .select('*, profiles!messages_sender_id_fkey(*)')
        .single();

    // Aktualizuj timestamp konverzace
    await _supabase
        .from('conversations')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', toConversationId);

    final message = MessageModel.fromJson(response);
    return message.copyWith(decryptedContent: content);
  }

  // ============================================
  // PINNED MESSAGES
  // ============================================

  /// Připne zprávu
  Future<void> pinMessage(String conversationId, String messageId) async {
    await _supabase.from('pinned_messages').insert({
      'conversation_id': conversationId,
      'message_id': messageId,
      'pinned_by': currentUserId,
    });
  }

  /// Odepne zprávu
  Future<void> unpinMessage(String conversationId, String messageId) async {
    await _supabase
        .from('pinned_messages')
        .delete()
        .eq('conversation_id', conversationId)
        .eq('message_id', messageId);
  }

  /// Získá připnuté zprávy
  Future<List<MessageModel>> getPinnedMessages(String conversationId) async {
    final response = await _supabase
        .from('pinned_messages')
        .select('message_id, messages(*, profiles!messages_sender_id_fkey(*))')
        .eq('conversation_id', conversationId)
        .order('pinned_at', ascending: false);

    final messages = <MessageModel>[];
    final sessionKey = await _getOrCreateSessionKey(conversationId);

    for (final row in (response as List)) {
      final msgData = row['messages'] as Map<String, dynamic>?;
      if (msgData != null) {
        var message = MessageModel.fromJson(msgData);
        if (!message.isDeleted) {
          try {
            final decrypted = await _encryption.decryptMessage(
              ciphertext: message.encryptedContent,
              iv: message.iv,
              secretKey: sessionKey,
            );
            message = message.copyWith(decryptedContent: decrypted);
          } catch (_) {
            // BEZPECNOST: Nikdy nepouzivame nesifrovaný obsah
            message = message.copyWith(decryptedContent: '[Nelze desifrovat zpravu]');
          }
        }
        messages.add(message);
      }
    }

    return messages;
  }

  // ============================================
  // POLLS
  // ============================================

  /// Vytvoří anketu
  Future<PollModel> createPoll({
    required String conversationId,
    required String question,
    required List<String> options,
    bool isAnonymous = false,
    bool allowsAddOptions = false,
    DateTime? expiresAt,
  }) async {
    // Vytvoř anketu
    final pollResponse = await _supabase
        .from('polls')
        .insert({
          'conversation_id': conversationId,
          'created_by': currentUserId,
          'question': question,
          'is_anonymous': isAnonymous,
          'allows_add_options': allowsAddOptions,
          'expires_at': expiresAt?.toIso8601String(),
        })
        .select()
        .single();

    final pollId = pollResponse['id'] as String;

    // Přidej možnosti
    for (final option in options) {
      await _supabase.from('poll_options').insert({
        'poll_id': pollId,
        'option_text': option,
        'added_by': currentUserId,
      });
    }

    // Odešli zprávu s anketou
    await sendMessage(
      conversationId: conversationId,
      content: question,
      messageType: 'poll',
      metadata: {'poll_id': pollId},
    );

    return PollModel.fromJson(pollResponse);
  }

  /// Hlasuje v anketě
  Future<void> votePoll(String pollId, String optionId) async {
    await _supabase.from('poll_votes').upsert({
      'poll_id': pollId,
      'option_id': optionId,
      'user_id': currentUserId,
    });
  }

  /// Odebere hlas z ankety
  Future<void> unvotePoll(String pollId, String optionId) async {
    await _supabase
        .from('poll_votes')
        .delete()
        .eq('poll_id', pollId)
        .eq('option_id', optionId)
        .eq('user_id', currentUserId!);
  }

  /// Získá anketu s hlasy
  Future<PollModel?> getPoll(String pollId) async {
    final response = await _supabase
        .from('polls')
        .select('''
          *,
          poll_options(*),
          poll_votes(*)
        ''')
        .eq('id', pollId)
        .maybeSingle();

    if (response == null) return null;
    return PollModel.fromJson(response);
  }

  // ============================================
  // ARCHIVE
  // ============================================

  /// Archivuje konverzaci
  Future<void> archiveConversation(String conversationId) async {
    await _supabase
        .from('conversation_participants')
        .update({
          'is_archived': true,
          'archived_at': DateTime.now().toIso8601String(),
        })
        .eq('conversation_id', conversationId)
        .eq('user_id', currentUserId!);
  }

  /// Odarchivuje konverzaci
  Future<void> unarchiveConversation(String conversationId) async {
    await _supabase
        .from('conversation_participants')
        .update({
          'is_archived': false,
          'archived_at': null,
        })
        .eq('conversation_id', conversationId)
        .eq('user_id', currentUserId!);
  }

  /// Získá archivované konverzace
  Future<List<ConversationModel>> getArchivedConversations() async {
    if (currentUserId == null) return [];

    try {
      final myConversations = await _supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', currentUserId!)
          .eq('is_archived', true);

      final conversationIds = (myConversations as List)
          .map((c) => c['conversation_id'] as String)
          .toList();

      if (conversationIds.isEmpty) return [];

      final response = await _supabase
          .from('conversations')
          .select('''
            *,
            conversation_participants(*, profiles(*))
          ''')
          .inFilter('id', conversationIds)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((c) => ConversationModel.fromJson(c))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Smaže zprávu (soft delete)
  Future<void> deleteMessage(String messageId) async {
    await _supabase.from('messages').update({
      'is_deleted': true,
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }

  /// Přidá reakci na zprávu
  Future<void> addReaction(String messageId, String emoji) async {
    await _supabase.from('message_reactions').upsert({
      'message_id': messageId,
      'user_id': currentUserId,
      'emoji': emoji,
    });
  }

  /// Odebere reakci
  Future<void> removeReaction(String messageId, String emoji) async {
    await _supabase
        .from('message_reactions')
        .delete()
        .eq('message_id', messageId)
        .eq('user_id', currentUserId!)
        .eq('emoji', emoji);
  }

  /// Označí zprávu jako přečtenou
  Future<void> markAsRead(String messageId) async {
    await _supabase.from('message_receipts').upsert({
      'message_id': messageId,
      'user_id': currentUserId,
      'status': 'read',
    });
  }

  /// Označí celou konverzaci jako přečtenou (aktualizuje last_read_at a vytvoří receipts)
  Future<void> markConversationAsRead(String conversationId) async {
    if (currentUserId == null) return;

    try {
      // Aktualizuj last_read_at
      await _supabase
          .from('conversation_participants')
          .update({'last_read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .eq('user_id', currentUserId!);

      // Získej všechny zprávy od ostatních v této konverzaci (limit kvůli výkonu)
      final messagesResponse = await _supabase
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUserId!)
          .limit(100);

      final messages = messagesResponse as List;

      // Vytvoř read receipts pro všechny zprávy
      for (final msg in messages) {
        try {
          await _supabase.from('message_receipts').upsert({
            'message_id': msg['id'],
            'user_id': currentUserId,
            'status': 'read',
            'timestamp': DateTime.now().toIso8601String(),
          }, onConflict: 'message_id,user_id');
        } catch (_) {
          // Ignoruj chyby (může už existovat)
        }
      }

      debugPrint('Marked conversation $conversationId as read for user $currentUserId (${messages.length} messages)');
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
    }
  }

  // ============================================
  // REAL-TIME
  // ============================================

  /// Stream nových zpráv v konverzaci
  Stream<MessageModel> messagesStream(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(1)
        .asyncMap((data) async {
          if (data.isEmpty) {
            throw Exception('No message');
          }
          final message = MessageModel.fromJson(data.first);

          // Dešifruj
          if (!message.isDeleted) {
            try {
              final sessionKey = await _getOrCreateSessionKey(conversationId);
              final decrypted = await _encryption.decryptMessage(
                ciphertext: message.encryptedContent,
                iv: message.iv,
                secretKey: sessionKey,
              );
              return message.copyWith(decryptedContent: decrypted);
            } catch (e) {
              // Fallback - loguj chybu a zobraz chybovou zprávu
              debugPrint('Stream decryption error for message ${message.id}: $e');
              return message.copyWith(decryptedContent: '[Nepodařilo se dešifrovat zprávu]');
            }
          }
          return message;
        });
  }

  /// Stream konverzací
  Stream<List<Map<String, dynamic>>> conversationsStream() {
    return _supabase
        .from('conversation_participants')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId!)
        .order('joined_at', ascending: false);
  }

  // ============================================
  // TYPING INDICATOR
  // ============================================

  /// Nastaví typing status
  Future<void> setTyping(String conversationId, bool isTyping) async {
    try {
      await _supabase.from('typing_indicators').upsert({
        'conversation_id': conversationId,
        'user_id': currentUserId,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Ignoruj chyby - není kritické
    }
  }

  /// Stream typing indikátorů v konverzaci
  Stream<List<String>> typingStream(String conversationId) {
    return _supabase
        .from('typing_indicators')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .eq('conversation_id', conversationId)
        .map((data) {
          final now = DateTime.now();
          return data
              .where((row) {
                if (row['user_id'] == currentUserId) return false;
                if (row['is_typing'] != true) return false;
                final updatedAt = DateTime.tryParse(row['updated_at'] ?? '');
                if (updatedAt == null) return false;
                // Zobraz pouze pokud bylo aktualizováno v posledních 5 sekundách
                return now.difference(updatedAt).inSeconds < 5;
              })
              .map((row) => row['user_id'] as String)
              .toList();
        });
  }

  // ============================================
  // UŽIVATELÉ
  // ============================================

  /// Vyhledá uživatele podle jména
  ///
  /// Automaticky filtruje zablokované uživatele z výsledků.
  Future<List<UserModel>> searchUsers(String query) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .neq('id', currentUserId!)
        .ilike('username', '%$query%')
        .limit(20);

    // Získej seznam zablokovaných uživatelů
    final blockedIds = await _blockService.getAllBlockedIds();

    // Filtruj zablokované uživatele z výsledků
    return (response as List)
        .map((u) => UserModel.fromJson(u as Map<String, dynamic>))
        .where((user) => !blockedIds.contains(user.id))
        .toList();
  }
}

/// Veřejné klíče uživatele
class UserPublicKeys {
  final String userId;
  final String identityPublicKey;
  final String? signingPublicKey;
  final String signedPrekeyPublic;
  final String signedPrekeySignature;
  final List<String> oneTimePrekeys;

  UserPublicKeys({
    required this.userId,
    required this.identityPublicKey,
    this.signingPublicKey,
    required this.signedPrekeyPublic,
    required this.signedPrekeySignature,
    required this.oneTimePrekeys,
  });

  factory UserPublicKeys.fromJson(Map<String, dynamic> json) {
    return UserPublicKeys(
      userId: json['user_id'] as String,
      identityPublicKey: json['identity_public_key'] as String,
      signingPublicKey: json['signing_public_key'] as String?,
      signedPrekeyPublic: json['signed_prekey_public'] as String,
      signedPrekeySignature: json['signed_prekey_signature'] as String? ?? '',
      oneTimePrekeys: (json['one_time_prekeys'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Ověří podpis signed prekey
  Future<bool> verifySignedPrekey(EncryptionService encryption) async {
    if (signingPublicKey == null || signedPrekeySignature.isEmpty) {
      return false;
    }

    final prekeyBytes = base64Decode(signedPrekeyPublic);
    return encryption.verifySignature(
      data: Uint8List.fromList(prekeyBytes),
      signatureBase64: signedPrekeySignature,
      signingPublicKeyBase64: signingPublicKey!,
    );
  }
}
