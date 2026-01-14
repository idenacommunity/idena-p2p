# Idena P2P Messenger

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey)](https://github.com/idenacommunity/idena-p2p)
[![Development Status](https://img.shields.io/badge/Status-MVP%20Complete-green)](https://github.com/idenacommunity/idena-p2p)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**A secure, decentralized messaging app for the Idena community with end-to-end encryption and proof-of-person identity verification.**

Built by the Idena community as a reference implementation for privacy-focused communication on the Idena network.

---

## 🤔 What is Idena P2P?

**Idena P2P** is a mobile messaging application that combines:
- 💬 **Secure Messaging** - End-to-end encrypted conversations
- 🔐 **Identity Verification** - Know who you're talking to (Human, Verified, Newbie)
- 💼 **Built-in Wallet** - Manage your Idena account and balance
- 🌐 **Decentralized** - No central authority controls your data

Think of it as **WhatsApp meets Idena**, where every user is verified as a unique human through Idena's proof-of-person validation.

---

## 🌟 Why Does This Exist?

### The Problem

In today's digital world:
- 🤖 **Bot armies** flood social platforms with fake accounts
- 🎭 **Anonymous trolls** hide behind multiple identities
- 📱 **Centralized apps** control and monetize your conversations
- 🔓 **Privacy concerns** with major messaging platforms

### The Solution

**Idena P2P** solves these problems by:

1. **Proof-of-Person Identity** 🙋
   - Every user proves they're a unique human through Idena's validation ceremony
   - No bots, no fake accounts, no anonymous trolls
   - See someone's identity status: Human, Verified, Newbie, etc.

2. **End-to-End Encryption** 🔒
   - Messages encrypted on your device before sending
   - Only you and your recipient can read them
   - Uses military-grade encryption (X25519 + ChaCha20-Poly1305)

3. **Your Data, Your Control** 📱
   - Messages stored locally on your device
   - No company reads or sells your conversations
   - Open-source code you can verify

4. **Decentralized Architecture** 🌐
   - No single point of failure
   - Community-run relay servers (Phase 3 will be fully P2P)
   - Censorship-resistant communication

---

## ✨ Key Features

### 💬 Messaging

- **End-to-End Encrypted Chat** - Military-grade encryption for all messages
- **Real-time Delivery** - Messages delivered instantly when both users online
- **Offline Message Queue** - Messages saved when recipient is offline
- **Delivery Status** - See when messages are sent, delivered, and read
- **Contact Management** - Save contacts with nicknames and trust levels
- **Conversation History** - All messages stored locally on your device

### 🔐 Security & Privacy

- **Argon2id PIN Hashing** - Industry-standard password protection
- **ChaCha20-Poly1305 Encryption** - Military-grade message encryption
- **Multi-layer Key Protection** - Private keys never stored in plaintext
- **Biometric Authentication** - Optional TouchID/FaceID support
- **Auto-lock** - Configurable timeout to lock the app
- **Screenshot Protection** - Prevents screenshots on sensitive screens
- **Root/Jailbreak Detection** - Warns if device security is compromised

### 💼 Idena Wallet

- **Account Management** - Create new accounts or import existing ones
- **Balance Display** - View your Idena (iDNA) balance
- **Identity State** - See your validation status (Human, Verified, etc.)
- **Secure Storage** - Private keys protected with platform-level encryption
- **BIP39 Support** - Import/export accounts with mnemonic phrases

### 👤 Identity Verification

- **Idena Address-Based** - Every user has a verified Idena address
- **Identity Badges** - See who is Human, Verified, Newbie, etc.
- **Trust Levels** - Mark contacts as trusted or unknown
- **No Anonymous Users** - Everyone is a verified unique human

---

## 🎯 Who Is This For?

### Perfect For:

- 👨‍👩‍👧‍👦 **Idena Community Members** - Communicate with fellow validators
- 🛡️ **Privacy Advocates** - People who value secure, encrypted communication
- 💻 **Developers** - Open-source reference implementation for Idena apps
- 🌐 **Web3 Enthusiasts** - Decentralized alternative to centralized messengers
- 🔒 **Security-Conscious Users** - Those who want verified, bot-free conversations

### Not For:

- ❌ People who need group chats (not yet implemented)
- ❌ Users who need media sharing (text-only for MVP)
- ❌ Those wanting anonymous messaging (all users are identity-verified)

---

## 🚀 Getting Started

### Quick Start (5 Minutes)

**1. Prerequisites**
- Android device (5.0+) or iOS device (12.0+)
- Idena account (create at [idena.io](https://idena.io))
- Flutter SDK (for development only)

**2. Install the App**

```bash
# Clone the repository
git clone https://github.com/idenacommunity/idena-p2p.git
cd idena-p2p

# Install dependencies
flutter pub get

# Run on your device
flutter run
```

**3. First Launch**
1. Open the app
2. Set up a PIN (6 digits)
3. Choose: Create new account OR Import existing account
4. Write down your mnemonic phrase (IMPORTANT!)
5. Start messaging!

**4. Start the Relay Server** (for messaging to work)

```bash
# In a new terminal
cd relay-server

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Start server
npm run dev
```

**5. Add Contacts & Send Messages**
1. Tap the Contacts icon
2. Add a contact's Idena address
3. Tap Messages → Start new conversation
4. Select your contact and start chatting!

---

## 📖 How It Works

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                        │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Screens: Home, Contacts, Conversations, Chat          │ │
│  └────────────────────┬───────────────────────────────────┘ │
│                       │                                      │
│  ┌────────────────────▼───────────────────────────────────┐ │
│  │  Providers: Account, Auth, Messaging                   │ │
│  └────────────────────┬───────────────────────────────────┘ │
│                       │                                      │
│  ┌────────────────────▼───────────────────────────────────┐ │
│  │  Services:                                              │ │
│  │  - Encryption (X25519 + ChaCha20-Poly1305)            │ │
│  │  - Storage (Hive database)                            │ │
│  │  - WebSocket (relay connection)                       │ │
│  │  - REST API (public key exchange)                     │ │
│  └─────────────────────────────────────────────────────────┘ │
└───────────────────────┬─────────────────────────────────────┘
                        │ Encrypted over WebSocket
┌───────────────────────▼─────────────────────────────────────┐
│                  Relay Server (Node.js)                      │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  WebSocket Manager: Real-time message routing          ││
│  │  Message Queue: Store messages for offline users       ││
│  │  Public Key Store: Facilitate key exchange             ││
│  └─────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────┘
                        ↕
                 (Phase 3: Full P2P)
```

### Message Flow

**Sending a Message:**

```
1. You type "Hello!" in the chat
   ↓
2. App fetches recipient's public key from relay server
   ↓
3. Message encrypted locally on your device
   ↓
4. Encrypted message sent via WebSocket
   ↓
5. Relay server routes to recipient
   ↓
6. Recipient's app decrypts the message
   ↓
7. "Hello!" appears in their chat
```

**Security Note:** The relay server NEVER sees the plaintext message. Only encrypted data passes through it.

---

## 🔒 Security Model

### End-to-End Encryption

**What gets encrypted:**
- ✅ Message content
- ✅ Attachments (future feature)
- ✅ Read receipts (future feature)

**What is NOT encrypted (by design):**
- ❌ Sender and recipient addresses (needed for routing)
- ❌ Message timestamps (needed for ordering)
- ❌ Online/offline status (needed for delivery)

### Key Management

**Your Private Key:**
1. Generated on your device
2. Stored in platform-secure storage (Keychain/Keystore)
3. Encrypted in memory when app is unlocked
4. Never leaves your device
5. Protected by PIN/biometric authentication

**Public Keys:**
- Shared via relay server
- Anyone can see them (that's the point!)
- Used by others to encrypt messages to you

### Trust Model

**Who you trust:**
- ✅ Your own device (stores your private key)
- ✅ The encryption algorithms (X25519, ChaCha20-Poly1305)
- ⚠️ The relay server (only for routing, not reading messages)
- ⚠️ The Idena network (for identity verification)

**Who you DON'T need to trust:**
- ❌ The relay server to read your messages (they're encrypted)
- ❌ Network admins to be honest (end-to-end encryption)
- ❌ Other app developers (open-source, verifiable code)

---

## 🎓 Use Cases

### 1. **Community Communication**
*Connect with fellow Idena validators*

> "I'm an Idena validator and want to discuss validation strategies with other verified humans without bots or spam."

**Solution:** Add other validators as contacts, start encrypted conversations, share tips and strategies knowing everyone is a verified unique human.

---

### 2. **Privacy-Focused Groups**
*Organize events or projects privately*

> "I'm organizing an Idena meetup and need a secure channel to coordinate with verified attendees."

**Solution:** Create a contact list of attendees, send encrypted messages, coordinate details without surveillance or data harvesting.

---

### 3. **Developer Collaboration**
*Work on Idena projects securely*

> "I'm building on Idena and need to discuss technical details with contributors I can trust are real people."

**Solution:** Verify contributors' Idena identities, communicate securely about code, coordinate development privately.

---

### 4. **Secure Customer Support**
*Provide support with verified identities*

> "I run an Idena-based service and want to support customers with verified identity, avoiding impersonation."

**Solution:** Customers reach out with their verified Idena addresses, you can confirm they're real users, provide secure support.

---

## 📱 Screenshots

*Coming soon - Screenshots of main screens*

---

## 🛠️ Development

### Project Structure

```
lib/
├── models/              # Data models (Message, Contact, etc.)
├── providers/           # State management (Provider pattern)
├── screens/             # UI screens
│   ├── home_screen.dart
│   ├── contacts/        # Contact management
│   └── messaging/       # Chat and conversations
├── services/            # Business logic
│   ├── crypto_service.dart              # Key generation
│   ├── messaging_encryption_service.dart # E2E encryption
│   ├── message_storage_service.dart     # Local database
│   ├── relay_websocket_service.dart     # Real-time messaging
│   └── relay_api_service.dart           # REST API client
└── widgets/             # Reusable UI components

relay-server/            # Node.js relay server
├── src/
│   ├── server.js        # Main server
│   ├── routes/          # API endpoints
│   ├── services/        # WebSocket, queue, keys
│   └── utils/           # Logging, etc.
└── test-message-flow.js # Automated tests
```

### Key Technologies

- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **Hive** - Local database (NoSQL)
- **WebSocket** - Real-time communication
- **Node.js** - Relay server runtime
- **Express** - Web framework for relay server

### Development Commands

```bash
# Flutter App
flutter run                    # Run on device
flutter test                   # Run tests
flutter analyze                # Check code quality
flutter build apk --release    # Build Android APK

# Relay Server
cd relay-server
npm run dev                    # Start with auto-reload
npm test                       # Run tests
node test-message-flow.js      # Test message flow
```

### Testing

**Automated Tests:**
```bash
# Flutter app tests
flutter test

# Relay server tests
cd relay-server
node test-message-flow.js
```

**Manual Testing:**
1. Start relay server: `cd relay-server && npm run dev`
2. Run app on Device A: `flutter run`
3. Run app on Device B: `flutter run -d device-2`
4. Send messages between devices
5. Verify encryption, delivery, offline queueing

---

## 🗺️ Roadmap

### ✅ Phase 0: Contact Management (Complete)
- Contact list with Idena addresses
- Identity badges (Human, Verified, etc.)
- Trust levels and nicknames

### ✅ Phase 1: Messaging UI & Local Storage (Complete)
- Chat screen with message bubbles
- Conversation list
- End-to-end encryption
- Local message storage

### ✅ Phase 1.5: Relay Server (Complete)
- Node.js WebSocket server
- Message routing and queueing
- Public key exchange infrastructure
- Online/offline status tracking

### ✅ Phase 2: Flutter Integration (Complete)
- WebSocket client with auto-reconnect
- Network message transmission
- Public key exchange
- Delivery status tracking

### 🔄 Phase 2.5: Production Readiness (In Progress)
- [ ] Push notifications (FCM/APNs)
- [ ] Typing indicators in UI
- [ ] Read receipts in UI
- [ ] Connection status indicator
- [ ] WSS (secure WebSocket)
- [ ] Deploy relay server to VPS
- [ ] Rate limiting
- [ ] Authentication tokens

### 📅 Phase 3: Full Decentralization (Future)
- [ ] Replace relay with libp2p
- [ ] DHT for peer discovery
- [ ] IPFS for offline message storage
- [ ] Direct peer-to-peer connections
- [ ] No central relay dependency

### 🎯 Future Features
- [ ] Group chats
- [ ] Media sharing (images, videos)
- [ ] Voice messages
- [ ] Video calls
- [ ] Message reactions
- [ ] Message editing/deletion
- [ ] Multi-device sync
- [ ] Desktop app (Windows, macOS, Linux)
- [ ] Web app

---

## 📊 Project Status

**Current Version:** 0.2.0-alpha (Messaging MVP)
**Status:** MVP Complete - Testing Phase
**Last Updated:** January 2026

### What's Working ✅

- ✅ Account creation and import
- ✅ PIN/biometric authentication
- ✅ Contact management
- ✅ End-to-end encrypted messaging
- ✅ Real-time message delivery
- ✅ Offline message queueing
- ✅ Public key exchange
- ✅ Delivery status tracking
- ✅ Local message storage
- ✅ Identity verification

### What's Not Ready ⚠️

- ⚠️ Push notifications
- ⚠️ Group chats
- ⚠️ Media sharing
- ⚠️ Production deployment
- ⚠️ App store distribution
- ⚠️ Professional security audit

### Known Limitations

1. **Centralized Relay (Temporary)**
   - Currently uses a central relay server
   - Phase 3 will move to fully decentralized P2P

2. **No Multi-Device Sync**
   - Messages only stored on one device
   - Cannot access same messages on multiple devices

3. **Text Messages Only**
   - No images, videos, or files yet
   - Coming in future updates

4. **Development Infrastructure**
   - Relay server runs locally (use VPS for production)
   - No HTTPS/WSS yet (use for testing only)

---

## 🤝 Contributing

We welcome contributions from the Idena community!

### How to Contribute

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes**
4. **Follow the code style**
   ```bash
   flutter format lib/
   flutter analyze
   ```
5. **Test your changes**
   ```bash
   flutter test
   ```
6. **Commit with anonymous identity**
   ```bash
   git config user.name "Idena Community"
   git config user.email "communityidena@gmail.com"
   git commit -m "Add amazing feature"
   ```
7. **Push and create Pull Request**
   ```bash
   git push origin feature/amazing-feature
   ```

### Development Guidelines

- Write clear, self-documenting code
- Add tests for new features
- Update documentation
- Follow the existing architecture
- Keep security in mind
- Use anonymous commits (Idena Community)

### Areas That Need Help

- 🧪 Testing on more devices (Android/iOS)
- 🔒 Security review and auditing
- 📝 Documentation improvements
- 🌍 Internationalization (i18n)
- 🎨 UI/UX enhancements
- 🐛 Bug reports and fixes

---

## 📄 Documentation

### For Users
- [QUICKSTART.md](QUICKSTART.md) - Get started in 5 minutes
- [SECURITY_FIXES_SUMMARY.md](SECURITY_FIXES_SUMMARY.md) - Security improvements

### For Developers
- [CLAUDE.md](CLAUDE.md) - Development guide for AI assistants
- [PHASE1_IMPLEMENTATION_SUMMARY.md](PHASE1_IMPLEMENTATION_SUMMARY.md) - Phase 1 details
- [PHASE1.5_RELAY_SERVER_SUMMARY.md](PHASE1.5_RELAY_SERVER_SUMMARY.md) - Relay server guide
- [PHASE2_INTEGRATION_SUMMARY.md](PHASE2_INTEGRATION_SUMMARY.md) - Integration guide
- [PHASE2_TEST_RESULTS.md](PHASE2_TEST_RESULTS.md) - Test results

### For Security Researchers
- [SECURITY_TESTING.md](SECURITY_TESTING.md) - Security testing procedures
- [relay-server/README.md](relay-server/README.md) - Relay server documentation

---

## ❓ FAQ

### General Questions

**Q: What is Idena?**
A: Idena is a blockchain network where every user proves they're a unique human through periodic validation ceremonies. No bots, no fake accounts, just verified humans.

**Q: Why do I need an Idena account?**
A: Your Idena address is your verified identity on the network. It proves you're a unique human and allows others to trust who they're communicating with.

**Q: Is this like WhatsApp?**
A: Similar, but with key differences:
- Every user is a verified unique human (no bots)
- Messages are end-to-end encrypted
- Open-source code you can verify
- No company owns or controls your data
- Decentralized infrastructure

**Q: How is this different from Signal or Telegram?**
A: Signal and Telegram are great for privacy, but they don't verify users are unique humans. Anyone can create multiple accounts. Idena P2P ensures every user is a verified person.

### Security Questions

**Q: Are my messages private?**
A: Yes! Messages are encrypted on your device before sending. The relay server only routes encrypted data and cannot read your messages.

**Q: Can the relay server read my messages?**
A: No. Messages are encrypted end-to-end. The relay server only sees encrypted data and routing information (sender/recipient addresses).

**Q: What if the relay server is hacked?**
A: Even if compromised, the relay server cannot decrypt messages. It only has encrypted data, sender/recipient addresses, and timestamps.

**Q: What if I lose my phone?**
A: Your messages are stored locally, so you'll lose access to them. However, your Idena account can be recovered with your mnemonic phrase on a new device.

**Q: Is my mnemonic phrase safe?**
A: Your mnemonic phrase is stored encrypted in platform-secure storage (Keychain on iOS, Keystore on Android). It's protected by your PIN and device security.

### Technical Questions

**Q: Why a centralized relay server for now?**
A: It's simpler for the MVP and allows us to test the system quickly. Phase 3 will implement full P2P using libp2p, removing the central relay.

**Q: What happens if the relay server goes down?**
A: You won't be able to send/receive messages until it's back up. Phase 3 will solve this with fully decentralized P2P.

**Q: Can I run my own relay server?**
A: Yes! The relay server code is open-source. See `relay-server/README.md` for deployment instructions.

**Q: What encryption do you use?**
A: X25519 for key exchange, ChaCha20-Poly1305-AEAD for message encryption, Argon2id for PIN hashing. All industry-standard, battle-tested algorithms.

**Q: Is the code audited?**
A: Community security review completed. Professional third-party audit is pending. Use with caution until audit complete.

### Usage Questions

**Q: Can I message people outside the Idena network?**
A: No, you can only message other Idena users. That's by design - everyone must be a verified unique human.

**Q: Can I delete messages?**
A: Currently, messages are only stored locally on your device. You can delete the conversation, which removes all messages from your device.

**Q: Are there group chats?**
A: Not yet. Group chats are planned for a future update.

**Q: Can I send images or files?**
A: Not yet. Currently text-only. Media sharing is planned for a future update.

**Q: Does this work offline?**
A: You can view existing conversations offline, but you need internet to send/receive new messages.

---

## 🔗 Resources

### Idena Network
- [Idena Website](https://idena.io) - Official website
- [Idena Docs](https://docs.idena.io) - Protocol documentation
- [Idena Explorer](https://scan.idena.io) - Blockchain explorer
- [Idena Discord](https://discord.gg/idena) - Community chat

### Development
- [Flutter Docs](https://docs.flutter.dev/) - Flutter framework
- [Dart Docs](https://dart.dev/guides) - Dart language
- [Node.js Docs](https://nodejs.org/docs/) - Node.js runtime

### Cryptography
- [X25519](https://cr.yp.to/ecdh.html) - Curve25519 key exchange
- [ChaCha20-Poly1305](https://tools.ietf.org/html/rfc7539) - AEAD encryption
- [Argon2](https://github.com/P-H-C/phc-winner-argon2) - Password hashing

### Related Projects
- [idena-lite-api](https://github.com/idenacommunity/idena-lite-api) - Lightweight Idena API
- [my-idena](https://github.com/redDwarf03/my-idena) - Production Idena wallet
- [idena-indexer](https://github.com/idena-network/idena-indexer) - Blockchain indexer

---

## ⚠️ Disclaimer

**IMPORTANT: READ BEFORE USING**

This software is provided "as is", without warranty of any kind, express or implied. While we've implemented industry-standard security practices:

- ✅ Code is open-source and reviewable
- ✅ Community security review completed
- ✅ Critical vulnerabilities fixed
- ⚠️ Professional third-party audit pending
- ⚠️ Limited real-world device testing
- ⚠️ Early development stage (MVP)

**Use at your own risk:**
- This is experimental software
- Not recommended for highly sensitive communications yet
- Always keep your mnemonic phrase safe
- Test thoroughly before relying on it
- Report security issues responsibly

**For production use, wait for:**
- Professional security audit completion
- Extensive real-world testing
- Community validation
- Stable release (v1.0.0)

---

## 📧 Contact & Support

- **GitHub Issues:** [Report bugs or request features](https://github.com/idenacommunity/idena-p2p/issues)
- **Discord:** Join [Idena Community Discord](https://discord.gg/idena)
- **Email:** communityidena@gmail.com (for security issues only)

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

**In short:** You can use, modify, and distribute this software freely, even for commercial purposes, as long as you include the original license and copyright notice.

---

## 🙏 Acknowledgments

**Built with ❤️ by the Idena Community**

Special thanks to:
- The Idena core team for building the proof-of-person network
- All community contributors who helped test and improve this app
- Open-source projects that made this possible (Flutter, Node.js, etc.)

**Contributors:**
- Anonymous community developers (maintaining privacy)
- You! (if you contribute to this project)

---

## 🌟 Star Us!

If you find this project useful, please give it a ⭐ on GitHub! It helps others discover the project and motivates us to keep improving it.

**Share with your Idena community friends!**

---

**Status:** MVP Complete - Ready for Testing
**Version:** 0.2.0-alpha (Messaging MVP)
**Last Updated:** January 14, 2026
**Maintainer:** Idena Community
**License:** MIT
**Website:** [idena.io](https://idena.io)

---

*"Proof-of-person messaging for a bot-free world"* 🚀
