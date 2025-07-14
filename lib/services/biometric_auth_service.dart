import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer l'authentification biométrique
class BiometricAuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  static const String _tokenKey = 'biometric_auth_token';
  static const String _emailKey = 'biometric_auth_email';
  static const String _biometricEnabledKey = 'biometric_enabled';
  
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Vérifie si l'authentification biométrique est disponible sur l'appareil
  static Future<bool> isAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      debugPrint('Erreur vérification biométrie: $e');
      return false;
    }
  }

  /// Récupère les types de biométrie disponibles
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Erreur récupération types biométrie: $e');
      return [];
    }
  }

  /// Vérifie si l'authentification biométrique est activée dans l'app
  static Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Erreur vérification activation biométrie: $e');
      return false;
    }
  }

  /// Active ou désactive l'authentification biométrique
  static Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
      
      // Si on désactive, on supprime les données stockées
      if (!enabled) {
        await _clearBiometricData();
      }
      
      return true;
    } catch (e) {
      debugPrint('Erreur activation/désactivation biométrie: $e');
      return false;
    }
  }

  /// Sauvegarde les données d'authentification pour la biométrie
  static Future<bool> saveBiometricCredentials({
    required String token,
    required String email,
  }) async {
    try {
      // Vérifier que la biométrie est disponible
      if (!await isAvailable()) {
        return false;
      }

      // Sauvegarder de manière sécurisée
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _emailKey, value: email);
      
      return true;
    } catch (e) {
      debugPrint('Erreur sauvegarde credentials biométrie: $e');
      return false;
    }
  }

  /// Authentification biométrique
  static Future<Map<String, dynamic>> authenticate() async {
    try {
      // Vérifier que la biométrie est activée
      if (!await isBiometricEnabled()) {
        return {
          'success': false,
          'error': 'Authentification biométrique désactivée',
        };
      }

      // Vérifier la disponibilité
      if (!await isAvailable()) {
        return {
          'success': false,
          'error': 'Authentification biométrique non disponible',
        };
      }

      // Obtenir les types disponibles pour personnaliser le message
      final availableTypes = await getAvailableBiometrics();
      String reason = 'Connectez-vous à ENA RDC';
      
      if (availableTypes.contains(BiometricType.face)) {
        reason = 'Utilisez Face ID pour vous connecter à ENA RDC';
      } else if (availableTypes.contains(BiometricType.fingerprint)) {
        reason = 'Utilisez votre empreinte pour vous connecter à ENA RDC';
      } else {
        reason = 'Utilisez votre authentification pour vous connecter à ENA RDC';
      }

      // Tenter l'authentification
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // Permet PIN/Pattern/Password
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );

      if (!didAuthenticate) {
        return {
          'success': false,
          'error': 'Authentification annulée ou échouée',
        };
      }

      // Récupérer les credentials stockés
      final token = await _storage.read(key: _tokenKey);
      final email = await _storage.read(key: _emailKey);

      if (token == null || email == null) {
        return {
          'success': false,
          'error': 'Aucune donnée d\'authentification trouvée',
        };
      }

      return {
        'success': true,
        'token': token,
        'email': email,
      };

    } on PlatformException catch (e) {
      String errorMessage = 'Erreur d\'authentification';
      
      switch (e.code) {
        case 'NotAvailable':
          errorMessage = 'Authentification biométrique non disponible';
          break;
        case 'NotEnrolled':
          errorMessage = 'Aucune biométrie configurée sur l\'appareil';
          break;
        case 'LockedOut':
          errorMessage = 'Trop de tentatives échouées. Réessayez plus tard';
          break;
        case 'PermanentlyLockedOut':
          errorMessage = 'Authentification bloquée. Utilisez le mot de passe';
          break;
        default:
          errorMessage = e.message ?? 'Erreur inconnue';
      }

      return {
        'success': false,
        'error': errorMessage,
        'code': e.code,
      };
    } catch (e) {
      debugPrint('Erreur authentification biométrique: $e');
      return {
        'success': false,
        'error': 'Erreur inattendue lors de l\'authentification',
      };
    }
  }

  /// Supprime les données biométriques stockées
  static Future<void> _clearBiometricData() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _emailKey);
    } catch (e) {
      debugPrint('Erreur suppression données biométrie: $e');
    }
  }

  /// Vérifie si des credentials sont stockés
  static Future<bool> hasStoredCredentials() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      final email = await _storage.read(key: _emailKey);
      return token != null && email != null;
    } catch (e) {
      debugPrint('Erreur vérification credentials: $e');
      return false;
    }
  }

  /// Réinitialise complètement la configuration biométrique
  static Future<void> resetBiometricAuth() async {
    try {
      await setBiometricEnabled(false);
      await _clearBiometricData();
    } catch (e) {
      debugPrint('Erreur reset biométrie: $e');
    }
  }

  /// Récupère une description des types de biométrie disponibles
  static Future<String> getBiometricTypeDescription() async {
    try {
      final availableTypes = await getAvailableBiometrics();
      
      if (availableTypes.isEmpty) {
        return 'Aucune biométrie disponible';
      }
      
      final descriptions = <String>[];
      
      if (availableTypes.contains(BiometricType.face)) {
        descriptions.add('Face ID');
      }
      if (availableTypes.contains(BiometricType.fingerprint)) {
        descriptions.add('Empreinte digitale');
      }
      if (availableTypes.contains(BiometricType.iris)) {
        descriptions.add('Reconnaissance iris');
      }
      
      // Si aucune biométrie spécifique mais authentification disponible
      if (descriptions.isEmpty && await isAvailable()) {
        descriptions.add('Authentification de l\'appareil');
      }
      
      return descriptions.join(', ');
    } catch (e) {
      debugPrint('Erreur description types biométrie: $e');
      return 'Authentification de l\'appareil';
    }
  }

  /// Test de l'authentification biométrique (pour la configuration initiale)
  static Future<bool> testBiometricAuthentication() async {
    try {
      if (!await isAvailable()) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Testez votre authentification pour ENA RDC',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('Erreur test biométrie: $e');
      return false;
    }
  }
}
