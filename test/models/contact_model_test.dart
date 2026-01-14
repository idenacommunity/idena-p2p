import 'package:flutter_test/flutter_test.dart';
import 'package:idena_p2p/models/contact.dart';
import 'package:idena_p2p/models/idena_account.dart';

void main() {
  group('Contact Model Tests', () {
    test('Contact - Create from IdenaAccount', () {
      final account = IdenaAccount(
        address: '0x1234567890123456789012345678901234567890',
        balance: 100.0,
        stake: 50.0,
        identityStatus: 'Human',
        age: 25,
      );

      final contact = Contact.fromAccount(account, nickname: 'Test User');

      expect(contact.address, account.address);
      expect(contact.nickname, 'Test User');
      expect(contact.state, 'Human');
      expect(contact.age, 25);
      expect(contact.stake, 50.0);
      expect(contact.isVerifiedHuman, true);
    });

    test('Contact - Display name returns nickname when available', () {
      final contact = Contact(
        address: '0x1234567890123456789012345678901234567890',
        nickname: 'Alice',
        state: 'Human',
        age: 10,
        stake: 100.0,
        isVerifiedHuman: true,
        addedAt: DateTime.now(),
      );

      expect(contact.displayName, 'Alice');
    });

    test('Contact - Display name returns shortened address when no nickname', () {
      final contact = Contact(
        address: '0x1234567890123456789012345678901234567890',
        state: 'Human',
        age: 10,
        stake: 100.0,
        isVerifiedHuman: true,
        addedAt: DateTime.now(),
      );

      expect(contact.displayName, '0x1234...7890');
    });

    test('Contact - Identity badges are correct', () {
      expect(
        Contact(
          address: '0x1234567890123456789012345678901234567890',
          state: 'Human',
          age: 10,
          stake: 100.0,
          isVerifiedHuman: true,
          addedAt: DateTime.now(),
        ).identityBadge,
        '✅',
      );

      expect(
        Contact(
          address: '0x1234567890123456789012345678901234567890',
          state: 'Verified',
          age: 10,
          stake: 100.0,
          isVerifiedHuman: true,
          addedAt: DateTime.now(),
        ).identityBadge,
        '⭐',
      );

      expect(
        Contact(
          address: '0x1234567890123456789012345678901234567890',
          state: 'Newbie',
          age: 2,
          stake: 10.0,
          isVerifiedHuman: false,
          addedAt: DateTime.now(),
        ).identityBadge,
        '🆕',
      );

      expect(
        Contact(
          address: '0x1234567890123456789012345678901234567890',
          state: 'Suspended',
          age: 5,
          stake: 50.0,
          isVerifiedHuman: false,
          addedAt: DateTime.now(),
        ).identityBadge,
        '⚠️',
      );

      expect(
        Contact(
          address: '0x1234567890123456789012345678901234567890',
          state: 'Zombie',
          age: 5,
          stake: 50.0,
          isVerifiedHuman: false,
          addedAt: DateTime.now(),
        ).identityBadge,
        '❌',
      );
    });

    test('Contact - Trust level calculation', () {
      final longStanding = Contact(
        address: '0x1234567890123456789012345678901234567890',
        state: 'Human',
        age: 60,
        stake: 1000.0,
        isVerifiedHuman: true,
        addedAt: DateTime.now(),
      );
      expect(longStanding.trustLevel, '🌟🌟🌟🌟🌟 Long-standing human');

      final verified = Contact(
        address: '0x1234567890123456789012345678901234567890',
        state: 'Verified',
        age: 15,
        stake: 500.0,
        isVerifiedHuman: true,
        addedAt: DateTime.now(),
      );
      expect(verified.trustLevel, '⭐⭐⭐ Verified human');

      final established = Contact(
        address: '0x1234567890123456789012345678901234567890',
        state: 'Human',
        age: 5,
        stake: 200.0,
        isVerifiedHuman: true,
        addedAt: DateTime.now(),
      );
      expect(established.trustLevel, '⭐⭐ Established identity');

      final newIdentity = Contact(
        address: '0x1234567890123456789012345678901234567890',
        state: 'Newbie',
        age: 2,
        stake: 50.0,
        isVerifiedHuman: false,
        addedAt: DateTime.now(),
      );
      expect(newIdentity.trustLevel, '🆕 New identity');
    });

    test('Contact - Needs verification check', () {
      final recentlyVerified = Contact(
        address: '0x1234567890123456789012345678901234567890',
        state: 'Human',
        age: 10,
        stake: 100.0,
        isVerifiedHuman: true,
        addedAt: DateTime.now(),
        lastVerified: DateTime.now(),
      );
      expect(recentlyVerified.needsVerification, false);

      final staleVerification = Contact(
        address: '0x1234567890123456789012345678901234567890',
        state: 'Human',
        age: 10,
        stake: 100.0,
        isVerifiedHuman: true,
        addedAt: DateTime.now(),
        lastVerified: DateTime.now().subtract(const Duration(hours: 25)),
      );
      expect(staleVerification.needsVerification, true);

      final neverVerified = Contact(
        address: '0x1234567890123456789012345678901234567890',
        state: 'Human',
        age: 10,
        stake: 100.0,
        isVerifiedHuman: true,
        addedAt: DateTime.now(),
        lastVerified: null,
      );
      expect(neverVerified.needsVerification, true);
    });

    test('Contact - JSON serialization', () {
      final contact = Contact(
        address: '0x1234567890123456789012345678901234567890',
        nickname: 'Test User',
        state: 'Human',
        age: 10,
        stake: 100.0,
        isVerifiedHuman: true,
        addedAt: DateTime(2024, 1, 1),
        lastVerified: DateTime(2024, 1, 2),
        notes: 'Test notes',
        isBlocked: false,
      );

      final json = contact.toJson();
      final restored = Contact.fromJson(json);

      expect(restored.address, contact.address);
      expect(restored.nickname, contact.nickname);
      expect(restored.state, contact.state);
      expect(restored.age, contact.age);
      expect(restored.stake, contact.stake);
      expect(restored.isVerifiedHuman, contact.isVerifiedHuman);
      expect(restored.notes, contact.notes);
      expect(restored.isBlocked, contact.isBlocked);
    });

    test('Contact - CopyWith updates fields correctly', () {
      final original = Contact(
        address: '0x1234567890123456789012345678901234567890',
        state: 'Newbie',
        age: 1,
        stake: 10.0,
        isVerifiedHuman: false,
        addedAt: DateTime.now(),
      );

      final updated = original.copyWith(
        nickname: 'Updated Name',
        state: 'Human',
        age: 10,
        isVerifiedHuman: true,
      );

      expect(updated.address, original.address);
      expect(updated.nickname, 'Updated Name');
      expect(updated.state, 'Human');
      expect(updated.age, 10);
      expect(updated.isVerifiedHuman, true);
    });

    test('Contact - Equality based on address', () {
      final contact1 = Contact(
        address: '0x1234567890123456789012345678901234567890',
        state: 'Human',
        age: 10,
        stake: 100.0,
        isVerifiedHuman: true,
        addedAt: DateTime.now(),
      );

      final contact2 = Contact(
        address: '0x1234567890123456789012345678901234567890',
        nickname: 'Different Name',
        state: 'Verified',
        age: 20,
        stake: 200.0,
        isVerifiedHuman: true,
        addedAt: DateTime.now(),
      );

      final contact3 = Contact(
        address: '0xABCDEF1234567890123456789012345678901234',
        state: 'Human',
        age: 10,
        stake: 100.0,
        isVerifiedHuman: true,
        addedAt: DateTime.now(),
      );

      expect(contact1 == contact2, true);
      expect(contact1 == contact3, false);
      expect(contact1.hashCode, contact2.hashCode);
    });
  });

  group('IdenaAccount Model Tests', () {
    test('IdenaAccount - Creates with correct identity status', () {
      final account = IdenaAccount(
        address: '0x1234567890123456789012345678901234567890',
        balance: 100.0,
        stake: 50.0,
        identityStatus: 'Human',
        age: 25,
      );

      expect(account.address, '0x1234567890123456789012345678901234567890');
      expect(account.balance, 100.0);
      expect(account.stake, 50.0);
      expect(account.identityStatus, 'Human');
      expect(account.age, 25);
      expect(account.totalBalance, 150.0);
    });

    test('IdenaAccount - Validates identity correctly', () {
      expect(
        IdenaAccount(
          address: '0x1234567890123456789012345678901234567890',
          identityStatus: 'Human',
        ).isValidated,
        true,
      );

      expect(
        IdenaAccount(
          address: '0x1234567890123456789012345678901234567890',
          identityStatus: 'Undefined',
        ).isValidated,
        false,
      );

      expect(
        IdenaAccount(
          address: '0x1234567890123456789012345678901234567890',
          identityStatus: 'Killed',
        ).isValidated,
        false,
      );
    });
  });
}
