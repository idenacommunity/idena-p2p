import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'pin_setup_screen.dart';

/// Settings screen for security and account management
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Security Section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Security',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change PIN'),
            subtitle: const Text('Update your wallet PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _changePin(context),
          ),
          const Divider(),

          // Account Information Section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return SwitchListTile(
                secondary: const Icon(Icons.security),
                title: const Text('PIN Protection'),
                subtitle: Text(
                  authProvider.isAuthenticated ? 'Enabled' : 'Disabled',
                ),
                value: authProvider.isAuthenticated,
                onChanged: null, // Always enabled, cannot disable
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.timer_outlined),
            title: Text('Auto-lock Timeout'),
            subtitle: Text('1 minute'),
            enabled: false,
          ),
        ],
      ),
    );
  }

  Future<void> _changePin(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final currentPin = await authProvider.getStoredPin();

    if (currentPin == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No PIN is currently set'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Verify current PIN first
    if (!context.mounted) return;
    final verified = await _verifyCurrentPin(context, currentPin);

    if (!verified || !context.mounted) {
      return;
    }

    // Navigate to PIN setup to create new PIN
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PinSetupScreen(
            onComplete: () {
              Navigator.of(context).pop(); // Back to settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PIN changed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Future<bool> _verifyCurrentPin(
      BuildContext context, String currentPin) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => _VerifyPinDialog(currentPin: currentPin),
        ) ??
        false;
  }
}

/// Dialog for verifying current PIN before changing
class _VerifyPinDialog extends StatefulWidget {
  final String currentPin;

  const _VerifyPinDialog({required this.currentPin});

  @override
  State<_VerifyPinDialog> createState() => _VerifyPinDialogState();
}

class _VerifyPinDialogState extends State<_VerifyPinDialog> {
  final _pinController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyAndContinue() {
    if (_pinController.text == widget.currentPin) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorText = 'Incorrect PIN';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify Current PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your current PIN to continue'),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Current PIN',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _verifyAndContinue(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _verifyAndContinue,
          child: const Text('Verify'),
        ),
      ],
    );
  }
}
