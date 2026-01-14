# Idena P2P Relay Server

**Version**: 1.0.0 (Phase 1.5 MVP)

A lightweight relay server for routing encrypted messages between Idena P2P messaging app users.

## Features

- ✅ **WebSocket Server** - Real-time bidirectional communication
- ✅ **Message Routing** - Route encrypted messages between users
- ✅ **Message Queue** - Store messages for offline users (up to 7 days)
- ✅ **Public Key Exchange** - Facilitate E2E encryption key distribution
- ✅ **Online/Offline Status** - Track user presence
- ✅ **RESTful API** - HTTP endpoints for message management
- ✅ **Connection Management** - Automatic cleanup of stale connections
- ✅ **In-Memory Storage** - Fast MVP implementation (upgradeable to Redis/DB)

## Architecture

```
┌─────────────────┐
│  Flutter App A  │
└────────┬────────┘
         │ WebSocket
         ├──────────────┐
         │              │
    ┌────▼─────────────▼────┐
    │   Relay Server         │
    │  ┌─────────────────┐  │
    │  │ WebSocket Mgr   │  │
    │  ├─────────────────┤  │
    │  │ Message Queue   │  │
    │  ├─────────────────┤  │
    │  │ Public Key Store│  │
    │  └─────────────────┘  │
    └────┬─────────────┬────┘
         │             │
         │ WebSocket   │
┌────────▼────────┐   │
│  Flutter App B  │   │
└─────────────────┘   │
                      │
            ┌─────────▼────────┐
            │  Flutter App C   │
            └──────────────────┘
```

## Quick Start

### Prerequisites

- Node.js >= 18.0.0
- npm or yarn

### Installation

```bash
# Navigate to relay server directory
cd relay-server

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your configuration
nano .env

# Start development server
npm run dev

# Or start production server
npm start
```

### Environment Variables

```env
PORT=3000                      # HTTP API port
NODE_ENV=development          # development | production
ALLOWED_ORIGINS=*             # CORS origins (comma-separated)
RATE_LIMIT_MAX_REQUESTS=100   # Max requests per window
MAX_OFFLINE_MESSAGES=1000     # Max queued messages per user
MESSAGE_RETENTION_HOURS=168   # Message expiration (7 days)
LOG_LEVEL=info                # error | warn | info | debug
```

## API Reference

### WebSocket API

#### Connect and Authenticate

```javascript
// Connect to WebSocket
const ws = new WebSocket('ws://localhost:3000');

// Authenticate (REQUIRED as first message)
ws.send(JSON.stringify({
  type: 'auth',
  address: '0x1234567890123456789012345678901234567890'
}));

// Server responds
{
  type: 'auth_success',
  address: '0x1234567890123456789012345678901234567890',
  timestamp: 1705234567890
}
```

#### Send Message

```javascript
ws.send(JSON.stringify({
  type: 'message',
  to: '0xRecipientAddress...',
  content: 'base64EncodedEncryptedMessage',
  messageId: 'uuid-v4',
  timestamp: 1705234567890
}));

// Server responds (if recipient online)
{
  type: 'delivered',
  messageId: 'uuid-v4',
  to: '0xRecipientAddress...',
  timestamp: 1705234567890
}

// Or (if recipient offline)
{
  type: 'queued',
  messageId: 'uuid-v4',
  to: '0xRecipientAddress...',
  timestamp: 1705234567890
}
```

#### Receive Message

```javascript
// Recipient receives
{
  type: 'message',
  from: '0xSenderAddress...',
  content: 'base64EncodedEncryptedMessage',
  messageId: 'uuid-v4',
  timestamp: 1705234567890,
  queued: false  // true if delivered from queue
}
```

#### Typing Indicator

```javascript
// Send typing status
ws.send(JSON.stringify({
  type: 'typing',
  to: '0xRecipientAddress...',
  isTyping: true
}));

// Recipient receives
{
  type: 'typing',
  from: '0xSenderAddress...',
  isTyping: true
}
```

#### Read Receipt

```javascript
// Send read receipt
ws.send(JSON.stringify({
  type: 'read_receipt',
  to: '0xSenderAddress...',
  messageId: 'uuid-v4'
}));

// Sender receives
{
  type: 'read',
  from: '0xRecipientAddress...',
  messageId: 'uuid-v4',
  timestamp: 1705234567890
}
```

#### Heartbeat

```javascript
// Keep connection alive
ws.send(JSON.stringify({ type: 'ping' }));

// Server responds
{ type: 'pong', timestamp: 1705234567890 }
```

### REST API

#### Health Check

```http
GET /health
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-01-14T...",
  "uptime": 12345,
  "connections": 5,
  "queuedMessages": 10
}
```

#### Public Key Management

**Store Public Key:**
```http
POST /api/public-keys
Content-Type: application/json

{
  "address": "0x1234567890123456789012345678901234567890",
  "publicKey": "base64EncodedPublicKey"
}
```

**Get Public Key:**
```http
GET /api/public-keys/:address
```

**Get Multiple Public Keys:**
```http
POST /api/public-keys/batch
Content-Type: application/json

{
  "addresses": ["0x...", "0x..."]
}
```

**Check if Key Exists:**
```http
HEAD /api/public-keys/:address
```

**Delete Public Key:**
```http
DELETE /api/public-keys/:address
```

#### Message Queue

**Get Queued Messages:**
```http
GET /api/messages/:address
```

**Get Queue Size:**
```http
GET /api/messages/:address/queue-size
```

**Clear Queue:**
```http
DELETE /api/messages/:address
```

**Get Queue Statistics:**
```http
GET /api/messages/stats/all
```

#### Online Status

**Check User Status:**
```http
GET /api/status/:address
```

