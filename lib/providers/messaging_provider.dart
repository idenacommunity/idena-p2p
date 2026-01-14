import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:idena_p2p/models/message.dart';
import 'package:idena_p2p/models/contact.dart';
import 'package:idena_p2p/services/message_storage_service.dart';
import 'package:idena_p2p/services/messaging_encryption_service.dart';
import 'package:idena_p2p/services/relay_websocket_service.dart';
import 'package:idena_p2p/services/relay_api_service.dart';

/// Provider for managing messaging state and operations
/// Phase 2: Integrated with relay server for real-time messaging
class MessagingProvider extends ChangeNotifier {
  final MessageStorageService _storageService = MessageStorageService();
  final MessagingEncryptionService _encryptionService =
      MessagingEncryptionService();
  final RelayWebSocketService _wsService = RelayWebSocketService();
  final RelayApiService _apiService = RelayApiService();

  // State
  List<Conversation> _conversations = [];
  Map<String, List<Message>> _messageCache = {};
  bool _isLoading = false;
  String? _error;
  String? _currentUserAddress;
  bool _isConnectedToRelay = false;
  StreamSubscription? _wsMessageSubscription;
  StreamSubscription? _wsStatusSubscription;
  StreamSubscription? _wsConnectionSubscription;

  // Getters
  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnectedToRelay => _isConnectedToRelay;
  int get totalUnreadCount =>
      _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);

  /// Initialize messaging provider
  /// Phase 2: Connects to relay server and sets up WebSocket listeners
  Future<void> init(String userAddress) async {
    _currentUserAddress = userAddress;
    await _storageService.init();
    await loadConversations();

    // Connect to relay server
    await _connectToRelayServer();

    // Upload public key to relay server
    await _uploadPublicKey();

    // Set up WebSocket event listeners
    _setupWebSocketListeners();
  }

  /// Connect to relay server via WebSocket
  Future<void> _connectToRelayServer() async {
    if (_currentUserAddress == null) return;

    try {
      print('[MessagingProvider] Connecting to relay server...');
      final connected = await _wsService.connect(_currentUserAddress!);

      if (connected) {
        print('[MessagingProvider] Connected to relay server');
        _isConnectedToRelay = true;
        notifyListeners();
      } else {
        print('[MessagingProvider] Failed to connect to relay server');
        _setError('Could not connect to relay server');
      }
    } catch (e) {
      print('[MessagingProvider] Relay connection error: $e');
      _setError('Relay connection error: $e');
    }
  }

  /// Upload public key to relay server
  Future<void> _uploadPublicKey() async {
    if (_currentUserAddress == null) return;

    try {
      final publicKey = await _encryptionService.exportPublicKeyBase64();
      final success = await _apiService.storePublicKey(
        _currentUserAddress!,
        publicKey,
      );

      if (success) {
        print('[MessagingProvider] Public key uploaded');
      } else {
        print('[MessagingProvider] Failed to upload public key');
      }
    } catch (e) {
      print('[MessagingProvider] Error uploading public key: $e');
    }
  }

  /// Set up WebSocket event listeners
  void _setupWebSocketListeners() {
    // Listen for incoming messages
    _wsMessageSubscription = _wsService.onMessage.listen((message) {
      _handleIncomingMessage(message);
    });

    // Listen for status updates (delivered, read, etc.)
    _wsStatusSubscription = _wsService.onStatusUpdate.listen((status) {
      _handleStatusUpdate(status);
    });

    // Listen for connection changes
    _wsConnectionSubscription = _wsService.onConnectionChange.listen((connected) {
      _isConnectedToRelay = connected;
      notifyListeners();
    });
  }

  /// Handle incoming message from WebSocket
  Future<void> _handleIncomingMessage(Map<String, dynamic> data) async {
    try {
      final from = data['from'] as String;
      final encryptedContent = data['content'] as String;
      final messageId = data['messageId'] as String;
      final timestamp = data['timestamp'] as int;

      print('[MessagingProvider] Incoming message from $from');

      // Get sender's public key
      final senderPublicKey = await _apiService.getPublicKey(from);
      if (senderPublicKey == null) {
        print('[MessagingProvider] No public key for sender');
        return;
      }

      // Decrypt message
      final decryptedContent = await _encryptionService.decryptMessage(
        encryptedContent,
        from,
        _encryptionService.importPublicKeyBase64(senderPublicKey),
      );

      // Create message object
      final message = Message(
        id: messageId,
        sender: from,
        recipient: _currentUserAddress!,
        content: decryptedContent,
        type: MessageType.text,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
        status: DeliveryStatus.delivered,
        direction: MessageDirection.incoming,
      );

      // Save to storage
      await _storageService.saveMessage(message);

      // Update cache
      if (_messageCache.containsKey(from)) {
        _messageCache[from]!.add(message);
      }

      // Reload conversations
      await loadConversations();

      notifyListeners();
    } catch (e) {
      print('[MessagingProvider] Error handling incoming message: $e');
    }
  }

  /// Handle status update from WebSocket
  Future<void> _handleStatusUpdate(Map<String, dynamic> status) async {
    final type = status['type'] as String?;
    final messageId = status['messageId'] as String?;

    if (messageId == null) return;

    DeliveryStatus? newStatus;

    switch (type) {
      case 'delivered':
        newStatus = DeliveryStatus.delivered;
        break;
      case 'queued':
        newStatus = DeliveryStatus.sent;
        break;
      case 'read':
        newStatus = DeliveryStatus.read;
        break;
    }

    if (newStatus != null) {
      await _storageService.updateMessageStatus(messageId, newStatus);
      // Reload affected conversation
      await loadConversations();
      notifyListeners();
    }
  }

  /// Load all conversations from storage
  Future<void> loadConversations() async {
    try {
      _setLoading(true);
      _conversations = await _storageService.getAllConversations();
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load conversations: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get messages for a specific conversation
  Future<List<Message>> getMessages(String contactAddress) async {
    // Check cache first
    if (_messageCache.containsKey(contactAddress)) {
      return _messageCache[contactAddress]!;
    }

    try {
      final messages = await _storageService.getMessages(contactAddress);
      _messageCache[contactAddress] = messages;
      return messages;
    } catch (e) {
      _setError('Failed to load messages: $e');
      return [];
    }
  }

  /// Send a text message to a contact
  Future<bool> sendMessage({
    required String recipientAddress,
    required String content,
  }) async {
    if (_currentUserAddress == null) {
      _setError('User address not set');
      return false;
    }

    try {
      // Fetch recipient's public key from relay server
      final recipientPublicKeyBase64 =
          await _apiService.getPublicKey(recipientAddress);
      if (recipientPublicKeyBase64 == null) {
        _setError('Recipient public key not found on relay server');
        return false;
      }

      final recipientPublicKey =
          _encryptionService.importPublicKeyBase64(recipientPublicKeyBase64);

      // Encrypt the message
      final encryptedContent = await _encryptionService.encryptMessage(
        content,
        recipientAddress,
        recipientPublicKey,
      );

      // Create and save the message
      final message = await _storageService.createMessage(
        sender: _currentUserAddress!,
        recipient: recipientAddress,
        content: encryptedContent,
        direction: MessageDirection.outgoing,
      );

      // Update cache
      if (_messageCache.containsKey(recipientAddress)) {
        _messageCache[recipientAddress]!.add(message);
      }

      // Reload conversations to update UI
      await loadConversations();

      // Send via WebSocket to relay server
      if (_isConnectedToRelay) {
        _wsService.sendMessage(
          to: recipientAddress,
          content: encryptedContent,
          messageId: message.id,
          timestamp: message.timestamp.millisecondsSinceEpoch,
        );
        print('[MessagingProvider] Message sent to relay server: ${message.id}');
      } else {
        print('[MessagingProvider] Not connected to relay - message saved locally');
        // Mark as sending if not connected (will retry when connection restored)
        await _storageService.updateMessageStatus(
          message.id,
          DeliveryStatus.sending,
        );
      }

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to send message: $e');
      return false;
    }
  }

  /// Receive and decrypt a message from a contact
  Future<void> receiveMessage({
    required String senderAddress,
    required String encryptedContent,
    required List<int> senderPublicKey,
    required String messageId,
    required DateTime timestamp,
  }) async {
    if (_currentUserAddress == null) {
      _setError('User address not set');
      return;
    }

    try {
      // Decrypt the message
      final decryptedContent = await _encryptionService.decryptMessage(
        encryptedContent,
        senderAddress,
        senderPublicKey,
      );

      // Create the message object
      final message = Message(
        id: messageId,
        sender: senderAddress,
        recipient: _currentUserAddress!,
        content: decryptedContent,
        type: MessageType.text,
        timestamp: timestamp,
        status: DeliveryStatus.delivered,
        direction: MessageDirection.incoming,
      );

      // Save to storage
      await _storageService.saveMessage(message);

      // Update cache
      if (_messageCache.containsKey(senderAddress)) {
        _messageCache[senderAddress]!.add(message);
      }

      // Reload conversations
      await loadConversations();

      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to receive message: $e');
    }
  }

  /// Mark conversation as read
  Future<void> markAsRead(String contactAddress) async {
    try {
      await _storageService.markConversationAsRead(contactAddress);
      await loadConversations();
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to mark as read: $e');
    }
  }

  /// Delete a conversation (including all messages)
  Future<bool> deleteConversation(String contactAddress) async {
    try {
      await _storageService.deleteConversation(contactAddress);

      // Remove from cache
      _messageCache.remove(contactAddress);

      // Reload conversations
      await loadConversations();

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete conversation: $e');
      return false;
    }
  }

  /// Search messages by content
  Future<List<Message>> searchMessages(String query) async {
    try {
      final results = await _storageService.searchMessages(query);
      return results;
    } catch (e) {
      _setError('Search failed: $e');
      return [];
    }
  }

  /// Get or create conversation for a contact
  Future<Conversation?> getOrCreateConversation(Contact contact) async {
    try {
      // Check if conversation exists
      var conversation =
          await _storageService.getConversation(contact.address);

      // If no conversation exists, create an empty one
      if (conversation == null) {
        // Create a placeholder conversation (will be updated when first message is sent)
        conversation = Conversation(
          contactAddress: contact.address,
          lastMessage: null,
          unreadCount: 0,
          lastUpdated: DateTime.now(),
        );
      }

      return conversation;
    } catch (e) {
      _setError('Failed to get/create conversation: $e');
      return null;
    }
  }

  /// Get local encryption public key for sharing with contacts
  Future<String> getPublicKey() async {
    try {
      return await _encryptionService.exportPublicKeyBase64();
    } catch (e) {
      _setError('Failed to get public key: $e');
      rethrow;
    }
  }

  /// Refresh conversations (pull to refresh)
  Future<void> refresh() async {
    await loadConversations();
  }

  /// Clear message cache for a specific conversation
  void clearMessageCache(String contactAddress) {
    _messageCache.remove(contactAddress);
    notifyListeners();
  }

  /// Clear all message caches
  void clearAllCaches() {
    _messageCache.clear();
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Close and cleanup
  Future<void> close() async {
    // Cancel WebSocket subscriptions
    await _wsMessageSubscription?.cancel();
    await _wsStatusSubscription?.cancel();
    await _wsConnectionSubscription?.cancel();

    // Disconnect from relay server
    await _wsService.disconnect();

    // Clear caches and close storage
    _messageCache.clear();
    _conversations.clear();
    _encryptionService.clearSecrets();
    await _storageService.close();
  }

  @override
  void dispose() {
    close();
    super.dispose();
  }
}
