const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const { logger } = require('./utils/logger');
const messageRoutes = require('./routes/messageRoutes');
const publicKeyRoutes = require('./routes/publicKeyRoutes');
const statusRoutes = require('./routes/statusRoutes');
const WebSocketManager = require('./services/websocketManager');
const MessageQueue = require('./services/messageQueue');
const PublicKeyStore = require('./services/publicKeyStore');

// Initialize Express app
const app = express();
const server = http.createServer(app);

// Initialize WebSocket server
const wss = new WebSocket.Server({ server });

// Initialize services
const messageQueue = new MessageQueue();
const publicKeyStore = new PublicKeyStore();
const wsManager = new WebSocketManager(wss, messageQueue, publicKeyStore);

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true
}));
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    connections: wsManager.getConnectionCount(),
    queuedMessages: messageQueue.getTotalQueueSize()
  });
});

// API routes
app.use('/api/messages', messageRoutes);
app.use('/api/public-keys', publicKeyRoutes);
app.use('/api/status', statusRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('API Error:', err);
  res.status(err.status || 500).json({
    error: {
      message: err.message || 'Internal server error',
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: {
      message: 'Endpoint not found',
      path: req.path
    }
  });
});

// Attach services to app for route access
app.locals.wsManager = wsManager;
app.locals.messageQueue = messageQueue;
app.locals.publicKeyStore = publicKeyStore;

// Start server
const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  logger.info(`Idena P2P Relay Server started`);
  logger.info(`HTTP API listening on port ${PORT}`);
  logger.info(`WebSocket server ready`);
  logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    logger.info('HTTP server closed');
    wsManager.closeAll();
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  logger.info('SIGINT signal received: closing HTTP server');
  server.close(() => {
    logger.info('HTTP server closed');
    wsManager.closeAll();
    process.exit(0);
  });
});

module.exports = { app, server, wss };
