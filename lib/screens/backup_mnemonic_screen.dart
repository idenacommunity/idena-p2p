import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'verify_mnemonic_screen.dart';
import '../services/screen_security_service.dart';

/// Screen for backing up the mnemonic phrase
/// SECURITY: Forces user to view and acknowledge mnemonic before proceeding
/// SECURITY: Screenshot protection enabled to prevent mnemonic capture
class BackupMnemonicScreen extends StatefulWidget {
  final String mnemonic;

  const BackupMnemonicScreen({
    super.key,
    required this.mnemonic,
  });

  @override
  State<BackupMnemonicScreen> createState() => _BackupMnemonicScreenState();
}

class _BackupMnemonicScreenState extends State<BackupMnemonicScreen> {
  bool _isMnemonicVisible = false;
  bool _hasAcknowledged = false;
  final _screenSecurity = ScreenSecurityService();

  @override
  void initState() {
    super.initState();
    // SECURITY: Enable screenshot protection on this sensitive screen
    _screenSecurity.enableScreenSecurity();
  }

  @override
  void dispose() {
    // SECURITY: Disable screenshot protection when leaving screen
    _screenSecurity.disableScreenSecurity();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.mnemonic.split(' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Recovery Phrase'),
        automaticallyImplyLeading: false, // Prevent going back
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Critical warning card
            Card(
              color: Colors.red.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: Colors.red.shade700,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'CRITICAL: Write Down Your Recovery Phrase',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If you lose this phrase, you will permanently lose access to your funds. '
                      'No one can recover it for you - not even us.',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            Text(
              'Important Steps:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            _buildInstructionItem(
              '1',
              'Write down your 12-word recovery phrase on paper',
              Icons.edit_note,
            ),
            const SizedBox(height: 8),
            _buildInstructionItem(
              '2',
              'Store it in a secure location (safe, vault, etc.)',
              Icons.lock_outline,
            ),
            const SizedBox(height: 8),
            _buildInstructionItem(
              '3',
              'Never share it with anyone or store it digitally',
              Icons.block,
            ),

            const SizedBox(height: 32),

            // Reveal/Hide button
            if (!_isMnemonicVisible)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isMnemonicVisible = true;
                  });
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Tap to Reveal Recovery Phrase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            else
              ...[
                // Mnemonic grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: words.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${index + 1}.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                words[index],
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Copy button
                OutlinedButton.icon(
                  onPressed: _copyMnemonic,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy to Clipboard (Use Carefully)'),
                ),

                const SizedBox(height: 24),

                // Acknowledgment checkbox
                CheckboxListTile(
                  value: _hasAcknowledged,
                  onChanged: (value) {
                    setState(() {
                      _hasAcknowledged = value ?? false;
                    });
                  },
                  title: const Text(
                    'I have written down my recovery phrase and stored it securely',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'You will need to verify it in the next step',
                    style: TextStyle(fontSize: 12),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),

                const SizedBox(height: 24),

                // Continue button
                ElevatedButton(
                  onPressed: _hasAcknowledged ? _proceedToVerification : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Continue to Verification'),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.blue.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _copyMnemonic() async {
    // SECURITY FIX: Copy mnemonic to clipboard
    await Clipboard.setData(ClipboardData(text: widget.mnemonic));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Recovery phrase copied. Will auto-clear in 60 seconds for security.',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );

    // SECURITY FIX: Auto-clear clipboard after 60 seconds
    // This prevents the mnemonic from lingering in clipboard indefinitely
    Timer(const Duration(seconds: 60), () async {
      try {
        // Only clear if clipboard still contains the mnemonic
        final currentClipboard = await Clipboard.getData(Clipboard.kTextPlain);
        if (currentClipboard?.text == widget.mnemonic) {
          await Clipboard.setData(const ClipboardData(text: ''));
          debugPrint('✓ Clipboard auto-cleared for security');
        }
      } catch (e) {
        debugPrint('Failed to auto-clear clipboard: $e');
      }
    });
  }

  void _proceedToVerification() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VerifyMnemonicScreen(
          mnemonic: widget.mnemonic,
        ),
      ),
    );
  }
}
