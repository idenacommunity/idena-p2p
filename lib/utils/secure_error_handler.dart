import 'package:flutter/foundation.dart';

/// Secure error handler that sanitizes error messages for production
///
/// SECURITY: Never expose internal implementation details in production.
/// Error messages can reveal:
/// - Stack traces with file paths
/// - Internal variable names
/// - Database queries
/// - API endpoint details
/// - Cryptographic implementation details
class SecureErrorHandler {
  /// Sanitize error messages to prevent information leakage
  ///
  /// In debug mode: Shows full error details for development
  /// In production: Shows user-friendly generic messages only
  static String sanitizeError(dynamic error) {
    if (kDebugMode) {
      // In debug mode, show full error for development
      return error.toString();
    }

    // In production, show generic user-friendly messages
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('handshake')) {
      return 'Network connection error. Please check your internet connection and try again.';
    }

    // Authentication errors
    if (errorString.contains('auth') ||
        errorString.contains('biometric') ||
        errorString.contains('pin') ||
        errorString.contains('password')) {
      return 'Authentication failed. Please try again.';
    }

    // Validation errors
    if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('format')) {
      return 'Invalid input. Please check your data and try again.';
    }

    // Storage errors
    if (errorString.contains('storage') ||
        errorString.contains('keychain') ||
        errorString.contains('keystore')) {
      return 'Storage error. Please restart the app and try again.';
    }

    // Crypto errors
    if (errorString.contains('crypto') ||
        errorString.contains('key') ||
        errorString.contains('encrypt') ||
        errorString.contains('decrypt')) {
      return 'Security operation failed. Please try again.';
    }

    // RPC/blockchain errors
    if (errorString.contains('rpc') ||
        errorString.contains('idena') ||
        errorString.contains('blockchain')) {
      return 'Unable to connect to Idena network. Please try again later.';
    }

    // Generic fallback - don't expose any internal details
    return 'An error occurred. Please try again or contact support if the problem persists.';
  }

  /// Log errors securely for debugging and monitoring
  ///
  /// In debug mode: Prints to console
  /// In production: Can be sent to secure logging service (Sentry, Firebase Crashlytics)
  ///
  /// IMPORTANT: Never log sensitive data:
  /// - Private keys
  /// - Mnemonic phrases
  /// - PINs or passwords
  /// - Session tokens
  /// - Personal information
  static void logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    if (kDebugMode) {
      // In debug mode, print full error details
      print('═══════════════════════════════════════');
      print('ERROR: $error');
      if (context != null) {
        print('Context: $context');
      }
      if (metadata != null) {
        print('Metadata: $metadata');
      }
      if (stackTrace != null) {
        print('Stack trace:\n$stackTrace');
      }
      print('═══════════════════════════════════════');
    } else {
      // In production: Send to secure logging service
      // Example: Sentry.captureException(error, stackTrace: stackTrace);
      // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace);

      // For now, we just silently skip logging in production
      // TODO: Integrate with a secure logging service before release
    }
  }

  /// Check if an error is security-related
  ///
  /// Use this to determine if an error should trigger additional security measures
  /// like lockout, notification, or security event logging
  static bool isSecurityError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    return errorString.contains('auth') ||
        errorString.contains('security') ||
        errorString.contains('crypto') ||
        errorString.contains('key') ||
        errorString.contains('pin') ||
        errorString.contains('biometric') ||
        errorString.contains('root') ||
        errorString.contains('jailbreak') ||
        errorString.contains('tamper');
  }

  /// Get a user-friendly error category
  ///
  /// Use this to provide more context in error reporting UI
  static String getErrorCategory(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return 'Network Error';
    }

    if (errorString.contains('auth') ||
        errorString.contains('biometric') ||
        errorString.contains('pin')) {
      return 'Authentication Error';
    }

    if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('format')) {
      return 'Validation Error';
    }

    if (errorString.contains('storage') ||
        errorString.contains('keychain') ||
        errorString.contains('keystore')) {
      return 'Storage Error';
    }

    if (errorString.contains('crypto') || errorString.contains('key')) {
      return 'Security Error';
    }

    return 'Application Error';
  }
}

/// Custom exception for security-related errors
class SecurityException implements Exception {
  final String message;
  final String? details;

  SecurityException(this.message, {this.details});

  @override
  String toString() {
    if (kDebugMode && details != null) {
      return 'SecurityException: $message\nDetails: $details';
    }
    return 'SecurityException: $message';
  }
}

/// Custom exception for validation errors
class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}

/// Custom exception for network errors
class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Custom exception for authentication errors
class AuthenticationException implements Exception {
  final String message;

  AuthenticationException(this.message);

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Custom exception for storage errors
class StorageException implements Exception {
  final String message;

  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
