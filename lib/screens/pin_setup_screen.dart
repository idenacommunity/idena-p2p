import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/screen_security_service.dart';
import 'pin_screen.dart';

/// Screen for setting up a new PIN
/// Provides explanation and initiates PIN creation flow
/// SECURITY: Screenshot protection enabled to prevent PIN capture
class PinSetupScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const PinSetupScreen({
    Key? key,
    this.onComplete,
  }) : super(key: key);

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _screenSecurity = ScreenSecurityService();

  @override
  void initState() {
    super.initState();
    // SECURITY: Enable screenshot protection on this sensitive screen
    _screenSecurity.enableScreenSecurity();
  }

  @override
  void dispose() {
    // SECURITY: Disable screenshot protection when leaving screen
    _screenSecurity.disableScreenSecurity();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Secure Your Wallet'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // No back button
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Lock icon
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 40),
              // Title
              const Text(
                'Protect Your Wallet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Description
              const Text(
                'Set up a 6-digit PIN to secure your wallet. '
                'You\'ll need this PIN every time you open the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // Setup PIN button
              ElevatedButton(
                onPressed: () => _setupPin(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Set Up PIN',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setupPin(BuildContext context) async {
    // Navigate to PIN entry screen
    final pin = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const PinScreen(
          mode: PinScreenMode.setup,
        ),
      ),
    );

    if (pin != null && pin.length == 6 && context.mounted) {
      // Save the PIN
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.setupPin(pin);

      if (success && context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN set up successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Call completion callback
        if (onComplete != null) {
          onComplete!();
        } else {
          // Default: go back to home
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    }
  }
}
