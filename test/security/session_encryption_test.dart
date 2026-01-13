import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idena_p2p/services/encryption_service.dart';
import 'package:idena_p2p/services/vault_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock flutter_secure_storage for testing
  const MethodChannel secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  final Map<String, String> secureStorageData = {};

  setUp(() {
    // Clear mock storage before each test
    secureStorageData.clear();

    // Mock secure storage responses
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel,
            (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'write':
          final args = methodCall.arguments as Map;
          secureStorageData[args['key']] = args['value'];
          return null;
        case 'read':
          final args = methodCall.arguments as Map;
          return secureStorageData[args['key']];
        case 'delete':
          final args = methodCall.arguments as Map;
          secureStorageData.remove(args['key']);
          return null;
        case 'deleteAll':
          secureStorageData.clear();
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    secureStorageData.clear();
  });

  group('Session Encryption Tests', () {
    late VaultService vaultService;
    late EncryptionService encryptionService;

    setUp(() {
      vaultService = VaultService();
      encryptionService = EncryptionService(vaultService: vaultService);
    });

    test('initializeSession creates active session', () async {
      expect(encryptionService.isSessionActive, false);

      await encryptionService.initializeSession();

      expect(encryptionService.isSessionActive, true);
    });

    test('encrypt/decrypt round trip works correctly', () async {
      const plaintext = 'test private key: 0x1234567890abcdef';

      await encryptionService.initializeSession();

      // Encrypt
      final encrypted = await encryptionService.encrypt(plaintext);

      // Should not be plaintext
      expect(encrypted, isNot(equals(plaintext)));
      expect(encrypted.length, greaterThan(plaintext.length),
          reason: 'Encrypted data should include nonce and MAC');

      // Decrypt
      final decrypted = await encryptionService.decrypt(encrypted);

      expect(decrypted, equals(plaintext));
    });

    test('encrypt produces different ciphertexts for same plaintext', () async {
      const plaintext = 'private_key_data';

      await encryptionService.initializeSession();

      // Encrypt same plaintext twice
      final encrypted1 = await encryptionService.encrypt(plaintext);
      final encrypted2 = await encryptionService.encrypt(plaintext);

      // Should produce different ciphertexts (different nonces)
      expect(encrypted1, isNot(equals(encrypted2)),
          reason:
              'Each encryption should use a unique nonce, producing different ciphertexts');

      // Both should decrypt to same plaintext
      final decrypted1 = await encryptionService.decrypt(encrypted1);
      final decrypted2 = await encryptionService.decrypt(encrypted2);

      expect(decrypted1, equals(plaintext));
      expect(decrypted2, equals(plaintext));
    });

    test('decrypt fails without active session', () async {
      const plaintext = 'test data';

      // Initialize session and encrypt
      await encryptionService.initializeSession();
      final encrypted = await encryptionService.encrypt(plaintext);

      // Clear session
      encryptionService.clearSession();

      // Decrypt should fail
      expect(
        () async => await encryptionService.decrypt(encrypted),
        throwsA(isA<StateError>()),
      );
    });

    test('encrypt fails without active session', () async {
      expect(
        () async => await encryptionService.encrypt('test'),
        throwsA(isA<StateError>()),
      );
    });

    test('clearSession deactivates session', () async {
      await encryptionService.initializeSession();
      expect(encryptionService.isSessionActive, true);

      encryptionService.clearSession();

      expect(encryptionService.isSessionActive, false);
    });

    test('handles Unicode and special characters', () async {
      const plaintext = '🔐 Private Key: 你好世界 @#\$%^&*()';

      await encryptionService.initializeSession();

      final encrypted = await encryptionService.encrypt(plaintext);
      final decrypted = await encryptionService.decrypt(encrypted);

      expect(decrypted, equals(plaintext));
    });

    test('handles empty string', () async {
      const plaintext = '';

      await encryptionService.initializeSession();

      final encrypted = await encryptionService.encrypt(plaintext);
      final decrypted = await encryptionService.decrypt(encrypted);

      expect(decrypted, equals(plaintext));
    });

    test('handles long strings (1KB)', () async {
      final plaintext = 'A' * 1024; // 1KB of data

      await encryptionService.initializeSession();

      final encrypted = await encryptionService.encrypt(plaintext);
      final decrypted = await encryptionService.decrypt(encrypted);

      expect(decrypted, equals(plaintext));
    });

    test('tampered ciphertext fails authentication', () async {
      const plaintext = 'sensitive data';

      await encryptionService.initializeSession();
      final encrypted = await encryptionService.encrypt(plaintext);

      // Tamper with encrypted data (modify last character)
      final tamperedEncrypted = '${encrypted.substring(0, encrypted.length - 1)}X';

      // Decrypt should fail with authentication error
      expect(
        () async => await encryptionService.decrypt(tamperedEncrypted),
        throwsA(isA<Exception>()),
      );
    });

    test('different sessions produce different ciphertexts', () async {
      const plaintext = 'private_key';

      // First session
      final service1 = EncryptionService(vaultService: vaultService);
      await service1.initializeSession();
      final encrypted1 = await service1.encrypt(plaintext);

      // Second session (different key)
      final service2 = EncryptionService(vaultService: vaultService);
      await service2.initializeSession();
      final encrypted2 = await service2.encrypt(plaintext);

      // Should produce different ciphertexts (different session keys)
      expect(encrypted1, isNot(equals(encrypted2)));

      // Each service can decrypt its own ciphertext
      final decrypted1 = await service1.decrypt(encrypted1);
      final decrypted2 = await service2.decrypt(encrypted2);

      expect(decrypted1, equals(plaintext));
      expect(decrypted2, equals(plaintext));

      // Cross-decryption should fail (wrong key)
      expect(
        () async => await service1.decrypt(encrypted2),
        throwsA(isA<Exception>()),
      );
    });

    test('session survives multiple encrypt/decrypt cycles', () async {
      await encryptionService.initializeSession();

      for (int i = 0; i < 10; i++) {
        final plaintext = 'message_$i';
        final encrypted = await encryptionService.encrypt(plaintext);
        final decrypted = await encryptionService.decrypt(encrypted);
        expect(decrypted, equals(plaintext));
      }
    });

    test('performance - encryption completes within 50ms', () async {
      const plaintext = 'test private key data';

      await encryptionService.initializeSession();

      final stopwatch = Stopwatch()..start();
      await encryptionService.encrypt(plaintext);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Encryption should be fast for good UX',
      );
    });

    test('performance - decryption completes within 50ms', () async {
      const plaintext = 'test private key data';

      await encryptionService.initializeSession();
      final encrypted = await encryptionService.encrypt(plaintext);

      final stopwatch = Stopwatch()..start();
      await encryptionService.decrypt(encrypted);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Decryption should be fast for good UX',
      );
    });

    test('encrypted data is base64 encoded', () async {
      const plaintext = 'test';

      await encryptionService.initializeSession();
      final encrypted = await encryptionService.encrypt(plaintext);

      // Should only contain base64 characters
      expect(
        RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(encrypted),
        true,
        reason: 'Encrypted data should be valid base64',
      );
    });

    test('encrypted data contains nonce, MAC, and ciphertext', () async {
      const plaintext = 'test';

      await encryptionService.initializeSession();
      final encrypted = await encryptionService.encrypt(plaintext);

      // Decode base64 to get raw bytes
      final bytes = encrypted.length;

      // Base64 encoding adds overhead, but should still contain:
      // 12-byte nonce + 16-byte MAC + ciphertext
      // Minimum: 28 bytes + ciphertext (4 bytes for 'test')
      // Base64: (32 bytes) * 4/3 = ~43 chars minimum
      expect(
        bytes,
        greaterThanOrEqualTo(40),
        reason:
            'Encrypted data should contain nonce (12 bytes) + MAC (16 bytes) + ciphertext',
      );
    });
  });
}
