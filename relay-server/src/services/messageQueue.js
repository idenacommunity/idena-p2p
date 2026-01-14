const { logger } = require('../utils/logger');

/**
 * Message Queue - Stores messages for offline users
 * In production, this should use Redis or a database
 * For MVP, we use in-memory storage
 */
class MessageQueue {
  constructor() {
    // Map of address -> array of messages
    this.queues = new Map();

    // Configuration
    this.maxMessagesPerUser = parseInt(process.env.MAX_OFFLINE_MESSAGES) || 1000;
    this.retentionHours = parseInt(process.env.MESSAGE_RETENTION_HOURS) || 168; // 7 days

    // Start cleanup interval
    this.startCleanup();
  }

  /**
   * Add message to queue
   */
  async enqueue(address, message) {
    const normalizedAddress = address.toLowerCase();

    if (!this.queues.has(normalizedAddress)) {
      this.queues.set(normalizedAddress, []);
    }

    const queue = this.queues.get(normalizedAddress);

    // Check queue size limit
    if (queue.length >= this.maxMessagesPerUser) {
      logger.warn('Queue full for user', {
        address: normalizedAddress,
        size: queue.length
      });
      // Remove oldest message
      queue.shift();
    }

    // Add timestamp for expiration tracking
    const queuedMessage = {
      ...message,
      queuedAt: Date.now()
    };

    queue.push(queuedMessage);

    logger.debug('Message enqueued', {
      address: normalizedAddress,
      messageId: message.messageId,
      queueSize: queue.length
    });

    return true;
  }

  /**
   * Get and remove all messages for user
   */
  async dequeue(address) {
    const normalizedAddress = address.toLowerCase();
    const queue = this.queues.get(normalizedAddress);

    if (!queue || queue.length === 0) {
      return [];
    }

    // Get all messages
    const messages = [...queue];

    // Clear queue
    this.queues.delete(normalizedAddress);

    logger.debug('Messages dequeued', {
      address: normalizedAddress,
      count: messages.length
    });

    return messages;
  }

  /**
   * Get queue size for specific user
   */
  getQueueSize(address) {
    const normalizedAddress = address.toLowerCase();
    const queue = this.queues.get(normalizedAddress);
    return queue ? queue.length : 0;
  }

  /**
   * Get total queued messages across all users
   */
  getTotalQueueSize() {
    let total = 0;
    for (const queue of this.queues.values()) {
      total += queue.length;
    }
    return total;
  }

  /**
   * Peek at messages without removing them
   */
  peek(address, limit = 10) {
    const normalizedAddress = address.toLowerCase();
    const queue = this.queues.get(normalizedAddress);

    if (!queue || queue.length === 0) {
      return [];
    }

    return queue.slice(0, limit);
  }

  /**
   * Clear all messages for a user
   */
  clear(address) {
    const normalizedAddress = address.toLowerCase();
    const deleted = this.queues.delete(normalizedAddress);

    if (deleted) {
      logger.info('Queue cleared', { address: normalizedAddress });
    }

    return deleted;
  }

  /**
   * Start cleanup interval to remove expired messages
   */
  startCleanup() {
    const cleanupInterval = 3600000; // 1 hour

    setInterval(() => {
      this.cleanup();
    }, cleanupInterval);

    logger.info('Message queue cleanup started', {
      interval: `${cleanupInterval / 1000}s`,
      retention: `${this.retentionHours}h`
    });
  }

  /**
   * Remove expired messages
   */
  cleanup() {
    const now = Date.now();
    const expirationTime = this.retentionHours * 3600000; // hours to ms
    let totalRemoved = 0;

    for (const [address, queue] of this.queues.entries()) {
      const originalLength = queue.length;

      // Filter out expired messages
      const filteredQueue = queue.filter(msg => {
        const age = now - msg.queuedAt;
        return age < expirationTime;
      });

      const removed = originalLength - filteredQueue.length;

      if (removed > 0) {
        if (filteredQueue.length === 0) {
          this.queues.delete(address);
        } else {
          this.queues.set(address, filteredQueue);
        }
        totalRemoved += removed;
      }
    }

    if (totalRemoved > 0) {
      logger.info('Expired messages cleaned up', { removed: totalRemoved });
    }
  }

  /**
   * Get statistics
   */
  getStats() {
    return {
      totalUsers: this.queues.size,
      totalMessages: this.getTotalQueueSize(),
      maxMessagesPerUser: this.maxMessagesPerUser,
      retentionHours: this.retentionHours
    };
  }
}

module.exports = MessageQueue;
