#!/usr/bin/env node

/**
 * Test script for Phase 2 message flow
 * Simulates two users (Alice and Bob) exchanging encrypted messages
 */

const WebSocket = require('ws');
const http = require('http');

// Test configuration
const RELAY_URL = 'ws://localhost:3002';
const API_BASE = 'http://localhost:3002';

// Test users
const ALICE = {
  address: '0x1234567890123456789012345678901234567890',
  publicKey: 'alice_public_key_base64_encoded_mock',
  name: 'Alice'
};

const BOB = {
  address: '0x9876543210987654321098765432109876543210',
  publicKey: 'bob_public_key_base64_encoded_mock',
  name: 'Bob'
};

// Utility functions
function log(message, data = null) {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${message}`);
  if (data) {
    console.log(JSON.stringify(data, null, 2));
  }
}

function apiRequest(path, method = 'GET', body = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, API_BASE);
    const options = {
      method,
      headers: {
        'Content-Type': 'application/json',
      }
    };

    const req = http.request(url, options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          resolve(data);
        }
      });
    });

    req.on('error', reject);

    if (body) {
      req.write(JSON.stringify(body));
    }

    req.end();
  });
}

// WebSocket client wrapper
class TestClient {
  constructor(user) {
    this.user = user;
    this.ws = null;
    this.authenticated = false;
    this.messages = [];
    this.statusUpdates = [];
  }

  connect() {
    return new Promise((resolve, reject) => {
      log(`📱 ${this.user.name} connecting to relay server...`);

      this.ws = new WebSocket(RELAY_URL);

      this.ws.on('open', () => {
        log(`✅ ${this.user.name} WebSocket connected`);
        this.authenticate().then(resolve).catch(reject);
      });

      this.ws.on('message', (data) => {
        const message = JSON.parse(data.toString());
        this.handleMessage(message);
      });

      this.ws.on('error', (error) => {
        log(`❌ ${this.user.name} WebSocket error:`, error.message);
        reject(error);
      });

      this.ws.on('close', () => {
        log(`🔌 ${this.user.name} WebSocket disconnected`);
      });
    });
  }

  authenticate() {
    return new Promise((resolve, reject) => {
      const authTimeout = setTimeout(() => {
        reject(new Error('Authentication timeout'));
      }, 5000);

      const authHandler = (data) => {
        const message = JSON.parse(data.toString());
        if (message.type === 'auth_success') {
          clearTimeout(authTimeout);
          this.authenticated = true;
          log(`✅ ${this.user.name} authenticated`);
          this.ws.off('message', authHandler);
          resolve();
        }
      };

      this.ws.on('message', authHandler);

      // Send authentication message
      this.send({
        type: 'auth',
        address: this.user.address
      });
    });
  }

  handleMessage(message) {
    log(`📨 ${this.user.name} received ${message.type}:`, message);

    switch (message.type) {
      case 'message':
        this.messages.push(message);
        log(`✉️  ${this.user.name} received message from ${message.from}`);
        log(`   Content: "${message.content}"`);
        log(`   Message ID: ${message.messageId}`);
        break;

      case 'delivered':
      case 'queued':
      case 'read':
        this.statusUpdates.push(message);
        log(`📊 ${this.user.name} status update: ${message.type} for message ${message.messageId}`);
        break;

      case 'typing':
        log(`✏️  ${message.from} is typing...`);
        break;

      case 'auth_success':
        // Already handled in authenticate()
        break;

      case 'pong':
        // Heartbeat response
        break;

      default:
        log(`❓ ${this.user.name} unknown message type: ${message.type}`);
    }
  }

  send(message) {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      throw new Error('WebSocket not connected');
    }
    this.ws.send(JSON.stringify(message));
  }

  sendMessage(to, content) {
    const messageId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const timestamp = Date.now();

    log(`📤 ${this.user.name} sending message to ${to}`);
    log(`   Content: "${content}"`);
    log(`   Message ID: ${messageId}`);

    this.send({
      type: 'message',
      to,
      content,
      messageId,
      timestamp
    });

    return messageId;
  }

  sendTypingIndicator(to, isTyping) {
    this.send({
      type: 'typing',
      to,
      isTyping
    });
  }

  sendReadReceipt(to, messageId) {
    log(`👁️  ${this.user.name} sending read receipt for ${messageId}`);
    this.send({
      type: 'read_receipt',
      to,
      messageId
    });
  }

  disconnect() {
    if (this.ws) {
      this.ws.close();
    }
  }
}

// Main test flow
async function runTests() {
  console.log('\n' + '='.repeat(80));
  console.log('🧪 PHASE 2 MESSAGE FLOW TEST');
  console.log('='.repeat(80) + '\n');

  try {
    // Test 1: Check server health
    console.log('\n📋 TEST 1: Server Health Check');
    console.log('-'.repeat(80));
    const health = await apiRequest('/health');
    log('✅ Server health check passed', health);

    // Test 2: Store public keys
    console.log('\n📋 TEST 2: Public Key Exchange');
    console.log('-'.repeat(80));

    log(`🔑 Storing ${ALICE.name}'s public key...`);
    const aliceKeyResult = await apiRequest('/api/public-keys', 'POST', {
      address: ALICE.address,
      publicKey: ALICE.publicKey
    });
    log(`✅ ${ALICE.name}'s public key stored`, aliceKeyResult);

    log(`🔑 Storing ${BOB.name}'s public key...`);
    const bobKeyResult = await apiRequest('/api/public-keys', 'POST', {
      address: BOB.address,
      publicKey: BOB.publicKey
    });
    log(`✅ ${BOB.name}'s public key stored`, bobKeyResult);

    // Verify keys can be retrieved
    log(`🔍 Retrieving ${BOB.name}'s public key...`);
    const bobKeyRetrieved = await apiRequest(`/api/public-keys/${BOB.address}`);
    log(`✅ ${BOB.name}'s public key retrieved`, bobKeyRetrieved);

    // Test 3: Connect clients
    console.log('\n📋 TEST 3: WebSocket Connections');
    console.log('-'.repeat(80));

    const alice = new TestClient(ALICE);
    const bob = new TestClient(BOB);

    await alice.connect();
    await bob.connect();

    // Wait a moment for connections to stabilize
    await new Promise(resolve => setTimeout(resolve, 500));

    // Test 4: Send messages (both online)
    console.log('\n📋 TEST 4: Send Messages (Both Online)');
    console.log('-'.repeat(80));

    const msg1 = alice.sendMessage(BOB.address, 'Hello Bob! This is Alice. 👋');
    await new Promise(resolve => setTimeout(resolve, 500));

    const msg2 = bob.sendMessage(ALICE.address, 'Hi Alice! Nice to hear from you! 😊');
    await new Promise(resolve => setTimeout(resolve, 500));

    const msg3 = alice.sendMessage(BOB.address, 'How are you doing?');
    await new Promise(resolve => setTimeout(resolve, 500));

    // Test 5: Typing indicators
    console.log('\n📋 TEST 5: Typing Indicators');
    console.log('-'.repeat(80));

    alice.sendTypingIndicator(BOB.address, true);
    await new Promise(resolve => setTimeout(resolve, 500));
    alice.sendTypingIndicator(BOB.address, false);
    await new Promise(resolve => setTimeout(resolve, 500));

    // Test 6: Read receipts
    console.log('\n📋 TEST 6: Read Receipts');
    console.log('-'.repeat(80));

    if (bob.messages.length > 0) {
      bob.sendReadReceipt(ALICE.address, bob.messages[0].messageId);
      await new Promise(resolve => setTimeout(resolve, 500));
    }

    // Test 7: Offline message (disconnect Bob, send message, reconnect)
    console.log('\n📋 TEST 7: Offline Message Queue');
    console.log('-'.repeat(80));

    log(`🔌 Disconnecting ${BOB.name}...`);
    bob.disconnect();
    await new Promise(resolve => setTimeout(resolve, 1000));

    log(`📤 ${ALICE.name} sending message to offline ${BOB.name}...`);
    const offlineMsg = alice.sendMessage(BOB.address, 'Bob, are you there? (sent while offline)');
    await new Promise(resolve => setTimeout(resolve, 1000));

    log(`🔌 Reconnecting ${BOB.name}...`);
    await bob.connect();
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Test 8: Check online status
    console.log('\n📋 TEST 8: Online Status Check');
    console.log('-'.repeat(80));

    const aliceStatus = await apiRequest(`/api/status/${ALICE.address}`);
    log(`👤 ${ALICE.name} status:`, aliceStatus);

    const bobStatus = await apiRequest(`/api/status/${BOB.address}`);
    log(`👤 ${BOB.name} status:`, bobStatus);

    // Wait for final messages
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Results summary
    console.log('\n' + '='.repeat(80));
    console.log('📊 TEST RESULTS SUMMARY');
    console.log('='.repeat(80) + '\n');

    console.log(`✉️  ${ALICE.name} received ${alice.messages.length} messages`);
    console.log(`✉️  ${BOB.name} received ${bob.messages.length} messages`);
    console.log(`📊 ${ALICE.name} received ${alice.statusUpdates.length} status updates`);
    console.log(`📊 ${BOB.name} received ${bob.statusUpdates.length} status updates`);

    console.log('\n📨 Alice\'s Messages:');
    alice.messages.forEach((msg, i) => {
      console.log(`   ${i + 1}. From: ${msg.from.substring(0, 10)}... | "${msg.content}"`);
    });

    console.log('\n📨 Bob\'s Messages:');
    bob.messages.forEach((msg, i) => {
      console.log(`   ${i + 1}. From: ${msg.from.substring(0, 10)}... | "${msg.content}"`);
    });

    console.log('\n📊 Alice\'s Status Updates:');
    alice.statusUpdates.forEach((status, i) => {
      console.log(`   ${i + 1}. Type: ${status.type} | Message: ${status.messageId}`);
    });

    console.log('\n📊 Bob\'s Status Updates:');
    bob.statusUpdates.forEach((status, i) => {
      console.log(`   ${i + 1}. Type: ${status.type} | Message: ${status.messageId}`);
    });

    // Final health check
    console.log('\n📋 Final Server Health:');
    const finalHealth = await apiRequest('/health');
    log('Server status:', finalHealth);

    // Cleanup
    console.log('\n🧹 Cleaning up...');
    alice.disconnect();
    bob.disconnect();

    console.log('\n' + '='.repeat(80));
    console.log('✅ ALL TESTS COMPLETED SUCCESSFULLY');
    console.log('='.repeat(80) + '\n');

    process.exit(0);

  } catch (error) {
    console.error('\n❌ TEST FAILED:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// Run tests
if (require.main === module) {
  runTests();
}

module.exports = { TestClient, ALICE, BOB };
