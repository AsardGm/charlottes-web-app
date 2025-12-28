import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// E2EE Encryption Service
/// Používá X25519 pro výměnu klíčů a AES-256-GCM pro šifrování zpráv
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final _secureStorage = const FlutterSecureStorage();
  final _x25519 = X25519();
  final _aesGcm = AesGcm.with256bits();

  // Klíče pro secure storage
  static const _identityPrivateKeyKey = 'identity_private_key';
  static const _identityPublicKeyKey = 'identity_public_key';
  static const _signedPrekeyPrivateKey = 'signed_prekey_private';
  static const _signedPrekeyPublicKey = 'signed_prekey_public';

  /// Vygeneruje nový pár identity klíčů
  Future<KeyPairData> generateIdentityKeyPair() async {
    final keyPair = await _x25519.newKeyPair();
    final privateKey = await keyPair.extractPrivateKeyBytes();
    final publicKey = (await keyPair.extractPublicKey()).bytes;

    // Uloží do secure storage
    await _secureStorage.write(
      key: _identityPrivateKeyKey,
      value: base64Encode(privateKey),
    );
    await _secureStorage.write(
      key: _identityPublicKeyKey,
      value: base64Encode(publicKey),
    );

    return KeyPairData(
      privateKey: privateKey,
      publicKey: publicKey,
    );
  }

  /// Vygeneruje signed pre-key
  Future<KeyPairData> generateSignedPrekey() async {
    final keyPair = await _x25519.newKeyPair();
    final privateKey = await keyPair.extractPrivateKeyBytes();
    final publicKey = (await keyPair.extractPublicKey()).bytes;

    await _secureStorage.write(
      key: _signedPrekeyPrivateKey,
      value: base64Encode(privateKey),
    );
    await _secureStorage.write(
      key: _signedPrekeyPublicKey,
      value: base64Encode(publicKey),
    );

    return KeyPairData(
      privateKey: privateKey,
      publicKey: publicKey,
    );
  }

  /// Vygeneruje one-time pre-keys
  Future<List<Uint8List>> generateOneTimePrekeys(int count) async {
    final prekeys = <Uint8List>[];
    for (int i = 0; i < count; i++) {
      final keyPair = await _x25519.newKeyPair();
      final publicKey = (await keyPair.extractPublicKey()).bytes;
      prekeys.add(Uint8List.fromList(publicKey));

      // Uloží private key
      final privateKey = await keyPair.extractPrivateKeyBytes();
      await _secureStorage.write(
        key: 'one_time_prekey_$i',
        value: base64Encode(privateKey),
      );
    }
    return prekeys;
  }

  /// Načte identity klíče ze storage
  Future<KeyPairData?> getIdentityKeyPair() async {
    final privateKeyStr = await _secureStorage.read(key: _identityPrivateKeyKey);
    final publicKeyStr = await _secureStorage.read(key: _identityPublicKeyKey);

    if (privateKeyStr == null || publicKeyStr == null) return null;

    return KeyPairData(
      privateKey: base64Decode(privateKeyStr),
      publicKey: base64Decode(publicKeyStr),
    );
  }

  /// Provede X3DH key exchange a vrátí shared secret
  Future<Uint8List> performKeyExchange({
    required Uint8List ourPrivateKey,
    required Uint8List theirPublicKey,
  }) async {
    final ourKeyPair = await _x25519.newKeyPairFromSeed(ourPrivateKey);
    final theirKey = SimplePublicKey(theirPublicKey, type: KeyPairType.x25519);

    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: ourKeyPair,
      remotePublicKey: theirKey,
    );

    return Uint8List.fromList(await sharedSecret.extractBytes());
  }

  /// Odvodí šifrovací klíč z shared secret pomocí HKDF
  Future<SecretKey> deriveEncryptionKey(Uint8List sharedSecret) async {
    final hkdf = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32,
    );

    final derivedKey = await hkdf.deriveKey(
      secretKey: SecretKey(sharedSecret),
      nonce: utf8.encode('CharlottesWebE2EE'),
      info: utf8.encode('message_encryption'),
    );

    return derivedKey;
  }

  /// Zašifruje zprávu pomocí AES-256-GCM
  Future<EncryptedMessage> encryptMessage({
    required String plaintext,
    required SecretKey secretKey,
  }) async {
    final plaintextBytes = utf8.encode(plaintext);
    final nonce = _aesGcm.newNonce();

    final secretBox = await _aesGcm.encrypt(
      plaintextBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    return EncryptedMessage(
      ciphertext: base64Encode(secretBox.cipherText),
      iv: base64Encode(nonce),
      mac: base64Encode(secretBox.mac.bytes),
    );
  }

  /// Dešifruje zprávu
  Future<String> decryptMessage({
    required String ciphertext,
    required String iv,
    required SecretKey secretKey,
    String? mac,
  }) async {
    final ciphertextBytes = base64Decode(ciphertext);
    final nonceBytes = base64Decode(iv);
    final macBytes = mac != null ? base64Decode(mac) : <int>[];

    final secretBox = SecretBox(
      ciphertextBytes,
      nonce: nonceBytes,
      mac: Mac(macBytes),
    );

    final plaintextBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(plaintextBytes);
  }

  /// Generuje náhodný session key pro konverzaci
  Future<SecretKey> generateSessionKey() async {
    return await _aesGcm.newSecretKey();
  }

  /// Exportuje session key jako base64
  Future<String> exportSessionKey(SecretKey key) async {
    final bytes = await key.extractBytes();
    return base64Encode(bytes);
  }

  /// Importuje session key z base64
  Future<SecretKey> importSessionKey(String base64Key) async {
    final bytes = base64Decode(base64Key);
    return SecretKey(bytes);
  }

  /// Zašifruje session key veřejným klíčem příjemce
  Future<String> encryptSessionKey({
    required SecretKey sessionKey,
    required Uint8List recipientPublicKey,
    required Uint8List ourPrivateKey,
  }) async {
    // Vytvoří shared secret pomocí ECDH
    final sharedSecret = await performKeyExchange(
      ourPrivateKey: ourPrivateKey,
      theirPublicKey: recipientPublicKey,
    );

    // Odvodí encryption key
    final encryptionKey = await deriveEncryptionKey(sharedSecret);

    // Zašifruje session key
    final sessionKeyBytes = await sessionKey.extractBytes();
    final encrypted = await encryptMessage(
      plaintext: base64Encode(sessionKeyBytes),
      secretKey: encryptionKey,
    );

    return '${encrypted.ciphertext}:${encrypted.iv}';
  }

  /// Dešifruje session key
  Future<SecretKey> decryptSessionKey({
    required String encryptedSessionKey,
    required Uint8List senderPublicKey,
    required Uint8List ourPrivateKey,
  }) async {
    final parts = encryptedSessionKey.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid encrypted session key format');
    }

    // Vytvoří shared secret
    final sharedSecret = await performKeyExchange(
      ourPrivateKey: ourPrivateKey,
      theirPublicKey: senderPublicKey,
    );

    // Odvodí decryption key
    final decryptionKey = await deriveEncryptionKey(sharedSecret);

    // Dešifruje session key
    final decrypted = await decryptMessage(
      ciphertext: parts[0],
      iv: parts[1],
      secretKey: decryptionKey,
    );

    return importSessionKey(decrypted);
  }

  /// Vymaže všechny klíče ze storage
  Future<void> clearAllKeys() async {
    await _secureStorage.deleteAll();
  }

  /// Zkontroluje zda uživatel má vygenerované klíče
  Future<bool> hasKeys() async {
    final privateKey = await _secureStorage.read(key: _identityPrivateKeyKey);
    return privateKey != null;
  }
}

/// Data klíčového páru
class KeyPairData {
  final List<int> privateKey;
  final List<int> publicKey;

  KeyPairData({
    required this.privateKey,
    required this.publicKey,
  });

  String get publicKeyBase64 => base64Encode(publicKey);
  String get privateKeyBase64 => base64Encode(privateKey);

  Uint8List get publicKeyBytes => Uint8List.fromList(publicKey);
  Uint8List get privateKeyBytes => Uint8List.fromList(privateKey);
}

/// Zašifrovaná zpráva
class EncryptedMessage {
  final String ciphertext;
  final String iv;
  final String? mac;

  EncryptedMessage({
    required this.ciphertext,
    required this.iv,
    this.mac,
  });
}
