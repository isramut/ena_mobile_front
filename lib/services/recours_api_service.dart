import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/recours_models.dart';

class RecoursApiService {
  static const String _cacheKey = 'recours_cache';
  static const Duration _cacheDuration = Duration(minutes: 10);

  /// Récupère le token d'authentification stocké
  static Future<String?> _getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('❌ Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  /// Récupère tous les recours du candidat connecté
  static Future<Map<String, dynamic>> getMesRecours({String? token}) async {
    print('📡 Récupération des recours...');
    
    try {
      final authToken = token ?? await _getStoredToken();
      if (authToken == null) {
        return {
          'success': false,
          'error': 'Token d\'authentification manquant',
        };
      }

      final url = '${ApiConfig.baseUrl}/api/recrutement/recours/';
      print('🌐 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final recoursResponse = RecoursResponse.fromJson(data);
        
        // Mettre en cache
        await _cacheRecours(data);
        
        print('✅ Recours chargés: ${recoursResponse.recours.length} éléments');
        return {
          'success': true,
          'data': recoursResponse,
        };
      } else {
        print('❌ Erreur API: ${response.statusCode}');
        print('📝 Réponse: ${response.body}');
        return {
          'success': false,
          'error': 'Erreur ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Exception lors du chargement des recours: $e');
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }

  /// Crée un nouveau recours
  static Future<Map<String, dynamic>> creerRecours({
    required String motifRejet,
    required String justification,
    String? candidature,
    List<String> documents = const [],
    String? token,
  }) async {
    print('📝 Création d\'un nouveau recours...');
    
    try {
      final authToken = token ?? await _getStoredToken();
      if (authToken == null) {
        return {
          'success': false,
          'error': 'Token d\'authentification manquant',
        };
      }

      final request = CreateRecoursRequest(
        motifRejet: motifRejet,
        justification: justification,
        candidature: candidature,
        documents: documents,
      );

      final url = '${ApiConfig.baseUrl}/api/recrutement/recours/';
      print('🌐 URL: $url');
      print('📤 Données: ${request.toJson()}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      print('📡 Status: ${response.statusCode}');
      print('📄 Réponse: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final recours = Recours.fromJson(data);
        
        // Invalider le cache pour forcer le rechargement
        await _clearCache();
        
        print('✅ Recours créé avec succès: ${recours.id}');
        return {
          'success': true,
          'data': recours,
        };
      } else if (response.statusCode == 400) {
        // Erreurs de validation
        final errorData = json.decode(response.body);
        final validationError = RecoursValidationError.fromJson(errorData);
        
        print('⚠️ Erreurs de validation: ${validationError.errors}');
        return {
          'success': false,
          'error': 'Erreurs de validation',
          'validation_errors': validationError,
        };
      } else {
        print('❌ Erreur API: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Erreur ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Exception lors de la création du recours: $e');
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }

  /// Récupère les recours avec cache pour améliorer les performances
  static Future<Map<String, dynamic>> getMesRecoursWithCache({String? token}) async {
    try {
      // 1. Essayer de charger depuis le cache
      final cachedData = await _getCachedRecours();
      if (cachedData != null) {
        print('💾 Données chargées depuis le cache');
        return {
          'success': true,
          'data': cachedData,
          'from_cache': true,
        };
      }

      // 2. Charger depuis l'API si pas de cache
      final result = await getMesRecours(token: token);
      return result;
    } catch (e) {
      print('❌ Erreur lors du chargement avec cache: $e');
      return {
        'success': false,
        'error': 'Erreur de chargement: $e',
      };
    }
  }

  /// Met en cache les données des recours
  static Future<void> _cacheRecours(List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_cacheKey, json.encode(cacheData));
      print('💾 Recours mis en cache');
    } catch (e) {
      print('⚠️ Erreur lors de la mise en cache: $e');
    }
  }

  /// Récupère les données depuis le cache si elles sont encore valides
  static Future<RecoursResponse?> _getCachedRecours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_cacheKey);
      
      if (cacheString == null) return null;

      final cacheData = json.decode(cacheString);
      final timestamp = cacheData['timestamp'] as int;
      final data = cacheData['data'];

      // Vérifier si le cache est encore valide
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _cacheDuration.inMilliseconds) {
        print('⏰ Cache expiré, suppression...');
        await _clearCache();
        return null;
      }

      return RecoursResponse.fromJson(data);
    } catch (e) {
      print('⚠️ Erreur lors de la lecture du cache: $e');
      await _clearCache();
      return null;
    }
  }

  /// Vide le cache des recours
  static Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      print('🗑️ Cache des recours supprimé');
    } catch (e) {
      print('⚠️ Erreur lors de la suppression du cache: $e');
    }
  }

  /// Rafraîchit les données en invalidant le cache
  static Future<Map<String, dynamic>> refreshRecours({String? token}) async {
    await _clearCache();
    return getMesRecours(token: token);
  }

  /// Valide les données avant soumission
  static Map<String, String?> validateRecoursData({
    required String motifRejet,
    required String justification,
  }) {
    Map<String, String?> errors = {};

    if (motifRejet.trim().isEmpty) {
      errors['motif_rejet'] = 'Le motif du rejet est obligatoire';
    } else if (motifRejet.trim().length < 10) {
      errors['motif_rejet'] = 'Le motif doit contenir au moins 10 caractères';
    }

    if (justification.trim().isEmpty) {
      errors['justification'] = 'La justification est obligatoire';
    } else if (justification.trim().length < 50) {
      errors['justification'] = 'La justification doit contenir au moins 50 caractères';
    }

    return errors;
  }

  /// Obtient les statistiques des recours
  static Map<String, int> getRecoursStats(List<Recours> recours) {
    Map<String, int> stats = {
      'total': recours.length,
      'en_attente': 0,
      'en_cours': 0,
      'accepte': 0,
      'rejete': 0,
    };

    for (final recours in recours) {
      stats[recours.statut] = (stats[recours.statut] ?? 0) + 1;
    }

    return stats;
  }
}
