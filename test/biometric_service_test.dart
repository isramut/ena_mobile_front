import 'package:flutter_test/flutter_test.dart';
import 'package:ena_mobile_front/services/biometric_service.dart';

void main() {
  group('BiometricAuthService Tests', () {
    test('isDeviceSupported should return boolean', () async {
      final result = await BiometricAuthService.isDeviceSupported();
      expect(result, isA<bool>());
    });

    test('getAvailableBiometrics should return list', () async {
      final result = await BiometricAuthService.getAvailableBiometrics();
      expect(result, isA<List>());
    });

    test('isBiometricEnabled should return boolean', () async {
      final result = await BiometricAuthService.isBiometricEnabled();
      expect(result, isA<bool>());
    });

    test('getPrimaryBiometricType should return string', () async {
      final result = await BiometricAuthService.getPrimaryBiometricType();
      expect(result, isA<String>());
    });

    test('hasStoredCredentials should return boolean', () async {
      final result = await BiometricAuthService.hasStoredCredentials();
      expect(result, isA<bool>());
    });

    test('canUseBiometric should return boolean', () async {
      final result = await BiometricAuthService.canUseBiometric();
      expect(result, isA<bool>());
    });

    test('setBiometricEnabled should work', () async {
      // Test désactivation
      final resultDisable = await BiometricAuthService.setBiometricEnabled(false);
      expect(resultDisable, isA<bool>());
      
      // Vérifier que c'est bien désactivé
      final isDisabled = await BiometricAuthService.isBiometricEnabled();
      expect(isDisabled, false);
      
      // Test activation
      final resultEnable = await BiometricAuthService.setBiometricEnabled(true);
      expect(resultEnable, isA<bool>());
      
      // Vérifier que c'est bien activé
      final isEnabled = await BiometricAuthService.isBiometricEnabled();
      expect(isEnabled, true);
    });

    test('testBiometricAuth should return Map with success key', () async {
      final result = await BiometricAuthService.testBiometricAuth();
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), true);
    });

    test('storeAuthCredentials should work', () async {
      final result = await BiometricAuthService.storeAuthCredentials(
        token: 'test_token',
        email: 'test@example.com',
      );
      expect(result, isA<bool>());
    });

    test('authenticateForLogin should return Map with success key', () async {
      final result = await BiometricAuthService.authenticateForLogin();
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), true);
    });

    test('clearAllBiometricData should work', () async {
      // Store some data first
      await BiometricAuthService.storeAuthCredentials(
        token: 'test_token',
        email: 'test@example.com',
      );
      
      // Clear it
      await BiometricAuthService.clearAllBiometricData();
      
      // Verify it's cleared
      final hasCredentials = await BiometricAuthService.hasStoredCredentials();
      expect(hasCredentials, false);
    });
  });
}
