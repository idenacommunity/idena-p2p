import 'dart:math';
import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/credentials.dart';
import 'package:pointycastle/digests/sha3.dart';
import '../utils/secure_error_handler.dart';

/// Service for cryptographic operations including key generation and address derivation
class CryptoService {
  /// Generates a new random 32-byte private key
  String generateNewPrivateKey() {
    final random = Random.secure();
    final bytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      bytes[i] = random.nextInt(256);
    }
    return HEX.encode(bytes);
  }

  /// Derives an Idena address from a private key
  /// Private key should be a 64-character hexadecimal string
  String deriveAddressFromPrivateKey(String privateKeyHex) {
    try {
      // Remove '0x' prefix if present
      if (privateKeyHex.startsWith('0x')) {
        privateKeyHex = privateKeyHex.substring(2);
      }

      // Validate private key length
      if (privateKeyHex.length != 64) {
        throw Exception('Private key must be 64 hexadecimal characters (32 bytes)');
      }

      // Create EthPrivateKey from hex
      final privateKey = EthPrivateKey.fromHex(privateKeyHex);

      // Get the public key bytes
      final publicKeyBytes = privateKeyBytesToPublic(privateKey.privateKey);

      // Hash the public key with Keccak-256
      final digest = SHA3Digest(256);
      digest.reset();
      final hash = digest.process(publicKeyBytes);

      // Take the last 20 bytes
      final addressBytes = hash.sublist(hash.length - 20);

      // Convert to checksummed address (EIP-55)
      final address = EthereumAddress(addressBytes);
      return address.hexEip55;
    } catch (e, stackTrace) {
      // SECURITY: Log error securely without exposing crypto details
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'CryptoService.deriveAddressFromPrivateKey',
      );
      throw ValidationException('Invalid private key format');
    }
  }

  /// Validates a private key format
  /// Returns true if the private key is valid (64 hex characters)
  bool validatePrivateKey(String privateKeyHex) {
    try {
      // Remove '0x' prefix if present
      if (privateKeyHex.startsWith('0x')) {
        privateKeyHex = privateKeyHex.substring(2);
      }

      // Check length
      if (privateKeyHex.length != 64) {
        return false;
      }

      // Check if it's valid hexadecimal
      HEX.decode(privateKeyHex);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generates a new BIP39 mnemonic (12 words by default)
  String generateMnemonic({int strength = 128}) {
    // strength = 128 for 12 words, 256 for 24 words
    return bip39.generateMnemonic(strength: strength);
  }

  /// Converts a BIP39 mnemonic to a private key
  String privateKeyFromMnemonic(String mnemonic) {
    try {
      // Validate mnemonic
      if (!bip39.validateMnemonic(mnemonic)) {
        throw Exception('Invalid mnemonic phrase');
      }

      // Generate seed from mnemonic (64 bytes)
      final seed = bip39.mnemonicToSeed(mnemonic);

      // Use the first 32 bytes as the private key
      final privateKeyBytes = seed.sublist(0, 32);

      return HEX.encode(privateKeyBytes);
    } catch (e, stackTrace) {
      // SECURITY: Log error securely without exposing mnemonic details
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'CryptoService.privateKeyFromMnemonic',
      );
      throw ValidationException('Invalid mnemonic phrase');
    }
  }

  /// Validates a BIP39 mnemonic
  bool validateMnemonic(String mnemonic) {
    try {
      return bip39.validateMnemonic(mnemonic);
    } catch (e) {
      return false;
    }
  }

  /// Derives mnemonic from an existing private key
  /// Note: This generates a new mnemonic and is not deterministic
  /// For backup purposes, store the original mnemonic used to create the key
  String mnemonicFromPrivateKey(String privateKeyHex) {
    // This is not a standard operation - typically you store the mnemonic
    // that was used to create the key rather than deriving it from the key
    // We'll throw an exception as this is not a recommended operation
    throw UnimplementedError(
      'Cannot derive mnemonic from private key. '
      'Store the original mnemonic used during account creation.'
    );
  }
}
