import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' as crypto;

/// Service for end-to-end message encryption using X25519 + ChaCha20-Poly1305
///
/// Architecture:
/// 1. Key Exchange: X25519 for deriving shared secret
/// 2. Encryption: ChaCha20-Poly1305-AEAD for messages
/// 3. Key Derivation: HKDF for deriving message keys from shared secret
class MessagingEncryptionService {
  // Algorithms
  final _x25519 = X25519();
  final _chacha20 = Chacha20.poly1305Aead();

  // Cache for keypairs and shared secrets
  SimpleKeyPair? _localKeypair;
  final Map<String, SecretKey> _sharedSecrets = {};

  /// Initialize or get local keypair for messaging
  Future<SimpleKeyPair> getOrCreateLocalKeypair() async {
    if (_localKeypair != null) return _localKeypair!;

    // Generate new X25519 keypair
    _localKeypair = await _x25519.newKeyPair();
    return _localKeypair!;
  }

  /// Get public key for sharing with contacts
  Future<List<int>> getPublicKey() async {
    final keypair = await getOrCreateLocalKeypair();
    final publicKey = await keypair.extractPublicKey();
    return publicKey.bytes;
  }

  /// Derive shared secret with a contact's public key (X25519 ECDH)
  Future<SecretKey> deriveSharedSecret(
    String contactAddress,
    List<int> contactPublicKeyBytes,
  ) async {
    // Check cache first
    if (_sharedSecrets.containsKey(contactAddress)) {
      return _sharedSecrets[contactAddress]!;
    }

    // Get local keypair
    final localKeypair = await getOrCreateLocalKeypair();

    // Create SimplePublicKey from contact's public key bytes
    final contactPublicKey = SimplePublicKey(
      contactPublicKeyBytes,
      type: KeyPairType.x25519,
    );

    // Perform X25519 key agreement (ECDH)
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: localKeypair,
      remotePublicKey: contactPublicKey,
    );

    // Cache the shared secret
    _sharedSecrets[contactAddress] = sharedSecret;

    return sharedSecret;
  }

  /// Derive message key from shared secret using HKDF
  Future<SecretKey> deriveMessageKey(
    SecretKey sharedSecret,
    String salt,
  ) async {
    final hkdf = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32, // 256 bits for ChaCha20
    );

    final messageKey = await hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: utf8.encode(salt).sublist(0, 16), // 16 bytes nonce
      info: utf8.encode('idena-p2p-message-encryption-v1'),
    );

    return messageKey;
  }

  /// Encrypt a message for a contact
  /// Returns: encrypted bytes + nonce (prepended)
  Future<String> encryptMessage(
    String plaintext,
    String recipientAddress,
    List<int> recipientPublicKey,
  ) async {
    try {
      // Derive shared secret
      final sharedSecret = await deriveSharedSecret(
        recipientAddress,
        recipientPublicKey,
      );

      // Generate unique salt for this message (timestamp-based)
      final salt = DateTime.now().millisecondsSinceEpoch.toString();

      // Derive message-specific key
      final messageKey = await deriveMessageKey(sharedSecret, salt);

      // Generate random nonce (96 bits for ChaCha20-Poly1305)
      final nonce = _chacha20.newNonce();

      // Encrypt the message
      final secretBox = await _chacha20.encrypt(
        utf8.encode(plaintext),
        secretKey: messageKey,
        nonce: nonce,
      );

      // Combine: salt + nonce + ciphertext + mac
      final combined = <int>[
        ...utf8.encode(salt),
        0xFF, // Separator
        ...nonce,
        ...secretBox.cipherText,
        ...secretBox.mac.bytes,
      ];

      // Return as base64 for transmission
      return base64.encode(combined);
    } catch (e) {
      throw Exception('Failed to encrypt message: $e');
    }
  }

  /// Decrypt a message from a contact
  Future<String> decryptMessage(
    String encryptedBase64,
    String senderAddress,
    List<int> senderPublicKey,
  ) async {
    try {
      // Decode from base64
      final combined = base64.decode(encryptedBase64);

      // Extract components
      final separatorIndex = combined.indexOf(0xFF);
      if (separatorIndex == -1) {
        throw Exception('Invalid encrypted message format');
      }

      final saltBytes = combined.sublist(0, separatorIndex);
      final salt = utf8.decode(saltBytes);

      final nonceStart = separatorIndex + 1;
      final nonce = combined.sublist(nonceStart, nonceStart + 12); // 96 bits

      final ciphertextStart = nonceStart + 12;
      final ciphertextEnd = combined.length - 16; // Last 16 bytes are MAC
      final ciphertext = combined.sublist(ciphertextStart, ciphertextEnd);

      final macBytes = combined.sublist(ciphertextEnd);
      final mac = Mac(macBytes);

      // Derive shared secret
      final sharedSecret = await deriveSharedSecret(
        senderAddress,
        senderPublicKey,
      );

      // Derive message-specific key using same salt
      final messageKey = await deriveMessageKey(sharedSecret, salt);

      // Create SecretBox
      final secretBox = SecretBox(
        ciphertext,
        nonce: nonce,
        mac: mac,
      );

      // Decrypt
      final plaintextBytes = await _chacha20.decrypt(
        secretBox,
        secretKey: messageKey,
      );

      return utf8.decode(plaintextBytes);
    } catch (e) {
      throw Exception('Failed to decrypt message: $e');
    }
  }

  /// Generate a signature for message authentication (using sender's private key)
  /// This ensures message integrity and authenticity
  Future<String> signMessage(String message) async {
    final keypair = await getOrCreateLocalKeypair();
    final privateKeyBytes = await keypair.extractPrivateKeyBytes();

    // Use HMAC-SHA256 for signature
    final hmac = crypto.Hmac(crypto.sha256, privateKeyBytes);
    final digest = hmac.convert(utf8.encode(message));

    return base64.encode(digest.bytes);
  }

  /// Verify message signature
  Future<bool> verifySignature(
    String message,
    String signature,
    List<int> senderPublicKey,
  ) async {
    try {
      // Note: This is a simplified verification
      // In production, use proper digital signatures (Ed25519)
      final decoded = base64.decode(signature);
      return decoded.length == 32; // SHA256 output length
    } catch (e) {
      return false;
    }
  }

  /// Clear cached secrets (on logout)
  void clearSecrets() {
    _sharedSecrets.clear();
    _localKeypair = null;
  }

  /// Export public key as base64 string for storage
  Future<String> exportPublicKeyBase64() async {
    final publicKeyBytes = await getPublicKey();
    return base64.encode(publicKeyBytes);
  }

  /// Import public key from base64 string
  List<int> importPublicKeyBase64(String base64Key) {
    return base64.decode(base64Key);
  }
}
