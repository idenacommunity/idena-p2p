import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:idena_p2p/providers/contact_provider.dart';

/// Screen for adding a new contact
class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Contact'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildAddressField(),
              const SizedBox(height: 16),
              _buildNicknameField(),
              const SizedBox(height: 32),
              _buildAddButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build info card explaining what this screen does
  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add a contact by entering their Idena address. '
                'Their identity will be verified from the blockchain.',
                style: TextStyle(color: Colors.blue[900]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Idena address input field
  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      decoration: InputDecoration(
        labelText: 'Idena Address *',
        hintText: '0x...',
        helperText: 'Enter the full Idena address (0x + 40 characters)',
        prefixIcon: const Icon(Icons.account_balance_wallet),
        suffixIcon: IconButton(
          icon: const Icon(Icons.paste),
          onPressed: _pasteAddress,
          tooltip: 'Paste from clipboard',
        ),
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
      maxLines: 2,
      validator: _validateAddress,
      enabled: !_isLoading,
    );
  }

  /// Build nickname input field
  Widget _buildNicknameField() {
    return TextFormField(
      controller: _nicknameController,
      decoration: const InputDecoration(
        labelText: 'Nickname (Optional)',
        hintText: 'Enter a friendly name',
        helperText: 'Give your contact a memorable nickname',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.words,
      maxLength: 50,
      enabled: !_isLoading,
      onFieldSubmitted: (_) => _addContact(),
    );
  }

  /// Build add contact button
  Widget _buildAddButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _addContact,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text(
              'Add Contact',
              style: TextStyle(fontSize: 16),
            ),
    );
  }

  /// Validate Idena address format
  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an Idena address';
    }

    final trimmed = value.trim();

    if (!trimmed.startsWith('0x')) {
      return 'Address must start with 0x';
    }

    if (trimmed.length != 42) {
      return 'Address must be 42 characters (0x + 40 hex chars)';
    }

    final hexPart = trimmed.substring(2);
    if (!RegExp(r'^[a-fA-F0-9]+$').hasMatch(hexPart)) {
      return 'Address contains invalid characters';
    }

    return null;
  }

  /// Paste address from clipboard
  Future<void> _pasteAddress() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData != null && clipboardData.text != null) {
        _addressController.text = clipboardData.text!.trim();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to paste: $e')),
        );
      }
    }
  }

  /// Add contact
  Future<void> _addContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final contactProvider = context.read<ContactProvider>();

      final address = _addressController.text.trim();
      final nickname = _nicknameController.text.trim();

      // Add contact
      final success = await contactProvider.addContact(
        address,
        nickname: nickname.isEmpty ? null : nickname,
      );

      if (!mounted) return;

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contact added successfully${nickname.isNotEmpty ? " as $nickname" : ""}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to contacts list
        Navigator.pop(context);
      } else {
        // Show error from provider
        final error = contactProvider.error ?? 'Failed to add contact';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(error)),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
