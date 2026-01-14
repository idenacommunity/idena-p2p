const { logger } = require('../utils/logger');

/**
 * Public Key Store - Manages user public keys for E2E encryption
 * In production, this should use a database
 * For MVP, we use in-memory storage
 */
class PublicKeyStore {
  constructor() {
    // Map of address -> public key data
    this.keys = new Map();
  }

  /**
   * Store or update public key for an address
   */
  async store(address, publicKey) {
    const normalizedAddress = address.toLowerCase();

    if (!publicKey || typeof publicKey !== 'string') {
      throw new Error('Invalid public key format');
    }

    const keyData = {
      address: normalizedAddress,
      publicKey,
      updatedAt: Date.now(),
      createdAt: this.keys.has(normalizedAddress)
        ? this.keys.get(normalizedAddress).createdAt
        : Date.now()
    };

    this.keys.set(normalizedAddress, keyData);

    logger.debug('Public key stored', {
      address: normalizedAddress,
      keyLength: publicKey.length
    });

    return keyData;
  }

  /**
   * Get public key for an address
   */
  async get(address) {
    const normalizedAddress = address.toLowerCase();
    const keyData = this.keys.get(normalizedAddress);

    if (!keyData) {
      return null;
    }

    return keyData;
  }

  /**
   * Get multiple public keys
   */
  async getMultiple(addresses) {
    const results = {};

    for (const address of addresses) {
      const normalizedAddress = address.toLowerCase();
      const keyData = this.keys.get(normalizedAddress);

      if (keyData) {
        results[normalizedAddress] = keyData;
      }
    }

    return results;
  }

  /**
   * Check if public key exists for address
   */
  async exists(address) {
    const normalizedAddress = address.toLowerCase();
    return this.keys.has(normalizedAddress);
  }

  /**
   * Delete public key
   */
  async delete(address) {
    const normalizedAddress = address.toLowerCase();
    const deleted = this.keys.delete(normalizedAddress);

    if (deleted) {
      logger.info('Public key deleted', { address: normalizedAddress });
    }

    return deleted;
  }

  /**
   * Get total number of stored keys
   */
  getCount() {
    return this.keys.size;
  }

  /**
   * Get statistics
   */
  getStats() {
    return {
      totalKeys: this.keys.size,
      addresses: Array.from(this.keys.keys())
    };
  }

  /**
   * Clear all keys (for testing)
   */
  clear() {
    const count = this.keys.size;
    this.keys.clear();
    logger.warn('All public keys cleared', { count });
    return count;
  }
}

module.exports = PublicKeyStore;
