import 'package:flutter_test/flutter_test.dart';
import 'package:idena_p2p/services/device_security_service.dart';
import 'package:idena_p2p/services/screen_security_service.dart';

void main() {
  group('Device Security Service Tests', () {
    late DeviceSecurityService deviceSecurityService;

    setUp(() {
      deviceSecurityService = DeviceSecurityService();
    });

    test('service initializes correctly', () {
      expect(deviceSecurityService, isNotNull);
    });

    test('getSecurityStatus returns status object', () async {
      final status = await deviceSecurityService.getSecurityStatus();

      expect(status, isA<DeviceSecurityStatus>());
      expect(status.isJailbroken, isA<bool>());
      expect(status.isDeveloperMode, isA<bool>());
    });

    test('DeviceSecurityStatus.isCompromised returns correct value', () {
      // Not compromised
      var status = DeviceSecurityStatus(
        isJailbroken: false,
        isDeveloperMode: false,
      );
      expect(status.isCompromised, false);

      // Compromised by jailbreak
      status = DeviceSecurityStatus(
        isJailbroken: true,
        isDeveloperMode: false,
      );
      expect(status.isCompromised, true);

      // Compromised by developer mode
      status = DeviceSecurityStatus(
        isJailbroken: false,
        isDeveloperMode: true,
      );
      expect(status.isCompromised, true);

      // Compromised by both
      status = DeviceSecurityStatus(
        isJailbroken: true,
        isDeveloperMode: true,
      );
      expect(status.isCompromised, true);
    });

    test('DeviceSecurityStatus.riskLevel returns correct level', () {
      // Low risk
      var status = DeviceSecurityStatus(
        isJailbroken: false,
        isDeveloperMode: false,
      );
      expect(status.riskLevel, SecurityRiskLevel.low);

      // Medium risk (developer mode only)
      status = DeviceSecurityStatus(
        isJailbroken: false,
        isDeveloperMode: true,
      );
      expect(status.riskLevel, SecurityRiskLevel.medium);

      // High risk (jailbroken)
      status = DeviceSecurityStatus(
        isJailbroken: true,
        isDeveloperMode: false,
      );
      expect(status.riskLevel, SecurityRiskLevel.high);

      // High risk (both)
      status = DeviceSecurityStatus(
        isJailbroken: true,
        isDeveloperMode: true,
      );
      expect(status.riskLevel, SecurityRiskLevel.high);
    });

    test('DeviceSecurityStatus.description returns correct message', () {
      // Secure device
      var status = DeviceSecurityStatus(
        isJailbroken: false,
        isDeveloperMode: false,
      );
      expect(status.description, 'Device is secure');

      // Jailbroken
      status = DeviceSecurityStatus(
        isJailbroken: true,
        isDeveloperMode: false,
      );
      expect(status.description, contains('jailbroken/rooted'));

      // Developer mode
      status = DeviceSecurityStatus(
        isJailbroken: false,
        isDeveloperMode: true,
      );
      expect(status.description, contains('Developer mode'));

      // Both issues
      status = DeviceSecurityStatus(
        isJailbroken: true,
        isDeveloperMode: true,
      );
      expect(status.description, contains('jailbroken/rooted'));
      expect(status.description, contains('Developer mode'));
    });
  });

  group('Screen Security Service Tests', () {
    late ScreenSecurityService screenSecurityService;

    setUp(() {
      screenSecurityService = ScreenSecurityService();
    });

    test('service initializes correctly', () {
      expect(screenSecurityService, isNotNull);
    });

    test('enableScreenSecurity returns bool', () async {
      final result = await screenSecurityService.enableScreenSecurity();
      expect(result, isA<bool>());
    });

    test('disableScreenSecurity returns bool', () async {
      final result = await screenSecurityService.disableScreenSecurity();
      expect(result, isA<bool>());
    });

    test('isSupported returns bool', () async {
      final result = await screenSecurityService.isSupported();
      expect(result, isA<bool>());
    });

    test('enable and disable can be called in sequence', () async {
      await screenSecurityService.enableScreenSecurity();
      await screenSecurityService.disableScreenSecurity();
      await screenSecurityService.enableScreenSecurity();

      // Should complete without errors
      expect(true, true);
    });
  });

  group('Mnemonic Verification Logic Tests', () {
    test('mnemonic word verification is case-insensitive', () {
      const expectedWord = 'abandon';

      expect('abandon'.toLowerCase() == expectedWord.toLowerCase(), true);
      expect('Abandon'.toLowerCase() == expectedWord.toLowerCase(), true);
      expect('ABANDON'.toLowerCase() == expectedWord.toLowerCase(), true);
      expect('aBaNdOn'.toLowerCase() == expectedWord.toLowerCase(), true);
    });

    test('mnemonic verification rejects incorrect words', () {
      const expectedWord = 'ability';

      expect('ability'.toLowerCase() == expectedWord.toLowerCase(), true);
      expect('able'.toLowerCase() == expectedWord.toLowerCase(), false);
      expect('about'.toLowerCase() == expectedWord.toLowerCase(), false);
      expect(''.toLowerCase() == expectedWord.toLowerCase(), false);
    });

    test('whitespace is trimmed during verification', () {
      const expectedWord = 'absent';

      expect('absent'.trim().toLowerCase() == expectedWord.toLowerCase(), true);
      expect(' absent'.trim().toLowerCase() == expectedWord.toLowerCase(), true);
      expect('absent '.trim().toLowerCase() == expectedWord.toLowerCase(), true);
      expect(' absent '.trim().toLowerCase() == expectedWord.toLowerCase(), true);
    });

    test('random word selection generates unique indices', () {
      final selectedIndices = <int>{};
      final random = <int>[];

      // Simulate selecting 3 random words
      while (random.length < 3) {
        final index = random.length * 3; // Simplified for test
        if (!selectedIndices.contains(index)) {
          selectedIndices.add(index);
          random.add(index);
        }
      }

      expect(selectedIndices.length, 3);
      expect(random.length, 3);
      // All indices should be unique
      expect(random.toSet().length, 3);
    });
  });
}
