# idena-p2p

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey)](https://github.com/idenacommunity/idena-p2p)
[![Development Status](https://img.shields.io/badge/Status-Early%20Development-orange)](https://github.com/idenacommunity/idena-p2p)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/idenacommunity/idena-p2p?style=social)](https://github.com/idenacommunity/idena-p2p/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/idenacommunity/idena-p2p?style=social)](https://github.com/idenacommunity/idena-p2p/network/members)

**A minimal Idena mobile wallet with PIN/biometric authentication and basic account management.**

Built by the Idena community as a lightweight reference implementation for mobile wallet development.

---

## ⚠️ Development Status

**IMPORTANT: This project is in early development.**

- ✅ **Security fixes applied** - Critical vulnerabilities fixed (Jan 2026) - see [SECURITY_FIXES_SUMMARY.md](SECURITY_FIXES_SUMMARY.md)
- ⚠️ **Limited device testing** - Needs more real-world testing on physical devices
- 🔄 **Active development** - Breaking changes may occur
- 🔍 **Professional audit pending** - Community security review completed
- 🧪 **Test coverage in progress** - Comprehensive testing ongoing

**Use with caution. While critical security issues have been fixed, this remains experimental software.**

---

## ✨ Features

- 🔐 **Secure Authentication**: PIN and biometric (TouchID/FaceID) support
- 💼 **Account Management**: Create new accounts or import via BIP39 mnemonic/private key
- 💰 **Balance & Identity**: View account balance and identity state
- 🔒 **Secure Storage**: Keychain (iOS) and Keystore (Android) integration
- ⚡ **Auto-lock**: Configurable timeout for enhanced security
- 🎨 **Clean UI**: Simple, intuitive interface built with Flutter

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10.7 or higher
- Dart SDK 3.0 or higher
- iOS: Xcode 14+ (for iOS development)
- Android: Android Studio with SDK 21+ (for Android development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/idenacommunity/idena-p2p.git
   cd idena-p2p
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # List available devices
   flutter devices

   # Run on specific device
   flutter run -d <device-id>

   # Run in release mode
   flutter run --release
   ```

### Building for Production

**Android:**
```bash
flutter build apk --release              # APK for sideloading
flutter build appbundle --release        # AAB for Google Play
```

**iOS:**
```bash
flutter build ios --release
flutter build ipa --release              # For App Store
```

## 🏗️ Architecture

This app uses the **Provider pattern** for state management:

- `AccountProvider`: Manages account state (addresses, balances, identities)
- `AuthProvider`: Manages authentication state (locked/unlocked, biometric availability)
- Service layer for business logic (Crypto, Vault, Auth, Idena RPC)

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

## 🔐 Security Features

### Active Security Protections

- **HTTPS Enforcement**: All RPC connections secured with HTTPS-only validation
- **Rate Limiting**: Protection against API abuse (10 requests/second)
- **Request Timeout**: 30-second timeout for all network requests
- **PIN Authentication**: Required for all sensitive operations
- **Biometric Support**: Optional TouchID/FaceID on supported devices
- **Secure Storage**: All private keys stored in iOS Keychain or Android Keystore
- **Clipboard Auto-Clear**: Mnemonic phrases auto-clear after 60 seconds
- **Screenshot Protection**: Native OS-level blocking on Android/iOS (FLAG_SECURE, blur effects)
- **Auto-lock**: Configurable timeout (immediate, 1min, 5min, 30min)
- **Session Security**: Keys encrypted in memory during active session

### Security Documentation

- [SECURITY_FIXES_SUMMARY.md](SECURITY_FIXES_SUMMARY.md) - Critical security fixes (Jan 2026)
- [SECURITY_TESTING.md](SECURITY_TESTING.md) - Security testing procedures
- [WEB_TEST_RESULTS.md](WEB_TEST_RESULTS.md) - Web platform testing guide

## 📱 Supported Platforms

- ✅ iOS 12.0+
- ✅ Android 5.0+ (API 21+)
- ✅ Web (tested on Chrome) - Limited functionality (no screenshot protection)
- ⚠️ macOS/Windows/Linux (not tested)

## 🛠️ Development

```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format lib/

# Clean build artifacts
flutter clean && flutter pub get
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built by the Idena community
- Reference implementation for mobile wallet development
- Special thanks to all contributors

## 📚 Resources

- [Idena Network](https://idena.io) - Official Idena website
- [Idena Docs](https://docs.idena.io) - Protocol documentation
- [Flutter Docs](https://docs.flutter.dev/) - Flutter framework documentation
- [Community Discord](https://discord.gg/idena) - Join the community

## 🔗 Related Projects

- [idena-lite-api](https://github.com/idenacommunity/idena-lite-api) - Lightweight Idena API
- [my-idena](https://github.com/redDwarf03/my-idena) - Production-ready Idena wallet

---

**Status**: Early Development (Not Production Ready)
**Version**: 0.1.0-alpha
**Maintainer**: Idena Community
**Warning**: Experimental software - Use at your own risk
