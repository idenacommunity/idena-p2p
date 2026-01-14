# Idena P2P Messaging - Quick Start Guide

**Version**: Phase 1.5 MVP
**Date**: January 14, 2026

## What's Implemented

✅ **Phase 1: UI & Local Storage** (Complete)
- Contact management
- Conversation list
- Chat screen with message bubbles
- End-to-end encryption (X25519 + ChaCha20-Poly1305)
- Local message storage (Hive)

✅ **Phase 1.5: Relay Server** (Complete)
- Node.js/Express relay server
- WebSocket real-time messaging
- Message queue for offline users
- Public key exchange API
- Online/offline status tracking

❌ **Phase 2: Integration** (Next Step)
- Connect Flutter app to relay server
- Real message transmission over network
- Push notifications

## Prerequisites

- Flutter SDK (latest stable)
- Node.js >= 18.0.0
- Android device/emulator or iOS device/simulator
- Git

## Quick Start (5 Minutes)

### Step 1: Clone Repository

```bash
git clone https://github.com/idenacommunity/idena-p2p.git
cd idena-p2p
```

### Step 2: Start Relay Server

```bash
cd relay-server

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Start server
npm run dev
```

**Expected Output:**
```
[INFO] Idena P2P Relay Server started
[INFO] HTTP API listening on port 3002
[INFO] WebSocket server ready
```

✅ Leave this terminal open (server running)

### Step 3: Test Relay Server

**In a new terminal:**

```bash
# Test health endpoint
curl http://localhost:3002/health

# Expected response:
# {"status":"ok","timestamp":"...","uptime":...,"connections":0,"queuedMessages":0}
```

### Step 4: Build & Run Flutter App

**In a new terminal:**

```bash
# Navigate back to project root
cd ..

# Get Flutter dependencies
flutter pub get

# List available devices
flutter devices

# Run on connected device/emulator
flutter run

# Or build and install APK
flutter build apk --debug
flutter install
```

### Step 5: Test the App

1. **Open app** → Authenticate with PIN/biometric
2. **Add contacts:**
   - Tap Contacts icon (people)
   - Tap + button
   - Enter Idena address (e.g., `0x1234567890123456789012345678901234567890`)
   - Optional: Add nickname

3. **View messages:**
   - Tap Messages icon (chat bubble)
   - See empty state (no conversations yet)

4. **Start conversation:**
   - Tap + button
   - Select a contact
   - Chat screen opens

5. **Send message:**
   - Type a message
   - Tap send button
   - Message appears in chat (currently local only)

**Note:** Messages are currently stored locally only. Phase 2 will connect to the relay server for real network transmission.

## Architecture Overview

```
┌─────────────────────┐
│   Flutter App       │  ← Phase 1 Complete
│  ┌──────────────┐   │     - UI screens
│  │ Conversations│   │     - Local storage
│  │ Chat Screen  │   │     - Encryption
│  │ Contacts     │   │
│  └──────────────┘   │
│         │           │
│  ┌──────▼────────┐  │
│  │ Hive Database │  │  ← Local messages
│  └───────────────┘  │
└─────────────────────┘
         │
         │ ❌ Not yet connected
         │
┌────────▼────────────┐
│  Relay Server       │  ← Phase 1.5 Complete
│  ┌──────────────┐   │     - WebSocket
│  │ WebSocket Mgr│   │     - Message queue
│  │ Message Queue│   │     - Public keys
│  │ Key Store    │   │
│  └──────────────┘   │
└─────────────────────┘
```

## Testing Scenarios

### Scenario 1: Add and View Contacts

```
1. Open app
2. Tap Contacts
3. Add contact with address: 0x1234567890123456789012345678901234567890
4. Add nickname: "Test User"
5. Contact appears in list with identity badge
6. Tap contact to view details
7. See trust level, identity age, etc.
```

### Scenario 2: Local Messaging (Phase 1)

```
1. Open app
2. Tap Messages icon
3. Tap + to start new conversation
4. Select a contact
5. Send a message: "Hello!"
6. Message appears in chat
7. Go back to conversation list
8. See conversation with last message preview
```

### Scenario 3: Test Relay Server

```bash
# Terminal 1: Start relay server
cd relay-server
npm run dev

# Terminal 2: Test WebSocket with wscat
npm install -g wscat
wscat -c ws://localhost:3002

# Authenticate
{"type":"auth","address":"0x1234567890123456789012345678901234567890"}

# Send message
{"type":"message","to":"0x9876543210987654321098765432109876543210","content":"encrypted_content","messageId":"abc123","timestamp":1705234567890}

# You'll receive: {"type":"queued",...} or {"type":"delivered",...}
```

### Scenario 4: Public Key Exchange

```bash
# Store public key
curl -X POST http://localhost:3002/api/public-keys \
  -H "Content-Type: application/json" \
  -d '{
    "address": "0x1234567890123456789012345678901234567890",
    "publicKey": "testPublicKey123"
  }'

# Get public key
curl http://localhost:3002/api/public-keys/0x1234567890123456789012345678901234567890
```

## Project Files

