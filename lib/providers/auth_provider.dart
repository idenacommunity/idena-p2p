import 'dart:async';
import 'package:flutter/material.dart';
import '../models/auth_state.dart';
import '../services/auth_service.dart';
import '../services/vault_service.dart';
import '../services/prefs_service.dart';

/// Provider for managing authentication state and lifecycle
/// Handles auto-lock timer, PIN validation, and app lifecycle events
class AuthProvider with ChangeNotifier, WidgetsBindingObserver {
  final AuthService _authService;
  final VaultService _vaultService;

  AuthState _currentState = AuthState.unauthenticated();
  Timer? _autoLockTimer;
  bool _isInitialized = false;

  AuthProvider({
    AuthService? authService,
    VaultService? vaultService,
    PrefsService? prefsService,
  })  : _vaultService = vaultService ?? VaultService(),
        _authService = authService ??
            AuthService(
              vaultService: vaultService ?? VaultService(),
              prefsService: prefsService ?? PrefsService(),
            ) {
    WidgetsBinding.instance.addObserver(this);
  }

  // Getters
  AuthState get currentState => _currentState;
  bool get isLocked => _currentState.isLocked;
  bool get isLockedOut => _currentState.isLockedOut;
  bool get isAuthenticated => _currentState.isAuthenticated;
  bool get needsAuthentication => _currentState.needsUnlock;
  bool get isInitialized => _isInitialized;
  Duration? get lockoutRemaining => _currentState.lockoutRemaining;

  @override
  void dispose() {
    _autoLockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Initializes authentication state on app startup
  Future<void> initialize() async {
    _currentState = await _authService.getAuthState();
    _isInitialized = true;
    notifyListeners();
  }

  /// Sets up a new PIN
  Future<bool> setupPin(String pin) async {
    try {
      await _authService.setPin(pin);
      _currentState = AuthState.unlocked();
      notifyListeners();
      _startAutoLockTimer();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verifies a PIN attempt
  Future<bool> verifyPin(String pin) async {
    final isValid = await _authService.validatePin(pin);

    if (isValid) {
      _currentState = AuthState.unlocked();
      notifyListeners();
      _startAutoLockTimer();
      return true;
    } else {
      // Update state with new failed attempt count
      _currentState = await _authService.getAuthState();
      notifyListeners();
      return false;
    }
  }

  /// Locks the app (requires PIN to unlock)
  Future<void> lock() async {
    _cancelAutoLockTimer();
    final failedAttempts = await _authService.getFailedAttempts();
    final lockoutEndTime = await _authService.getLockoutEndTime();

    if (lockoutEndTime != null) {
      _currentState = AuthState.lockedOut(
        lockoutEndTime: lockoutEndTime,
        failedAttempts: failedAttempts,
      );
    } else {
      _currentState = AuthState.locked(failedAttempts: failedAttempts);
    }

    notifyListeners();
  }

  /// Unlocks the app
  Future<void> unlock() async {
    _currentState = AuthState.unlocked();
    notifyListeners();
    _startAutoLockTimer();
  }

  /// Deletes the PIN and resets authentication
  Future<void> deletePin() async {
    await _authService.deletePin();
    _cancelAutoLockTimer();
    _currentState = AuthState.unauthenticated();
    notifyListeners();
  }

  /// Gets the stored PIN (for validation in UI)
  /// Note: This returns the raw PIN for legacy UI validation.
  /// For secure authentication, use verifyPin() instead.
  Future<String?> getStoredPin() async {
    // ignore: deprecated_member_use_from_same_package
    return _vaultService.getPin();
  }

  /// Starts the auto-lock timer (fixed 1 minute)
  void _startAutoLockTimer() {
    _cancelAutoLockTimer();

    // Fixed 1-minute timeout
    final timeout = const Duration(minutes: 1);

    _autoLockTimer = Timer(timeout, () async {
      await lock();
    });
  }

  /// Cancels the auto-lock timer
  void _cancelAutoLockTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
  }

  /// Resets the auto-lock timer (extends the timeout)
  void resetAutoLockTimer() {
    if (_currentState.isAuthenticated) {
      _startAutoLockTimer();
    }
  }

  /// Handles app lifecycle changes for auto-lock
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized || !_currentState.isAuthenticated) return;

    switch (state) {
      case AppLifecycleState.paused:
        // App went to background - auto-lock timer already running
        break;
      case AppLifecycleState.resumed:
        // App returned to foreground
        // Check if we should still be unlocked or if timer expired
        // Timer will handle locking if it expired
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., system dialog)
        break;
      case AppLifecycleState.detached:
        // App is detached
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }
}
