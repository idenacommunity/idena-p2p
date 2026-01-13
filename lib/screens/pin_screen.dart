import 'package:flutter/material.dart';
import '../services/screen_security_service.dart';

/// PIN screen mode: setup new PIN or enter existing PIN
enum PinScreenMode {
  /// Setup mode: user creates new PIN (requires confirmation)
  setup,

  /// Enter mode: user enters existing PIN for validation
  enter,
}

/// Reusable PIN entry screen with numeric keypad
/// Supports two modes: setup (with confirmation) and enter (validation)
/// SECURITY: Screenshot protection enabled to prevent PIN capture
class PinScreen extends StatefulWidget {
  final PinScreenMode mode;
  final String? expectedPin; // For enter mode validation
  final int pinLength;

  const PinScreen({
    super.key,
    required this.mode,
    this.expectedPin,
    this.pinLength = 6,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _confirmedPin = '';
  bool _awaitingConfirmation = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  final _screenSecurity = ScreenSecurityService();

  @override
  void initState() {
    super.initState();
    // SECURITY: Enable screenshot protection on this sensitive screen
    _screenSecurity.enableScreenSecurity();
    _setupShakeAnimation();
  }

  @override
  void dispose() {
    // SECURITY: Disable screenshot protection when leaving screen
    _screenSecurity.disableScreenSecurity();
    _shakeController.dispose();
    super.dispose();
  }

  void _setupShakeAnimation() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );

    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reverse();
      }
    });
  }

  void _onNumberPressed(int number) {
    if (_pin.length < widget.pinLength) {
      setState(() {
        _pin += number.toString();
      });

      // Check if PIN is complete
      if (_pin.length == widget.pinLength) {
        _handlePinComplete();
      }
    }
  }

  void _onBackspacePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _handlePinComplete() {
    if (widget.mode == PinScreenMode.setup) {
      _handleSetupMode();
    } else {
      _handleEnterMode();
    }
  }

  void _handleSetupMode() {
    if (!_awaitingConfirmation) {
      // First PIN entry - ask for confirmation
      setState(() {
        _confirmedPin = _pin;
        _pin = '';
        _awaitingConfirmation = true;
      });
    } else {
      // Confirmation entry - check if they match
      if (_pin == _confirmedPin) {
        // PINs match - return the PIN
        Navigator.of(context).pop(_pin);
      } else {
        // PINs don't match - shake and reset
        _triggerShake();
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            _pin = '';
            _confirmedPin = '';
            _awaitingConfirmation = false;
          });
        });
      }
    }
  }

  void _handleEnterMode() {
    if (widget.expectedPin != null && _pin == widget.expectedPin) {
      // Correct PIN
      Navigator.of(context).pop(true);
    } else {
      // Incorrect PIN - shake and reset
      _triggerShake();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _pin = '';
        });
        // Return false to indicate failure
        Navigator.of(context).pop(false);
      });
    }
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
  }

  String _getHeaderText() {
    if (widget.mode == PinScreenMode.setup) {
      return _awaitingConfirmation ? 'Confirm PIN' : 'Create PIN';
    } else {
      return 'Enter PIN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_getHeaderText()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // PIN dots display
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                );
              },
              child: _buildPinDots(),
            ),
            const SizedBox(height: 60),
            // Numeric keypad
            _buildNumericKeypad(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.pinLength,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index < _pin.length ? Colors.blue : Colors.grey[300],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        children: [
          _buildKeypadRow([1, 2, 3]),
          const SizedBox(height: 16),
          _buildKeypadRow([4, 5, 6]),
          const SizedBox(height: 16),
          _buildKeypadRow([7, 8, 9]),
          const SizedBox(height: 16),
          _buildKeypadRow([null, 0, -1]), // null = empty, -1 = backspace
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<int?> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        if (number == null) {
          return const SizedBox(width: 70, height: 70); // Empty space
        } else if (number == -1) {
          return _buildKeypadButton(
            icon: Icons.backspace_outlined,
            onPressed: _onBackspacePressed,
          );
        } else {
          return _buildKeypadButton(
            text: number.toString(),
            onPressed: () => _onNumberPressed(number),
          );
        }
      }).toList(),
    );
  }

  Widget _buildKeypadButton({
    String? text,
    IconData? icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: text != null
              ? Text(
                  text,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : Icon(icon, size: 24, color: Colors.grey[700]),
        ),
      ),
    );
  }
}
