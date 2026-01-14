import 'package:flutter/foundation.dart';
import 'package:idena_p2p/models/contact.dart';
import 'package:idena_p2p/services/contact_service.dart';

/// Provider for managing contacts state
class ContactProvider extends ChangeNotifier {
  final ContactService _contactService = ContactService();

  List<Contact> _contacts = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  String _searchQuery = '';

  /// Get all contacts
  List<Contact> get contacts => _searchQuery.isEmpty
      ? _contacts
      : _contacts
          .where((contact) =>
              (contact.nickname?.toLowerCase().contains(_searchQuery) ??
                  false) ||
              contact.address.toLowerCase().contains(_searchQuery))
          .toList();

  /// Get verified human contacts only
  List<Contact> get verifiedHumanContacts =>
      _contacts.where((c) => c.isVerifiedHuman).toList();

  /// Check if contacts are being loaded
  bool get isLoading => _isLoading;

  /// Check if provider is initialized
  bool get isInitialized => _isInitialized;

  /// Get last error message
  String? get error => _error;

  /// Get contact count
  int get contactCount => _contacts.length;

  /// Get current search query
  String get searchQuery => _searchQuery;

  /// Initialize the contact service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);
      _clearError();

      await _contactService.init();
      await loadContacts();

      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize contacts: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load all contacts from database
  Future<void> loadContacts() async {
    try {
      _setLoading(true);
      _clearError();

      _contacts = await _contactService.getAllContacts();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load contacts: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new contact
  Future<bool> addContact(String address, {String? nickname}) async {
    try {
      _setLoading(true);
      _clearError();

      // Validate address format
      if (!_isValidIdenaAddress(address)) {
        _setError('Invalid Idena address format');
        return false;
      }

      // Check if contact already exists
      if (await _contactService.contactExists(address)) {
        _setError('Contact already exists');
        return false;
      }

      // Add contact
      final contact = await _contactService.addContact(
        address,
        nickname: nickname,
      );

      // Add to local list and sort
      _contacts.add(contact);
      _sortContacts();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add contact: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update contact details
  Future<bool> updateContact(
    String address, {
    String? nickname,
    String? notes,
    bool? isBlocked,
  }) async {
    try {
      _clearError();

      await _contactService.updateContact(
        address,
        nickname: nickname,
        notes: notes,
        isBlocked: isBlocked,
      );

      // Update in local list
      final index = _contacts.indexWhere((c) => c.address == address);
      if (index != -1) {
        _contacts[index] = _contacts[index].copyWith(
          nickname: nickname,
          notes: notes,
          isBlocked: isBlocked,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update contact: $e');
      return false;
    }
  }

  /// Remove a contact
  Future<bool> removeContact(String address) async {
    try {
      _clearError();

      await _contactService.removeContact(address);

      // Remove from local list
      _contacts.removeWhere((c) => c.address == address);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to remove contact: $e');
      return false;
    }
  }

  /// Verify/refresh a contact's identity state
  Future<bool> verifyContact(String address) async {
    try {
      _clearError();

      final updated = await _contactService.verifyContact(address);

      // Update in local list
      final index = _contacts.indexWhere((c) => c.address == address);
      if (index != -1) {
        _contacts[index] = updated;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to verify contact: $e');
      return false;
    }
  }

  /// Refresh all contacts' identity state
  Future<void> refreshAllContacts() async {
    try {
      _setLoading(true);
      _clearError();

      _contacts = await _contactService.refreshAllContacts();
      _sortContacts();
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh contacts: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get contact by address
  Contact? getContact(String address) {
    try {
      return _contacts.firstWhere(
        (c) => c.address.toLowerCase() == address.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if address is a contact
  bool isContact(String address) {
    return _contacts.any(
      (c) => c.address.toLowerCase() == address.toLowerCase(),
    );
  }

  /// Check if contact is a verified human
  bool isVerifiedHuman(String address) {
    final contact = getContact(address);
    return contact?.isVerifiedHuman ?? false;
  }

  /// Get contacts that need verification
  List<Contact> getContactsNeedingVerification() {
    return _contacts.where((c) => c.needsVerification).toList();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  /// Clear search query
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Sort contacts by most recently added
  void _sortContacts() {
    _contacts.sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  /// Validate Idena address format (0x + 40 hex chars)
  bool _isValidIdenaAddress(String address) {
    final regex = RegExp(r'^0x[a-fA-F0-9]{40}$');
    return regex.hasMatch(address);
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _error = null;
  }

  /// Clear all contacts (for testing/reset)
  Future<void> clearAllContacts() async {
    try {
      _clearError();
      await _contactService.clearAllContacts();
      _contacts.clear();
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear contacts: $e');
    }
  }

  @override
  void dispose() {
    _contactService.close();
    super.dispose();
  }
}
