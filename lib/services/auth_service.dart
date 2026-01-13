import '../models/auth_state.dart';
import 'vault_service.dart';
import 'prefs_service.dart';

/// Service for authentication logic including PIN validation and lockout management
class AuthService {
  final VaultService _vaultService;
  final PrefsService _prefsService;

  AuthService({
    required VaultService vaultService,
    required PrefsService prefsService,
  })  : _vaultService = vaultService,
        _prefsService = prefsService;

  /// Checks if a PIN is currently set up
  Future<bool> hasPin() async {
    return await _vaultService.hasPin();
  }

  /// Sets up a new PIN
  Future<void> setPin(String pin) async {
    await _vaultService.savePin(pin);
    // Reset failed attempts when setting new PIN
    await _prefsService.resetFailedAttempts();
    await _prefsService.clearLockoutData();
  }

  /// Validates a PIN attempt using secure Argon2id verification
  /// SECURITY FIX: Uses verifyPin() instead of plaintext comparison
  /// Returns true if PIN is correct, false otherwise
  /// Handles failed attempt tracking and lockout calculation
  Future<bool> validatePin(String pin) async {
    // Use secure Argon2id verification (constant-time comparison)
    final isValid = await _vaultService.verifyPin(pin);

    if (isValid) {
      // Correct PIN - reset failed attempts
      await _prefsService.resetFailedAttempts();
      await _prefsService.clearLockoutData();
      return true;
    } else {
      // Incorrect PIN - increment failed attempts
      final failedAttempts = await _prefsService.incrementFailedAttempts();

      // Calculate and set lockout if threshold reached
      final lockoutDuration = _calculateLockoutDuration(failedAttempts);
      if (lockoutDuration > Duration.zero) {
        final lockoutEndTime = DateTime.now().add(lockoutDuration);
        await _prefsService.setLockoutEndTime(lockoutEndTime);
      }

      return false;
    }
  }

  /// Deletes the stored PIN
  Future<void> deletePin() async {
    await _vaultService.deletePin();
    await _prefsService.resetFailedAttempts();
    await _prefsService.clearLockoutData();
  }

  /// Gets the current authentication state
  Future<AuthState> getAuthState() async {
    final hasPin = await _vaultService.hasPin();

    if (!hasPin) {
      return AuthState.unauthenticated();
    }

    // Check for lockout
    final lockoutEndTime = await _prefsService.getLockoutEndTime();
    final failedAttempts = await _prefsService.getFailedAttempts();

    if (lockoutEndTime != null) {
      // Check if lockout has expired
      if (DateTime.now().isBefore(lockoutEndTime)) {
        return AuthState.lockedOut(
          lockoutEndTime: lockoutEndTime,
          failedAttempts: failedAttempts,
        );
      } else {
        // Lockout expired, clear it
        await _prefsService.clearLockoutData();
      }
    }

    // Default to locked state (needs PIN entry)
    return AuthState.locked(failedAttempts: failedAttempts);
  }

  /// Gets the number of failed PIN attempts
  Future<int> getFailedAttempts() async {
    return await _prefsService.getFailedAttempts();
  }

  /// Resets failed attempts counter
  Future<void> resetFailedAttempts() async {
    await _prefsService.resetFailedAttempts();
    await _prefsService.clearLockoutData();
  }

  /// Gets the lockout end time (null if not locked out)
  Future<DateTime?> getLockoutEndTime() async {
    final lockoutEndTime = await _prefsService.getLockoutEndTime();

    // Return null if lockout has expired
    if (lockoutEndTime != null && DateTime.now().isAfter(lockoutEndTime)) {
      await _prefsService.clearLockoutData();
      return null;
    }

    return lockoutEndTime;
  }

  /// Calculates lockout duration based on failed attempts
  /// Progressive lockout: 5 attempts = 1min, 10 = 5min, 15 = 15min, 20+ = 24hrs
  Duration _calculateLockoutDuration(int failedAttempts) {
    if (failedAttempts >= 20) {
      return const Duration(hours: 24);
    } else if (failedAttempts >= 15) {
      return const Duration(minutes: 15);
    } else if (failedAttempts >= 10) {
      return const Duration(minutes: 5);
    } else if (failedAttempts >= 5) {
      return const Duration(minutes: 1);
    }
    return Duration.zero;
  }

  /// Checks if lock is enabled
  Future<bool> isLockEnabled() async {
    return await _prefsService.getLockEnabled();
  }

  /// Sets lock enabled/disabled
  Future<void> setLockEnabled(bool enabled) async {
    await _prefsService.setLockEnabled(enabled);
  }
}
