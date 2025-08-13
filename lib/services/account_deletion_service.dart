import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Service pour gérer la suppression de compte utilisateur
class AccountDeletionService {
  
  /// Récupère le token d'authentification stocké
  static Future<String?> _getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      return null;
    }
  }

  /// Demande de suppression de compte
  /// 
  /// [reason] : Raison optionnelle de la suppression
  /// [deletionType] : Type de suppression ('complete' ou 'partial') - optionnel
  /// 
  /// Retourne une Map avec:
  /// - success: bool
  /// - data: {message, token, deletion_request_id} si succès
  /// - error: String si erreur
  static Future<Map<String, dynamic>> requestAccountDeletion({
    String? reason,
    String? deletionType,
    String? token,
  }) async {
    try {
      final authToken = token ?? await _getStoredToken();
      if (authToken == null) {
        return {
          'success': false,
          'error': 'Token d\'authentification manquant',
        };
      }

      // Construire le payload (tous les paramètres sont optionnels selon Joel)
      final Map<String, dynamic> payload = {};
      if (reason != null && reason.trim().isNotEmpty) {
        payload['reason'] = reason.trim();
      }
      if (deletionType != null && deletionType.trim().isNotEmpty) {
        payload['deletion_type'] = deletionType.trim();
      }

      final response = await http.post(
        Uri.parse(ApiConfig.accountDeletionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      final responseData = _parseResponse(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 
                   responseData['message'] ?? 
                   'Erreur lors de la demande de suppression',
          'details': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion au serveur',
        'details': e.toString(),
      };
    }
  }

  /// Parse la réponse HTTP en JSON
  static Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {
        'error': 'Réponse serveur invalide',
        'raw_response': response.body,
      };
    }
  }

  /// Vérifie si une demande de suppression est déjà en cours
  /// (Basé sur le message d'erreur observé dans les tests)
  static bool isDeletionAlreadyInProgress(Map<String, dynamic> errorResponse) {
    final errorMessage = errorResponse['error']?.toString().toLowerCase() ?? '';
    return errorMessage.contains('demande de suppression') && 
           errorMessage.contains('déjà en cours');
  }

  /// Formate le message d'erreur pour l'utilisateur
  static String formatErrorMessage(Map<String, dynamic> errorResponse) {
    if (isDeletionAlreadyInProgress(errorResponse)) {
      return 'Une demande de suppression de votre compte est déjà en cours. '
             'Vous recevrez une confirmation par email sous 30 jours.';
    }

    final error = errorResponse['error'];
    if (error != null) {
      return error.toString();
    }

    return 'Une erreur s\'est produite lors de la demande de suppression.';
  }
}
