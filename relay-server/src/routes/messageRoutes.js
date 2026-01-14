const express = require('express');
const router = express.Router();
const { logger } = require('../utils/logger');

/**
 * Get queued messages for an address
 * GET /api/messages/:address
 */
router.get('/:address', async (req, res) => {
  try {
    const { address } = req.params;
    const { limit } = req.query;

    if (!address || !/^0x[a-fA-F0-9]{40}$/.test(address)) {
      return res.status(400).json({
        error: 'Invalid Idena address format'
      });
    }

    const messageQueue = req.app.locals.messageQueue;
    const messages = limit
      ? messageQueue.peek(address, parseInt(limit))
      : await messageQueue.dequeue(address);

    res.json({
      address: address.toLowerCase(),
      count: messages.length,
      messages
    });
  } catch (error) {
    logger.error('Error getting messages', { error: error.message });
    res.status(500).json({
      error: 'Failed to retrieve messages'
    });
  }
});

/**
 * Get queue size for an address
 * GET /api/messages/:address/queue-size
 */
router.get('/:address/queue-size', (req, res) => {
  try {
    const { address } = req.params;

    if (!address || !/^0x[a-fA-F0-9]{40}$/.test(address)) {
      return res.status(400).json({
        error: 'Invalid Idena address format'
      });
    }

    const messageQueue = req.app.locals.messageQueue;
    const size = messageQueue.getQueueSize(address);

    res.json({
      address: address.toLowerCase(),
      queueSize: size
    });
  } catch (error) {
    logger.error('Error getting queue size', { error: error.message });
    res.status(500).json({
      error: 'Failed to get queue size'
    });
  }
});

/**
 * Clear message queue for an address (for testing)
 * DELETE /api/messages/:address
 */
router.delete('/:address', (req, res) => {
  try {
    const { address } = req.params;

    if (!address || !/^0x[a-fA-F0-9]{40}$/.test(address)) {
      return res.status(400).json({
        error: 'Invalid Idena address format'
      });
    }

    const messageQueue = req.app.locals.messageQueue;
    const cleared = messageQueue.clear(address);

    res.json({
      address: address.toLowerCase(),
      cleared,
      message: cleared ? 'Queue cleared' : 'No messages to clear'
    });
  } catch (error) {
    logger.error('Error clearing queue', { error: error.message });
    res.status(500).json({
      error: 'Failed to clear queue'
    });
  }
});

/**
 * Get message queue statistics
 * GET /api/messages/stats
 */
router.get('/stats/all', (req, res) => {
  try {
    const messageQueue = req.app.locals.messageQueue;
    const stats = messageQueue.getStats();

    res.json(stats);
  } catch (error) {
    logger.error('Error getting stats', { error: error.message });
    res.status(500).json({
      error: 'Failed to get statistics'
    });
  }
});

module.exports = router;
