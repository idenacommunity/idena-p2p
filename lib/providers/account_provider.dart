import 'package:flutter/foundation.dart';
import '../models/idena_account.dart';
import '../services/crypto_service.dart';
import '../services/vault_service.dart';
import '../services/idena_service.dart';
import '../services/encryption_service.dart';
import '../utils/secure_error_handler.dart';

/// Provider for managing account state throughout the application
/// Uses ChangeNotifier to notify UI of state changes
/// SECURITY FIX: Private keys are encrypted in memory using session-based encryption
class AccountProvider with ChangeNotifier {
  final CryptoService _cryptoService = CryptoService();
  final VaultService _vaultService = VaultService();
  final IdenaService _idenaService = IdenaService();
  late final EncryptionService _encryptionService;

  IdenaAccount? _currentAccount;
  String? _encryptedPrivateKey; // SECURITY: Encrypted in memory
  bool _isConnected = false;
  bool _isLoading = false;
  String? _error;

  AccountProvider() {
    _encryptionService = EncryptionService(vaultService: _vaultService);
  }

  // Getters
  IdenaAccount? get currentAccount => _currentAccount;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// SECURITY: Loads private key from vault and encrypts it in memory
  /// This keeps the key encrypted at rest (in vault) and in memory (session encryption)
  Future<void> _loadAndEncryptPrivateKey() async {
    final privateKey = await _vaultService.getPrivateKey();

    if (privateKey == null) {
      throw Exception('Private key not found in vault');
    }

    // Initialize encryption session if not already active
    if (!_encryptionService.isSessionActive) {
      await _encryptionService.initializeSession();
    }

    // Encrypt private key for in-memory storage
    _encryptedPrivateKey = await _encryptionService.encrypt(privateKey);
  }

  /// SECURITY: Retrieves the decrypted private key (use only when needed for signing)
  /// Decrypts the in-memory encrypted key using the session key
  Future<String> getDecryptedPrivateKey() async {
    if (_encryptedPrivateKey == null) {
      throw Exception('No private key loaded in memory');
    }

    return await _encryptionService.decrypt(_encryptedPrivateKey!);
  }

