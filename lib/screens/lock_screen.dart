import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/biometrics_util.dart';
import 'pin_screen.dart';
import 'home_screen.dart';

/// Screen shown when app is locked and requires authentication
/// Handles biometric authentication and lockout countdown
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final BiometricsUtil _biometricsUtil = BiometricsUtil();
  Timer? _countdownTimer;
  String _countdownText = '';
  bool _isLockedOut = false;
  bool _attemptedBiometric = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();

    if (mounted) {
      final state = authProvider.currentState;

      if (state.isLockedOut) {
        _startCountdown();
      } else if (!_attemptedBiometric) {
        // Try biometric authentication automatically
        _attemptedBiometric = true;
        _attemptBiometricAuth();
      }
    }
  }

  void _startCountdown() {
    setState(() {
      _isLockedOut = true;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final authProvider = context.read<AuthProvider>();
      final remaining = authProvider.lockoutRemaining;

      if (remaining == null || remaining.inSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isLockedOut = false;
          _countdownText = '';
        });
      } else {
        setState(() {
          _countdownText = _formatDuration(remaining);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _attemptBiometricAuth() async {
    final hasBio = await _biometricsUtil.hasBiometrics();

    if (!hasBio || !mounted) return;

    final success = await _biometricsUtil.authenticateWithBiometrics(
      reason: 'Unlock your Idena wallet',
    );

    if (success && mounted) {
      await _unlockAndNavigate();
    }
  }

  Future<void> _showPinEntry() async {
    final authProvider = context.read<AuthProvider>();
    final storedPin = await authProvider.getStoredPin();

    if (storedPin == null || !mounted) return;

    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PinScreen(
          mode: PinScreenMode.enter,
          expectedPin: storedPin,
        ),
      ),
    );

    if (success == true && mounted) {
      await authProvider.unlock();
      await _unlockAndNavigate();
    } else if (success == false && mounted) {
      // PIN was incorrect, check if now locked out
      await authProvider.initialize();
      final state = authProvider.currentState;

      if (state.isLockedOut) {
        _startCountdown();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect PIN'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unlockAndNavigate() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.unlock();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Lock icon
              const Icon(
                Icons.lock,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 40),
              // Title
              const Text(
                'Wallet Locked',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Lockout countdown or instruction
              if (_isLockedOut && _countdownText.isNotEmpty) ...[
                const Text(
                  'Too many failed attempts',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try again in $_countdownText',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ] else ...[
                const Text(
                  'Enter your PIN to unlock',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
              const Spacer(),
              // Unlock button
              ElevatedButton(
                onPressed: _isLockedOut ? null : _showPinEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: const Text(
                  'Unlock with PIN',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              // Try biometric button (if not locked out)
              if (!_isLockedOut)
                TextButton(
                  onPressed: _attemptBiometricAuth,
                  child: const Text(
                    'Use Biometric',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
