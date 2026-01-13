/// Lock timeout options for auto-lock feature
enum LockTimeoutOption {
  /// Lock immediately when app backgrounds (3 seconds delay)
  instantly,

  /// Lock after 1 minute in background
  oneMinute,

  /// Lock after 5 minutes in background
  fiveMinutes,

  /// Lock after 15 minutes in background
  fifteenMinutes,
}

/// Represents a lock timeout setting with display name and duration
class LockTimeout {
  final LockTimeoutOption option;

  const LockTimeout(this.option);

  /// Returns the display name for this timeout option
  String getDisplayName() {
    switch (option) {
      case LockTimeoutOption.instantly:
        return 'Instantly';
      case LockTimeoutOption.oneMinute:
        return '1 Minute';
      case LockTimeoutOption.fiveMinutes:
        return '5 Minutes';
      case LockTimeoutOption.fifteenMinutes:
        return '15 Minutes';
    }
  }

  /// Returns the actual duration for this timeout option
  Duration getDuration() {
    switch (option) {
      case LockTimeoutOption.instantly:
        return const Duration(seconds: 3); // Small delay to allow app switching
      case LockTimeoutOption.oneMinute:
        return const Duration(minutes: 1);
      case LockTimeoutOption.fiveMinutes:
        return const Duration(minutes: 5);
      case LockTimeoutOption.fifteenMinutes:
        return const Duration(minutes: 15);
    }
  }

  /// Returns the index for storage in SharedPreferences
  int getIndex() {
    return option.index;
  }

  /// Creates a LockTimeout from an index (from SharedPreferences)
  static LockTimeout fromIndex(int index) {
    if (index >= 0 && index < LockTimeoutOption.values.length) {
      return LockTimeout(LockTimeoutOption.values[index]);
    }
    return const LockTimeout(LockTimeoutOption.oneMinute); // Default
  }

  /// Default timeout (1 minute)
  static const LockTimeout defaultTimeout =
      LockTimeout(LockTimeoutOption.oneMinute);
}
