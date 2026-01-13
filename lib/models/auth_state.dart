/// Authentication status enum
enum AuthStatus {
  /// No account exists or authentication not set up
  unauthenticated,

  /// Account exists but needs authentication (PIN locked)
  locked,

  /// Successfully authenticated and unlocked
  unlocked,

  /// Locked out due to too many failed attempts
  lockedOut,
}

/// Represents the current authentication state
class AuthState {
  /// Current authentication status
  final AuthStatus status;

  /// When the lockout ends (null if not locked out)
  final DateTime? lockoutEndTime;

  /// Number of failed PIN attempts
  final int failedAttempts;

  const AuthState({
    required this.status,
    this.lockoutEndTime,
    this.failedAttempts = 0,
  });

  /// Returns true if the user is authenticated and can access the app
  bool get isAuthenticated => status == AuthStatus.unlocked;

  /// Returns true if the user needs to unlock (locked or locked out)
  bool get needsUnlock =>
      status == AuthStatus.locked || status == AuthStatus.lockedOut;

  /// Returns true if currently locked out
  bool get isLockedOut => status == AuthStatus.lockedOut;

  /// Returns true if locked but not locked out
  bool get isLocked => status == AuthStatus.locked;

  /// Returns the remaining lockout duration (null if not locked out)
  Duration? get lockoutRemaining {
    if (lockoutEndTime == null) return null;
    final remaining = lockoutEndTime!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Returns true if the lockout has expired
  bool get isLockoutExpired {
    if (lockoutEndTime == null) return true;
    return DateTime.now().isAfter(lockoutEndTime!);
  }

  /// Creates an unauthenticated state (no account)
  factory AuthState.unauthenticated() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Creates a locked state (needs PIN entry)
  factory AuthState.locked({int failedAttempts = 0}) {
    return AuthState(
      status: AuthStatus.locked,
      failedAttempts: failedAttempts,
    );
  }

  /// Creates an unlocked state (authenticated)
  factory AuthState.unlocked() {
    return const AuthState(
      status: AuthStatus.unlocked,
      failedAttempts: 0,
    );
  }

  /// Creates a locked out state (too many failed attempts)
  factory AuthState.lockedOut({
    required DateTime lockoutEndTime,
    required int failedAttempts,
  }) {
    return AuthState(
      status: AuthStatus.lockedOut,
      lockoutEndTime: lockoutEndTime,
      failedAttempts: failedAttempts,
    );
  }

  /// Creates a copy with updated fields
  AuthState copyWith({
    AuthStatus? status,
    DateTime? lockoutEndTime,
    int? failedAttempts,
  }) {
    return AuthState(
      status: status ?? this.status,
      lockoutEndTime: lockoutEndTime ?? this.lockoutEndTime,
      failedAttempts: failedAttempts ?? this.failedAttempts,
    );
  }

  @override
  String toString() {
    return 'AuthState(status: $status, failedAttempts: $failedAttempts, lockoutEndTime: $lockoutEndTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuthState &&
        other.status == status &&
        other.lockoutEndTime == lockoutEndTime &&
        other.failedAttempts == failedAttempts;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        (lockoutEndTime?.hashCode ?? 0) ^
        failedAttempts.hashCode;
  }
}
