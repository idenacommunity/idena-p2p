const express = require('express');
const router = express.Router();
const { logger } = require('../utils/logger');

/**
 * Check if user is online
 * GET /api/status/:address
 */
router.get('/:address', (req, res) => {
  try {
    const { address } = req.params;

    if (!address || !/^0x[a-fA-F0-9]{40}$/.test(address)) {
      return res.status(400).json({
        error: 'Invalid Idena address format'
      });
    }

    const wsManager = req.app.locals.wsManager;
    const online = wsManager.isOnline(address);

    res.json({
      address: address.toLowerCase(),
      online,
      timestamp: Date.now()
    });
  } catch (error) {
    logger.error('Error checking status', { error: error.message });
    res.status(500).json({
      error: 'Failed to check status'
    });
  }
});

/**
 * Check status of multiple users
 * POST /api/status/batch
 * Body: { addresses: ["0x...", "0x..."] }
 */
router.post('/batch', (req, res) => {
  try {
    const { addresses } = req.body;

    if (!Array.isArray(addresses) || addresses.length === 0) {
      return res.status(400).json({
        error: 'addresses must be a non-empty array'
      });
    }

    // Validate all addresses
    for (const address of addresses) {
      if (!/^0x[a-fA-F0-9]{40}$/.test(address)) {
        return res.status(400).json({
          error: `Invalid address format: ${address}`
        });
      }
    }

    const wsManager = req.app.locals.wsManager;
    const results = {};

    for (const address of addresses) {
      results[address.toLowerCase()] = wsManager.isOnline(address);
    }

    res.json({
      timestamp: Date.now(),
      statuses: results
    });
  } catch (error) {
    logger.error('Error checking batch status', { error: error.message });
    res.status(500).json({
      error: 'Failed to check statuses'
    });
  }
});

/**
 * Get list of all online users
 * GET /api/status/online/all
 */
router.get('/online/all', (req, res) => {
  try {
    const wsManager = req.app.locals.wsManager;
    const onlineUsers = wsManager.getOnlineUsers();

    res.json({
      count: onlineUsers.length,
      users: onlineUsers,
      timestamp: Date.now()
    });
  } catch (error) {
    logger.error('Error getting online users', { error: error.message });
    res.status(500).json({
      error: 'Failed to get online users'
    });
  }
});

module.exports = router;
