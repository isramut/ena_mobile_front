import 'dart:convert';
import 'dart:io';
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

      return null;
    }
  }

  /// Récupère tous les recours du candidat connecté
  static Future<Map<String, dynamic>> getMesRecours({String? token}) async {

    try {
      final authToken = token ?? await _getStoredToken();
      if (authToken == null) {
        return {
          'success': false,
          'error': 'Token d\'authentification manquant',
        };
      }

      final url = '${ApiConfig.baseUrl}/api/recrutement/recours/';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final recoursResponse = RecoursResponse.fromJson(data);
        
        // Mettre en cache
        await _cacheRecours(data);

        return {
          'success': true,
          'data': recoursResponse,
        };
      } else {


        return {
          'success': false,
          'error': 'Erreur ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {

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
    List<File> documents = const [],
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

      final url = '${ApiConfig.baseUrl}/api/recrutement/recours/';

      // Créer une requête multipart si des fichiers sont présents
      if (documents.isNotEmpty) {
        final request = http.MultipartRequest('POST', Uri.parse(url));
        
        // Headers d'authentification
        request.headers['Authorization'] = 'Bearer $authToken';
        
        // Champs de données
        request.fields['motif_rejet'] = motifRejet;
        request.fields['justification'] = justification;
        if (candidature != null) {
          request.fields['candidature'] = candidature;
        }
        
        // Ajouter les fichiers
        for (int i = 0; i < documents.length; i++) {
          final file = documents[i];
          final multipartFile = await http.MultipartFile.fromPath(
            'documents',
            file.path,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = json.decode(responseBody);
          final recours = Recours.fromJson(data);
          
          // Invalider le cache pour forcer le rechargement
          await _clearCache();

          return {
            'success': true,
            'data': recours,
          };
        } else if (response.statusCode == 400) {
          // Erreurs de validation
          final errorData = json.decode(responseBody);
          final validationError = RecoursValidationError.fromJson(errorData);

          return {
            'success': false,
            'error': 'Erreurs de validation',
            'validation_errors': validationError,
          };
        } else {
          return {
            'success': false,
            'error': 'Erreur ${response.statusCode}: $responseBody',
          };
        }
      } else {
        // Requête JSON classique si pas de fichiers
        final request = CreateRecoursRequest(
          motifRejet: motifRejet,
          justification: justification,
          candidature: candidature,
          documents: [],
        );

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: json.encode(request.toJson()),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = json.decode(response.body);
          final recours = Recours.fromJson(data);
          
          // Invalider le cache pour forcer le rechargement
          await _clearCache();

          return {
            'success': true,
            'data': recours,
          };
        } else if (response.statusCode == 400) {
          // Erreurs de validation
          final errorData = json.decode(response.body);
          final validationError = RecoursValidationError.fromJson(errorData);

          return {
            'success': false,
            'error': 'Erreurs de validation',
            'validation_errors': validationError,
          };
        } else {
          return {
            'success': false,
            'error': 'Erreur ${response.statusCode}: ${response.body}',
          };
        }
      }
    } catch (e) {

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

    } catch (e) {

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

        await _clearCache();
        return null;
      }

      return RecoursResponse.fromJson(data);
    } catch (e) {

      await _clearCache();
      return null;
    }
  }

  /// Vide le cache des recours
  static Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);

    } catch (e) {

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

  /// Valide les fichiers avant upload
  static Map<String, String?> validateFiles(List<File> files) {
    Map<String, String?> errors = {};
    
    if (files.length > 5) {
      errors['files'] = 'Maximum 5 fichiers autorisés';
      return errors;
    }

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = file.path.split('/').last.toLowerCase();
      final fileSize = file.lengthSync();
      
      // Vérifier la taille (max 5MB par fichier)
      if (fileSize > 5 * 1024 * 1024) {
        errors['file_$i'] = 'Le fichier ${fileName} est trop volumineux (max 5MB)';
        continue;
      }
      
      // Vérifier l'extension
      if (!fileName.endsWith('.pdf') && 
          !fileName.endsWith('.jpg') && 
          !fileName.endsWith('.jpeg') && 
          !fileName.endsWith('.png') &&
          !fileName.endsWith('.doc') &&
          !fileName.endsWith('.docx')) {
        errors['file_$i'] = 'Format non supporté pour ${fileName} (PDF, JPG, PNG, DOC, DOCX uniquement)';
      }
    }

    return errors;
  }

  /// Obtient la taille formatée d'un fichier
  static String getFormattedFileSize(int bytes) {
    if (bytes < 1024) {
      return "$bytes B";
    } else if (bytes < 1024 * 1024) {
      return "${(bytes / 1024).toStringAsFixed(1)} KB";
    } else {
      return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    }
  }
}
