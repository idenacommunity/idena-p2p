import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/idena_account.dart';

/// Widget to display account information in a card format
class AccountCard extends StatelessWidget {
  final IdenaAccount account;

  const AccountCard({
    super.key,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address section
            _buildAddressSection(context),
            const SizedBox(height: 20),

            // Identity status badge
            _buildIdentityBadge(),
            const SizedBox(height: 20),

            // Balance section
            _buildBalanceSection(),
            const SizedBox(height: 16),

            // Stake section
            _buildStakeSection(),

            if (account.epoch != null) ...[
              const SizedBox(height: 16),
              _buildEpochInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Address',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _truncateAddress(account.address),
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: () => _copyAddress(context),
          tooltip: 'Copy address',
        ),
      ],
    );
  }

  Widget _buildIdentityBadge() {
    final color = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            account.identityStatus,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (account.age != null) ...[
            const SizedBox(width: 8),
            Text(
              '(Age: ${account.age})',
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Balance',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '${account.balance.toStringAsFixed(4)} iDNA',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStakeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Stake (Locked)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '${account.stake.toStringAsFixed(4)} iDNA',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildEpochInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Epoch ${account.epoch}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _truncateAddress(String address) {
    if (address.length <= 16) return address;
    return '${address.substring(0, 10)}...${address.substring(address.length - 6)}';
  }

  Color _getStatusColor() {
    switch (account.identityStatus.toLowerCase()) {
      case 'human':
        return Colors.amber[700]!;
      case 'verified':
        return Colors.green;
      case 'newbie':
        return Colors.blue;
      case 'candidate':
        return Colors.grey;
      case 'suspended':
      case 'zombie':
      case 'killed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (account.identityStatus.toLowerCase()) {
      case 'human':
        return Icons.verified_user;
      case 'verified':
        return Icons.check_circle;
      case 'newbie':
        return Icons.person;
      case 'candidate':
        return Icons.person_outline;
      case 'suspended':
      case 'zombie':
      case 'killed':
        return Icons.warning;
      default:
        return Icons.help_outline;
    }
  }

  void _copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: account.address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
