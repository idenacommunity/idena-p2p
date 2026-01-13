import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/secure_error_handler.dart';

/// Service for communicating with the Idena network via RPC
/// Implements direct JSON-RPC calls to Idena nodes with security features
class IdenaService {
  // Default public Idena RPC node
  static const String defaultNodeUrl = 'https://rpc.idena.dev';

  // SECURITY: Rate limiting - max 10 requests per second
  final _requestQueue = <DateTime>[];
  static const _maxRequestsPerSecond = 10;

  // SECURITY: Request timeout
  static const _requestTimeout = Duration(seconds: 30);

  /// Validates that a URL uses HTTPS only (security requirement)
  void _validateHttpsUrl(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme != 'https') {
      throw Exception(
        'Security Error: Only HTTPS connections are allowed. '
        'HTTP connections are insecure and expose blockchain data to attackers.',
      );
    }
  }

  /// Enforces rate limiting to prevent API abuse
  Future<void> _enforceRateLimit() async {
    // Clean old requests (older than 1 second)
    final now = DateTime.now();
    _requestQueue.removeWhere(
      (time) => now.difference(time).inSeconds >= 1,
    );

    // Check if rate limit exceeded
    if (_requestQueue.length >= _maxRequestsPerSecond) {
      // Wait 100ms and retry
      await Future.delayed(const Duration(milliseconds: 100));
      return _enforceRateLimit(); // Recursive retry
    }

    // Add current request to queue
    _requestQueue.add(now);
  }

  /// Makes a JSON-RPC call to the Idena node
  /// SECURITY: Enforces HTTPS, rate limiting, and request timeout
  Future<dynamic> _rpcCall(String method, List<dynamic> params) async {
    try {
      // SECURITY: Validate HTTPS
      _validateHttpsUrl(defaultNodeUrl);

      // SECURITY: Enforce rate limiting
      await _enforceRateLimit();

      // Make request with timeout
      final response = await http
          .post(
            Uri.parse(defaultNodeUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': method,
              'params': params,
              'id': 1,
            }),
          )
          .timeout(
            _requestTimeout,
            onTimeout: () {
              throw TimeoutException(
                'RPC request timed out after ${_requestTimeout.inSeconds} seconds',
              );
            },
          );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['error'] != null) {
          final rpcError = jsonResponse['error']['message'];
          throw NetworkException('RPC Error: $rpcError');
        }
        return jsonResponse['result'];
      } else {
        throw NetworkException('HTTP Error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      // SECURITY: Log error securely for debugging
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'IdenaService._rpcCall',
      );

      // Re-throw as NetworkException if not already
      if (e is NetworkException) {
        rethrow;
      }
      throw NetworkException('Failed to make RPC call: ${SecureErrorHandler.sanitizeError(e)}');
    }
  }

  /// Checks if the connection to the Idena node is working
  /// Returns true if the node is reachable and responding
  Future<bool> checkConnection() async {
    try {
      await _rpcCall('dna_getBalance', ['0x0000000000000000000000000000000000000000']);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets the balance and stake for an Idena address
  Future<Map<String, dynamic>?> getBalance(String address) async {
    try {
      final result = await _rpcCall('dna_getBalance', [address]);
      return result as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to get balance for address $address: $e');
    }
  }

  /// Gets the identity information for an Idena address
  Future<Map<String, dynamic>?> getIdentity(String address) async {
    try {
      final result = await _rpcCall('dna_identity', [address]);
      return result as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to get identity for address $address: $e');
    }
  }

  /// Gets the current epoch number
  Future<int?> getEpochInfo() async {
    try {
      final result = await _rpcCall('dna_epoch', []);
      if (result != null && result is Map<String, dynamic>) {
        return result['epoch'] as int?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validates if an address is a valid Idena address format
  bool isValidIdenaAddress(String address) {
    // Idena addresses follow Ethereum format: 0x followed by 40 hex characters
    final regex = RegExp(r'^0x[a-fA-F0-9]{40}$');
    return regex.hasMatch(address);
  }

  /// Gets comprehensive account information (balance + identity + epoch)
  Future<Map<String, dynamic>> getAccountInfo(String address) async {
    try {
      final balanceResponse = await getBalance(address);
      final identityResponse = await getIdentity(address);
      final epoch = await getEpochInfo();

      // Parse balance and stake
      final balance = balanceResponse?['balance'] ?? 0.0;
      final stake = balanceResponse?['stake'] ?? 0.0;

      // Parse identity
      final state = identityResponse?['state'] ?? 'Unknown';
      final identityAddress = identityResponse?['address'] ?? address;
      final age = identityResponse?['age'] ?? 0;

      return {
        'balance': balance is num ? balance.toDouble() : 0.0,
        'stake': stake is num ? stake.toDouble() : 0.0,
        'identityState': state.toString(),
        'identityAddress': identityAddress.toString(),
        'epoch': epoch ?? 0,
        'age': age is num ? age.toInt() : 0,
      };
    } catch (e) {
      throw Exception('Failed to get account information: $e');
    }
  }
}
