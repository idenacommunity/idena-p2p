import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for communicating with the Idena network via RPC
/// Implements direct JSON-RPC calls to Idena nodes
class IdenaService {
  // Default public Idena RPC node
  static const String defaultNodeUrl = 'https://rpc.idena.dev';

  /// Makes a JSON-RPC call to the Idena node
  Future<dynamic> _rpcCall(String method, List<dynamic> params) async {
    try {
      final response = await http.post(
        Uri.parse(defaultNodeUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': method,
          'params': params,
          'id': 1,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['error'] != null) {
          throw Exception('RPC Error: ${jsonResponse['error']['message']}');
        }
        return jsonResponse['result'];
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to make RPC call: $e');
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
