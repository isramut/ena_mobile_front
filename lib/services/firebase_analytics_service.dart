import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service pour gérer Firebase Analytics dans l'application MyENA
class FirebaseAnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver _observer = 
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Observer pour navigation automatique
  static FirebaseAnalyticsObserver get observer => _observer;

  /// Instance Firebase Analytics
  static FirebaseAnalytics get analytics => _analytics;

  // ===================== ÉVÉNEMENTS DE CANDIDATURE =====================

  /// Événement : Début du processus de candidature
  static Future<void> trackCandidatureStarted() async {
    try {
      await _analytics.logEvent(
        name: 'candidature_started',
        parameters: {
          'screen_name': 'candidature_process',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'build_mode': kDebugMode ? 'debug' : 'release', // Ajout du mode de build
        },
      );
      if (kDebugMode) {
        print('📊 Analytics: Candidature started');
      }
      // Log en release aussi pour vérifier
      print('🔥 Firebase: Candidature started (${kDebugMode ? 'DEBUG' : 'RELEASE'})');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics Error (candidature_started): $e');
      }
      // Log des erreurs en release pour diagnostic
      print('🚨 Firebase Error: $e');
    }
  }

  /// Événement : Progression dans les étapes de candidature
  static Future<void> trackCandidatureStepProgress(int stepNumber, String stepName) async {
    try {
      await _analytics.logEvent(
        name: 'candidature_step_progress',
        parameters: {
          'step_number': stepNumber,
          'step_name': stepName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (kDebugMode) {
        print('📊 Analytics: Step $stepNumber ($stepName) reached');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics Error (candidature_step_progress): $e');
      }
    }
  }

  /// Événement : Validation d'une étape
  static Future<void> trackStepValidated(int stepNumber, String stepName) async {
    try {
      await _analytics.logEvent(
        name: 'candidature_step_validated',
        parameters: {
          'step_number': stepNumber,
          'step_name': stepName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (kDebugMode) {
        print('📊 Analytics: Step $stepNumber ($stepName) validated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics Error (candidature_step_validated): $e');
      }
    }
  }

  /// Événement : Erreur de validation dans une étape
  static Future<void> trackStepValidationError(int stepNumber, String errorType) async {
    try {
      await _analytics.logEvent(
        name: 'candidature_step_error',
        parameters: {
          'step_number': stepNumber,
          'error_type': errorType,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (kDebugMode) {
        print('📊 Analytics: Step $stepNumber validation error: $errorType');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics Error (candidature_step_error): $e');
      }
    }
  }

  /// Événement : Candidature soumise avec succès
  static Future<void> trackCandidatureSubmitted(String statutProfessionnel) async {
    try {
      await _analytics.logEvent(
        name: 'candidature_submitted',
        parameters: {
          'statut_professionnel': statutProfessionnel,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (kDebugMode) {
        print('📊 Analytics: Candidature submitted ($statutProfessionnel)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics Error (candidature_submitted): $e');
      }
    }
  }

  /// Événement : Abandon du processus de candidature
  static Future<void> trackCandidatureAbandoned(int lastStep, String reason) async {
    try {
      await _analytics.logEvent(
        name: 'candidature_abandoned',
        parameters: {
          'last_step': lastStep,
          'abandon_reason': reason,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (kDebugMode) {
        print('📊 Analytics: Candidature abandoned at step $lastStep ($reason)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics Error (candidature_abandoned): $e');
      }
    }
  }

  // ===================== ÉVÉNEMENTS DE FICHIERS =====================

  /// Événement : Upload d'un fichier
  static Future<void> trackFileUpload(String fileType, String fileName, int fileSizeBytes) async {
    try {
      await _analytics.logEvent(
        name: 'file_uploaded',
        parameters: {
          'file_type': fileType,
          'file_name': fileName,
          'file_size_bytes': fileSizeBytes,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (kDebugMode) {
        print('📊 Analytics: File uploaded - $fileType ($fileName)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics Error (file_uploaded): $e');
      }
    }
  }

  /// Événement : Erreur d'upload de fichier
  static Future<void> trackFileUploadError(String fileType, String errorReason) async {
    try {
      await _analytics.logEvent(
        name: 'file_upload_error',
        parameters: {
          'file_type': fileType,
          'error_reason': errorReason,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (kDebugMode) {
        print('📊 Analytics: File upload error - $fileType ($errorReason)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics Error (file_upload_error): $e');
      }
    }
  }

  // ===================== ÉVÉNEMENTS GÉNÉRAUX =====================

  /// Événement : Connexion utilisateur
  static Future<void> trackUserLogin() async {
    try {
      await _analytics.logLogin(loginMethod: 'ena_credentials');
      if (kDebugMode) {
        print('📊 Analytics: User login');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics Error (user_login): $e');
      }
    }
  }

  /// Événement : Ouverture de l'application
  static Future<void> trackAppOpened() async {
    try {
      await _analytics.logAppOpen();
      if (kDebugMode) {
        print('📊 Analytics: App opened');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics Error (app_opened): $e');
      }
    }
  }

  /// Événement : Navigation vers un écran
  static Future<void> trackScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      if (kDebugMode) {
        print('📊 Analytics: Screen view - $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics Error (screen_view): $e');
      }
    }
  }

  /// Définir les propriétés utilisateur
  static Future<void> setUserProperties({
    String? statusProfessionnel,
    String? province,
    String? filiere,
  }) async {
    try {
      if (statusProfessionnel != null) {
        await _analytics.setUserProperty(
          name: 'statut_professionnel',
          value: statusProfessionnel,
        );
      }
      if (province != null) {
        await _analytics.setUserProperty(
          name: 'province',
          value: province,
        );
      }
      if (filiere != null) {
        await _analytics.setUserProperty(
          name: 'filiere',
          value: filiere,
        );
      }
      if (kDebugMode) {
        print('📊 Analytics: User properties set');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics Error (set_user_properties): $e');
      }
    }
  }

  /// Définir l'ID utilisateur
  static Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      if (kDebugMode) {
        print('📊 Analytics: User ID set - $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics Error (set_user_id): $e');
      }
    }
  }

  // ===================== ÉVÉNEMENTS DE SAUVEGARDE AUTO =====================

  /// Événement : Sauvegarde automatique
  static Future<void> trackAutoSave(int currentStep) async {
    try {
      await _analytics.logEvent(
        name: 'auto_save_triggered',
        parameters: {
          'current_step': currentStep,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (kDebugMode) {
        print('📊 Analytics: Auto save at step $currentStep');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics Error (auto_save_triggered): $e');
      }
    }
  }

  /// Événement : Restauration de données sauvegardées
  static Future<void> trackDataRestored(int stepRestored) async {
    try {
      await _analytics.logEvent(
        name: 'data_restored',
        parameters: {
          'step_restored': stepRestored,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (kDebugMode) {
        print('📊 Analytics: Data restored at step $stepRestored');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Analytics Error (data_restored): $e');
      }
    }
  }
}
