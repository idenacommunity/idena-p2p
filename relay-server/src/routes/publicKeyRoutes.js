const express = require('express');
const router = express.Router();
const { logger } = require('../utils/logger');

/**
 * Store/update public key
 * POST /api/public-keys
 * Body: { address, publicKey }
 */
router.post('/', async (req, res) => {
  try {
    const { address, publicKey } = req.body;

    // Validate address
    if (!address || !/^0x[a-fA-F0-9]{40}$/.test(address)) {
      return res.status(400).json({
        error: 'Invalid Idena address format'
      });
    }

    // Validate public key
    if (!publicKey || typeof publicKey !== 'string' || publicKey.length === 0) {
      return res.status(400).json({
        error: 'Invalid public key'
      });
    }

    const publicKeyStore = req.app.locals.publicKeyStore;
    const result = await publicKeyStore.store(address, publicKey);

    res.json({
      success: true,
      address: result.address,
      updatedAt: result.updatedAt
    });
  } catch (error) {
    logger.error('Error storing public key', { error: error.message });
    res.status(500).json({
      error: 'Failed to store public key'
    });
  }
});

/**
 * Get public key for an address
 * GET /api/public-keys/:address
 */
router.get('/:address', async (req, res) => {
  try {
    const { address } = req.params;

    if (!address || !/^0x[a-fA-F0-9]{40}$/.test(address)) {
      return res.status(400).json({
        error: 'Invalid Idena address format'
      });
    }

    const publicKeyStore = req.app.locals.publicKeyStore;
    const keyData = await publicKeyStore.get(address);

    if (!keyData) {
      return res.status(404).json({
        error: 'Public key not found for this address'
      });
    }

    res.json({
      address: keyData.address,
      publicKey: keyData.publicKey,
      updatedAt: keyData.updatedAt,
      createdAt: keyData.createdAt
    });
  } catch (error) {
    logger.error('Error getting public key', { error: error.message });
    res.status(500).json({
      error: 'Failed to retrieve public key'
    });
  }
});

/**
 * Get multiple public keys
 * POST /api/public-keys/batch
 * Body: { addresses: ["0x...", "0x..."] }
 */
router.post('/batch', async (req, res) => {
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

    const publicKeyStore = req.app.locals.publicKeyStore;
    const results = await publicKeyStore.getMultiple(addresses);

    res.json({
      count: Object.keys(results).length,
      keys: results
    });
  } catch (error) {
    logger.error('Error getting multiple public keys', { error: error.message });
    res.status(500).json({
      error: 'Failed to retrieve public keys'
    });
  }
});

/**
 * Check if public key exists
 * HEAD /api/public-keys/:address
 */
router.head('/:address', async (req, res) => {
  try {
    const { address } = req.params;

    if (!address || !/^0x[a-fA-F0-9]{40}$/.test(address)) {
      return res.status(400).end();
    }

    const publicKeyStore = req.app.locals.publicKeyStore;
    const exists = await publicKeyStore.exists(address);

    res.status(exists ? 200 : 404).end();
  } catch (error) {
    logger.error('Error checking public key', { error: error.message });
    res.status(500).end();
  }
});

/**
 * Delete public key
 * DELETE /api/public-keys/:address
 */
router.delete('/:address', async (req, res) => {
  try {
    const { address } = req.params;

    if (!address || !/^0x[a-fA-F0-9]{40}$/.test(address)) {
      return res.status(400).json({
        error: 'Invalid Idena address format'
      });
    }

    const publicKeyStore = req.app.locals.publicKeyStore;
    const deleted = await publicKeyStore.delete(address);

    res.json({
      success: deleted,
      message: deleted ? 'Public key deleted' : 'Public key not found'
    });
  } catch (error) {
    logger.error('Error deleting public key', { error: error.message });
    res.status(500).json({
      error: 'Failed to delete public key'
    });
  }
});

/**
 * Get public key statistics
 * GET /api/public-keys/stats/all
 */
router.get('/stats/all', (req, res) => {
  try {
    const publicKeyStore = req.app.locals.publicKeyStore;
    const stats = publicKeyStore.getStats();

    res.json(stats);
  } catch (error) {
    logger.error('Error getting stats', { error: error.message });
    res.status(500).json({
      error: 'Failed to get statistics'
    });
  }
});

module.exports = router;
