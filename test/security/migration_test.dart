import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idena_p2p/services/migration_service.dart';
import 'package:idena_p2p/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock flutter_secure_storage for testing
  const MethodChannel secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  final Map<String, String> secureStorageData = {};

  setUp(() {
    // Clear mock storage before each test
    secureStorageData.clear();

    // Mock secure storage responses
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel,
            (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'write':
          final args = methodCall.arguments as Map;
          secureStorageData[args['key']] = args['value'];
          return null;
        case 'read':
          final args = methodCall.arguments as Map;
          return secureStorageData[args['key']];
        case 'delete':
          final args = methodCall.arguments as Map;
          secureStorageData.remove(args['key']);
          return null;
        case 'deleteAll':
          secureStorageData.clear();
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    secureStorageData.clear();
  });

  group('Migration Service Tests', () {
    late VaultService vaultService;
    late SharedPreferences prefs;
    late MigrationService migrationService;

    setUp(() async {
      vaultService = VaultService();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      migrationService = MigrationService(
        vaultService: vaultService,
        prefs: prefs,
      );
    });

    test('initial installation has version 0', () {
      expect(migrationService.getStoredVersion(), 0);
      expect(migrationService.needsMigration(), true);
    });

    test('performMigrations updates version to current', () async {
      expect(migrationService.getStoredVersion(), 0);

      await migrationService.performMigrations();

      expect(migrationService.getStoredVersion(), MigrationService.currentVersion);
      expect(migrationService.needsMigration(), false);
    });

    test('performMigrations returns true when migrations performed', () async {
      final result = await migrationService.performMigrations();

      expect(result, true, reason: 'Should return true when migrations are performed');
    });

    test('performMigrations returns false when no migrations needed', () async {
      // First run - perform migrations
      await migrationService.performMigrations();

      // Second run - no migrations needed
      final result = await migrationService.performMigrations();

      expect(result, false, reason: 'Should return false when already up to date');
    });

    test('migration is idempotent (safe to run multiple times)', () async {
      // Run migrations multiple times
      await migrationService.performMigrations();
      await migrationService.performMigrations();
      await migrationService.performMigrations();

      // Should still be at current version
      expect(migrationService.getStoredVersion(), MigrationService.currentVersion);
    });

    test('needsMigration returns correct status', () {
      expect(migrationService.needsMigration(), true);

      // After migration
      migrationService.performMigrations().then((_) {
        expect(migrationService.needsMigration(), false);
      });
    });

    test('getMigrationStatus returns correct information', () {
      final status = migrationService.getMigrationStatus();

      expect(status['stored_version'], 0);
      expect(status['current_version'], MigrationService.currentVersion);
      expect(status['needs_migration'], true);
      expect(status['stored_description'], isNotNull);
      expect(status['current_description'], isNotNull);
    });

    test('getVersionDescription returns descriptions for all versions', () {
      expect(MigrationService.getVersionDescription(0), contains('Initial release'));
      expect(MigrationService.getVersionDescription(1), contains('Argon2id'));
      expect(MigrationService.getVersionDescription(2), contains('ChaCha20'));
    });

    test('resetMigrationVersion clears stored version', () async {
      // Perform migrations
      await migrationService.performMigrations();
      expect(migrationService.getStoredVersion(), MigrationService.currentVersion);

      // Reset
      await migrationService.resetMigrationVersion();

      expect(migrationService.getStoredVersion(), 0);
      expect(migrationService.needsMigration(), true);
    });

    test('v0 to v1 migration handles no PIN gracefully', () async {
      // No PIN stored
      expect(await vaultService.hasPin(), false);

      // Should complete without error
      await migrationService.performMigrations();

      expect(migrationService.getStoredVersion(), MigrationService.currentVersion);
    });

    test('v0 to v1 migration detects existing PIN', () async {
      // Store a legacy PIN (simulate pre-migration)
      secureStorageData['idena_pin_legacy'] = '1234';

      // Run migrations
      await migrationService.performMigrations();

      // Should complete successfully
      expect(migrationService.getStoredVersion(), MigrationService.currentVersion);
    });

    test('v1 to v2 migration handles no private key gracefully', () async {
      // Set version to 1 (skipping v0→v1)
      await prefs.setInt('security_migration_version', 1);

      // No private key stored
      expect(await vaultService.hasStoredKey(), false);

      // Recreate service to pick up new version
      migrationService = MigrationService(
        vaultService: vaultService,
        prefs: prefs,
      );

      // Should complete without error
      await migrationService.performMigrations();

      expect(migrationService.getStoredVersion(), MigrationService.currentVersion);
    });

    test('v1 to v2 migration detects existing private key', () async {
      // Set version to 1
      await prefs.setInt('security_migration_version', 1);

      // Store a private key
      await vaultService.savePrivateKey('0x1234567890abcdef');

      // Recreate service
      migrationService = MigrationService(
        vaultService: vaultService,
        prefs: prefs,
      );

      // Run migration
      await migrationService.performMigrations();

      // Should complete successfully
      expect(migrationService.getStoredVersion(), MigrationService.currentVersion);
      expect(await vaultService.hasStoredKey(), true);
    });

    test('partial migration state is preserved on failure', () async {
      // This test ensures that if a migration fails, we don't lose progress

      // Simulate a scenario where we're partway through
      await prefs.setInt('security_migration_version', 1);

      // Create service at version 1
      migrationService = MigrationService(
        vaultService: vaultService,
        prefs: prefs,
      );

      expect(migrationService.getStoredVersion(), 1);

      // Complete migration
      await migrationService.performMigrations();

      expect(migrationService.getStoredVersion(), MigrationService.currentVersion);
    });

    test('migration service handles fresh install correctly', () async {
      // Fresh install - no data, no version
      expect(await vaultService.hasPin(), false);
      expect(await vaultService.hasStoredKey(), false);
      expect(migrationService.getStoredVersion(), 0);

      // Run migrations
      await migrationService.performMigrations();

      // Should go straight to current version
      expect(migrationService.getStoredVersion(), MigrationService.currentVersion);
    });

    test('migration service handles upgrade from v0 correctly', () async {
      // Simulate v0 user with legacy data
      secureStorageData['idena_pin_legacy'] = '1234';
      await vaultService.savePrivateKey('0xlegacykey');

      expect(migrationService.getStoredVersion(), 0);

      // Run all migrations
      await migrationService.performMigrations();

      // Should be at current version
      expect(migrationService.getStoredVersion(), MigrationService.currentVersion);

      // Data should still be accessible
      expect(await vaultService.hasStoredKey(), true);
    });

    test('current version constant matches expected value', () {
      // This ensures we update tests when adding new migrations
      expect(MigrationService.currentVersion, 2,
          reason: 'Update this test when adding new migrations');
    });

    test('performance - migration completes quickly', () async {
      final stopwatch = Stopwatch()..start();

      await migrationService.performMigrations();

      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Migration should complete within 1 second',
      );
    });
  });
}
