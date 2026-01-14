import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/account_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/contact_provider.dart';
import 'services/migration_service.dart';
import 'services/vault_service.dart';
import 'services/device_security_service.dart';
import 'app.dart';

void main() async {
  // Ensure Flutter is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  // SECURITY: Check device security status on startup
  await _checkDeviceSecurity();

  // SECURITY: Run data migrations before app starts
  // This ensures backward compatibility when security features are upgraded
  await _performSecurityMigrations();

  // Initialize ContactProvider
  final contactProvider = ContactProvider();
  await contactProvider.init();

  runApp(
    /// Wrap the app with multiple providers for state management
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider.value(value: contactProvider),
      ],
      child: const IdenaApp(),
    ),
  );
}

/// Checks device security status and warns user if compromised
/// Called on app startup to detect jailbreak/root
Future<void> _checkDeviceSecurity() async {
  try {
    final deviceSecurity = DeviceSecurityService();
    final status = await deviceSecurity.getSecurityStatus();

    if (status.isCompromised) {
      debugPrint('⚠️ SECURITY WARNING: ${status.description}');
      debugPrint('⚠️ Risk Level: ${status.riskLevel.name.toUpperCase()}');

      // Log warning but allow app to continue
      // In production, you might want to show a dialog or restrict functionality
      if (status.riskLevel == SecurityRiskLevel.high) {
        debugPrint('⚠️ HIGH RISK: Device is jailbroken/rooted. Wallet security may be compromised.');
      }
    } else {
      debugPrint('✅ Device security check passed');
    }
  } catch (e) {
    debugPrint('⚠️ Device security check failed: $e');
    // Continue app startup even if security check fails
  }
}

/// Performs security-related data migrations
/// Called once on app startup to ensure data is up-to-date
Future<void> _performSecurityMigrations() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final vaultService = VaultService();
    final migrationService = MigrationService(
      vaultService: vaultService,
      prefs: prefs,
    );

    final migrationsPerformed = await migrationService.performMigrations();

    if (migrationsPerformed) {
      debugPrint('✅ Security migrations completed successfully');
    } else {
      debugPrint('✅ No security migrations needed');
    }
  } catch (e) {
    debugPrint('⚠️ Security migration failed: $e');
    // Continue app startup even if migration fails
    // This prevents the app from being stuck if there's a migration bug
  }
}
