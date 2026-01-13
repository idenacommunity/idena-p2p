import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:hex/hex.dart';
import 'vault_service.dart';

/// Service for session-based in-memory encryption of sensitive data
/// SECURITY FIX: Encrypts private keys in memory to protect against memory dumps
/// Uses ChaCha20-Poly1305-AEAD (RFC 7539) - a fast, secure authenticated cipher
class EncryptionService {
  final VaultService _vaultService;
  SecretKey? _secretKey;
  final Chacha20 _cipher = Chacha20.poly1305Aead();

  EncryptionService({required VaultService vaultService})
      : _vaultService = vaultService;

  /// Initializes a new encryption session with a cryptographically secure random key
  /// SECURITY: Uses Random.secure() from VaultService for key generation
  /// Must be called before encrypt/decrypt operations
  Future<void> initializeSession() async {
    // Generate secure 256-bit session key (64 hex chars = 32 bytes)
    final sessionKeyHex = _vaultService.generateSessionKey();

    // Convert hex to bytes for ChaCha20 (requires 32 bytes)
    final keyBytes = Uint8List.fromList(HEX.decode(sessionKeyHex));

    _secretKey = SecretKey(keyBytes);
  }

  /// Encrypts plaintext using ChaCha20-Poly1305-AEAD
  /// Returns base64-encoded ciphertext with nonce and MAC prepended
  /// Format: [12-byte-nonce][16-byte-mac][ciphertext] (all base64 encoded)
  Future<String> encrypt(String plaintext) async {
    if (_secretKey == null) {
      throw StateError(
          'Session not initialized. Call initializeSession() first.');
    }

    // Encrypt with authenticated encryption
    final secretBox = await _cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: _secretKey!,
    );

    // Combine nonce + MAC + ciphertext for storage
    // Nonce (12 bytes) + MAC (16 bytes) + ciphertext
    final combined = <int>[
      ...secretBox.nonce,
      ...secretBox.mac.bytes,
      ...secretBox.cipherText,
    ];

    return base64.encode(combined);
  }

  /// Decrypts ciphertext encrypted with encrypt()
  /// Extracts nonce and MAC, verifies authenticity, then decrypts
  /// Returns original plaintext or throws on authentication failure
  Future<String> decrypt(String encryptedBase64) async {
    if (_secretKey == null) {
      throw StateError(
          'Session not initialized. Call initializeSession() first.');
    }

    try {
      // Decode from base64
      final combined = base64.decode(encryptedBase64);

      // Extract components
      final nonce = combined.sublist(0, 12); // First 12 bytes
      final macBytes = combined.sublist(12, 28); // Next 16 bytes
      final cipherText = combined.sublist(28); // Remaining bytes

      // Reconstruct SecretBox
      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      // Decrypt and verify MAC
      final plainBytes = await _cipher.decrypt(
        secretBox,
        secretKey: _secretKey!,
      );

      return utf8.decode(plainBytes);
    } on SecretBoxAuthenticationError {
      throw Exception(
          'Decryption failed: Authentication error. Data may have been tampered with.');
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Clears the session key from memory
  /// SECURITY: Always call this when the session ends (logout, app background, etc.)
  /// Prevents key from lingering in memory after it's no longer needed
  void clearSession() {
    _secretKey = null;
  }

  /// Checks if an encryption session is currently active
  bool get isSessionActive => _secretKey != null;
}
