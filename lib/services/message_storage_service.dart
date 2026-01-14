import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:idena_p2p/models/message.dart';

/// Service for storing and managing messages locally using Hive
class MessageStorageService {
  static const String _messagesBoxName = 'messages';
  static const String _conversationsBoxName = 'conversations';

  late Box<Map> _messagesBox;
  late Box<Map> _conversationsBox;

  final _uuid = const Uuid();

  /// Initialize Hive boxes
  Future<void> init() async {
    _messagesBox = await Hive.openBox<Map>(_messagesBoxName);
    _conversationsBox = await Hive.openBox<Map>(_conversationsBoxName);
  }

  /// Save a message to local storage
  Future<void> saveMessage(Message message) async {
    await _messagesBox.put(message.id, message.toJson());

    // Update conversation
    await _updateConversation(message);
  }

  /// Get all messages for a conversation (sorted by timestamp)
  Future<List<Message>> getMessages(String contactAddress) async {
    final messages = <Message>[];

    for (var key in _messagesBox.keys) {
      try {
        final json = Map<String, dynamic>.from(_messagesBox.get(key) as Map);
        final message = Message.fromJson(json);

        // Filter messages for this conversation
        if (message.sender == contactAddress || message.recipient == contactAddress) {
          messages.add(message);
        }
      } catch (e) {
        print('Error loading message $key: $e');
      }
    }

    // Sort by timestamp (oldest first)
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return messages;
  }

  /// Get recent messages (limited count)
  Future<List<Message>> getRecentMessages(
    String contactAddress, {
    int limit = 50,
  }) async {
    final messages = await getMessages(contactAddress);

    // Return last N messages
    if (messages.length > limit) {
      return messages.sublist(messages.length - limit);
    }

    return messages;
  }

  /// Create a new message
  Future<Message> createMessage({
    required String sender,
    required String recipient,
    required String content,
    required MessageDirection direction,
    MessageType type = MessageType.text,
  }) async {
    final message = Message(
      id: _uuid.v4(),
      sender: sender,
      recipient: recipient,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      status: DeliveryStatus.sending,
      direction: direction,
    );

    await saveMessage(message);

    return message;
  }

  /// Update message status
  Future<void> updateMessageStatus(
    String messageId,
    DeliveryStatus status,
  ) async {
    final json = _messagesBox.get(messageId);
    if (json == null) return;

    final message = Message.fromJson(Map<String, dynamic>.from(json as Map));
    final updated = message.copyWith(status: status);

    await _messagesBox.put(messageId, updated.toJson());
  }

  /// Get all conversations (sorted by last message)
  Future<List<Conversation>> getAllConversations() async {
    final conversations = <Conversation>[];

    for (var key in _conversationsBox.keys) {
      try {
        final json = Map<String, dynamic>.from(_conversationsBox.get(key) as Map);
        conversations.add(Conversation.fromJson(json));
      } catch (e) {
        print('Error loading conversation $key: $e');
      }
    }

    // Sort by last updated (most recent first)
    conversations.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

    return conversations;
  }

  /// Get conversation for a specific contact
  Future<Conversation?> getConversation(String contactAddress) async {
    final json = _conversationsBox.get(contactAddress.toLowerCase());
    if (json == null) return null;

    try {
      return Conversation.fromJson(Map<String, dynamic>.from(json as Map));
    } catch (e) {
      print('Error loading conversation for $contactAddress: $e');
      return null;
    }
  }

  /// Update conversation with new message
  Future<void> _updateConversation(Message message) async {
    // Determine contact address (the other party)
    final contactAddress = message.direction == MessageDirection.outgoing
        ? message.recipient
        : message.sender;

    // Get existing conversation or create new
    var conversation = await getConversation(contactAddress);

    if (conversation == null) {
      // Create new conversation
      conversation = Conversation(
        contactAddress: contactAddress,
        lastMessage: message,
        unreadCount: message.direction == MessageDirection.incoming ? 1 : 0,
        lastUpdated: message.timestamp,
      );
    } else {
      // Update existing conversation
      final newUnreadCount = message.direction == MessageDirection.incoming
          ? conversation.unreadCount + 1
          : conversation.unreadCount;

      conversation = conversation.copyWith(
        lastMessage: message,
        unreadCount: newUnreadCount,
        lastUpdated: message.timestamp,
      );
    }

    // Save conversation
    await _conversationsBox.put(
      contactAddress.toLowerCase(),
      conversation.toJson(),
    );
  }

  /// Mark conversation as read (reset unread count)
  Future<void> markConversationAsRead(String contactAddress) async {
    final conversation = await getConversation(contactAddress);
    if (conversation == null) return;

    final updated = conversation.copyWith(unreadCount: 0);
    await _conversationsBox.put(
      contactAddress.toLowerCase(),
      updated.toJson(),
    );
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _messagesBox.delete(messageId);
  }

  /// Delete conversation (including all messages)
  Future<void> deleteConversation(String contactAddress) async {
    // Delete all messages for this conversation
    final messages = await getMessages(contactAddress);
    for (var message in messages) {
      await deleteMessage(message.id);
    }

    // Delete conversation metadata
    await _conversationsBox.delete(contactAddress.toLowerCase());
  }

  /// Get unread message count for a contact
  Future<int> getUnreadCount(String contactAddress) async {
    final conversation = await getConversation(contactAddress);
    return conversation?.unreadCount ?? 0;
  }

  /// Get total unread message count across all conversations
  Future<int> getTotalUnreadCount() async {
    final conversations = await getAllConversations();
    return conversations.fold<int>(
      0,
      (sum, conv) => sum + conv.unreadCount,
    );
  }

  /// Search messages by content
  Future<List<Message>> searchMessages(String query) async {
    if (query.isEmpty) return [];

    final allMessages = <Message>[];
    final lowerQuery = query.toLowerCase();

    for (var key in _messagesBox.keys) {
      try {
        final json = Map<String, dynamic>.from(_messagesBox.get(key) as Map);
        final message = Message.fromJson(json);

        if (message.content.toLowerCase().contains(lowerQuery)) {
          allMessages.add(message);
        }
      } catch (e) {
        // Skip invalid entries
      }
    }

    // Sort by timestamp (most recent first)
    allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return allMessages;
  }

  /// Get message statistics
  Future<Map<String, int>> getMessageStats() async {
    final totalMessages = _messagesBox.length;
    final conversations = await getAllConversations();
    final totalUnread = await getTotalUnreadCount();

    return {
      'total_messages': totalMessages,
      'total_conversations': conversations.length,
      'total_unread': totalUnread,
    };
  }

  /// Clear all messages (for testing or reset)
  Future<void> clearAllMessages() async {
    await _messagesBox.clear();
    await _conversationsBox.clear();
  }

  /// Close database
  Future<void> close() async {
    await _messagesBox.close();
    await _conversationsBox.close();
  }
}
