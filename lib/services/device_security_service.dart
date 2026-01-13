import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

/// Service for detecting device security compromises
/// Checks for jailbreak (iOS) and root access (Android)
class DeviceSecurityService {
  /// Checks if the device is jailbroken (iOS) or rooted (Android)
  Future<bool> isJailbroken() async {
    try {
      return await FlutterJailbreakDetection.jailbroken;
    } catch (e) {
      // If detection fails, assume device is secure
      return false;
    }
  }

  /// Checks if developer mode is enabled (Android)
  Future<bool> isDeveloperModeEnabled() async {
    try {
      return await FlutterJailbreakDetection.developerMode;
    } catch (e) {
      // If detection fails, assume developer mode is off
      return false;
    }
  }

  /// Checks if the device is compromised (jailbroken, rooted, or developer mode)
  Future<bool> isDeviceCompromised() async {
    final jailbroken = await isJailbroken();
    final developerMode = await isDeveloperModeEnabled();
    return jailbroken || developerMode;
  }

  /// Gets detailed security status of the device
  Future<DeviceSecurityStatus> getSecurityStatus() async {
    final jailbroken = await isJailbroken();
    final developerMode = await isDeveloperModeEnabled();

    return DeviceSecurityStatus(
      isJailbroken: jailbroken,
      isDeveloperMode: developerMode,
    );
  }
}

/// Represents the security status of the device
class DeviceSecurityStatus {
  final bool isJailbroken;
  final bool isDeveloperMode;

  DeviceSecurityStatus({
    required this.isJailbroken,
    required this.isDeveloperMode,
  });

  /// Returns true if any security issue is detected
  bool get isCompromised => isJailbroken || isDeveloperMode;

  /// Returns a human-readable description of security issues
  String get description {
    if (!isCompromised) {
      return 'Device is secure';
    }

    final issues = <String>[];
    if (isJailbroken) {
      issues.add('Device is jailbroken/rooted');
    }
    if (isDeveloperMode) {
      issues.add('Developer mode is enabled');
    }

    return issues.join(', ');
  }

  /// Returns security risk level
  SecurityRiskLevel get riskLevel {
    if (isJailbroken) {
      return SecurityRiskLevel.high;
    } else if (isDeveloperMode) {
      return SecurityRiskLevel.medium;
    }
    return SecurityRiskLevel.low;
  }
}

/// Represents the security risk level of the device
enum SecurityRiskLevel {
  low,
  medium,
  high,
}
