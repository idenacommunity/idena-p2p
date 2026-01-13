import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/account_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';

/// Root application widget
class IdenaApp extends StatelessWidget {
  const IdenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Idena Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const AppInitializer(),
    );
  }
}

/// Initializer widget that loads stored account on startup
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize authentication and account state when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeApp();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Forward lifecycle events to AuthProvider
    context.read<AuthProvider>().didChangeAppLifecycleState(state);
  }

  Future<void> _initializeApp() async {
    final authProvider = context.read<AuthProvider>();
    final accountProvider = context.read<AccountProvider>();

    // Initialize authentication state
    await authProvider.initialize();

    // Load stored account
    await accountProvider.loadStoredAccount();

    if (!mounted) return;

    // Route based on authentication state
    if (accountProvider.isConnected && authProvider.isLocked) {
      // Account exists but locked - show lock screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LockScreen()),
      );
    }
    // Otherwise HomeScreen is already shown
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
