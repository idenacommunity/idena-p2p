import 'dart:convert';
import 'package:http/http.dart' as http;

/// REST API service for interacting with the relay server
/// Handles public key exchange, message queue queries, and status checks
class RelayApiService {
  // API configuration
  static const String _defaultHost = 'localhost';
  static const int _defaultPort = 3002;
  static const Duration _timeout = Duration(seconds: 10);

  final String _baseUrl;

  RelayApiService({String? host, int? port})
      : _baseUrl = 'http://${host ?? _defaultHost}:${port ?? _defaultPort}';

  /// Store or update public key for an address
  Future<bool> storePublicKey(String address, String publicKey) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/public-keys'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'address': address,
              'publicKey': publicKey,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        print('[RelayAPI] Public key stored for $address');
        return true;
      } else {
        print('[RelayAPI] Failed to store public key: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[RelayAPI] Error storing public key: $e');
      return false;
    }
  }

  /// Get public key for an address
  Future<String?> getPublicKey(String address) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/public-keys/$address'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final publicKey = data['publicKey'] as String?;
        print('[RelayAPI] Retrieved public key for $address');
        return publicKey;
      } else if (response.statusCode == 404) {
        print('[RelayAPI] No public key found for $address');
        return null;
      } else {
        print('[RelayAPI] Failed to get public key: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[RelayAPI] Error getting public key: $e');
      return null;
    }
  }

  /// Get multiple public keys in batch
  Future<Map<String, String>> getPublicKeys(List<String> addresses) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/public-keys/batch'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'addresses': addresses}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final keys = data['keys'] as Map<String, dynamic>;
        final result = <String, String>{};

        keys.forEach((address, keyData) {
          if (keyData is Map<String, dynamic>) {
            final publicKey = keyData['publicKey'] as String?;
            if (publicKey != null) {
              result[address] = publicKey;
            }
          }
        });

        print('[RelayAPI] Retrieved ${result.length} public keys');
        return result;
      } else {
        print('[RelayAPI] Failed to get public keys: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('[RelayAPI] Error getting public keys: $e');
      return {};
    }
  }

  /// Check if user is online
  Future<bool> isOnline(String address) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/status/$address'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['online'] as bool? ?? false;
      } else {
        print('[RelayAPI] Failed to check status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[RelayAPI] Error checking status: $e');
      return false;
    }
  }

  /// Check status of multiple users
  Future<Map<String, bool>> getOnlineStatuses(List<String> addresses) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/status/batch'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'addresses': addresses}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final statuses = data['statuses'] as Map<String, dynamic>;
        final result = <String, bool>{};

        statuses.forEach((address, online) {
          result[address] = online as bool? ?? false;
        });

        return result;
      } else {
        print('[RelayAPI] Failed to get statuses: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('[RelayAPI] Error getting statuses: $e');
      return {};
    }
  }

  /// Get queued messages for an address
  Future<List<Map<String, dynamic>>> getQueuedMessages(String address) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/messages/$address'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final messages = data['messages'] as List<dynamic>? ?? [];
        return messages.map((m) => m as Map<String, dynamic>).toList();
      } else {
        print('[RelayAPI] Failed to get messages: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[RelayAPI] Error getting messages: $e');
      return [];
    }
  }

  /// Get queue size for an address
  Future<int> getQueueSize(String address) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/messages/$address/queue-size'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['queueSize'] as int? ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      print('[RelayAPI] Error getting queue size: $e');
      return 0;
    }
  }

  /// Check server health
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('[RelayAPI] Server health: ${data['status']}');
        return data['status'] == 'ok';
      } else {
        return false;
      }
    } catch (e) {
      print('[RelayAPI] Server health check failed: $e');
      return false;
    }
  }
}
