import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../services/crypto_service.dart';
import '../utils/secure_error_handler.dart';
import 'backup_mnemonic_screen.dart';
import 'pin_setup_screen.dart';

/// Screen for creating a new Idena account
class NewAccountScreen extends StatefulWidget {
  const NewAccountScreen({super.key});

  @override
  State<NewAccountScreen> createState() => _NewAccountScreenState();
}

class _NewAccountScreenState extends State<NewAccountScreen> {
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildCreateView(),
      ),
    );
  }

  Widget _buildCreateView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.add_circle_outline,
          size: 80,
          color: Colors.green.shade300,
        ),
        const SizedBox(height: 32),

        Text(
          'Create New Account',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        Text(
          'A new account will be created with a unique seed phrase. '
          'Make sure to save it securely!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),

        ElevatedButton.icon(
          onPressed: _isCreating ? null : _createAccount,
          icon: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: Text(_isCreating ? 'Creating...' : 'Create Account'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _createAccount() async {
    setState(() {
      _isCreating = true;
    });

    try {
      // SECURITY FIX (VULN-003): Generate mnemonic first, but don't create account yet
      // User must backup and verify before account is created
      final cryptoService = CryptoService();
      final mnemonic = cryptoService.generateMnemonic();

      setState(() {
        _isCreating = false;
      });

      if (!mounted) return;

      // Navigate to backup and verification flow
      final backupComplete = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => BackupMnemonicScreen(mnemonic: mnemonic),
        ),
      );

      // Only create account if backup was completed successfully
      if (backupComplete == true && mounted) {
        await _createAccountWithMnemonic(mnemonic);
      }
    } catch (e, stackTrace) {
      // SECURITY: Log error securely without exposing details to user
      SecureErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'NewAccountScreen._createAccount',
      );

      setState(() {
        _isCreating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(SecureErrorHandler.sanitizeError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Creates the account after backup verification is complete
  Future<void> _createAccountWithMnemonic(String mnemonic) async {
    try {
      final provider = context.read<AccountProvider>();
      await provider.connectWithMnemonic(mnemonic);

      if (mounted) {
        // Navigate to PIN setup
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PinSetupScreen(
              onComplete: () {
                // Go back to home after PIN setup
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account created successfully!'),
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
        context: 'NewAccountScreen._createAccountWithMnemonic',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(SecureErrorHandler.sanitizeError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}
