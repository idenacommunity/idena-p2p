# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ Repository Guidelines

**IMPORTANT: This is a public, ongoing, community-maintained project that MUST remain anonymous.**

### Anonymity Requirements
- **ALL commits** must be authored by "Idena Community <communityidena@gmail.com>"
- **NEVER** include personal names, emails, or identifying information in commits, code comments, or documentation
- **ALWAYS** use the anonymous SSH key (`~/.ssh/id_ed25519_idenacommunity`) when pushing changes
- Git configuration must be set to anonymous credentials before any commit:
  ```bash
  git config user.name "Idena Community"
  git config user.email "communityidena@gmail.com"
  ```

### Project Status
- **Visibility**: Public repository on GitHub (https://github.com/idenacommunity/idena-p2p)
- **Status**: Active development, ongoing project
- **Maintenance**: Community-maintained by anonymous contributors
- **Contributions**: All contributions welcome, but must follow anonymity guidelines
- **Purpose**: Reference implementation for Idena mobile wallet development

### When Working on This Project
1. Always verify git config before committing
2. Use anonymous commit messages
3. Never reference personal projects or identities
4. Keep focus on community benefit
5. Document clearly for future anonymous contributors

## Project Overview

**idena_p2p** is a minimal Idena mobile wallet built with Flutter, featuring PIN/biometric authentication and basic account management. It serves as a simplified reference implementation compared to the production-ready my-idena app.

**Key Features:**
- Create/import Idena accounts (BIP39 mnemonic, private key)
- PIN and biometric authentication
- View balance and identity state
- Basic account management
- Secure storage via Keychain/Keystore

## Project Structure

```
lib/
├── app.dart                      # Main app widget configuration
├── main.dart                     # App entry point with Provider setup
├── models/                       # Data models
│   ├── idena_account.dart        # Account model (address, balance, identity)
│   ├── auth_state.dart           # Authentication state model
│   └── lock_timeout.dart         # Auto-lock timeout settings
├── providers/                    # State management with Provider pattern
│   ├── account_provider.dart     # Account state management
│   └── auth_provider.dart        # Authentication state management
├── screens/                      # UI screens
│   ├── connect_screen.dart       # Initial connection/account selection
│   ├── home_screen.dart          # Main home screen with account info
│   ├── new_account_screen.dart   # Create new account flow
│   ├── backup_mnemonic_screen.dart   # Display and backup mnemonic phrase
│   ├── verify_mnemonic_screen.dart   # Verify mnemonic backup (word quiz)
│   ├── import_mnemonic_screen.dart  # Import account via mnemonic
│   ├── import_private_key_screen.dart  # Import account via private key
│   ├── lock_screen.dart          # PIN/biometric lock screen
│   ├── pin_screen.dart           # PIN entry screen (with lockout display)
│   ├── pin_setup_screen.dart     # PIN setup on first use
│   └── settings_screen.dart      # App settings and preferences
├── services/                     # Business logic and external APIs
│   ├── crypto_service.dart       # Key generation, address derivation, BIP39
│   ├── idena_service.dart        # RPC communication with Idena nodes
│   ├── vault_service.dart        # Secure storage via flutter_secure_storage
│   ├── auth_service.dart         # PIN validation, authentication logic
│   ├── prefs_service.dart        # SharedPreferences wrapper
│   ├── encryption_service.dart   # Session-based in-memory encryption (ChaCha20-Poly1305)
│   ├── device_security_service.dart  # Root/jailbreak detection
│   ├── migration_service.dart    # Data migration for security upgrades
│   └── screen_security_service.dart  # Screen security (prevent screenshots)
├── utils/                        # Utility functions
│   └── biometrics_util.dart      # Biometric authentication wrapper
└── widgets/                      # Reusable UI components
    └── account_card.dart         # Account display card widget
```

## Common Commands

### Setup
```bash
# Install dependencies
flutter pub get

# Check Flutter installation
flutter doctor
```

### Running
```bash
# List available devices
flutter devices

# Run on connected device/emulator
flutter run

# Run on specific device
flutter run -d <device-id>

# Run in release mode
flutter run --release

# Hot reload: Press 'r' in terminal
# Hot restart: Press 'R' in terminal
```

### Building
```bash
# Build for Android
flutter build apk                # Debug APK
flutter build apk --release      # Release APK
flutter build appbundle          # For Play Store

# Build for iOS
flutter build ios                # Debug build
flutter build ipa                # For App Store
```

### Testing & Code Quality
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Analyze code for issues
flutter analyze

# Format code
flutter format lib/

# Check formatting without applying
flutter format --set-exit-if-changed lib/

# Clean build artifacts
flutter clean && flutter pub get
```

## Architecture

### State Management: Provider Pattern

The app uses the Provider pattern for state management:

- `AccountProvider`: Manages account state (addresses, balances, identities)
- `AuthProvider`: Manages authentication state (locked/unlocked, biometric availability)
- Providers wrapped with `MultiProvider` in `main.dart`
- UI widgets use `Provider.of<T>(context)` or `context.watch<T>()` for reactive updates
- All state changes flow through providers using `notifyListeners()`

### Service Layer

Services are instantiated directly (no dependency injection framework):

- `CryptoService`: Cryptographic operations (key generation, address derivation, BIP39 mnemonic)
- `VaultService`: Secure storage abstraction using `flutter_secure_storage` with Argon2id PIN hashing
- `AuthService`: Authentication logic (PIN validation with Argon2id, lockout management)
- `PrefsService`: Settings and preferences using `shared_preferences`
- `IdenaService`: Network communication via JSON-RPC to Idena nodes
- `EncryptionService`: Session-based in-memory encryption using ChaCha20-Poly1305-AEAD for private keys
- `DeviceSecurityService`: Root/jailbreak detection using `flutter_jailbreak_detection`
- `MigrationService`: Handles data migrations when security features are upgraded
- `ScreenSecurityService`: Screen security (prevent screenshots on sensitive screens)

### Data Flow

```
User action → Screen calls Provider method
  ↓
Provider calls appropriate service (Crypto/Vault/Auth/Idena)
  ↓
Provider updates internal state
  ↓
Provider calls notifyListeners()
  ↓
Listening widgets rebuild with new state
```

### App Startup Flow

The app performs several security checks and initializations on startup:

```
main.dart (app entry)
  ↓
1. WidgetsFlutterBinding.ensureInitialized()
  ↓
2. _checkDeviceSecurity()
   - DeviceSecurityService checks for root/jailbreak
   - Logs warning if device is compromised (HIGH/MEDIUM/LOW risk)
   - Continues app startup even if compromised (user awareness)
  ↓
3. _performSecurityMigrations()
   - MigrationService checks migration flags in SharedPreferences
   - Migrates PIN from plaintext to Argon2id if needed
   - Migrates private keys to session encryption if needed
   - Marks migrations as complete to avoid re-running
  ↓
4. MultiProvider setup
   - AuthProvider: Authentication state
   - AccountProvider: Account state with encrypted private keys
  ↓
5. IdenaApp widget
   - MaterialApp with routing
   - Initial route determined by auth state
```

**Why This Order Matters:**
- Security checks before any user data is loaded
- Migrations ensure backward compatibility with older app versions
- Providers initialized after migrations complete
- Failed security checks don't block app (user can still proceed with warnings)

### Authentication System

**PIN Security (Phase 1 Security Enhancement):**
- PIN hashing using **Argon2id** (OWASP recommended, PHC format)
- Constant-time verification to prevent timing attacks
- Lockout system after failed attempts (exponential backoff: 1min → 5min → 15min)
- Failed attempt tracking persisted across app restarts

**Session Security:**
- Private keys encrypted in memory using **ChaCha20-Poly1305-AEAD** (RFC 7539)
- Session keys generated with cryptographically secure random (256-bit)
- Keys stored only in encrypted form in memory
- Automatic cleanup on lock/logout

**Biometric Authentication:**
- TouchID/FaceID via `local_auth` as optional convenience over PIN
- Biometric check triggers PIN validation in background

**Auto-lock:**
- Configurable timeout (immediate, 1min, 5min, 30min)
- App lifecycle tracking with `WidgetsBindingObserver` to lock on background
- Session-based unlocked state managed by `AuthProvider`

**App Startup Security (Phase 2):**
- Root/jailbreak detection on app launch
- Security warnings for compromised devices
- Automatic data migrations for security upgrades

## Key Dependencies

**State Management:**
- `provider` ^6.1.2: State management pattern

**Cryptography & Security:**
- `bip39` ^1.0.6: BIP39 mnemonic generation
- `web3dart` ^2.6.1: Ethereum-compatible crypto operations (key derivation, signing)
- `pointycastle` ^3.9.1: SHA3 hashing (Keccak-256) for address derivation
- `hex` ^0.2.0: Hexadecimal encoding/decoding
- `hashlib` ^1.20.0: **Argon2id** PIN hashing with PHC format (Phase 1 security)
- `cryptography` ^2.7.0: **ChaCha20-Poly1305** for session-based encryption (Phase 1 security)
- `crypto` ^3.0.5: Additional crypto utilities

**Secure Storage & Authentication:**
- `flutter_secure_storage` ^9.2.2: Secure storage (Keychain/Keystore)
- `local_auth` ^2.1.0: Biometric authentication (TouchID/FaceID)
- `shared_preferences` ^2.2.0: Local settings storage
- `flutter_jailbreak_detection` ^1.10.0: Root/jailbreak detection (Phase 2 security)

**Networking:**
- `http` ^0.13.3: Network requests (JSON-RPC)

**Testing:**
- `mocktail` ^1.0.4: Mocking for security tests

## Idena-Specific Concepts

### Address Format
- Idena uses Ethereum-compatible addresses (EIP-55 checksummed)
- Format: `0x` + 40 hexadecimal characters
- Derived from private key using Keccak-256 hash

### Key Derivation
```
BIP39 mnemonic → Seed (64 bytes)
  ↓
First 32 bytes of seed → Private key
  ↓
Private key → Public key
  ↓
Keccak-256 hash → Last 20 bytes → Address
```

### Identity States
- Undefined → Newbie → Verified → Human → Suspended → Zombie → Killed

### JSON-RPC Methods
Key RPC methods used in `IdenaService`:
- `dna_getBalance`: Get balance and stake
- `dna_identity`: Get identity state and age
- `dna_epoch`: Get current epoch number
- Default public node: `https://rpc.idena.dev`

## Code Style and Conventions

- **Dart Version**: 3.10.7+ with full null safety
- Use null safety syntax (`?`, `!`, `late`) consistently
- Follow Flutter/Dart style guide: run `flutter format lib/`
- Use meaningful variable names, especially for cryptographic operations
- Comment complex cryptographic or network operations
- Prefer `async/await` over raw Futures for readability
- Use `context.watch<T>()` and `context.read<T>()` for Provider access

## Testing

### Test Structure

Tests are organized in `test/` directory with security-focused test coverage:

```
test/
├── security/                           # Security-focused tests
│   ├── authentication_security_test.dart   # PIN validation, lockout, Argon2id
│   ├── session_encryption_test.dart        # ChaCha20-Poly1305 encryption
│   ├── cryptographic_security_test.dart    # Key derivation, entropy
│   ├── phase2_security_test.dart           # Device security, screen security
│   └── migration_test.dart                 # Data migration tests
└── widget_test.dart                    # Basic widget tests
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/security/authentication_security_test.dart

# Run tests with coverage
flutter test --coverage

# Run tests in a specific directory
flutter test test/security/
```

### Testing Patterns

**Mocking Secure Storage:**
```dart
// Mock flutter_secure_storage for testing
const MethodChannel secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

final Map<String, String> secureStorageData = {};

setUp(() async {
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
      // ... handle other methods
    }
  });
});
```

**Security Test Focus Areas:**
- Argon2id PIN hashing and verification
- ChaCha20-Poly1305 encryption/decryption
- Session key generation and cleanup
- Lockout mechanism and exponential backoff
- Private key encryption in memory
- Migration from old to new security features

## Security Best Practices

**Code Security:**
- Never log or print private keys, seeds, PINs, or session keys
- Use secure storage (Keychain/Keystore) for all sensitive data at rest
- Encrypt private keys in memory using `EncryptionService`
- Clear sensitive data from memory after use
- Always use `getDecryptedPrivateKey()` method instead of accessing raw private keys

**Authentication Security:**
- Use Argon2id for PIN hashing (never store PINs in plaintext)
- Implement lockout after failed attempts with exponential backoff
- Session-based unlocked state (clear on lock)
- Auto-lock on app background with configurable timeout
- Biometric authentication as optional convenience over PIN

**Runtime Security:**
- Check device security status on app startup (root/jailbreak detection)
- Prevent screenshots on sensitive screens (PIN entry, private key display)
- Run security migrations on app startup for backward compatibility

## Important Implementation Details

### Private Key Management

**Storage Architecture (Multi-layer Security):**
```
Private Key Protection Layers:
1. At Rest (VaultService):
   - Stored in Keychain (iOS) or Keystore (Android)
   - Platform-level encryption

2. In Memory (EncryptionService):
   - Encrypted using ChaCha20-Poly1305-AEAD
   - Session key (256-bit) generated on app startup
   - Never stored in plaintext in memory

3. Access Pattern:
   - AccountProvider._encryptedPrivateKey holds encrypted key
   - Use getDecryptedPrivateKey() only when needed for signing
   - Automatic cleanup on logout/lock via clearSession()
```

**When to Access Private Keys:**
- Only decrypt when signing transactions
- Never pass decrypted keys between functions
- Use `getDecryptedPrivateKey()` and immediately use the result
- Avoid storing decrypted keys in local variables

### PIN Validation Flow

**Argon2id Verification:**
```dart
// WRONG - Don't compare plaintext PINs
final storedPin = await vault.getPin();
if (pin == storedPin) { ... }  // ❌ NEVER DO THIS

// CORRECT - Use Argon2id verification
final isValid = await vault.verifyPin(pin);  // ✅ Secure verification
if (isValid) { ... }
```

**Lockout Mechanism:**
- Failed attempts: 3 → 1min lockout, 5 → 5min lockout, 7 → 15min lockout
- Lockout time stored in SharedPreferences (persists across app restarts)
- `AuthState` model tracks lockout status and remaining time
- UI displays countdown timer during lockout

### Migration System

**Purpose:** Safely upgrade security features without breaking existing users

**How It Works:**
```dart
// MigrationService checks flags in SharedPreferences
final migrationFlags = {
  'pin_migrated_to_argon2id': false,
  'private_key_encrypted_in_memory': false,
};

// Each migration runs once
if (!prefs.getBool('pin_migrated_to_argon2id')) {
  // Re-hash existing PINs with Argon2id
  await _migratePin();
  await prefs.setBool('pin_migrated_to_argon2id', true);
}
```

**Adding New Migrations:**
1. Add migration flag to `PrefsService`
2. Implement migration logic in `MigrationService`
3. Test with both old and new data formats
4. Update version number in pubspec.yaml

### Provider Communication Patterns

**AccountProvider and AuthProvider Interaction:**
- `AuthProvider`: Manages lock/unlock state, PIN validation
- `AccountProvider`: Manages account data, encrypted private keys
- Providers don't directly communicate (no circular dependencies)
- Screens coordinate between providers using `context.read<T>()`

**Example Pattern:**
```dart
// In a screen
final authProvider = context.read<AuthProvider>();
final accountProvider = context.read<AccountProvider>();

// Check auth state before account operations
if (authProvider.isUnlocked) {
  await accountProvider.refreshAccountData();
}
```

## Platform-Specific Notes

### iOS
- Uses Keychain for secure storage via `flutter_secure_storage`
- Biometric authentication via TouchID/FaceID requires `NSFaceIDUsageDescription` in `Info.plist`
- Lock screen accessibility: `KeychainAccessibility.first_unlock`

### Android
- Uses Android Keystore for secure storage
- Biometric authentication requires permissions in `AndroidManifest.xml`
- Some devices may have keystore issues (see my-idena fallback encryption pattern)
- `encryptedSharedPreferences: true` option for secure storage

## Reference Implementation

This is a simplified version of the production `my-idena` app. When adding features:

1. Check `../my-idena` for reference implementations
2. Adapt InheritedWidget patterns to Provider patterns
3. Convert GetIt service locator usage to direct service instantiation
4. Add null safety annotations (my-idena uses pre-null-safety Dart)
5. Replace `idena_lib_dart` library calls with direct JSON-RPC via `IdenaService`

See the main repository CLAUDE.md (`../CLAUDE.md`) for cross-project development patterns.

## Community Resources

- **Community RPC Nodes:** https://rpc.holismo.org/, https://rpc.idio.network/
- **Discord**: Idena Network server
- **Related Projects**: See main repository CLAUDE.md for full ecosystem overview
