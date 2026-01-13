# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
│   ├── import_mnemonic_screen.dart  # Import account via mnemonic
│   ├── import_private_key_screen.dart  # Import account via private key
│   ├── new_account_screen.dart   # Create new account
│   ├── lock_screen.dart          # PIN/biometric lock screen
│   ├── pin_screen.dart           # PIN entry screen
│   ├── pin_setup_screen.dart     # PIN setup on first use
│   └── settings_screen.dart      # App settings and preferences
├── services/                     # Business logic and external APIs
│   ├── crypto_service.dart       # Key generation, address derivation, BIP39
│   ├── idena_service.dart        # RPC communication with Idena nodes
│   ├── vault_service.dart        # Secure storage via flutter_secure_storage
│   ├── auth_service.dart         # PIN validation, authentication logic
│   └── prefs_service.dart        # SharedPreferences wrapper
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
- `VaultService`: Secure storage abstraction using `flutter_secure_storage`
- `AuthService`: Authentication logic (PIN validation, session management)
- `PrefsService`: Settings and preferences using `shared_preferences`
- `IdenaService`: Network communication via JSON-RPC to Idena nodes

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

### Authentication System

- PIN-based authentication stored securely in Keychain/Keystore
- Biometric authentication (TouchID/FaceID) via `local_auth`
- Auto-lock with configurable timeout (immediate, 1min, 5min, 30min)
- App lifecycle tracking with `WidgetsBindingObserver` to lock on background
- Session-based unlocked state managed by `AuthProvider`

## Key Dependencies

- `provider` ^6.1.2: State management
- `flutter_secure_storage` ^9.2.2: Secure storage (Keychain/Keystore)
- `local_auth` ^2.2.0: Biometric authentication (TouchID/FaceID)
- `shared_preferences` ^2.2.3: Local settings storage
- `bip39` ^1.0.6: BIP39 mnemonic generation
- `web3dart` ^2.7.3: Ethereum-compatible crypto operations
- `pointycastle` ^3.9.1: SHA3 hashing (Keccak-256)
- `hex` ^0.2.0: Hexadecimal encoding/decoding
- `http` ^1.2.2: Network requests (JSON-RPC)

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

## Security Best Practices

- Never log or print private keys, seeds, or PINs
- Use secure storage (Keychain/Keystore) for all sensitive data
- Implement session-based unlocked state (clear on lock)
- Clear sensitive data from memory after use
- Auto-lock on app background with configurable timeout
- Biometric authentication as optional convenience over PIN

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
