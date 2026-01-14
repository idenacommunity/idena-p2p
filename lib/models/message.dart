/// Message model for P2P messaging
class Message {
  /// Unique message ID (UUID)
  final String id;

  /// Sender's Idena address
  final String sender;

  /// Recipient's Idena address
  final String recipient;

  /// Message content (encrypted for transmission)
  final String content;

  /// Type of message
  final MessageType type;

  /// When the message was sent
  final DateTime timestamp;

  /// Message signature (signed with sender's Idena key)
  final String? signature;

  /// Delivery status
  final DeliveryStatus status;

  /// Whether this is an incoming or outgoing message
  final MessageDirection direction;

  /// Encryption metadata (for future E2E encryption)
  final EncryptionMetadata? encryptionMetadata;

  Message({
    required this.id,
    required this.sender,
    required this.recipient,
    required this.content,
    required this.type,
    required this.timestamp,
    this.signature,
    required this.status,
    required this.direction,
    this.encryptionMetadata,
  });

  /// Get short preview of message content
  String get preview {
    switch (type) {
      case MessageType.text:
        return content.length > 50 ? '${content.substring(0, 50)}...' : content;
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 File';
      case MessageType.voiceCall:
        return '📞 Voice Call';
      case MessageType.videoCall:
        return '📹 Video Call';
      case MessageType.location:
        return '📍 Location';
      default:
        return 'Message';
    }
  }

  /// Check if message is encrypted
  bool get isEncrypted => encryptionMetadata != null;

  /// Create a copy with updated fields
  Message copyWith({
    String? id,
    String? sender,
    String? recipient,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    String? signature,
    DeliveryStatus? status,
    MessageDirection? direction,
    EncryptionMetadata? encryptionMetadata,
  }) {
    return Message(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      recipient: recipient ?? this.recipient,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      signature: signature ?? this.signature,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      encryptionMetadata: encryptionMetadata ?? this.encryptionMetadata,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'recipient': recipient,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'signature': signature,
      'status': status.name,
      'direction': direction.name,
      'encryptionMetadata': encryptionMetadata?.toJson(),
    };
  }

  /// Create Message from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      sender: json['sender'] as String,
      recipient: json['recipient'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      signature: json['signature'] as String?,
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DeliveryStatus.sent,
      ),
      direction: MessageDirection.values.firstWhere(
        (e) => e.name == json['direction'],
        orElse: () => MessageDirection.outgoing,
      ),
      encryptionMetadata: json['encryptionMetadata'] != null
          ? EncryptionMetadata.fromJson(json['encryptionMetadata'])
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Type of message content
enum MessageType {
  text,
  image,
  file,
  voiceCall,
  videoCall,
  location,
}

/// Message delivery status
enum DeliveryStatus {
  sending,    // Currently being sent
  sent,       // Sent to server/peer
  delivered,  // Delivered to recipient
  read,       // Read by recipient
  failed,     // Failed to send
}

/// Message direction (incoming or outgoing)
enum MessageDirection {
  incoming,
  outgoing,
}

/// Encryption metadata for end-to-end encryption
class EncryptionMetadata {
  /// Ratchet step (for Signal Protocol)
  final int? ratchetStep;

  /// Ephemeral session key
  final String? ephemeralKey;

  /// Encryption algorithm used
  final String algorithm;

  EncryptionMetadata({
    this.ratchetStep,
    this.ephemeralKey,
    required this.algorithm,
  });

  Map<String, dynamic> toJson() {
    return {
      'ratchetStep': ratchetStep,
      'ephemeralKey': ephemeralKey,
      'algorithm': algorithm,
    };
  }

  factory EncryptionMetadata.fromJson(Map<String, dynamic> json) {
    return EncryptionMetadata(
      ratchetStep: json['ratchetStep'] as int?,
      ephemeralKey: json['ephemeralKey'] as String?,
      algorithm: json['algorithm'] as String,
    );
  }
}

/// Conversation model representing a chat with a contact
class Conversation {
  /// Idena address of the contact
  final String contactAddress;

  /// Last message in the conversation
  final Message? lastMessage;

  /// Number of unread messages
  final int unreadCount;

  /// When the conversation was last updated
  final DateTime lastUpdated;

  /// Whether the conversation is pinned
  final bool isPinned;

  /// Whether the conversation is muted
  final bool isMuted;

  Conversation({
    required this.contactAddress,
    this.lastMessage,
    required this.unreadCount,
    required this.lastUpdated,
    this.isPinned = false,
    this.isMuted = false,
  });

  Conversation copyWith({
    String? contactAddress,
    Message? lastMessage,
    int? unreadCount,
    DateTime? lastUpdated,
    bool? isPinned,
    bool? isMuted,
  }) {
    return Conversation(
      contactAddress: contactAddress ?? this.contactAddress,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contactAddress': contactAddress,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isPinned': isPinned,
      'isMuted': isMuted,
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      contactAddress: json['contactAddress'] as String,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      isMuted: json['isMuted'] as bool? ?? false,
    );
  }
}
