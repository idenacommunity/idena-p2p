import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:idena_p2p/models/message.dart';
import 'package:idena_p2p/models/contact.dart';
import 'package:idena_p2p/providers/messaging_provider.dart';
import 'package:idena_p2p/providers/contact_provider.dart';
import 'package:idena_p2p/screens/messaging/chat_screen.dart';
import 'package:idena_p2p/screens/contacts/contacts_list_screen.dart';
import 'package:intl/intl.dart';

/// Screen displaying list of all conversations
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final messagingProvider = context.read<MessagingProvider>();
    await messagingProvider.loadConversations();
  }

  Future<void> _refresh() async {
    final messagingProvider = context.read<MessagingProvider>();
    await messagingProvider.refresh();
  }

  void _startNewConversation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ContactsListScreen(selectMode: true),
      ),
    ).then((selectedContact) {
      if (selectedContact != null && selectedContact is Contact) {
        _openChat(selectedContact);
      }
    });
  }

  void _openChat(Contact contact) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(contact: contact),
      ),
    );
  }

  List<Conversation> _filterConversations(List<Conversation> conversations) {
    if (_searchQuery.isEmpty) return conversations;

    final contactProvider = context.read<ContactProvider>();
    return conversations.where((conversation) {
      final contact = contactProvider.getContactByAddress(conversation.contactAddress);
      if (contact == null) return false;

      final searchLower = _searchQuery.toLowerCase();
      final matchesName = contact.displayName.toLowerCase().contains(searchLower);
      final matchesAddress = contact.address.toLowerCase().contains(searchLower);
      final matchesMessage = conversation.lastMessage?.content.toLowerCase().contains(searchLower) ?? false;

      return matchesName || matchesAddress || matchesMessage;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ConversationSearchDelegate(),
              );
            },
            tooltip: 'Search messages',
          ),
        ],
      ),
      body: Consumer2<MessagingProvider, ContactProvider>(
        builder: (context, messagingProvider, contactProvider, child) {
          if (messagingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (messagingProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    messagingProvider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadConversations,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final conversations = _filterConversations(messagingProvider.conversations);

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No conversations yet'
                        : 'No matching conversations',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  if (_searchQuery.isEmpty)
                    const Text(
                      'Start a conversation with a contact',
                      style: TextStyle(color: Colors.grey),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _startNewConversation,
                    icon: const Icon(Icons.add),
                    label: const Text('New Conversation'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search conversations...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                // Conversation list
                Expanded(
                  child: ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final contact = contactProvider.getContactByAddress(
                        conversation.contactAddress,
                      );

                      if (contact == null) {
                        return const SizedBox.shrink();
                      }

                      return ConversationTile(
                        conversation: conversation,
                        contact: contact,
                        onTap: () => _openChat(contact),
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Conversation'),
                              content: Text(
                                'Delete conversation with ${contact.displayName}?\nAll messages will be deleted.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await messagingProvider.deleteConversation(
                              conversation.contactAddress,
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewConversation,
        tooltip: 'New Conversation',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

/// Widget for displaying a single conversation in the list
class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final Contact contact;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.contact,
    required this.onTap,
    required this.onDelete,
  });

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return DateFormat.jm().format(timestamp); // 5:30 PM
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat.E().format(timestamp); // Mon, Tue, etc.
    } else {
      return DateFormat.MMMd().format(timestamp); // Jan 15
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastMessage = conversation.lastMessage;
    final hasUnread = conversation.unreadCount > 0;

    return Dismissible(
      key: Key(conversation.contactAddress),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Conversation'),
            content: Text(
              'Delete conversation with ${contact.displayName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete(),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                contact.displayName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Text(
                contact.identityBadge,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                contact.displayName,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (lastMessage != null)
              Text(
                _formatTimestamp(lastMessage.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: hasUnread ? Colors.blue : Colors.grey,
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            if (lastMessage != null && lastMessage.direction == MessageDirection.outgoing)
              const Icon(Icons.check, size: 16, color: Colors.grey),
            Expanded(
              child: Text(
                lastMessage?.content ?? 'No messages yet',
                style: TextStyle(
                  color: hasUnread ? Colors.black : Colors.grey,
                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasUnread)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  conversation.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Search delegate for searching conversations
class ConversationSearchDelegate extends SearchDelegate<Conversation?> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final messagingProvider = context.watch<MessagingProvider>();
    final contactProvider = context.watch<ContactProvider>();

    if (query.isEmpty) {
      return const Center(
        child: Text('Enter a search query'),
      );
    }

    final searchResults = messagingProvider.conversations.where((conversation) {
      final contact = contactProvider.getContactByAddress(conversation.contactAddress);
      if (contact == null) return false;

      final searchLower = query.toLowerCase();
      return contact.displayName.toLowerCase().contains(searchLower) ||
          contact.address.toLowerCase().contains(searchLower) ||
          (conversation.lastMessage?.content.toLowerCase().contains(searchLower) ?? false);
    }).toList();

    if (searchResults.isEmpty) {
      return const Center(
        child: Text('No matching conversations'),
      );
    }

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final conversation = searchResults[index];
        final contact = contactProvider.getContactByAddress(
          conversation.contactAddress,
        );

        if (contact == null) return const SizedBox.shrink();

        return ConversationTile(
          conversation: conversation,
          contact: contact,
          onTap: () {
            close(context, conversation);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(contact: contact),
              ),
            );
          },
          onDelete: () async {
            await messagingProvider.deleteConversation(conversation.contactAddress);
          },
        );
      },
    );
  }
}
