import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:idena_p2p/models/contact.dart';
import 'package:idena_p2p/providers/contact_provider.dart';

/// Screen displaying detailed information about a contact
class ContactDetailScreen extends StatefulWidget {
  final Contact contact;

  const ContactDetailScreen({
    super.key,
    required this.contact,
  });

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  late Contact _contact;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editContact,
            tooltip: 'Edit nickname',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block),
                    SizedBox(width: 8),
                    Text('Block contact'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Remove contact', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildInfoSection(),
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  /// Build header with avatar and display name
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getAvatarColor(_contact),
            _getAvatarColor(_contact).withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              _getInitials(_contact),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _getAvatarColor(_contact),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _contact.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _contact.identityBadge,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                _contact.state,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build information section
  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            icon: Icons.account_balance_wallet,
            title: 'Address',
            subtitle: _contact.address,
            onTap: () => _copyToClipboard(_contact.address, 'Address copied'),
            trailing: const Icon(Icons.copy, size: 20),
          ),
          _buildInfoCard(
            icon: Icons.stars,
            title: 'Trust Level',
            subtitle: _contact.trustLevel,
          ),
          _buildInfoCard(
            icon: Icons.calendar_today,
            title: 'Identity Age',
            subtitle: '${_contact.age} epochs',
          ),
          _buildInfoCard(
            icon: Icons.account_balance,
            title: 'Stake',
            subtitle: '${_contact.stake.toStringAsFixed(2)} iDNA',
          ),
          _buildInfoCard(
            icon: Icons.access_time,
            title: 'Added',
            subtitle: _formatDate(_contact.addedAt),
          ),
          if (_contact.lastVerified != null)
            _buildInfoCard(
              icon: Icons.verified,
              title: 'Last Verified',
              subtitle: _formatDate(_contact.lastVerified!),
              trailing: _contact.needsVerification
                  ? const Icon(Icons.warning, color: Colors.orange, size: 20)
                  : null,
            ),
        ],
      ),
    );
  }

  /// Build individual info card
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 14)),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  /// Build actions section
  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _isVerifying ? null : _verifyIdentity,
            icon: _isVerifying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Verify Identity'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Implement messaging
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Messaging feature coming soon!'),
                ),
              );
            },
            icon: const Icon(Icons.message),
            label: const Text('Send Message'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Get initials for avatar
  String _getInitials(Contact contact) {
    if (contact.nickname != null && contact.nickname!.isNotEmpty) {
      final words = contact.nickname!.split(' ');
      if (words.length >= 2) {
        return '${words[0][0]}${words[1][0]}'.toUpperCase();
      }
      return contact.nickname!.substring(0, 2).toUpperCase();
    }
    return contact.address.substring(2, 4).toUpperCase();
  }

  /// Get avatar background color
  Color _getAvatarColor(Contact contact) {
    switch (contact.state) {
      case 'Human':
        return Colors.green;
      case 'Verified':
        return Colors.blue;
      case 'Newbie':
        return Colors.amber;
      case 'Suspended':
        return Colors.orange;
      case 'Zombie':
      case 'Killed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Copy text to clipboard
  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Edit contact nickname
  void _editContact() {
    final nicknameController = TextEditingController(text: _contact.nickname);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Nickname'),
        content: TextField(
          controller: nicknameController,
          decoration: const InputDecoration(
            labelText: 'Nickname',
            hintText: 'Enter a friendly name',
          ),
          textCapitalization: TextCapitalization.words,
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final nickname = nicknameController.text.trim();
              await context.read<ContactProvider>().updateContact(
                    _contact.address,
                    nickname: nickname.isEmpty ? null : nickname,
                  );

              if (mounted) {
                final updated = context.read<ContactProvider>().getContact(_contact.address);
                if (updated != null) {
                  setState(() => _contact = updated);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Verify identity
  Future<void> _verifyIdentity() async {
    setState(() => _isVerifying = true);

    try {
      final success = await context.read<ContactProvider>().verifyContact(
            _contact.address,
          );

      if (!mounted) return;

      if (success) {
        final updated = context.read<ContactProvider>().getContact(_contact.address);
        if (updated != null) {
          setState(() => _contact = updated);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identity verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  /// Handle menu actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'block':
        _blockContact();
        break;
      case 'delete':
        _deleteContact();
        break;
    }
  }

  /// Block contact
  void _blockContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Contact'),
        content: const Text('Are you sure you want to block this contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<ContactProvider>().updateContact(
                    _contact.address,
                    isBlocked: !_contact.isBlocked,
                  );

              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  /// Delete contact
  void _deleteContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Contact'),
        content: const Text('Are you sure you want to remove this contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<ContactProvider>().removeContact(_contact.address);

              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
