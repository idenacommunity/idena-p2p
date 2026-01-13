import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import 'pin_setup_screen.dart';

/// Screen for importing an account using a private key
class ImportPrivateKeyScreen extends StatefulWidget {
  const ImportPrivateKeyScreen({super.key});

  @override
  State<ImportPrivateKeyScreen> createState() => _ImportPrivateKeyScreenState();
}

class _ImportPrivateKeyScreenState extends State<ImportPrivateKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _privateKeyController = TextEditingController();
  bool _isImporting = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _privateKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Private Key'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.vpn_key,
                size: 80,
                color: Colors.orange.shade300,
              ),
              const SizedBox(height: 32),

              Text(
                'Import with Private Key',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'Enter your 64-character hexadecimal private key',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Warning card
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Never share your private key with anyone!',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Private key input field
              TextFormField(
                controller: _privateKeyController,
                obscureText: _obscureText,
                maxLines: _obscureText ? 1 : 3,
                decoration: InputDecoration(
                  labelText: 'Private Key',
                  hintText: 'Enter your private key (without 0x prefix)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a private key';
                  }

                  // Remove 0x prefix if present
                  final cleanKey = value.startsWith('0x')
                      ? value.substring(2)
                      : value;

                  if (cleanKey.length != 64) {
                    return 'Private key must be 64 hexadecimal characters';
                  }

                  // Check if it's valid hexadecimal
                  if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleanKey)) {
                    return 'Private key must contain only hexadecimal characters (0-9, a-f)';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Import button
              ElevatedButton.icon(
                onPressed: _isImporting ? null : _importAccount,
                icon: _isImporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(_isImporting ? 'Importing...' : 'Import Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final provider = context.read<AccountProvider>();
      var privateKey = _privateKeyController.text.trim();

      // Remove 0x prefix if present
      if (privateKey.startsWith('0x')) {
        privateKey = privateKey.substring(2);
      }

      await provider.connectWithPrivateKey(privateKey);

      if (mounted) {
        // Clear the form
        _privateKeyController.clear();

        // Navigate to PIN setup before going home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PinSetupScreen(
              onComplete: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account imported successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }
}
