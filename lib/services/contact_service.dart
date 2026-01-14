import 'package:hive_flutter/hive_flutter.dart';
import 'package:idena_p2p/models/contact.dart';
import 'package:idena_p2p/models/idena_account.dart';
import 'package:idena_p2p/services/idena_service.dart';

/// Service for managing contacts and their identity verification
class ContactService {
  static const String _contactsBoxName = 'contacts';
  late Box<Map> _contactsBox;
  final IdenaService _idenaService = IdenaService();

  /// Initialize Hive and open contacts box
  Future<void> init() async {
    await Hive.initFlutter();
    _contactsBox = await Hive.openBox<Map>(_contactsBoxName);
  }

  /// Get all contacts
  Future<List<Contact>> getAllContacts() async {
    final contacts = <Contact>[];
    for (var key in _contactsBox.keys) {
      try {
        final json = Map<String, dynamic>.from(_contactsBox.get(key) as Map);
        contacts.add(Contact.fromJson(json));
      } catch (e) {
        // Skip invalid entries
        print('Error loading contact $key: $e');
      }
    }

    // Sort by most recently added
    contacts.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return contacts;
  }

  /// Get contact by address
  Future<Contact?> getContact(String address) async {
    final json = _contactsBox.get(address.toLowerCase());
    if (json == null) return null;

    try {
      return Contact.fromJson(Map<String, dynamic>.from(json as Map));
    } catch (e) {
      print('Error loading contact $address: $e');
      return null;
    }
  }

  /// Add a new contact
  Future<Contact> addContact(String address, {String? nickname}) async {
    // Check if contact already exists
    final existing = await getContact(address);
    if (existing != null) {
      throw Exception('Contact already exists');
    }

    // Fetch account information from Idena blockchain
    final account = await _fetchAccountInfo(address);

    // Create contact from account
    final contact = Contact.fromAccount(account, nickname: nickname);

    // Save to database
    await _contactsBox.put(
      address.toLowerCase(),
      contact.toJson(),
    );

    return contact;
  }

  /// Update contact nickname or notes
  Future<void> updateContact(
    String address, {
    String? nickname,
    String? notes,
    bool? isBlocked,
  }) async {
    final contact = await getContact(address);
    if (contact == null) {
      throw Exception('Contact not found');
    }

    final updated = contact.copyWith(
      nickname: nickname,
      notes: notes,
      isBlocked: isBlocked,
    );

    await _contactsBox.put(
      address.toLowerCase(),
      updated.toJson(),
    );
  }

  /// Remove a contact
  Future<void> removeContact(String address) async {
    await _contactsBox.delete(address.toLowerCase());
  }

  /// Verify and update contact's identity state
  Future<Contact> verifyContact(String address) async {
    final contact = await getContact(address);
    if (contact == null) {
      throw Exception('Contact not found');
    }

    // Fetch fresh account information
    final account = await _fetchAccountInfo(address);

    // Update contact with fresh data
    final updated = contact.copyWith(
      state: account.identityStatus,
      age: account.age ?? 0,
      stake: account.stake,
      isVerifiedHuman: _isVerifiedHuman(account.identityStatus),
      lastVerified: DateTime.now(),
    );

    // Save updated contact
    await _contactsBox.put(
      address.toLowerCase(),
      updated.toJson(),
    );

    return updated;
  }

  /// Refresh all contacts' identity state
  Future<List<Contact>> refreshAllContacts() async {
    final contacts = await getAllContacts();
    final refreshed = <Contact>[];

    for (var contact in contacts) {
      try {
        final updated = await verifyContact(contact.address);
        refreshed.add(updated);
      } catch (e) {
        print('Error refreshing contact ${contact.address}: $e');
        // Keep original contact if refresh fails
        refreshed.add(contact);
      }
    }

    return refreshed;
  }

  /// Check if address is a verified human
  Future<bool> isVerifiedHuman(String address) async {
    try {
      final account = await _fetchAccountInfo(address);
      return _isVerifiedHuman(account.identityStatus);
    } catch (e) {
      return false;
    }
  }

  /// Get contacts that need verification (>24 hours old)
  Future<List<Contact>> getContactsNeedingVerification() async {
    final contacts = await getAllContacts();
    return contacts.where((c) => c.needsVerification).toList();
  }

  /// Get verified human contacts only
  Future<List<Contact>> getVerifiedHumanContacts() async {
    final contacts = await getAllContacts();
    return contacts.where((c) => c.isVerifiedHuman).toList();
  }

  /// Search contacts by nickname or address
  Future<List<Contact>> searchContacts(String query) async {
    if (query.isEmpty) return getAllContacts();

    final contacts = await getAllContacts();
    final lowerQuery = query.toLowerCase();

    return contacts.where((contact) {
      final matchesNickname =
          contact.nickname?.toLowerCase().contains(lowerQuery) ?? false;
      final matchesAddress = contact.address.toLowerCase().contains(lowerQuery);
      return matchesNickname || matchesAddress;
    }).toList();
  }

  /// Check if contact exists
  Future<bool> contactExists(String address) async {
    return _contactsBox.containsKey(address.toLowerCase());
  }

  /// Get contact count
  Future<int> getContactCount() async {
    return _contactsBox.length;
  }

  /// Clear all contacts (for testing or reset)
  Future<void> clearAllContacts() async {
    await _contactsBox.clear();
  }

  /// Fetch account information from Idena blockchain
  Future<IdenaAccount> _fetchAccountInfo(String address) async {
    try {
      // Get balance and identity state in parallel
      final results = await Future.wait([
        _idenaService.getBalance(address),
        _idenaService.getIdentity(address),
      ]);

      final balanceResult = results[0] as Map<String, dynamic>;
      final identityResult = results[1] as Map<String, dynamic>;

      return IdenaAccount(
        address: address,
        balance: (balanceResult['balance'] as num?)?.toDouble() ?? 0.0,
        stake: (balanceResult['stake'] as num?)?.toDouble() ?? 0.0,
        identityStatus: identityResult['state'] as String? ?? 'Undefined',
        age: identityResult['age'] as int?,
      );
    } catch (e) {
      throw Exception('Failed to fetch account information: $e');
    }
  }

  /// Check if identity state is verified human
  bool _isVerifiedHuman(String state) {
    return state == 'Human' || state == 'Verified';
  }

  /// Close the database
  Future<void> close() async {
    await _contactsBox.close();
  }
}
