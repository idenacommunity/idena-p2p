import 'package:shared_preferences/shared_preferences.dart';
import '../models/lock_timeout.dart';

/// Service for managing non-sensitive app preferences using SharedPreferences
/// Handles authentication settings, lockout data, and configuration
class PrefsService {
  // Storage keys
  static const String _lockEnabledKey = 'idena_lock_enabled';
  static const String _lockTimeoutKey = 'idena_lock_timeout';
  static const String _failedAttemptsKey = 'idena_failed_attempts';
  static const String _lockoutEndTimeKey = 'idena_lockout_end_time';
  static const String _firstLaunchKey = 'idena_first_launch';

  /// Returns true if lock feature is enabled
  Future<bool> getLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lockEnabledKey) ?? true; // Default: enabled
  }

  /// Sets lock enabled/disabled
  Future<void> setLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockEnabledKey, enabled);
  }

  /// Returns the configured lock timeout
  Future<LockTimeout> getLockTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_lockTimeoutKey);
    if (index == null) return LockTimeout.defaultTimeout;
    return LockTimeout.fromIndex(index);
  }

  /// Sets the lock timeout
  Future<void> setLockTimeout(LockTimeout timeout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lockTimeoutKey, timeout.getIndex());
  }

  /// Returns the number of failed PIN attempts
  Future<int> getFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_failedAttemptsKey) ?? 0;
  }

  /// Sets the number of failed PIN attempts
  Future<void> setFailedAttempts(int attempts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_failedAttemptsKey, attempts);
  }

  /// Increments failed attempts counter and returns new count
  Future<int> incrementFailedAttempts() async {
    final current = await getFailedAttempts();
    final newCount = current + 1;
    await setFailedAttempts(newCount);
    return newCount;
  }

  /// Resets failed attempts to zero
  Future<void> resetFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_failedAttemptsKey);
  }

  /// Returns the lockout end time (null if not locked out)
  Future<DateTime?> getLockoutEndTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isoString = prefs.getString(_lockoutEndTimeKey);
    if (isoString == null) return null;

    try {
      return DateTime.parse(isoString);
    } catch (e) {
      // Invalid format, remove it
      await prefs.remove(_lockoutEndTimeKey);
      return null;
    }
  }

  /// Sets the lockout end time
  Future<void> setLockoutEndTime(DateTime endTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lockoutEndTimeKey, endTime.toIso8601String());
  }

  /// Clears lockout data (end time and failed attempts)
  Future<void> clearLockoutData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lockoutEndTimeKey);
    await prefs.remove(_failedAttemptsKey);
  }

  /// Returns true if this is the first app launch
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  /// Marks the app as having been launched
  Future<void> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }

  /// Clears all authentication-related preferences
  /// Use this on logout or app reset
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lockEnabledKey);
    await prefs.remove(_lockTimeoutKey);
    await prefs.remove(_failedAttemptsKey);
    await prefs.remove(_lockoutEndTimeKey);
    // Note: Don't clear first launch flag
  }
}
