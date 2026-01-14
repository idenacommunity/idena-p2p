import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// WebSocket service for connecting to the relay server
/// Handles real-time message transmission, typing indicators, and read receipts
class RelayWebSocketService {
  // WebSocket configuration
  static const String _defaultHost = 'localhost';
  static const int _defaultPort = 3002;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _pingInterval = Duration(seconds: 30);

  // State
  WebSocketChannel? _channel;
  String? _userAddress;
  bool _isConnected = false;
  bool _isAuthenticated = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  // Stream controllers for events
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // Getters
  bool get isConnected => _isConnected && _isAuthenticated;
  String? get userAddress => _userAddress;

  // Event streams
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onStatusUpdate => _statusController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<bool> get onConnectionChange => _connectionController.stream;

  /// Connect to relay server and authenticate
  Future<bool> connect(String userAddress, {String? host, int? port}) async {
    if (_isConnected && _userAddress == userAddress) {
      return true; // Already connected with same address
    }

    // Disconnect if already connected with different address
    if (_isConnected) {
      await disconnect();
    }

    _userAddress = userAddress;
    final wsHost = host ?? _defaultHost;
    final wsPort = port ?? _defaultPort;
    final uri = Uri.parse('ws://$wsHost:$wsPort');

    try {
      print('[WebSocket] Connecting to $uri');
      _channel = WebSocketChannel.connect(uri);

      // Listen to messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onConnectionError,
        onDone: _onConnectionClosed,
        cancelOnError: false,
      );

      // Send authentication message
      _send({
        'type': 'auth',
        'address': userAddress,
      });

      // Wait for auth response (with timeout)
      final authResult = await _waitForAuth();
      if (authResult) {
        _isConnected = true;
        _isAuthenticated = true;
        _connectionController.add(true);
        _startPingTimer();
        print('[WebSocket] Connected and authenticated as $userAddress');
        return true;
      } else {
        _errorController.add('Authentication failed');
        await disconnect();
        return false;
      }
    } catch (e) {
      print('[WebSocket] Connection error: $e');
      _errorController.add('Connection failed: $e');
      _scheduleReconnect();
      return false;
    }
  }

  /// Disconnect from relay server
  Future<void> disconnect() async {
    print('[WebSocket] Disconnecting');
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();

    _isConnected = false;
    _isAuthenticated = false;
    _connectionController.add(false);

    await _channel?.sink.close(status.goingAway);
    _channel = null;
  }

  /// Send a message to a recipient
  void sendMessage({
    required String to,
    required String content,
    required String messageId,
    int? timestamp,
  }) {
    if (!isConnected) {
      _errorController.add('Not connected to relay server');
      return;
    }

    _send({
      'type': 'message',
      'to': to,
      'content': content,
      'messageId': messageId,
      'timestamp': timestamp ?? DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Send typing indicator
  void sendTypingIndicator(String to, bool isTyping) {
    if (!isConnected) return;

    _send({
      'type': 'typing',
      'to': to,
      'isTyping': isTyping,
    });
  }

  /// Send read receipt
  void sendReadReceipt(String to, String messageId) {
    if (!isConnected) return;

    _send({
      'type': 'read_receipt',
      'to': to,
      'messageId': messageId,
    });
  }

  /// Handle incoming WebSocket message
  void _onMessage(dynamic data) {
    try {
      final message = jsonDecode(data.toString()) as Map<String, dynamic>;
      final type = message['type'] as String?;

      print('[WebSocket] Received: $type');

      switch (type) {
        case 'auth_success':
          _handleAuthSuccess(message);
          break;

        case 'message':
          _handleIncomingMessage(message);
          break;

        case 'delivered':
        case 'queued':
          _handleDeliveryStatus(message);
          break;

        case 'read':
          _handleReadReceipt(message);
          break;

        case 'typing':
          _handleTypingIndicator(message);
          break;

        case 'pong':
          // Heartbeat response
          break;

        case 'error':
          _handleError(message);
          break;

        default:
          print('[WebSocket] Unknown message type: $type');
      }
    } catch (e) {
      print('[WebSocket] Error parsing message: $e');
    }
  }

  /// Handle authentication success
  void _handleAuthSuccess(Map<String, dynamic> message) {
    print('[WebSocket] Authentication successful');
    _isAuthenticated = true;
    _statusController.add({
      'type': 'auth_success',
      'address': message['address'],
      'timestamp': message['timestamp'],
    });
  }

  /// Handle incoming message
  void _handleIncomingMessage(Map<String, dynamic> message) {
    print('[WebSocket] Incoming message from ${message['from']}');
    _messageController.add(message);
  }

  /// Handle delivery status (delivered or queued)
  void _handleDeliveryStatus(Map<String, dynamic> message) {
    print('[WebSocket] Message ${message['messageId']} ${message['type']}');
    _statusController.add(message);
  }

  /// Handle read receipt
  void _handleReadReceipt(Map<String, dynamic> message) {
    print('[WebSocket] Message ${message['messageId']} read by ${message['from']}');
    _statusController.add(message);
  }

  /// Handle typing indicator
  void _handleTypingIndicator(Map<String, dynamic> message) {
    _statusController.add(message);
  }

  /// Handle error message
  void _handleError(Map<String, dynamic> message) {
    final errorMsg = message['message'] as String? ?? 'Unknown error';
    print('[WebSocket] Error: $errorMsg');
    _errorController.add(errorMsg);
  }

  /// Handle connection error
  void _onConnectionError(error) {
    print('[WebSocket] Connection error: $error');
    _isConnected = false;
    _isAuthenticated = false;
    _connectionController.add(false);
    _errorController.add('Connection error: $error');
    _scheduleReconnect();
  }

  /// Handle connection closed
  void _onConnectionClosed() {
    print('[WebSocket] Connection closed');
    _isConnected = false;
    _isAuthenticated = false;
    _connectionController.add(false);
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  /// Wait for authentication response
  Future<bool> _waitForAuth() async {
    try {
      await for (final update in _statusController.stream) {
        if (update['type'] == 'auth_success') {
          return true;
        }
        // Timeout after 5 seconds
        await Future.delayed(const Duration(seconds: 5));
        return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Start ping timer to keep connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (_isConnected) {
        _send({'type': 'ping'});
      }
    });
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return; // Already scheduled
    }

    if (_userAddress == null) {
      return; // No address to reconnect with
    }

    print('[WebSocket] Scheduling reconnect in ${_reconnectDelay.inSeconds}s');
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isConnected && _userAddress != null) {
        print('[WebSocket] Attempting reconnect...');
        connect(_userAddress!);
      }
    });
  }

  /// Send message through WebSocket
  void _send(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      print('[WebSocket] Error sending message: $e');
      _errorController.add('Failed to send: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _messageController.close();
    _statusController.close();
    _errorController.close();
    _connectionController.close();
    disconnect();
  }
}
