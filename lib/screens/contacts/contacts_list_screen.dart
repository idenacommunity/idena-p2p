import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:idena_p2p/models/contact.dart';
import 'package:idena_p2p/providers/contact_provider.dart';
import 'package:idena_p2p/screens/contacts/add_contact_screen.dart';
import 'package:idena_p2p/screens/contacts/contact_detail_screen.dart';

/// Screen displaying list of all contacts
class ContactsListScreen extends StatefulWidget {
  final bool selectMode;

  const ContactsListScreen({super.key, this.selectMode = false});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectMode ? 'Select Contact' : 'Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshContacts(context),
            tooltip: 'Refresh all contacts',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          Expanded(child: _buildContactsList(context)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddContact(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  /// Search bar widget
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search contacts...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ContactProvider>().clearSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (query) {
          context.read<ContactProvider>().setSearchQuery(query);
        },
      ),
    );
  }

  /// Build contacts list
  Widget _buildContactsList(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.contacts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  style: TextStyle(color: Colors.red[300]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadContacts(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.contacts.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () => _refreshContacts(context),
          child: ListView.builder(
            itemCount: provider.contacts.length,
            itemBuilder: (context, index) {
              final contact = provider.contacts[index];
              return _buildContactTile(context, contact);
            },
          ),
        );
      },
    );
  }

  /// Build empty state when no contacts
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No contacts yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first contact to get started',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddContact(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }

  /// Build contact list tile
  Widget _buildContactTile(BuildContext context, Contact contact) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAvatarColor(contact),
          child: Text(
            _getInitials(contact),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                contact.displayName,
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              contact.identityBadge,
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              contact.address,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              contact.trustLevel,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
              ),
            ),
            if (contact.needsVerification)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '⚠️ Needs verification',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        trailing: contact.isBlocked
            ? const Icon(Icons.block, color: Colors.red)
            : const Icon(Icons.chevron_right),
        onTap: () => _navigateToContactDetail(context, contact),
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

  /// Get avatar background color based on identity state
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

  /// Navigate to add contact screen
  void _navigateToAddContact(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddContactScreen()),
    );
  }

  /// Navigate to contact detail screen or return contact in select mode
  void _navigateToContactDetail(BuildContext context, Contact contact) {
    if (widget.selectMode) {
      // In select mode, return the selected contact
      Navigator.of(context).pop(contact);
    } else {
      // Normal mode, navigate to detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContactDetailScreen(contact: contact),
        ),
      );
    }
  }

  /// Refresh all contacts
  Future<void> _refreshContacts(BuildContext context) async {
    await context.read<ContactProvider>().refreshAllContacts();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts refreshed')),
      );
    }
  }
}
