import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:hashlib/hashlib.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hex/hex.dart';
import '../utils/secure_error_handler.dart';

/// Service for securely storing and retrieving sensitive data like private keys
/// Uses platform-specific secure storage (Keychain on iOS, Keystore on Android)
class VaultService {
  static const String _privateKeyStorageKey = 'idena_private_key';
  static const String _addressStorageKey = 'idena_address';
  static const String _pinStorageKey = 'idena_pin';
  static const String _pinSaltKey = 'idena_pin_salt';
  static const String _legacyPinKey = 'idena_pin_legacy';

  // Initialize secure storage with platform-specific options
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Saves the private key securely
  /// The key is encrypted and stored in platform keystore
  Future<void> savePrivateKey(String privateKey) async {
    try {
      await _storage.write(
        key: _privateKeyStorageKey,
        value: privateKey,
      );
    } catch (e, stackTrace) {
      // SECURITY: Log error securely without exposing private key details
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'VaultService.savePrivateKey',
      );
      throw StorageException('Failed to save private key securely');
    }
  }

  /// Saves the address for quick access
  Future<void> saveAddress(String address) async {
    try {
      await _storage.write(
        key: _addressStorageKey,
        value: address,
      );
    } catch (e, stackTrace) {
      // SECURITY: Log error securely
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'VaultService.saveAddress',
      );
      throw StorageException('Failed to save address');
    }
  }

  /// Retrieves the stored private key
  /// Returns null if no key is stored
  Future<String?> getPrivateKey() async {
    try {
      return await _storage.read(key: _privateKeyStorageKey);
    } catch (e, stackTrace) {
      // SECURITY: Log error securely without exposing storage details
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'VaultService.getPrivateKey',
      );
      throw StorageException('Failed to retrieve private key');
    }
  }

  /// Retrieves the stored address
  /// Returns null if no address is stored
  Future<String?> getAddress() async {
    try {
      return await _storage.read(key: _addressStorageKey);
    } catch (e, stackTrace) {
      // SECURITY: Log error securely
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'VaultService.getAddress',
      );
      throw StorageException('Failed to retrieve address');
    }
  }

  /// Checks if a private key is currently stored
  Future<bool> hasStoredKey() async {
    try {
      final privateKey = await _storage.read(key: _privateKeyStorageKey);
      return privateKey != null && privateKey.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Generates or retrieves the PIN salt (16 random bytes)
  /// SECURITY: Salt is generated once and reused for all PIN hashes
  Future<String> _getPinSalt() async {
    try {
      String? salt = await _storage.read(key: _pinSaltKey);

      if (salt == null) {
        // Generate new random salt (16 bytes = 128 bits)
        final random = Random.secure();
        final saltBytes = Uint8List(16);
        for (int i = 0; i < 16; i++) {
          saltBytes[i] = random.nextInt(256);
        }
        salt = HEX.encode(saltBytes);
        await _storage.write(key: _pinSaltKey, value: salt);
      }

      return salt;
    } catch (e, stackTrace) {
      // SECURITY: Log error securely
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'VaultService._getPinSalt',
      );
      throw SecurityException('Failed to get PIN salt');
    }
  }

  /// Hashes a PIN using Argon2id (OWASP recommended parameters)
  /// SECURITY FIX: Uses Argon2id instead of plaintext storage
  Future<String> _hashPin(String pin) async {
    try {
      final saltHex = await _getPinSalt();
      final saltBytes = Uint8List.fromList(HEX.decode(saltHex));

      // Create Argon2 instance with OWASP recommended parameters
      final argon2 = Argon2(
        version: Argon2Version.v13, // Latest version
        type: Argon2Type.argon2id, // Argon2id (hybrid mode - best for password hashing)
        hashLength: 32, // 256-bit hash output
        iterations: 3, // OWASP minimum for password hashing
        parallelism: 4, // 4 parallel threads
        memorySizeKB: 65536, // 64 MB
        salt: saltBytes,
      );

      // Hash the PIN and get PHC encoded string
      final digest = argon2.convert(utf8.encode(pin));

      return digest.encoded();
    } catch (e, stackTrace) {
      // SECURITY: Log error securely without exposing PIN details
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'VaultService._hashPin',
      );
      throw SecurityException('Failed to hash PIN');
    }
  }

  /// Saves the PIN securely using Argon2id hashing
  /// SECURITY FIX: PIN is hashed, not stored in plaintext
  /// The hashed PIN is stored in platform keystore
  Future<void> savePin(String pin) async {
    try {
      // Migrate legacy plaintext PIN if exists
      await _migratePinIfNeeded();

      // Hash the PIN using Argon2id
      final hashedPin = await _hashPin(pin);

      // Store the hash
      await _storage.write(
        key: _pinStorageKey,
        value: hashedPin,
      );
    } catch (e, stackTrace) {
      // SECURITY: Log error securely without exposing PIN details
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'VaultService.savePin',
      );
      throw SecurityException('Failed to save PIN securely');
    }
  }

  /// Verifies a PIN against the stored hash
  /// SECURITY FIX: Uses constant-time comparison via Argon2 verification
  /// Returns true if PIN matches, false otherwise
  Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _storage.read(key: _pinStorageKey);

      if (storedHash == null) {
        return false;
      }

      // Verify using Argon2's built-in verification (constant-time)
      // argon2Verify() parses the PHC encoded string and verifies the password
      return argon2Verify(storedHash, utf8.encode(pin));
    } catch (e, stackTrace) {
      // SECURITY: Log error securely without exposing PIN details
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'VaultService.verifyPin',
      );
      // If verification fails for any reason, return false (safer than throwing)
      return false;
    }
  }

  /// Retrieves the stored PIN hash (for migration purposes only)
  /// WARNING: This returns the hash, not the plaintext PIN
  /// Use verifyPin() for authentication instead
  @Deprecated('Use verifyPin() for authentication')
  Future<String?> getPin() async {
    try {
      return await _storage.read(key: _pinStorageKey);
    } catch (e, stackTrace) {
      // SECURITY: Log error securely
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'VaultService.getPin',
      );
      throw StorageException('Failed to retrieve PIN hash');
    }
  }

  /// Migrates legacy plaintext PIN to hashed version
  /// SECURITY: Automatically called during savePin() to upgrade old installs
  Future<void> _migratePinIfNeeded() async {
    try {
      final legacyPin = await _storage.read(key: _legacyPinKey);

      if (legacyPin != null) {
        // Hash the legacy PIN
        final hashedPin = await _hashPin(legacyPin);

        // Store hashed version
        await _storage.write(key: _pinStorageKey, value: hashedPin);

        // Delete legacy plaintext PIN
        await _storage.delete(key: _legacyPinKey);
      }
    } catch (e) {
      // Non-critical error - migration is best-effort
      // Silently continue if migration fails
    }
  }

  /// Deletes the stored PIN and salt
  /// SECURITY: Also removes the salt to ensure complete cleanup
  Future<void> deletePin() async {
    try {
      await _storage.delete(key: _pinStorageKey);
      await _storage.delete(key: _pinSaltKey);
      await _storage.delete(key: _legacyPinKey); // Clean up legacy if exists
    } catch (e, stackTrace) {
      // SECURITY: Log error securely
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'VaultService.deletePin',
      );
      throw StorageException('Failed to delete PIN');
    }
  }

  /// Checks if a PIN is currently stored
  Future<bool> hasPin() async {
    try {
      final pin = await _storage.read(key: _pinStorageKey);
      return pin != null && pin.isNotEmpty;
    } catch (e, stackTrace) {
      // SECURITY: Log error securely
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'VaultService.hasPin',
      );
      return false;
    }
  }

  /// Deletes the stored private key (disconnect/logout)
  /// This permanently removes the account from the device
  Future<void> deletePrivateKey() async {
    try {
      await _storage.delete(key: _privateKeyStorageKey);
      await _storage.delete(key: _addressStorageKey);
    } catch (e, stackTrace) {
      // SECURITY: Log error securely without exposing storage details
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'VaultService.deletePrivateKey',
      );
      throw StorageException('Failed to delete private key');
    }
  }

  /// Deletes all stored data
  /// Use this for a complete reset
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e, stackTrace) {
      // SECURITY: Log error securely
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'VaultService.deleteAll',
      );
      throw StorageException('Failed to delete all data');
    }
  }

  /// Generates a cryptographically secure session key for in-memory encryption
  /// SECURITY FIX: Uses Random.secure() instead of DateTime-based generation
  /// Returns a random 32-byte hex string (64 hex characters)
  String generateSessionKey() {
    // Use cryptographically secure random number generator
    final random = Random.secure();
    final bytes = Uint8List(32); // 32 bytes = 256 bits of entropy

    // Fill with secure random bytes
    for (int i = 0; i < 32; i++) {
      bytes[i] = random.nextInt(256);
    }

    // Convert to hex string (64 characters)
    return HEX.encode(bytes);
  }
}