### Flutter App
```
lib/
├── models/
│   ├── contact.dart              # Contact model
│   ├── message.dart              # Message model
│   └── idena_account.dart        # Account model
├── providers/
│   ├── contact_provider.dart     # Contact state
│   ├── messaging_provider.dart   # Messaging state
│   └── account_provider.dart     # Account state
├── screens/
│   ├── contacts/                 # Contact screens
│   │   ├── contacts_list_screen.dart
│   │   ├── add_contact_screen.dart
│   │   └── contact_detail_screen.dart
│   ├── messaging/                # Messaging screens
│   │   ├── conversations_screen.dart
│   │   └── chat_screen.dart
│   └── home_screen.dart          # Main home screen
├── services/
│   ├── contact_service.dart      # Contact management
│   ├── message_storage_service.dart     # Local storage
│   └── messaging_encryption_service.dart # E2E encryption
└── main.dart                     # App entry point
```

### Relay Server
```
relay-server/
├── src/
│   ├── server.js                 # Main server
│   ├── routes/                   # REST API routes
│   ├── services/                 # Core services
│   └── utils/                    # Utilities
├── package.json
├── .env                          # Configuration
└── README.md                     # Documentation
```

## Development Workflow

### Working on Flutter App

```bash
# Start with hot reload
flutter run

# Make changes to code
# Hot reload: Press 'r' in terminal
# Hot restart: Press 'R' in terminal

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format lib/
```

### Working on Relay Server

```bash
cd relay-server

# Start with auto-restart on changes
npm run dev

# Make changes to code
# Server automatically restarts

# View logs
tail -f /tmp/relay-server.log

# Test endpoints
curl http://localhost:3002/health
```

### Common Development Tasks

**Add new feature to Flutter:**
1. Create/modify models in `lib/models/`
2. Update providers in `lib/providers/`
3. Create/modify screens in `lib/screens/`
4. Test with `flutter run`

**Add new API endpoint:**
1. Create route in `relay-server/src/routes/`
2. Update service in `relay-server/src/services/`
3. Test with curl or Postman
4. Update README.md with endpoint docs

## Troubleshooting

### Flutter App Issues

**Issue:** Build fails
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**Issue:** Contacts not showing
```bash
# Check Hive database initialization
# Look for logs in debug console
```

**Issue:** Authentication fails
```bash
# Clear app data and try again
flutter run
# Reinstall app if needed
```

### Relay Server Issues

**Issue:** Port already in use
```bash
# Change port in .env
PORT=3003

# Or kill existing process
pkill -f "node src/server.js"
```

**Issue:** WebSocket won't connect
```bash
# Check server is running
curl http://localhost:3002/health

# Check firewall
# Verify URL format: ws://localhost:3002 (not http://)
```

**Issue:** Messages not routing
```bash
# Check server logs
# Verify authentication succeeded
# Check recipient is online
curl http://localhost:3002/api/status/:address
```

## Next Steps

### Phase 2: Flutter Integration (Immediate)

**Tasks:**
1. Add WebSocket service to Flutter app
2. Connect to relay server on app start
3. Upload user public key to server
4. Fetch contact public keys before encrypting
5. Send messages via WebSocket instead of local-only
6. Receive messages from WebSocket
7. Update delivery status based on server responses

**Files to Modify:**
- Create: `lib/services/relay_websocket_service.dart`
- Update: `lib/providers/messaging_provider.dart`
- Update: `lib/models/contact.dart` (add `publicKey` field)
- Update: `lib/screens/messaging/chat_screen.dart`

### Phase 3: P2P Decentralization (Future)

**Goals:**
- Replace centralized relay with libp2p
- DHT for peer discovery
- IPFS for offline message storage
- Direct peer-to-peer connections

## Resources

### Documentation
- **Phase 1 Summary**: `PHASE1_IMPLEMENTATION_SUMMARY.md`
- **Phase 1.5 Summary**: `PHASE1.5_RELAY_SERVER_SUMMARY.md`
- **Relay Server README**: `relay-server/README.md`
- **Project CLAUDE.md**: Development guidance

### Testing Files
- **Phase 0 Results**: `PHASE0_TEST_RESULTS.md`
- **Unit Tests**: `test/models/contact_model_test.dart`

### API References
- **Relay Server API**: See `relay-server/README.md` for full API docs
- **WebSocket Protocol**: See relay server README for message formats

## Getting Help

**Issues:**
- GitHub: https://github.com/idenacommunity/idena-p2p/issues

**Community:**
- Discord: Idena Network server
- Forum: discuss.idena.io

**Development:**
- Use Claude Code for AI-assisted development
- Share CLAUDE.md files for context

## Contributing

This is a community project. Contributions welcome!

**Guidelines:**
1. Use anonymous commits (Idena Community)
2. Follow existing code style
3. Add tests for new features
4. Update documentation
5. Submit pull requests

**Git Configuration:**
```bash
git config user.name "Idena Community"
git config user.email "communityidena@gmail.com"
```

---

**Happy Coding!** 🚀

Built with ❤️ by the Idena Community
