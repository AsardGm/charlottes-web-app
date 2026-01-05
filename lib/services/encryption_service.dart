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
  final _ed25519 = Ed25519();

  // Vytvoří novou instanci AES-GCM pro každou operaci
  AesGcm get _aesGcm => AesGcm.with256bits();

  // Klíče pro secure storage
  static const _identityPrivateKeyKey = 'identity_private_key';
  static const _identityPublicKeyKey = 'identity_public_key';
  static const _signingPrivateKeyKey = 'signing_private_key';
  static const _signingPublicKeyKey = 'signing_public_key';
  static const _signedPrekeyPrivateKey = 'signed_prekey_private';
  static const _signedPrekeyPublicKey = 'signed_prekey_public';

  /// Vygeneruje nový pár identity klíčů (X25519 pro key exchange)
  /// a signing klíčů (Ed25519 pro podpisy)
  Future<KeyPairData> generateIdentityKeyPair() async {
    // X25519 klíče pro key exchange
    final keyPair = await _x25519.newKeyPair();
    final privateKey = await keyPair.extractPrivateKeyBytes();
    final publicKey = (await keyPair.extractPublicKey()).bytes;

    // Ed25519 klíče pro podpisy
    final signingKeyPair = await _ed25519.newKeyPair();
    final signingPrivateKey = await signingKeyPair.extractPrivateKeyBytes();
    final signingPublicKey = (await signingKeyPair.extractPublicKey()).bytes;

    // Uloží do secure storage
    await _secureStorage.write(
      key: _identityPrivateKeyKey,
      value: base64Encode(privateKey),
    );
    await _secureStorage.write(
      key: _identityPublicKeyKey,
      value: base64Encode(publicKey),
    );
    await _secureStorage.write(
      key: _signingPrivateKeyKey,
      value: base64Encode(signingPrivateKey),
    );
    await _secureStorage.write(
      key: _signingPublicKeyKey,
      value: base64Encode(signingPublicKey),
    );

    return KeyPairData(
      privateKey: privateKey,
      publicKey: publicKey,
      signingPrivateKey: signingPrivateKey,
      signingPublicKey: signingPublicKey,
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
  /// Ciphertext obsahuje i MAC (concatenated)
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

    // Spojíme ciphertext + mac do jednoho stringu
    final combined = [...secretBox.cipherText, ...secretBox.mac.bytes];

    return EncryptedMessage(
      ciphertext: base64Encode(combined),
      iv: base64Encode(nonce),
    );
  }

  /// Dešifruje zprávu
  /// Očekává ciphertext s MAC na konci
  Future<String> decryptMessage({
    required String ciphertext,
    required String iv,
    required SecretKey secretKey,
    String? mac,
  }) async {
    final combinedBytes = base64Decode(ciphertext);
    final nonceBytes = base64Decode(iv);

    // MAC je posledních 16 bytů
    final macLength = 16;
    if (combinedBytes.length < macLength) {
      throw Exception('Invalid ciphertext length');
    }

    final ciphertextBytes = combinedBytes.sublist(0, combinedBytes.length - macLength);
    final macBytes = combinedBytes.sublist(combinedBytes.length - macLength);

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

  /// Podepíše data pomocí Ed25519
  Future<String> signData(Uint8List data) async {
    final signingPrivateKeyStr =
        await _secureStorage.read(key: _signingPrivateKeyKey);
    if (signingPrivateKeyStr == null) {
      throw Exception('Signing key not found');
    }

    final signingPrivateKey = base64Decode(signingPrivateKeyStr);

    // Vytvoření KeyPair z private key
    final keyPair = await _ed25519.newKeyPairFromSeed(signingPrivateKey);

    // Podepsání dat
    final signature = await _ed25519.sign(data, keyPair: keyPair);

    return base64Encode(signature.bytes);
  }

  /// Ověří podpis pomocí Ed25519 veřejného klíče
  Future<bool> verifySignature({
    required Uint8List data,
    required String signatureBase64,
    required String signingPublicKeyBase64,
  }) async {
    try {
      final signatureBytes = base64Decode(signatureBase64);
      final signingPublicKeyBytes = base64Decode(signingPublicKeyBase64);

      final publicKey = SimplePublicKey(
        signingPublicKeyBytes,
        type: KeyPairType.ed25519,
      );

      final signature = Signature(signatureBytes, publicKey: publicKey);

      return await _ed25519.verify(data, signature: signature);
    } catch (_) {
      return false;
    }
  }

  /// Získá signing public key z úložiště
  Future<String?> getSigningPublicKey() async {
    final key = await _secureStorage.read(key: _signingPublicKeyKey);
    return key;
  }
}

/// Data klíčového páru
class KeyPairData {
  final List<int> privateKey;
  final List<int> publicKey;
  final List<int>? signingPrivateKey;
  final List<int>? signingPublicKey;

  KeyPairData({
    required this.privateKey,
    required this.publicKey,
    this.signingPrivateKey,
    this.signingPublicKey,
  });

  String get publicKeyBase64 => base64Encode(publicKey);
  String get privateKeyBase64 => base64Encode(privateKey);
  String? get signingPublicKeyBase64 =>
      signingPublicKey != null ? base64Encode(signingPublicKey!) : null;

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