**Response:**
```json
{
  "address": "0x1234...",
  "online": true,
  "timestamp": 1705234567890
}
```

**Check Multiple Users:**
```http
POST /api/status/batch
Content-Type: application/json

{
  "addresses": ["0x...", "0x..."]
}
```

**Get All Online Users:**
```http
GET /api/status/online/all
```

## Project Structure

```
relay-server/
├── src/
│   ├── server.js                 # Main server file
│   ├── routes/
│   │   ├── messageRoutes.js     # Message queue API
│   │   ├── publicKeyRoutes.js   # Public key API
│   │   └── statusRoutes.js      # Online status API
│   ├── services/
│   │   ├── websocketManager.js  # WebSocket connection management
│   │   ├── messageQueue.js      # Offline message queue
│   │   └── publicKeyStore.js    # Public key storage
│   └── utils/
│       └── logger.js             # Logging utility
├── package.json
├── .env.example
└── README.md
```

## Security Considerations

### What the Relay Server DOES NOT See

✅ **Message Content**: All messages are encrypted end-to-end by clients
✅ **Private Keys**: Never transmitted to or stored on the server
✅ **Decrypted Messages**: Server only routes encrypted payloads

### What the Relay Server DOES See

⚠️ **Metadata**:
- Sender and recipient addresses
- Message timestamps
- Message sizes
- Online/offline status
- Connection patterns

### Recommendations

1. **Use HTTPS/WSS** in production (TLS encryption)
2. **Implement rate limiting** to prevent abuse
3. **Add authentication** for API endpoints
4. **Monitor logs** for suspicious activity
5. **Rotate keys regularly** on client side
6. **Use Redis/Database** for production (not in-memory)

## Deployment

### Option 1: VPS (Hetzner, DigitalOcean, etc.)

```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Clone repository
git clone https://github.com/idenacommunity/idena-p2p.git
cd idena-p2p/relay-server

# Install dependencies
npm install --production

# Set up systemd service
sudo nano /etc/systemd/system/idena-relay.service
```

**Systemd Service File:**
```ini
[Unit]
Description=Idena P2P Relay Server
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/relay-server
ExecStart=/usr/bin/node src/server.js
Restart=always
Environment=NODE_ENV=production
Environment=PORT=3000

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start service
sudo systemctl enable idena-relay
sudo systemctl start idena-relay
sudo systemctl status idena-relay
```

### Option 2: Docker

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY src ./src

EXPOSE 3000

CMD ["node", "src/server.js"]
```

```bash
# Build and run
docker build -t idena-relay .
docker run -d -p 3000:3000 --name idena-relay idena-relay
```

### Option 3: Cloud Platform (Railway, Fly.io, Render)

1. Connect GitHub repository
2. Select `relay-server` directory as root
3. Set environment variables
4. Deploy automatically

## Monitoring

### Logs

```bash
# View logs
journalctl -u idena-relay -f

# Or with Docker
docker logs -f idena-relay
```

### Metrics

Monitor these key metrics:
- **Active Connections**: Number of connected users
- **Queued Messages**: Messages waiting for offline users
- **Message Throughput**: Messages/second
- **Memory Usage**: Should stay under 512MB for MVP
- **Error Rate**: Track failed message deliveries

## Scaling

### Current Limitations (MVP)

- In-memory storage (lost on restart)
- Single server instance (no horizontal scaling)
- No persistent message history
- No push notifications

### Future Improvements (Phase 2+)

- **Redis** for message queue and presence
- **PostgreSQL** for public keys and message history
- **Load Balancer** for multiple server instances
- **Sticky Sessions** for WebSocket connections
- **Push Notifications** via FCM/APNS
- **Message Encryption** at rest (database)
- **Authentication** via JWT or OAuth

## Testing

### Manual Testing with wscat

```bash
# Install wscat
npm install -g wscat

# Connect to WebSocket
wscat -c ws://localhost:3000

# Send authentication
{"type":"auth","address":"0x1234567890123456789012345678901234567890"}

# Send message
{"type":"message","to":"0x9876543210987654321098765432109876543210","content":"test","messageId":"abc123","timestamp":1705234567890}
```

### Testing REST API with curl

```bash
# Health check
curl http://localhost:3000/health

# Store public key
curl -X POST http://localhost:3000/api/public-keys \
  -H "Content-Type: application/json" \
  -d '{"address":"0x1234...","publicKey":"testkey123"}'

# Get public key
curl http://localhost:3000/api/public-keys/0x1234...

# Check status
curl http://localhost:3000/api/status/0x1234...
```

## Troubleshooting

### Connection Issues

**Problem**: WebSocket connection fails
**Solution**:
- Check firewall allows port 3000
- Verify CORS settings in .env
- Check WebSocket URL format (ws:// not http://)

### Message Not Delivered

**Problem**: Messages not reaching recipient
**Solution**:
- Verify recipient authenticated successfully
- Check recipient is online (`GET /api/status/:address`)
- Check message queue (`GET /api/messages/:address/queue-size`)
- Review server logs for errors

### High Memory Usage

**Problem**: Server memory grows over time
**Solution**:
- Restart server to clear in-memory queues
- Reduce `MESSAGE_RETENTION_HOURS`
- Implement Redis for production use

## Contributing

This is a community project. Contributions welcome!

**Guidelines:**
- Follow existing code style
- Add tests for new features
- Update documentation
- Use anonymous commits (Idena Community)

## License

MIT License - See LICENSE file

## Support

- **GitHub Issues**: https://github.com/idenacommunity/idena-p2p/issues
- **Discord**: Idena Network server

---

**Built with ❤️ by the Idena Community**
**Last updated**: January 14, 2026
