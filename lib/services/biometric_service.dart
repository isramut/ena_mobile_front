import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_api_service.dart';

/// Service pour gérer l'authentification biométrique
class BiometricAuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Clés de stockage liées à l'utilisateur
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _secureTokenKey = 'secure_auth_token';
  static const String _userEmailKey = 'secure_user_email';
  static const String _biometricUserKey = 'biometric_user_email'; // Email de l'utilisateur qui a activé la biométrie

  /// Vérifie si la biométrie est disponible sur l'appareil
  static Future<bool> isDeviceSupported() async {
    try {
      final result = await _localAuth.canCheckBiometrics;

      return result;
    } catch (e) {

      return false;
    }
  }

  /// Obtient les types de biométrie disponibles
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      if (await isDeviceSupported()) {
        final biometrics = await _localAuth.getAvailableBiometrics();

        return biometrics;
      }

      return [];
    } catch (e) {

      return [];
    }
  }

  /// Vérifie si la biométrie est activée dans les paramètres de l'app
  static Future<bool> isBiometricEnabled() async {
    // Utiliser la nouvelle méthode qui vérifie l'utilisateur
    return await isBiometricEnabledForCurrentUser();
  }

  /// Active ou désactive l'authentification biométrique
  static Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (enabled) {
        // Enregistrer l'utilisateur qui active la biométrie
        final currentUserEmail = await getCurrentUserEmail();
        if (currentUserEmail == null) {

          return false;
        }
        
        await prefs.setBool(_biometricEnabledKey, true);
        await prefs.setString(_biometricUserKey, currentUserEmail);

      } else {
        // Si on désactive, supprimer les données sécurisées ET l'association utilisateur
        await prefs.setBool(_biometricEnabledKey, false);
        await prefs.remove(_biometricUserKey);
        await _clearSecureData();

      }
      
      return true;
    } catch (e) {

      return false;
    }
  }

  /// Vérifie si l'authentification biométrique est disponible et activée
  static Future<bool> canUseBiometric() async {
    try {
      final isSupported = await isDeviceSupported();
      final isEnabled = await isBiometricEnabled();
      final availableBiometrics = await getAvailableBiometrics();
      
      // Ne pas vérifier hasStoredCredentials ici car après logout, 
      // l'utilisateur peut vouloir utiliser la biométrie mais les credentials sont vides
      return isSupported && isEnabled && availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si l'authentification biométrique est disponible sur l'appareil (sans vérifier l'activation app)
  static Future<bool> isBiometricAvailableOnDevice() async {
    try {
      // Utiliser le test de compatibilité pour Android 11 et versions antérieures
      final isCompatible = await testAuthCompatibility();

      return isCompatible;
    } catch (e) {

      return false;
    }
  }

  /// Méthode de diagnostic pour déboguer les problèmes biométriques
  static Future<Map<String, dynamic>> diagnoseBiometric() async {
    final Map<String, dynamic> diagnosis = {};
    
    try {
      // Test 1: Capacité de vérification biométrique
      diagnosis['canCheckBiometrics'] = await _localAuth.canCheckBiometrics;
      
      // Test 2: Vérification du support matériel
      diagnosis['isDeviceSupported'] = await _localAuth.isDeviceSupported();
      
      // Test 3: Biométries disponibles
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      diagnosis['availableBiometrics'] = availableBiometrics.map((e) => e.toString()).toList();
      diagnosis['availableBiometricsCount'] = availableBiometrics.length;
      
      // Test 4: Types spécifiques
      diagnosis['hasFingerprint'] = availableBiometrics.contains(BiometricType.fingerprint);
      diagnosis['hasFace'] = availableBiometrics.contains(BiometricType.face);
      diagnosis['hasIris'] = availableBiometrics.contains(BiometricType.iris);
      diagnosis['hasWeak'] = availableBiometrics.contains(BiometricType.weak);
      diagnosis['hasStrong'] = availableBiometrics.contains(BiometricType.strong);
      
      // Test 5: Notre méthode personnalisée
      diagnosis['isBiometricAvailableOnDevice'] = await isBiometricAvailableOnDevice();
      
      // Test 6: État actuel dans l'app
      diagnosis['isBiometricEnabledInApp'] = await isBiometricEnabled();

    } catch (e) {
      diagnosis['error'] = e.toString();

    }
    
    return diagnosis;
  }

  /// Obtient le type de biométrie principal disponible (pour l'affichage)
  static Future<String> getPrimaryBiometricType() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      
      if (availableBiometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return 'Empreinte digitale';
      } else if (availableBiometrics.contains(BiometricType.iris)) {
        return 'Reconnaissance iris';
      } else {
        // Si pas de biométrie "classique", mais l'appareil supporte l'authentification
        final isDeviceSupported = await _localAuth.isDeviceSupported();
        if (isDeviceSupported) {
          return 'méthode de déverrouillage (schéma, PIN, mot de passe)';
        } else {
          return 'Authentification sécurisée';
        }
      }
    } catch (e) {
      return 'Authentification sécurisée';
    }
  }

  /// Teste l'authentification biométrique avec gestion d'erreurs améliorée
  static Future<Map<String, dynamic>> testBiometricAuth() async {
    try {
      if (!await isBiometricAvailableOnDevice()) {
        return {
          'success': false,
          'error': 'Authentification biométrique non disponible sur cet appareil',
        };
      }

      final String biometricType = await getPrimaryBiometricType();
      
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Testez votre $biometricType pour ENA RDC',
        options: const AuthenticationOptions(
          biometricOnly: false, // Permet PIN/Pattern
          stickyAuth: true,
          sensitiveTransaction: false,
        ),
      );

      return {
        'success': authenticated,
        'message': authenticated 
            ? 'Test réussi ! $biometricType configuré correctement.'
            : 'Test échoué. Veuillez réessayer.',
      };
    } on PlatformException catch (e) {
      // Gestion spécifique des erreurs de plateforme
      String errorMessage;
      switch (e.code) {
        case 'no_fragment_activity':
          errorMessage = 'Erreur de configuration de l\'application. Redémarrez l\'app et réessayez.';
          break;
        case 'NotAvailable':
          errorMessage = 'Authentification biométrique non disponible sur cet appareil';
          break;
        case 'NotEnrolled':
          errorMessage = 'Aucune empreinte ou méthode biométrique configurée';
          break;
        case 'PermanentlyLockedOut':
          errorMessage = 'Authentification biométrique temporairement bloquée';
          break;
        case 'LockedOut':
          errorMessage = 'Trop de tentatives échouées. Réessayez plus tard.';
          break;
        default:
          errorMessage = 'Erreur: ${e.message ?? 'Erreur inconnue'}';
      }
      
      return {
        'success': false,
        'error': errorMessage,
        'details': 'Code: ${e.code}, Message: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur lors du test : ${e.toString()}',
      };
    }
  }

  /// Stocke les informations d'authentification de manière sécurisée
  static Future<bool> storeAuthCredentials({
    required String token,
    required String email,
  }) async {
    try {
      await _secureStorage.write(key: _secureTokenKey, value: token);
      await _secureStorage.write(key: _userEmailKey, value: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Authentification biométrique pour se connecter avec pré-chargement
  static Future<Map<String, dynamic>> authenticateForLogin() async {
    try {
      if (!await canUseBiometric()) {
        return {
          'success': false,
          'error': 'Authentification biométrique non disponible',
        };
      }

      // Vérifier qu'on a des credentials stockés
      final storedToken = await _secureStorage.read(key: _secureTokenKey);
      final storedEmail = await _secureStorage.read(key: _userEmailKey);
      
      if (storedToken == null || storedEmail == null) {
        return {
          'success': false,
          'error': 'Aucune session sauvegardée. Veuillez vous connecter d\'abord avec votre email et mot de passe pour activer la biométrie.',
        };
      }

      final String biometricType = await getPrimaryBiometricType();

      // 🚀 LANCER LE PRÉ-CHARGEMENT EN PARALLÈLE avec l'authentification
      AuthApiService.preloadDuringAuth(token: storedToken);
      
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Connectez-vous à ENA RDC avec votre $biometricType',
        options: const AuthenticationOptions(
          biometricOnly: false, // Permet PIN/Pattern/Biométrie
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );

      if (authenticated) {
        // L'authentification a réussi, le pré-chargement continue en arrière-plan

        return {
          'success': true,
          'token': storedToken,
          'email': storedEmail,
          'preloadStarted': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Authentification biométrique échouée',
        };
      }
    } on PlatformException catch (e) {
      // Gestion spécifique des erreurs de plateforme pour le login
      String errorMessage;
      switch (e.code) {
        case 'no_fragment_activity':
          errorMessage = 'Erreur de configuration. Redémarrez l\'application.';
          break;
        case 'NotAvailable':
          // Sur Android 11 et versions antérieures, parfois l'auth dit "non disponible"
          // même si PIN/schéma configuré. Essayer de donner un message plus clair.
          errorMessage = 'Authentification non disponible. Vérifiez que votre écran de verrouillage est configuré (PIN, schéma ou biométrie).';
          break;
        case 'NotEnrolled':
          errorMessage = 'Aucune méthode de verrouillage configurée sur votre appareil (PIN, schéma, empreinte, etc.)';
          break;
        case 'PermanentlyLockedOut':
          errorMessage = 'Authentification bloquée temporairement. Utilisez votre PIN/schéma pour débloquer.';
          break;
        case 'LockedOut':
          errorMessage = 'Trop de tentatives échouées. Réessayez plus tard ou utilisez votre PIN/schéma.';
          break;
        case 'UserCancel':
          errorMessage = 'Authentification annulée par l\'utilisateur';
          break;
        case 'SystemCancel':
          errorMessage = 'Authentification interrompue par le système';
          break;
        default:
          // Pour les anciennes versions Android, donner des messages plus informatifs
          if (e.message?.toLowerCase().contains('not available') == true) {
            errorMessage = 'Authentification non disponible sur cet appareil. Vérifiez vos paramètres de sécurité.';
          } else if (e.message?.toLowerCase().contains('not enrolled') == true) {
            errorMessage = 'Aucune méthode de sécurité configurée. Configurez un PIN, schéma ou biométrie.';
          } else {
            errorMessage = 'Erreur d\'authentification : ${e.message ?? 'Erreur inconnue'}';
          }
      }




      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur d\'authentification : ${e.toString()}',
      };
    }
  }

  /// Supprime toutes les données sécurisées
  static Future<void> _clearSecureData() async {
    try {
      await _secureStorage.delete(key: _secureTokenKey);
      await _secureStorage.delete(key: _userEmailKey);
    } catch (e) {
      // Ignore les erreurs de suppression
    }
  }

  /// Nettoie toutes les données biométriques (logout)
  static Future<void> clearAllBiometricData() async {
    await _clearSecureData();
  }

  /// Vérifie si on a des credentials stockés
  static Future<bool> hasStoredCredentials() async {
    try {
      final storedToken = await _secureStorage.read(key: _secureTokenKey);
      final storedEmail = await _secureStorage.read(key: _userEmailKey);


      final result = storedToken != null && storedEmail != null;

      return result;
    } catch (e) {

      return false;
    }
  }

  /// Test spécifique pour la compatibilité avec les anciennes versions Android
  static Future<bool> testAuthCompatibility() async {
    try {

      // Test simple sans vraiment authentifier
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await getAvailableBiometrics();




      // Si on a des vraies biométries, ça marche
      if (availableBiometrics.isNotEmpty) {

        return true;
      }
      
      // Si l'appareil dit qu'il supporte mais pas de vraies biométries,
      // cela signifie probablement PIN/schéma disponible
      if (isDeviceSupported && canCheckBiometrics) {

        return true;
      }

      return false;
    } catch (e) {

      return false;
    }
  }

  /// Obtient l'email de l'utilisateur actuellement connecté
  static Future<String?> getCurrentUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_email'); // ou toute autre clé utilisée pour stocker l'email courant
    } catch (e) {

      return null;
    }
  }

  /// Vérifie si la biométrie est activée pour l'utilisateur actuel
  static Future<bool> isBiometricEnabledForCurrentUser() async {
    try {
      final currentUserEmail = await getCurrentUserEmail();
      if (currentUserEmail == null) {

        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final isGenerallyEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
      
      if (!isGenerallyEnabled) {

        return false;
      }

      // Vérifier si c'est le même utilisateur qui a activé la biométrie
      final biometricUserEmail = prefs.getString(_biometricUserKey);
      final isSameUser = biometricUserEmail == currentUserEmail;



      return isSameUser;
    } catch (e) {

      return false;
    }
  }

  /// Désactive la biométrie lors du logout d'un utilisateur
  static Future<void> handleUserLogout() async {
    try {
      // NE PAS supprimer les credentials sécurisés lors du logout
      // Cela permet à l'utilisateur de se reconnecter directement avec la biométrie
      // Les credentials sont préservés pour permettre la reconnexion biométrique

    } catch (e) {

    }
  }

  /// Vérifie et désactive la biométrie si l'utilisateur a changé
  static Future<void> checkUserChanged() async {
    try {
      final currentUserEmail = await getCurrentUserEmail();
      final prefs = await SharedPreferences.getInstance();
      final biometricUserEmail = prefs.getString(_biometricUserKey);



      // Si l'utilisateur a changé, désactiver la biométrie ET supprimer les credentials
      if (biometricUserEmail != null && 
          currentUserEmail != null && 
          biometricUserEmail != currentUserEmail) {

        await setBiometricEnabled(false);
        await _clearSecureData(); // Supprimer les credentials de l'ancien utilisateur
      }
    } catch (e) {

    }
  }
}