  /// Loads a stored account on app startup
  /// Checks if a private key is saved and loads the account info
  /// SECURITY FIX: Loads private key into encrypted memory
  Future<void> loadStoredAccount() async {
    _setLoading(true);
    _error = null;

    try {
      final hasKey = await _vaultService.hasStoredKey();

      if (!hasKey) {
        _isConnected = false;
        _setLoading(false);
        return;
      }

      final address = await _vaultService.getAddress();

      if (address == null) {
        _isConnected = false;
        _setLoading(false);
        return;
      }

      // SECURITY: Load and encrypt private key in memory
      await _loadAndEncryptPrivateKey();

      // Create minimal account while loading full info
      _currentAccount = IdenaAccount.minimal(address);
      _isConnected = true;
      notifyListeners();

      // Load full account information from network
      await refreshAccountData();
    } catch (e, stackTrace) {
      // SECURITY: Log error securely and sanitize for display
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'AccountProvider.loadStoredAccount',
      );
      _error = SecureErrorHandler.sanitizeError(e);
      _isConnected = false;
    } finally {
      _setLoading(false);
    }
  }

  /// Creates a new account with a randomly generated private key
  /// Returns the mnemonic phrase that should be backed up
  /// SECURITY FIX: Stores private key encrypted in memory
  Future<String> connectWithNewAccount() async {
    _setLoading(true);
    _error = null;

    try {
      // Generate mnemonic and derive private key
      final mnemonic = _cryptoService.generateMnemonic();
      final privateKey = _cryptoService.privateKeyFromMnemonic(mnemonic);

      // Derive address
      final address = _cryptoService.deriveAddressFromPrivateKey(privateKey);

      // Save to secure storage
      await _vaultService.savePrivateKey(privateKey);
      await _vaultService.saveAddress(address);

      // SECURITY: Load and encrypt private key in memory
      await _loadAndEncryptPrivateKey();

      // Create account object
      _currentAccount = IdenaAccount.minimal(address);
      _isConnected = true;
      notifyListeners();

      // Load account info from network (in background)
      refreshAccountData();

      return mnemonic;
    } catch (e, stackTrace) {
      // SECURITY: Log error securely and sanitize for display
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'AccountProvider.connectWithNewAccount',
      );
      _error = SecureErrorHandler.sanitizeError(e);
      throw Exception(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Connects with an existing private key
  /// SECURITY FIX: Stores private key encrypted in memory
  Future<void> connectWithPrivateKey(String privateKey) async {
    _setLoading(true);
    _error = null;

    try {
      // Validate private key
      if (!_cryptoService.validatePrivateKey(privateKey)) {
        throw Exception('Invalid private key format');
      }

      // Derive address
      final address = _cryptoService.deriveAddressFromPrivateKey(privateKey);

      // Save to secure storage
      await _vaultService.savePrivateKey(privateKey);
      await _vaultService.saveAddress(address);

      // SECURITY: Load and encrypt private key in memory
      await _loadAndEncryptPrivateKey();

      // Create account object
      _currentAccount = IdenaAccount.minimal(address);
      _isConnected = true;
      notifyListeners();

      // Load account info from network
      await refreshAccountData();
    } catch (e, stackTrace) {
      // SECURITY: Log error securely and sanitize for display
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'AccountProvider.connectWithPrivateKey',
      );
      _error = SecureErrorHandler.sanitizeError(e);
      throw Exception(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Connects with a mnemonic phrase
  /// SECURITY FIX: Stores private key encrypted in memory
  Future<void> connectWithMnemonic(String mnemonic) async {
    _setLoading(true);
    _error = null;

    try {
      // Validate mnemonic
      if (!_cryptoService.validateMnemonic(mnemonic)) {
        throw Exception('Invalid mnemonic phrase');
      }

      // Derive private key from mnemonic
      final privateKey = _cryptoService.privateKeyFromMnemonic(mnemonic);

      // Derive address
      final address = _cryptoService.deriveAddressFromPrivateKey(privateKey);

      // Save to secure storage
      await _vaultService.savePrivateKey(privateKey);
      await _vaultService.saveAddress(address);

      // SECURITY: Load and encrypt private key in memory
      await _loadAndEncryptPrivateKey();

      // Create account object
      _currentAccount = IdenaAccount.minimal(address);
      _isConnected = true;
      notifyListeners();

      // Load account info from network
      await refreshAccountData();
    } catch (e, stackTrace) {
      // SECURITY: Log error securely and sanitize for display
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'AccountProvider.connectWithMnemonic',
      );
      _error = SecureErrorHandler.sanitizeError(e);
      throw Exception(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Disconnects the current account and removes it from storage
  /// SECURITY FIX: Clears encryption session and encrypted private key from memory
  Future<void> disconnect() async {
    _setLoading(true);
    _error = null;

    try {
      await _vaultService.deletePrivateKey();

      // SECURITY: Clear encryption session and encrypted key from memory
      _encryptionService.clearSession();
      _encryptedPrivateKey = null;

      _currentAccount = null;
      _isConnected = false;
      notifyListeners();
    } catch (e, stackTrace) {
      // SECURITY: Log error securely and sanitize for display
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'AccountProvider.disconnect',
      );
      _error = SecureErrorHandler.sanitizeError(e);
      throw Exception(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Refreshes account data from the Idena network
  /// Updates balance, identity status, and epoch information
  Future<void> refreshAccountData() async {
    if (_currentAccount == null) return;

    try {
      final accountInfo = await _fetchAccountInfo(_currentAccount!.address);

      _currentAccount = IdenaAccount.fromMap(accountInfo);
      _error = null;
      notifyListeners();
    } catch (e, stackTrace) {
      // SECURITY: Log error securely and sanitize for display
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'AccountProvider.refreshAccountData',
      );
      _error = SecureErrorHandler.sanitizeError(e);
      // Don't throw - we want to keep the account connected even if refresh fails
      notifyListeners();
    }
  }

  /// Helper method to fetch account information from the network
  Future<Map<String, dynamic>> _fetchAccountInfo(String address) async {
    return await _idenaService.getAccountInfo(address);
  }

  /// Helper to set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clears any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// SECURITY: Clean up encryption session when provider is disposed
  @override
  void dispose() {
    _encryptionService.clearSession();
    _encryptedPrivateKey = null;
    super.dispose();
  }
}
