import 'package:flutter/services.dart';

/// Service for managing screen security features
/// - Android: FLAG_SECURE prevents screenshots and screen recording
/// - iOS: Blurs app content in app switcher
class ScreenSecurityService {
  static const _channel = MethodChannel('com.idena.idena_p2p/screen_security');

  /// Enables screen security features
  /// - Android: Sets FLAG_SECURE on the window
  /// - iOS: Adds blur effect to app switcher
  Future<bool> enableScreenSecurity() async {
    try {
      await _channel.invokeMethod('enableScreenSecurity');
      return true;
    } on PlatformException {
      // Platform channel not implemented yet (native code needed)
      // This is expected during development
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Disables screen security features
  /// Should be called when leaving sensitive screens
  Future<bool> disableScreenSecurity() async {
    try {
      await _channel.invokeMethod('disableScreenSecurity');
      return true;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks if screen security is supported on this platform
  Future<bool> isSupported() async {
    try {
      final result = await _channel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
