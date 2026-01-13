import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../utils/secure_error_handler.dart';
import '../widgets/account_card.dart';
import 'connect_screen.dart';
import 'settings_screen.dart';

/// Main home screen that displays connection status and account information
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Idena Wallet'),
        actions: [
          Consumer<AccountProvider>(
            builder: (context, provider, _) {
              if (provider.isConnected && !provider.isLoading) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                      tooltip: 'Settings',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => provider.refreshAccountData(),
                      tooltip: 'Refresh account data',
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<AccountProvider>(
        builder: (context, provider, _) {
          // Show loading indicator
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading account...'),
                ],
              ),
            );
          }

          // Show error message if any
          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => provider.clearError(),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show connected state or disconnected state
          if (provider.isConnected && provider.currentAccount != null) {
            return _buildConnectedView(context, provider);
          } else {
            return _buildDisconnectedView(context);
          }
        },
      ),
    );
  }

  Widget _buildConnectedView(BuildContext context, AccountProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.refreshAccountData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Account information card
            AccountCard(account: provider.currentAccount!),

            const SizedBox(height: 16),

            // Total balance display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '${provider.currentAccount!.totalBalance.toStringAsFixed(4)} iDNA',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Disconnect button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showDisconnectDialog(context, provider),
                  icon: const Icon(Icons.logout),
                  label: const Text('Disconnect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnectedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Idena logo placeholder
            Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.blue.shade300,
            ),
            const SizedBox(height: 24),

            Text(
              'Welcome to Idena Wallet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            Text(
              'Connect to your Idena account to get started',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Connect button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConnectScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.link),
                label: const Text('Connect Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDisconnectDialog(BuildContext context, AccountProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Account'),
        content: const Text(
          'Are you sure you want to disconnect? '
          'Make sure you have backed up your private key or seed phrase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.disconnect();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account disconnected'),
                    ),
                  );
                }
              } catch (e, stackTrace) {
                // SECURITY: Log error securely without exposing details to user
                SecureErrorHandler.logError(
                  e,
                  stackTrace: stackTrace,
                  context: 'HomeScreen._showDisconnectDialog',
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(SecureErrorHandler.sanitizeError(e)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Disconnect',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
