import 'package:local_auth/local_auth.dart';

/// Utility class for biometric authentication (TouchID/FaceID/Fingerprint)
class BiometricsUtil {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Checks if the device supports and has enrolled biometric authentication
  Future<bool> hasBiometrics() async {
    try {
      // Check if device can perform biometric authentication
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      // Check if device is physically capable of biometrics
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) return false;

      // Check for available biometric types
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      // Return true if any biometric is available
      return availableBiometrics.contains(BiometricType.face) ||
          availableBiometrics.contains(BiometricType.fingerprint) ||
          availableBiometrics.contains(BiometricType.strong) ||
          availableBiometrics.contains(BiometricType.weak);
    } catch (e) {
      // If there's any error checking, assume biometrics not available
      return false;
    }
  }

  /// Attempts to authenticate using biometrics
  /// Returns true if authentication successful, false otherwise
  Future<bool> authenticateWithBiometrics({
    required String reason,
  }) async {
    try {
      // Check if biometrics are available
      if (!await hasBiometrics()) {
        return false;
      }

      // Attempt authentication
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true, // Show auth dialog until user explicitly cancels
          biometricOnly: true, // Don't fall back to device PIN
        ),
      );
    } catch (e) {
      // Authentication failed or was cancelled
      return false;
    }
  }

  /// Gets a list of available biometric types on the device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Stops authentication in progress (if any)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      // Ignore errors when stopping authentication
    }
  }
}
