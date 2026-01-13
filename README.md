# idena-p2p

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey)](https://github.com/idenacommunity/idena-p2p)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/idenacommunity/idena-p2p?style=social)](https://github.com/idenacommunity/idena-p2p/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/idenacommunity/idena-p2p?style=social)](https://github.com/idenacommunity/idena-p2p/network/members)

**A minimal Idena mobile wallet with PIN/biometric authentication and basic account management.**

Built by the Idena community as a lightweight reference implementation for mobile wallet development.

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

- **PIN Authentication**: Required for all sensitive operations
- **Biometric Support**: Optional TouchID/FaceID on supported devices
- **Secure Storage**: All private keys stored in iOS Keychain or Android Keystore
- **Auto-lock**: Configurable timeout (immediate, 1min, 5min, 30min)
- **Session Security**: Keys encrypted in memory during active session

## 📱 Supported Platforms

- ✅ iOS 12.0+
- ✅ Android 5.0+ (API 21+)
- ⚠️ macOS/Windows/Linux (not tested)
- ⚠️ Web (not supported)

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

**Status**: Active Development
**Version**: 1.0.0
**Maintainer**: Idena Community
