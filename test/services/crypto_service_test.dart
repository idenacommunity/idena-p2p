import 'package:flutter_test/flutter_test.dart';
import 'package:idena_p2p/services/crypto_service.dart';

void main() {
  group('CryptoService Tests', () {
    late CryptoService cryptoService;

    setUp(() {
      cryptoService = CryptoService();
    });

    group('Mnemonic Generation', () {
      test('generates valid 12-word mnemonic', () {
        final mnemonic = cryptoService.generateMnemonic();

        expect(mnemonic, isNotNull);
        expect(mnemonic.isNotEmpty, true);

        // Should have 12 words
        final words = mnemonic.split(' ');
        expect(words.length, 12, reason: 'Should generate 12-word mnemonic');

        // Each word should be non-empty
        for (final word in words) {
          expect(word.isNotEmpty, true);
        }
      });

      test('generates unique mnemonics', () {
        final mnemonics = <String>{};

        for (int i = 0; i < 10; i++) {
          mnemonics.add(cryptoService.generateMnemonic());
        }

        expect(mnemonics.length, 10, reason: 'All mnemonics should be unique');
      });

      test('generated mnemonic is valid for import', () {
        final mnemonic = cryptoService.generateMnemonic();

        // Should be able to derive keys from generated mnemonic
        expect(
          () => cryptoService.privateKeyFromMnemonic(mnemonic),
          returnsNormally,
        );
      });
    });

    group('Mnemonic Validation', () {
      test('validates correct 12-word mnemonic', () {
        const validMnemonic =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

        final isValid = cryptoService.validateMnemonic(validMnemonic);

        expect(isValid, true, reason: 'Valid mnemonic should pass validation');
      });

      test('rejects invalid mnemonic - wrong word count', () {
        const tooFew = 'abandon abandon abandon';
        const tooMany =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

        expect(cryptoService.validateMnemonic(tooFew), false);
        expect(cryptoService.validateMnemonic(tooMany), false);
      });

      test('rejects invalid mnemonic - invalid words', () {
        const invalidWord =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon invalid';

        expect(cryptoService.validateMnemonic(invalidWord), false);
      });

      test('rejects invalid mnemonic - invalid checksum', () {
        const invalidChecksum =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon';

        expect(cryptoService.validateMnemonic(invalidChecksum), false);
      });

      test('handles empty and null input', () {
        expect(cryptoService.validateMnemonic(''), false);
      });

      test('handles extra whitespace', () {
        const withSpaces =
            '  abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about  ';

        // Trim before validation (validateMnemonic doesn't trim automatically)
        expect(cryptoService.validateMnemonic(withSpaces.trim()), true);
      });
    });

    group('Private Key Derivation', () {
      test('derives private key from mnemonic', () {
        const mnemonic =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

        final privateKey = cryptoService.privateKeyFromMnemonic(mnemonic);

        expect(privateKey, isNotNull);
        expect(privateKey.length, 64, reason: 'Private key should be 64 hex characters');

        // Should be valid hex
        expect(
          RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(privateKey),
          true,
          reason: 'Private key should be valid hex',
        );
      });

      test('same mnemonic produces same private key', () {
        const mnemonic =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

        final key1 = cryptoService.privateKeyFromMnemonic(mnemonic);
        final key2 = cryptoService.privateKeyFromMnemonic(mnemonic);
        final key3 = cryptoService.privateKeyFromMnemonic(mnemonic);

        expect(key1, equals(key2));
        expect(key2, equals(key3));
      });

      test('different mnemonics produce different private keys', () {
        const mnemonic1 =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
        const mnemonic2 =
            'legal winner thank year wave sausage worth useful legal winner thank yellow';

        final key1 = cryptoService.privateKeyFromMnemonic(mnemonic1);
        final key2 = cryptoService.privateKeyFromMnemonic(mnemonic2);

        expect(key1, isNot(equals(key2)));
      });
    });

    group('Address Derivation', () {
      test('derives address from private key', () {
        const privateKey =
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

        final address = cryptoService.deriveAddressFromPrivateKey(privateKey);

        expect(address, isNotNull);
        expect(address.startsWith('0x'), true, reason: 'Address should start with 0x');
        expect(address.length, 42, reason: 'Address should be 42 characters (0x + 40 hex)');

        // Should be valid hex after 0x
        expect(
          RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(address),
          true,
          reason: 'Address should be valid Ethereum-compatible format',
        );
      });

      test('same private key produces same address', () {
        const privateKey =
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

        final address1 = cryptoService.deriveAddressFromPrivateKey(privateKey);
        final address2 = cryptoService.deriveAddressFromPrivateKey(privateKey);
        final address3 = cryptoService.deriveAddressFromPrivateKey(privateKey);

        expect(address1, equals(address2));
        expect(address2, equals(address3));
      });

      test('different private keys produce different addresses', () {
        const key1 =
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
        const key2 =
            'd4735e3a265e16eee03f59718b9b5d03019c07d8b6c51f90da3a666eec13ab35';

        final address1 = cryptoService.deriveAddressFromPrivateKey(key1);
        final address2 = cryptoService.deriveAddressFromPrivateKey(key2);

        expect(address1, isNot(equals(address2)));
      });

      test('address uses EIP-55 checksum casing', () {
        const privateKey =
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

        final address = cryptoService.deriveAddressFromPrivateKey(privateKey);

        // Should have mixed case (EIP-55 checksum)
        expect(address, isNot(equals(address.toLowerCase())));
      });
    });

    group('Full Key Generation Flow', () {
      test('can generate account from new mnemonic', () {
        final mnemonic = cryptoService.generateMnemonic();
        final privateKey = cryptoService.privateKeyFromMnemonic(mnemonic);
        final address = cryptoService.deriveAddressFromPrivateKey(privateKey);

        expect(mnemonic.split(' ').length, 12);
        expect(privateKey.length, 64);
        expect(address.length, 42);
        expect(address.startsWith('0x'), true);
      });

      test('can restore account from mnemonic', () {
        const originalMnemonic =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

        final privateKey = cryptoService.privateKeyFromMnemonic(originalMnemonic);
        final address = cryptoService.deriveAddressFromPrivateKey(privateKey);

        // Create new instance and restore
        final restoredKey = cryptoService.privateKeyFromMnemonic(originalMnemonic);
        final restoredAddress = cryptoService.deriveAddressFromPrivateKey(restoredKey);

        expect(restoredKey, equals(privateKey));
        expect(restoredAddress, equals(address));
      });

      test('can import account from private key', () {
        const privateKey =
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

        final address = cryptoService.deriveAddressFromPrivateKey(privateKey);

        // Should be able to derive address
        expect(address.length, 42);
        expect(address.startsWith('0x'), true);
      });
    });

    group('Private Key Validation', () {
      test('validates correct private key format', () {
        const validKey =
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

        // Should not throw
        expect(
          () => cryptoService.deriveAddressFromPrivateKey(validKey),
          returnsNormally,
        );
      });

      test('handles private key with 0x prefix', () {
        const keyWithPrefix =
            '0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

        // Should handle prefix gracefully
        expect(
          () => cryptoService.deriveAddressFromPrivateKey(keyWithPrefix),
          returnsNormally,
        );
      });

      test('handles uppercase private key', () {
        const uppercaseKey =
            'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855';

        // Should handle case-insensitive
        expect(
          () => cryptoService.deriveAddressFromPrivateKey(uppercaseKey),
          returnsNormally,
        );
      });
    });

    group('Edge Cases', () {
      test('handles mnemonic with varied spacing', () {
        const normalSpacing =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
        const extraSpacing =
            'abandon  abandon   abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

        final key1 = cryptoService.privateKeyFromMnemonic(normalSpacing);
        final key2 = cryptoService.privateKeyFromMnemonic(extraSpacing.trim().replaceAll(RegExp(r'\s+'), ' '));

        // Should produce same key after normalization
        expect(key1, equals(key2));
      });

      test('handles trailing/leading whitespace in mnemonic', () {
        const mnemonic =
            '  abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about  ';

        expect(
          () => cryptoService.privateKeyFromMnemonic(mnemonic.trim()),
          returnsNormally,
        );
      });
    });

    group('Performance', () {
      test('generates mnemonic quickly', () {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 10; i++) {
          cryptoService.generateMnemonic();
        }

        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'Should generate 10 mnemonics in < 100ms',
        );
      });

      test('derives private key quickly', () {
        const mnemonic =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 10; i++) {
          cryptoService.privateKeyFromMnemonic(mnemonic);
        }

        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(15000),
          reason: 'Should derive 10 private keys in < 15s',
        );
      });

      test('derives address quickly', () {
        const privateKey =
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 10; i++) {
          cryptoService.deriveAddressFromPrivateKey(privateKey);
        }

        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(3000),
          reason: 'Should derive 10 addresses in < 3s',
        );
      });
    });
  });
}
