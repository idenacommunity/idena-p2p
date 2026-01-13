import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../utils/secure_error_handler.dart';
import 'pin_setup_screen.dart';

/// Screen for importing an account using a mnemonic seed phrase
class ImportMnemonicScreen extends StatefulWidget {
  const ImportMnemonicScreen({super.key});

  @override
  State<ImportMnemonicScreen> createState() => _ImportMnemonicScreenState();
}

class _ImportMnemonicScreenState extends State<ImportMnemonicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mnemonicController = TextEditingController();
  bool _isImporting = false;

  @override
  void dispose() {
    _mnemonicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Seed Phrase'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.key,
                size: 80,
                color: Colors.blue.shade300,
              ),
              const SizedBox(height: 32),

              Text(
                'Import with Seed Phrase',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'Enter your 12 or 24-word recovery phrase',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Warning card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Separate each word with a space. Make sure they are in the correct order.',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Mnemonic input field
              TextFormField(
                controller: _mnemonicController,
                maxLines: 5,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Seed Phrase',
                  hintText: 'word1 word2 word3 ...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your seed phrase';
                  }

                  final words = value.trim().split(RegExp(r'\s+'));

                  if (words.length != 12 && words.length != 24) {
                    return 'Seed phrase must be 12 or 24 words';
                  }

                  // Check for empty words
                  if (words.any((word) => word.isEmpty)) {
                    return 'Invalid seed phrase format';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 8),

              Text(
                'Tip: You can paste your seed phrase from clipboard',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
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
                  backgroundColor: Colors.blue,
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
      final mnemonic = _mnemonicController.text.trim();

      await provider.connectWithMnemonic(mnemonic);

      if (mounted) {
        // Clear the form
        _mnemonicController.clear();

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
    } catch (e, stackTrace) {
      // SECURITY: Log error securely without exposing details to user
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'ImportMnemonicScreen._importAccount',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(SecureErrorHandler.sanitizeError(e)),
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
