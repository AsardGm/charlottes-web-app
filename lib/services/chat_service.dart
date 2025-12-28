import 'dart:async';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation_model.dart';
import '../models/user_model.dart';
import 'encryption_service.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EncryptionService _encryption = EncryptionService();

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

    // Ulož veřejné klíče do databáze
    await _supabase.from('user_keys').upsert({
      'user_id': currentUserId,
      'identity_public_key': identityKey.publicKeyBase64,
      'signed_prekey_public': signedPrekey.publicKeyBase64,
      'signed_prekey_signature': '', // TODO: Podepsat identity klíčem
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
      final response = await _supabase
          .from('conversations')
          .select('''
            *,
            conversation_participants(*, profiles(*))
          ''')
          .order('updated_at', ascending: false);

      if ((response as List).isEmpty) {
        return [];
      }

      final conversations = response
          .map((c) => ConversationModel.fromJson(c))
          .toList();

      // Načti poslední zprávu pro každou konverzaci
      for (var i = 0; i < conversations.length; i++) {
        try {
          final lastMessage = await _getLastMessage(conversations[i].id);
          if (lastMessage != null) {
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
              unreadCount: conversations[i].unreadCount,
            );
          }
        } catch (_) {
          // Ignoruj chyby při načítání poslední zprávy
        }
      }

      return conversations;
    } catch (e) {
      // Vrať prázdný seznam pokud dojde k chybě
      return [];
    }
  }

  Future<MessageModel?> _getLastMessage(String conversationId) async {
    final response = await _supabase
        .from('messages')
        .select('*, profiles(*)')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return MessageModel.fromJson(response);
  }

  /// Získá nebo vytvoří direct konverzaci s uživatelem
  Future<String> getOrCreateDirectConversation(String otherUserId) async {
    final response = await _supabase.rpc(
      'get_or_create_direct_conversation',
      params: {'other_user_id': otherUserId},
    );

    final conversationId = response as String;

    // Inicializuj šifrování pro konverzaci
    await _initializeConversationEncryption(conversationId, otherUserId);

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

    // Vygeneruj session key
    final sessionKey = await _encryption.generateSessionKey();
    _sessionKeys[conversationId] = sessionKey;

    // Přidej členy včetně sebe
    final allMembers = {...memberIds, currentUserId!};
    for (final memberId in allMembers) {
      final encryptedKey = await _encryptSessionKeyForUser(sessionKey, memberId);
      await _supabase.from('conversation_participants').insert({
        'conversation_id': conversationId,
        'user_id': memberId,
        'role': memberId == currentUserId ? 'admin' : 'member',
        'encrypted_session_key': encryptedKey,
      });
    }

    return conversationId;
  }

  /// Inicializuje šifrování pro konverzaci
  Future<void> _initializeConversationEncryption(
    String conversationId,
    String otherUserId,
  ) async {
    // Zkontroluj zda už máme session key
    if (_sessionKeys.containsKey(conversationId)) return;

    // Zkus načíst z databáze
    final participant = await _supabase
        .from('conversation_participants')
        .select()
        .eq('conversation_id', conversationId)
        .eq('user_id', currentUserId!)
        .maybeSingle();

    if (participant != null && participant['encrypted_session_key'] != null) {
      // Dešifruj existující session key
      final otherKeys = await getUserPublicKeys(otherUserId);
      if (otherKeys != null) {
        final ourKeys = await _encryption.getIdentityKeyPair();
        if (ourKeys != null) {
          final sessionKey = await _encryption.decryptSessionKey(
            encryptedSessionKey: participant['encrypted_session_key'],
            senderPublicKey: base64Decode(otherKeys.identityPublicKey),
            ourPrivateKey: ourKeys.privateKeyBytes,
          );
          _sessionKeys[conversationId] = sessionKey;
          return;
        }
      }
    }

    // Vytvoř nový session key
    final sessionKey = await _encryption.generateSessionKey();
    _sessionKeys[conversationId] = sessionKey;

    // Zašifruj pro oba účastníky
    final encryptedForUs =
        await _encryptSessionKeyForUser(sessionKey, currentUserId!);
    final encryptedForOther =
        await _encryptSessionKeyForUser(sessionKey, otherUserId);

    // Ulož do databáze
    await _supabase
        .from('conversation_participants')
        .update({'encrypted_session_key': encryptedForUs})
        .eq('conversation_id', conversationId)
        .eq('user_id', currentUserId!);

    await _supabase
        .from('conversation_participants')
        .update({'encrypted_session_key': encryptedForOther})
        .eq('conversation_id', conversationId)
        .eq('user_id', otherUserId);
  }

  Future<String?> _encryptSessionKeyForUser(
    SecretKey sessionKey,
    String userId,
  ) async {
    final userKeys = await getUserPublicKeys(userId);
    if (userKeys == null) return null;

    final ourKeys = await _encryption.getIdentityKeyPair();
    if (ourKeys == null) return null;

    return await _encryption.encryptSessionKey(
      sessionKey: sessionKey,
      recipientPublicKey: base64Decode(userKeys.identityPublicKey),
      ourPrivateKey: ourKeys.privateKeyBytes,
    );
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
    final response = await _supabase
        .from('messages')
        .select('''
          *,
          profiles(*),
          message_reactions(*),
          message_receipts(*)
        ''')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final messages = (response as List)
        .map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
        .toList();

    // Dešifruj zprávy
    final sessionKey = _sessionKeys[conversationId];
    if (sessionKey != null) {
      for (var i = 0; i < messages.length; i++) {
        if (!messages[i].isDeleted) {
          try {
            final decrypted = await _encryption.decryptMessage(
              ciphertext: messages[i].encryptedContent,
              iv: messages[i].iv,
              secretKey: sessionKey,
            );
            messages[i] = messages[i].copyWith(decryptedContent: decrypted);
          } catch (e) {
            messages[i] = messages[i].copyWith(
              decryptedContent: '[Nelze dešifrovat]',
            );
          }
        }
      }
    }

    return messages;
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
    // Získej session key
    var sessionKey = _sessionKeys[conversationId];
    if (sessionKey == null) {
      throw Exception('No session key for conversation');
    }

    // Zašifruj obsah
    final encrypted = await _encryption.encryptMessage(
      plaintext: content,
      secretKey: sessionKey,
    );

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
          'message_type': messageType,
          'metadata': metadata ?? {},
          'reply_to_id': replyToId,
          'expires_at': expiresAt?.toIso8601String(),
        })
        .select('*, profiles(*)')
        .single();

    // Aktualizuj timestamp konverzace
    await _supabase
        .from('conversations')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);

    final message = MessageModel.fromJson(response);
    return message.copyWith(decryptedContent: content);
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
          final sessionKey = _sessionKeys[conversationId];
          if (sessionKey != null && !message.isDeleted) {
            try {
              final decrypted = await _encryption.decryptMessage(
                ciphertext: message.encryptedContent,
                iv: message.iv,
                secretKey: sessionKey,
              );
              return message.copyWith(decryptedContent: decrypted);
            } catch (_) {
              return message.copyWith(decryptedContent: '[Nelze dešifrovat]');
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
  // UŽIVATELÉ
  // ============================================

  /// Vyhledá uživatele podle jména
  Future<List<UserModel>> searchUsers(String query) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .neq('id', currentUserId!)
        .ilike('username', '%$query%')
        .limit(20);

    return (response as List)
        .map((u) => UserModel.fromJson(u as Map<String, dynamic>))
        .toList();
  }
}

/// Veřejné klíče uživatele
class UserPublicKeys {
  final String userId;
  final String identityPublicKey;
  final String signedPrekeyPublic;
  final String signedPrekeySignature;
  final List<String> oneTimePrekeys;

  UserPublicKeys({
    required this.userId,
    required this.identityPublicKey,
    required this.signedPrekeyPublic,
    required this.signedPrekeySignature,
    required this.oneTimePrekeys,
  });

  factory UserPublicKeys.fromJson(Map<String, dynamic> json) {
    return UserPublicKeys(
      userId: json['user_id'] as String,
      identityPublicKey: json['identity_public_key'] as String,
      signedPrekeyPublic: json['signed_prekey_public'] as String,
      signedPrekeySignature: json['signed_prekey_signature'] as String? ?? '',
      oneTimePrekeys: (json['one_time_prekeys'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
