import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idena_p2p/services/vault_service.dart';
import 'package:idena_p2p/services/auth_service.dart';
import 'package:idena_p2p/services/prefs_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock flutter_secure_storage for testing
  const MethodChannel secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  final Map<String, String> secureStorageData = {};

  setUp(() async {
    // Clear mock storage before each test
    secureStorageData.clear();

    // Mock shared_preferences for testing
    SharedPreferences.setMockInitialValues({});

    // Mock secure storage responses
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (MethodCall methodCall) async {
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

  group('PIN Hashing Security Tests', () {
    late VaultService vaultService;

    setUp(() {
      vaultService = VaultService();
    });

    test('savePin stores hashed PIN, not plaintext', () async {
      const pin = '1234';

      await vaultService.savePin(pin);

      // Get the stored value
      final stored = secureStorageData['idena_pin'];

      // Should NOT be plaintext
      expect(stored, isNot(equals(pin)));

      // Should be an Argon2 encoded string (starts with $argon2)
      expect(stored, isNotNull);
      expect(stored!.startsWith(r'$argon2'), true,
          reason: 'PIN should be hashed with Argon2');

      // Should contain salt and hash parameters
      // PHC format: $argon2id$v=19$m=65536,t=3,p=4$<salt>$<hash>
      expect(stored.contains(r'$v='), true, reason: 'Should contain version');
      expect(stored.contains('m='), true, reason: 'Should contain memory parameter');
      expect(stored.contains('t='), true, reason: 'Should contain iterations parameter');
      expect(stored.contains('p='), true, reason: 'Should contain parallelism parameter');
    });

    test('same PIN produces verifiable hash (deterministic with salt)', () async {
      const pin = '5678';

      // Save PIN
      await vaultService.savePin(pin);

      // Verify the same PIN multiple times
      final result1 = await vaultService.verifyPin(pin);
      final result2 = await vaultService.verifyPin(pin);
      final result3 = await vaultService.verifyPin(pin);

      expect(result1, true, reason: 'First verification should succeed');
      expect(result2, true, reason: 'Second verification should succeed');
      expect(result3, true, reason: 'Third verification should succeed');
    });

    test('different PINs produce different hashes', () async {
      const pin1 = '1234';
      const pin2 = '5678';
      const pin3 = '9999';

      // Save first PIN
      await vaultService.savePin(pin1);
      final hash1 = secureStorageData['idena_pin']!;

      // Clear and save second PIN (need fresh salt)
      secureStorageData.clear();
      await vaultService.savePin(pin2);
      final hash2 = secureStorageData['idena_pin']!;

      // Clear and save third PIN
      secureStorageData.clear();
      await vaultService.savePin(pin3);
      final hash3 = secureStorageData['idena_pin']!;

      // All hashes should be different
      expect(hash1, isNot(equals(hash2)));
      expect(hash2, isNot(equals(hash3)));
      expect(hash1, isNot(equals(hash3)));
    });

    test('verifyPin succeeds with correct PIN', () async {
      const pin = '4321';

      await vaultService.savePin(pin);

      final result = await vaultService.verifyPin(pin);

      expect(result, true, reason: 'Correct PIN should verify successfully');
    });

    test('verifyPin fails with incorrect PIN', () async {
      const correctPin = '1234';
      const incorrectPin = '9999';

      await vaultService.savePin(correctPin);

      final result = await vaultService.verifyPin(incorrectPin);

      expect(result, false, reason: 'Incorrect PIN should fail verification');
    });

    test('verifyPin handles common wrong PINs', () async {
      const correctPin = '1234';

      await vaultService.savePin(correctPin);

      // Test various incorrect PINs
      final wrongPins = ['0000', '1111', '1235', '4321', '9999', '', '123'];

      for (final wrongPin in wrongPins) {
        final result = await vaultService.verifyPin(wrongPin);
        expect(result, false,
            reason: 'Wrong PIN "$wrongPin" should not verify against "1234"');
      }
    });

    test('salt is generated and persisted', () async {
      const pin = '1234';

      await vaultService.savePin(pin);

      // Check that salt was generated
      final salt = secureStorageData['idena_pin_salt'];

      expect(salt, isNotNull, reason: 'Salt should be generated');
      expect(salt!.length, 32, reason: 'Salt should be 16 bytes (32 hex chars)');

      // Verify salt is valid hex
      expect(
        RegExp(r'^[0-9a-f]{32}$').hasMatch(salt),
        true,
        reason: 'Salt should be valid lowercase hex',
      );
    });

    test('same salt is reused for multiple PIN saves', () async {
      const pin1 = '1234';
      const pin2 = '5678';

      // Save first PIN
      await vaultService.savePin(pin1);
      final salt1 = secureStorageData['idena_pin_salt'];

      // Save second PIN (without clearing salt)
      await vaultService.savePin(pin2);
      final salt2 = secureStorageData['idena_pin_salt'];

      expect(salt1, equals(salt2),
          reason: 'Salt should be reused across PIN changes');
    });

    test('timing attack resistance - constant time verification', () async {
      const correctPin = '1234';

      await vaultService.savePin(correctPin);

      // Measure verification time for correct PIN
      final correctTimings = <int>[];
      for (int i = 0; i < 50; i++) {
        final start = DateTime.now().microsecondsSinceEpoch;
        await vaultService.verifyPin(correctPin);
        final end = DateTime.now().microsecondsSinceEpoch;
        correctTimings.add(end - start);
      }

      // Measure verification time for incorrect PIN
      final incorrectTimings = <int>[];
      for (int i = 0; i < 50; i++) {
        final start = DateTime.now().microsecondsSinceEpoch;
        await vaultService.verifyPin('9999');
        final end = DateTime.now().microsecondsSinceEpoch;
        incorrectTimings.add(end - start);
      }

      // Calculate averages
      final correctAvg =
          correctTimings.reduce((a, b) => a + b) / correctTimings.length;
      final incorrectAvg =
          incorrectTimings.reduce((a, b) => a + b) / incorrectTimings.length;

      // Difference should be small (< 40% variance)
      // Argon2 is designed to take similar time regardless of result
      // Note: 40% accounts for system load variability while still detecting timing attacks
      final difference = (correctAvg - incorrectAvg).abs();
      final variance = difference / correctAvg;

      expect(
        variance,
        lessThan(0.4),
        reason:
            'Verification time should be constant (< 40% variance) to resist timing attacks',
      );
    });

    test('verifyPin returns false for null/missing PIN hash', () async {
      // Don't save any PIN
      final result = await vaultService.verifyPin('1234');

      expect(result, false,
          reason: 'Verification should fail when no PIN is stored');
    });

    test('hasPin returns correct status', () async {
      // Initially no PIN
      expect(await vaultService.hasPin(), false);

      // After saving PIN
      await vaultService.savePin('1234');
      expect(await vaultService.hasPin(), true);

      // After deleting PIN
      await vaultService.deletePin();
      expect(await vaultService.hasPin(), false);
    });

    test('deletePin removes hash, salt, and legacy PIN', () async {
      await vaultService.savePin('1234');

      // Verify PIN and salt exist
      expect(secureStorageData['idena_pin'], isNotNull);
      expect(secureStorageData['idena_pin_salt'], isNotNull);

      await vaultService.deletePin();

      // All PIN-related data should be removed
      expect(secureStorageData['idena_pin'], isNull);
      expect(secureStorageData['idena_pin_salt'], isNull);
      expect(secureStorageData['idena_pin_legacy'], isNull);
    });

    test('performance - PIN hashing completes within 1500ms', () async {
      const pin = '1234';

      final stopwatch = Stopwatch()..start();
      await vaultService.savePin(pin);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1500),
        reason: 'PIN hashing should complete within 1500ms (Argon2id with 64MB is secure but slower)',
      );
    });

    test('performance - PIN verification completes within 1500ms', () async {
      const pin = '1234';
      await vaultService.savePin(pin);

      final stopwatch = Stopwatch()..start();
      await vaultService.verifyPin(pin);
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1500),
        reason: 'PIN verification should complete within 1500ms (Argon2id verification)',
      );
    });

    test('handles various PIN formats', () async {
      final testPins = [
        '0000', // All zeros
        '9999', // All nines
        '1234', // Sequential
        '4321', // Reverse sequential
        '1111', // Repeating
        '0123', // Leading zero
        '8642', // Even numbers
        '1357', // Odd numbers
      ];

      for (final pin in testPins) {
        secureStorageData.clear();
        await vaultService.savePin(pin);

        final verifyCorrect = await vaultService.verifyPin(pin);
        expect(verifyCorrect, true, reason: 'PIN "$pin" should verify correctly');

        final verifyIncorrect = await vaultService.verifyPin('0000');
        if (pin != '0000') {
          expect(verifyIncorrect, false,
              reason: 'Wrong PIN should not verify against "$pin"');
        }
      }
    });

    test('hash format follows Argon2 specification', () async {
      await vaultService.savePin('1234');

      final hash = secureStorageData['idena_pin']!;

      // Argon2 encoded format: $argon2id$v=19$m=65536,t=3,p=4$salt$hash
      final parts = hash.split(r'$');

      expect(parts.length, greaterThanOrEqualTo(5),
          reason: 'Hash should have multiple parts');
      expect(parts[1], equals('argon2id'), reason: 'Should use Argon2id variant');
      expect(parts[2], equals('v=19'), reason: 'Should use version 19');
      expect(parts[3], contains('m='), reason: 'Should contain memory parameter');
      expect(parts[3], contains('t='), reason: 'Should contain iterations parameter');
      expect(parts[3], contains('p='), reason: 'Should contain parallelism parameter');
    });

    test('different instances use same salt', () async {
      // First instance saves PIN
      final vault1 = VaultService();
      await vault1.savePin('1234');
      final salt1 = secureStorageData['idena_pin_salt'];

      // Second instance verifies PIN (should reuse salt)
      final vault2 = VaultService();
      final result = await vault2.verifyPin('1234');

      expect(result, true, reason: 'Different instance should verify successfully');

      // Save new PIN with second instance
      await vault2.savePin('5678');
      final salt2 = secureStorageData['idena_pin_salt'];

      expect(salt1, equals(salt2), reason: 'Salt should persist across instances');
    });
  });

  group('AuthService PIN Validation Tests', () {
    late VaultService vaultService;
    late PrefsService prefsService;
    late AuthService authService;

    setUp(() {
      vaultService = VaultService();
      prefsService = PrefsService();
      authService = AuthService(
        vaultService: vaultService,
        prefsService: prefsService,
      );
    });

    test('setPin uses secure hashing', () async {
      await authService.setPin('1234');

      // Verify PIN was hashed (not stored as plaintext)
      final stored = secureStorageData['idena_pin'];
      expect(stored, isNot(equals('1234')));
      expect(stored!.startsWith(r'$argon2'), true);
    });

    test('validatePin uses secure verification', () async {
      await authService.setPin('1234');

      final correctResult = await authService.validatePin('1234');
      expect(correctResult, true);

      final incorrectResult = await authService.validatePin('9999');
      expect(incorrectResult, false);
    });

    test('validatePin handles lockout progression', () async {
      await authService.setPin('1234');

      // Make 5 failed attempts (triggers 1-minute lockout)
      for (int i = 0; i < 5; i++) {
        await authService.validatePin('9999');
      }

      final authState = await authService.getAuthState();
      expect(authState.isLockedOut, true);
    });

    test('validatePin resets failed attempts on success', () async {
      await authService.setPin('1234');

      // Make some failed attempts
      await authService.validatePin('9999');
      await authService.validatePin('9999');

      int attempts = await authService.getFailedAttempts();
      expect(attempts, 2);

      // Correct PIN should reset attempts
      await authService.validatePin('1234');

      attempts = await authService.getFailedAttempts();
      expect(attempts, 0);
    });

    test('deletePin cleans up all PIN-related data', () async {
      await authService.setPin('1234');
      await authService.validatePin('9999'); // Create failed attempt

      await authService.deletePin();

      // PIN should be gone
      expect(await authService.hasPin(), false);

      // Failed attempts should be reset
      final attempts = await authService.getFailedAttempts();
      expect(attempts, 0);
    });
  });

  group('PIN Migration Tests', () {
    late VaultService vaultService;

    setUp(() {
      vaultService = VaultService();
    });

    test('migrates legacy plaintext PIN to hashed version', () async {
      // Simulate legacy plaintext PIN
      secureStorageData['idena_pin_legacy'] = '1234';

      // Save new PIN (triggers migration)
      await vaultService.savePin('5678');

      // Legacy PIN should be deleted
      expect(secureStorageData['idena_pin_legacy'], isNull);

      // New PIN should be hashed
      final hash = secureStorageData['idena_pin'];
      expect(hash, isNotNull);
      expect(hash!.startsWith(r'$argon2'), true);
    });

    test('migration is silent if no legacy PIN exists', () async {
      // No legacy PIN
      await vaultService.savePin('1234');

      // Should work normally
      final result = await vaultService.verifyPin('1234');
      expect(result, true);
    });
  });
}
