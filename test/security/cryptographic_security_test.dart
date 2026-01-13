import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:idena_p2p/services/vault_service.dart';

void main() {
  group('Session Key Security Tests', () {
    late VaultService vaultService;

    setUp(() {
      vaultService = VaultService();
    });

    test('generates 64-character hex string (32 bytes)', () {
      final key = vaultService.generateSessionKey();

      // Should be exactly 64 characters (32 bytes in hex)
      expect(key.length, 64, reason: 'Session key must be 64 hex characters');

      // Should only contain valid hex characters
      expect(
        RegExp(r'^[0-9a-f]{64}$').hasMatch(key),
        true,
        reason: 'Session key must contain only lowercase hex characters',
      );
    });

    test('generates unique keys across 100 invocations', () {
      final keys = <String>{};

      // Generate 100 keys
      for (int i = 0; i < 100; i++) {
        keys.add(vaultService.generateSessionKey());
      }

      // All keys should be unique
      expect(
        keys.length,
        100,
        reason: 'All 100 session keys should be unique',
      );
    });

    test('generates keys with diverse hex character distribution', () {
      final key = vaultService.generateSessionKey();

      // Check that the key uses diverse hex characters (not just '0' or a single char)
      final chars = key.split('').toSet();

      // Should use at least 10 different hex characters out of 16 possible
      expect(
        chars.length,
        greaterThanOrEqualTo(10),
        reason: 'Key should use diverse hex characters for good entropy',
      );
    });

    test('statistical randomness check - chi-square test', () {
      // Generate multiple keys and check character distribution
      final keys = List.generate(1000, (_) => vaultService.generateSessionKey());

      // Count occurrences of each hex digit
      final charCounts = <String, int>{
        '0': 0,
        '1': 0,
        '2': 0,
        '3': 0,
        '4': 0,
        '5': 0,
        '6': 0,
        '7': 0,
        '8': 0,
        '9': 0,
        'a': 0,
        'b': 0,
        'c': 0,
        'd': 0,
        'e': 0,
        'f': 0,
      };

      for (final key in keys) {
        for (final char in key.split('')) {
          charCounts[char] = (charCounts[char] ?? 0) + 1;
        }
      }

      // Expected: ~4000 occurrences per hex digit (64 chars * 1000 keys / 16 digits)
      const expected = (64 * 1000) / 16;
      const tolerance = expected * 0.15; // 15% tolerance

      // Check each hex digit is within tolerance
      for (final entry in charCounts.entries) {
        expect(
          entry.value,
          greaterThan(expected - tolerance),
          reason: 'Hex digit ${entry.key} appears too infrequently',
        );
        expect(
          entry.value,
          lessThan(expected + tolerance),
          reason: 'Hex digit ${entry.key} appears too frequently',
        );
      }
    });

    test('keys are not predictable from previous keys', () {
      // Generate sequential keys
      final key1 = vaultService.generateSessionKey();
      final key2 = vaultService.generateSessionKey();
      final key3 = vaultService.generateSessionKey();

      // Calculate how many characters differ
      int differences = 0;
      for (int i = 0; i < 64; i++) {
        if (key1[i] != key2[i]) differences++;
      }

      // At least 50% of characters should differ (not just incrementing)
      expect(
        differences,
        greaterThanOrEqualTo(32),
        reason: 'Sequential keys should differ significantly',
      );

      // Verify keys are all different
      expect(key1, isNot(equals(key2)));
      expect(key2, isNot(equals(key3)));
      expect(key1, isNot(equals(key3)));
    });

    test('keys have sufficient entropy - no repeating patterns', () {
      final key = vaultService.generateSessionKey();

      // Check for obvious patterns (e.g., "0000", "1111", "abab")
      // Count consecutive identical characters
      int maxConsecutive = 1;
      int currentConsecutive = 1;

      for (int i = 1; i < key.length; i++) {
        if (key[i] == key[i - 1]) {
          currentConsecutive++;
          maxConsecutive = max(maxConsecutive, currentConsecutive);
        } else {
          currentConsecutive = 1;
        }
      }

      // No more than 4 consecutive identical characters
      expect(
        maxConsecutive,
        lessThanOrEqualTo(4),
        reason: 'Key should not have long runs of identical characters',
      );
    });

    test('performance - generates key in reasonable time', () {
      final stopwatch = Stopwatch()..start();

      // Generate 100 keys
      for (int i = 0; i < 100; i++) {
        vaultService.generateSessionKey();
      }

      stopwatch.stop();

      // Should generate 100 keys in less than 100ms (1ms per key)
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'Key generation should be fast',
      );
    });

    test('no timestamp-based patterns', () {
      // The old implementation used DateTime.now().microsecondsSinceEpoch
      // which created predictable patterns. Verify the new implementation doesn't.

      // Generate keys quickly in succession
      final keys = <String>[];
      for (int i = 0; i < 10; i++) {
        keys.add(vaultService.generateSessionKey());
      }

      // Check that keys don't have incrementing patterns
      // (in old implementation, consecutive keys would have sequential patterns)
      for (int i = 1; i < keys.length; i++) {
        final key1 = keys[i - 1];
        final key2 = keys[i];

        // Count how many positions have values that differ by exactly 1
        int incrementByOne = 0;
        for (int j = 0; j < 64; j++) {
          final val1 = int.parse(key1[j], radix: 16);
          final val2 = int.parse(key2[j], radix: 16);
          if ((val2 - val1).abs() == 1) {
            incrementByOne++;
          }
        }

        // Should not have more than 15 positions incrementing by 1
        // (random keys would have ~4 on average: 64 positions * 1/16 probability)
        // Old implementation had 30-40+, so 15 is a safe threshold
        expect(
          incrementByOne,
          lessThan(15),
          reason: 'Keys should not show timestamp-based incrementing patterns',
        );
      }
    });

    test('uses full byte range 0-255', () {
      // Generate multiple keys and verify we see both high and low byte values
      final keys = List.generate(100, (_) => vaultService.generateSessionKey());

      bool hasLowByte = false; // Values 0x00-0x0F
      bool hasHighByte = false; // Values 0xF0-0xFF

      for (final key in keys) {
        for (int i = 0; i < key.length; i += 2) {
          final byte = int.parse(key.substring(i, i + 2), radix: 16);
          if (byte <= 0x0F) hasLowByte = true;
          if (byte >= 0xF0) hasHighByte = true;

          if (hasLowByte && hasHighByte) break;
        }
        if (hasLowByte && hasHighByte) break;
      }

      expect(hasLowByte, true, reason: 'Should generate low byte values');
      expect(hasHighByte, true, reason: 'Should generate high byte values');
    });
  });
}
