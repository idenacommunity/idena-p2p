const { logger } = require('../utils/logger');

/**
 * WebSocket Manager - Handles WebSocket connections and message routing
 */
class WebSocketManager {
  constructor(wss, messageQueue, publicKeyStore) {
    this.wss = wss;
    this.messageQueue = messageQueue;
    this.publicKeyStore = publicKeyStore;

    // Map of address -> WebSocket connection
    this.connections = new Map();

    // Map of address -> last activity timestamp
    this.lastActivity = new Map();

    this.setupWebSocketServer();
    this.startHeartbeat();
  }

  /**
   * Setup WebSocket server event handlers
   */
  setupWebSocketServer() {
    this.wss.on('connection', (ws, req) => {
      logger.info('New WebSocket connection', { ip: req.socket.remoteAddress });

      // Handle authentication message
      let authenticated = false;
      let userAddress = null;

      ws.on('message', async (data) => {
        try {
          const message = JSON.parse(data.toString());

          // First message must be authentication
          if (!authenticated) {
            if (message.type === 'auth' && message.address) {
              userAddress = message.address.toLowerCase();
              this.connections.set(userAddress, ws);
              this.lastActivity.set(userAddress, Date.now());
              authenticated = true;

              logger.info('User authenticated', { address: userAddress });

              // Send authentication success
              ws.send(JSON.stringify({
                type: 'auth_success',
                address: userAddress,
                timestamp: Date.now()
              }));

              // Broadcast online status
              this.broadcastStatus(userAddress, 'online');

              // Send any queued messages
              await this.deliverQueuedMessages(userAddress, ws);
            } else {
              ws.send(JSON.stringify({
                type: 'error',
                message: 'Authentication required'
              }));
              ws.close();
            }
            return;
          }

          // Update last activity
          this.lastActivity.set(userAddress, Date.now());

          // Handle different message types
          switch (message.type) {
            case 'message':
              await this.handleMessage(userAddress, message, ws);
              break;

            case 'typing':
              this.handleTyping(userAddress, message);
              break;

            case 'read_receipt':
              this.handleReadReceipt(userAddress, message);
              break;

            case 'ping':
              ws.send(JSON.stringify({ type: 'pong', timestamp: Date.now() }));
              break;

            default:
              logger.warn('Unknown message type', { type: message.type });
          }
        } catch (error) {
          logger.error('Error handling WebSocket message', { error: error.message });
          ws.send(JSON.stringify({
            type: 'error',
            message: 'Failed to process message'
          }));
        }
      });

      ws.on('close', () => {
        if (authenticated && userAddress) {
          this.connections.delete(userAddress);
          this.lastActivity.delete(userAddress);
          this.broadcastStatus(userAddress, 'offline');
          logger.info('User disconnected', { address: userAddress });
        }
      });

      ws.on('error', (error) => {
        logger.error('WebSocket error', { error: error.message, address: userAddress });
      });
    });
  }

  /**
   * Handle incoming message
   */
  async handleMessage(fromAddress, message, ws) {
    const { to, content, messageId, timestamp } = message;

    if (!to || !content || !messageId) {
      ws.send(JSON.stringify({
        type: 'error',
        messageId,
        message: 'Invalid message format'
      }));
      return;
    }

    const recipientAddress = to.toLowerCase();

    // Check if recipient is online
    const recipientWs = this.connections.get(recipientAddress);

    if (recipientWs && recipientWs.readyState === 1) { // 1 = OPEN
      // Recipient is online - deliver immediately
      recipientWs.send(JSON.stringify({
        type: 'message',
        from: fromAddress,
        content,
        messageId,
        timestamp: timestamp || Date.now()
      }));

      // Send delivery confirmation to sender
      ws.send(JSON.stringify({
        type: 'delivered',
        messageId,
        to: recipientAddress,
        timestamp: Date.now()
      }));

      logger.debug('Message delivered', {
        from: fromAddress,
        to: recipientAddress,
        messageId
      });
    } else {
      // Recipient is offline - queue the message
      await this.messageQueue.enqueue(recipientAddress, {
        from: fromAddress,
        content,
        messageId,
        timestamp: timestamp || Date.now()
      });

      // Send queued confirmation to sender
      ws.send(JSON.stringify({
        type: 'queued',
        messageId,
        to: recipientAddress,
        timestamp: Date.now()
      }));

      logger.debug('Message queued', {
        from: fromAddress,
        to: recipientAddress,
        messageId
      });
    }
  }

  /**
   * Handle typing indicator
   */
  handleTyping(fromAddress, message) {
    const { to, isTyping } = message;
    if (!to) return;

    const recipientAddress = to.toLowerCase();
    const recipientWs = this.connections.get(recipientAddress);

    if (recipientWs && recipientWs.readyState === 1) {
      recipientWs.send(JSON.stringify({
        type: 'typing',
        from: fromAddress,
        isTyping
      }));
    }
  }

  /**
   * Handle read receipt
   */
  handleReadReceipt(fromAddress, message) {
    const { to, messageId } = message;
    if (!to || !messageId) return;

    const recipientAddress = to.toLowerCase();
    const recipientWs = this.connections.get(recipientAddress);

    if (recipientWs && recipientWs.readyState === 1) {
      recipientWs.send(JSON.stringify({
        type: 'read',
        from: fromAddress,
        messageId,
        timestamp: Date.now()
      }));
    }
  }

  /**
   * Deliver queued messages to user
   */
  async deliverQueuedMessages(address, ws) {
    const queuedMessages = await this.messageQueue.dequeue(address);

    if (queuedMessages.length > 0) {
      logger.info(`Delivering ${queuedMessages.length} queued messages`, { address });

      for (const msg of queuedMessages) {
        ws.send(JSON.stringify({
          type: 'message',
          from: msg.from,
          content: msg.content,
          messageId: msg.messageId,
          timestamp: msg.timestamp,
          queued: true
        }));
      }
    }
  }

  /**
   * Broadcast online/offline status to contacts
   */
  broadcastStatus(address, status) {
    // In a full implementation, this would check the user's contact list
    // and only broadcast to their contacts
    // For MVP, we skip this to keep it simple
    logger.debug('Status update', { address, status });
  }

  /**
   * Check if user is online
   */
  isOnline(address) {
    const ws = this.connections.get(address.toLowerCase());
    return ws && ws.readyState === 1;
  }

  /**
   * Get connection count
   */
  getConnectionCount() {
    return this.connections.size;
  }

  /**
   * Get online users list
   */
  getOnlineUsers() {
    return Array.from(this.connections.keys());
  }

  /**
   * Start heartbeat to detect stale connections
   */
  startHeartbeat() {
    setInterval(() => {
      const now = Date.now();
      const timeout = 60000; // 60 seconds

      for (const [address, lastActive] of this.lastActivity.entries()) {
        if (now - lastActive > timeout) {
          const ws = this.connections.get(address);
          if (ws) {
            logger.warn('Closing stale connection', { address });
            ws.close();
          }
        }
      }
    }, 30000); // Check every 30 seconds
  }

  /**
   * Close all connections
   */
  closeAll() {
    logger.info('Closing all WebSocket connections');
    for (const ws of this.connections.values()) {
      ws.close();
    }
    this.connections.clear();
    this.lastActivity.clear();
  }
}

module.exports = WebSocketManager;
