import 'dart:math';
import 'package:flutter/material.dart';

/// Screen for verifying the user has correctly backed up their mnemonic
/// Tests 3 random words to ensure the user actually wrote it down
class VerifyMnemonicScreen extends StatefulWidget {
  final String mnemonic;

  const VerifyMnemonicScreen({
    super.key,
    required this.mnemonic,
  });

  @override
  State<VerifyMnemonicScreen> createState() => _VerifyMnemonicScreenState();
}

class _VerifyMnemonicScreenState extends State<VerifyMnemonicScreen> {
  late List<String> _words;
  late List<int> _testIndices;
  final List<TextEditingController> _controllers = [];
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _words = widget.mnemonic.split(' ');
    _selectRandomWords();

    // Create controllers for each test word
    for (int i = 0; i < 3; i++) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Selects 3 random word indices to test
  void _selectRandomWords() {
    final random = Random();
    final indices = <int>[];

    while (indices.length < 3) {
      final index = random.nextInt(_words.length);
      if (!indices.contains(index)) {
        indices.add(index);
      }
    }

    indices.sort();
    _testIndices = indices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Recovery Phrase'),
        automaticallyImplyLeading: false, // Prevent going back
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Icon(
              Icons.verified_user,
              size: 64,
              color: Colors.blue.shade400,
            ),
            const SizedBox(height: 16),

            Text(
              'Verify Your Backup',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'Please enter the following words from your recovery phrase to confirm you have backed it up correctly.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Test word inputs
            ..._buildTestInputs(),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Verify button
            ElevatedButton(
              onPressed: _isVerifying ? null : _verifyWords,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Verify and Continue'),
            ),

            const SizedBox(height: 16),

            // Try again button
            TextButton(
              onPressed: _retryVerification,
              child: const Text('I need to review my recovery phrase again'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTestInputs() {
    final inputs = <Widget>[];

    for (int i = 0; i < _testIndices.length; i++) {
      final wordIndex = _testIndices[i];
      inputs.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Word #${wordIndex + 1}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controllers[i],
              decoration: InputDecoration(
                hintText: 'Enter word ${wordIndex + 1}',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) {
                // Clear error when user starts typing
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    return inputs;
  }

  void _verifyWords() {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    // Check each word
    bool allCorrect = true;
    for (int i = 0; i < _testIndices.length; i++) {
      final wordIndex = _testIndices[i];
      final expectedWord = _words[wordIndex];
      final enteredWord = _controllers[i].text.trim().toLowerCase();

      if (expectedWord.toLowerCase() != enteredWord) {
        allCorrect = false;
        break;
      }
    }

    setState(() {
      _isVerifying = false;
    });

    if (allCorrect) {
      _onVerificationSuccess();
    } else {
      setState(() {
        _errorMessage =
            'One or more words are incorrect. Please check your recovery phrase and try again.';
      });
    }
  }

  void _onVerificationSuccess() {
    // Return true to indicate successful verification
    Navigator.of(context).pop(true);
  }

  void _retryVerification() {
    // Go back to backup screen
    Navigator.of(context).pop(false);
  }
}
