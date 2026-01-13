import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';
import 'vault_service.dart';

/// Service for managing data migrations across app versions
/// Ensures backward compatibility when security features are upgraded
///
/// Migration History:
/// - v0: Initial release (no security features)
/// - v1: Added Argon2id PIN hashing
/// - v2: Added session-based memory encryption
class MigrationService {
  static const String _migrationVersionKey = 'security_migration_version';
  static const int currentVersion = 2;

  final VaultService _vaultService;
  final SharedPreferences _prefs;

  MigrationService({
    required VaultService vaultService,
    required SharedPreferences prefs,
  })  : _vaultService = vaultService,
        _prefs = prefs;

  /// Performs all necessary migrations to bring the app to the current version
  /// Safe to call on every app startup - only runs migrations that haven't been applied
  /// Returns true if any migrations were performed
  Future<bool> performMigrations() async {
    final storedVersion = _prefs.getInt(_migrationVersionKey) ?? 0;

    developer.log(
      'Migration check: stored version=$storedVersion, current version=$currentVersion',
      name: 'MigrationService',
    );

    if (storedVersion >= currentVersion) {
      developer.log('No migrations needed', name: 'MigrationService');
      return false;
    }

    bool migrationsPerformed = false;

    try {
      // Run migrations in sequence
      if (storedVersion < 1) {
        await _migrateToV1();
        migrationsPerformed = true;
      }

      if (storedVersion < 2) {
        await _migrateToV2();
        migrationsPerformed = true;
      }

      // Update stored version to current
      await _prefs.setInt(_migrationVersionKey, currentVersion);

      developer.log(
        'Migrations completed successfully: v$storedVersion → v$currentVersion',
        name: 'MigrationService',
      );

      return migrationsPerformed;
    } catch (e) {
      developer.log(
        'Migration failed: $e',
        name: 'MigrationService',
        error: e,
      );
      // Don't update version if migration fails
      rethrow;
    }
  }

  /// Migration v0 → v1: Argon2id PIN Hashing
  /// Migrates legacy plaintext PINs to hashed versions
  /// This is handled automatically by VaultService._migratePinIfNeeded()
  Future<void> _migrateToV1() async {
    developer.log('Migrating to v1: Argon2id PIN hashing', name: 'MigrationService');

    // Check if user has a PIN that needs migration
    final hasLegacyPin = await _vaultService.hasPin();

    if (hasLegacyPin) {
      developer.log('Legacy PIN detected, migration will occur on next PIN verification',
          name: 'MigrationService');

      // Note: Actual migration happens in VaultService._migratePinIfNeeded()
      // which is called automatically during savePin()
      // We just need to ensure the migration flag is set
    } else {
      developer.log('No PIN to migrate', name: 'MigrationService');
    }

    // No explicit action needed here - VaultService handles PIN migration automatically
    // when savePin() is called next time
  }

  /// Migration v1 → v2: Session-Based Memory Encryption
  /// Private keys are now encrypted in memory using ChaCha20-Poly1305
  /// No data migration needed - this is a runtime change in AccountProvider
  Future<void> _migrateToV2() async {
    developer.log('Migrating to v2: Session-based memory encryption',
        name: 'MigrationService');

    // Check if user has a stored account
    final hasStoredKey = await _vaultService.hasStoredKey();

    if (hasStoredKey) {
      developer.log(
        'Private key detected, will be encrypted in memory on next load',
        name: 'MigrationService',
      );

      // No data migration needed - AccountProvider will automatically
      // encrypt the private key in memory when loadStoredAccount() is called
    } else {
      developer.log('No private key to migrate', name: 'MigrationService');
    }

    // No explicit action needed - AccountProvider handles memory encryption
    // automatically when loading accounts
  }

  /// Gets the current migration version stored locally
  int getStoredVersion() {
    return _prefs.getInt(_migrationVersionKey) ?? 0;
  }

  /// Checks if migrations are needed (stored version < current version)
  bool needsMigration() {
    return getStoredVersion() < currentVersion;
  }

  /// Resets migration version (use only for testing/debugging)
  /// WARNING: This will cause migrations to run again on next startup
  Future<void> resetMigrationVersion() async {
    await _prefs.remove(_migrationVersionKey);
    developer.log('Migration version reset', name: 'MigrationService');
  }

  /// Gets a human-readable description of the current version's changes
  static String getVersionDescription(int version) {
    switch (version) {
      case 0:
        return 'Initial release (no security enhancements)';
      case 1:
        return 'Phase 1.1: Argon2id PIN hashing (OWASP compliant)';
      case 2:
        return 'Phase 1.2: Session-based memory encryption (ChaCha20-Poly1305)';
      default:
        return 'Unknown version';
    }
  }

  /// Gets migration status information for debugging/display
  Map<String, dynamic> getMigrationStatus() {
    final stored = getStoredVersion();
    return {
      'stored_version': stored,
      'current_version': currentVersion,
      'needs_migration': needsMigration(),
      'stored_description': getVersionDescription(stored),
      'current_description': getVersionDescription(currentVersion),
    };
  }
}
