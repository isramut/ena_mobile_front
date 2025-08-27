import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/recours_models.dart';

class RecoursApiService {
  /// Récupère le token d'authentification stocké
  static Future<String?> _getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      return null;
    }
  }

  /// Créer un recours avec des documents
  static Future<Map<String, dynamic>> creerRecoursDocuments({
    String? token,
    required String typeRecours,
    required String motif,
    required List<File> files,
    String? commentaires,
  }) async {
    try {
      final authToken = token ?? await _getStoredToken();
      
      if (authToken == null) {
        return {
          'success': false,
          'error': 'Token d\'authentification manquant',
        };
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/recours/documents'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $authToken',
      });

      request.fields['type_recours'] = typeRecours;
      request.fields['motif'] = motif;
      if (commentaires != null && commentaires.isNotEmpty) {
        request.fields['commentaires'] = commentaires;
      }

      // Ajouter les fichiers
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final multipartFile = await http.MultipartFile.fromPath(
          'documents[]',
          file.path,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final recours = Recours.fromJson(data);

        return {
          'success': true,
          'data': recours,
        };
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Données invalides',
          'details': errorData['details'],
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Token d\'authentification invalide',
        };
      } else if (response.statusCode == 413) {
        return {
          'success': false,
          'error': 'Fichiers trop volumineux',
        };
      } else if (response.statusCode == 422) {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': 'Erreur de validation',
          'details': errorData['errors'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Erreur lors de la création du recours',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Récupérer la liste des recours de l'utilisateur connecté
  static Future<Map<String, dynamic>> getMesRecours({String? token}) async {
    try {
      final authToken = token ?? await _getStoredToken();
      
      if (authToken == null) {
        return {
          'success': false,
          'error': 'Token d\'authentification manquant',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/recrutement/recours/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Support pour l'ancien et le nouveau format
        if (data is List) {
          // Ancien format - liste directe
          final recoursList = data
              .map((item) => Recours.fromJson(item))
              .toList();
          
          return {
            'success': true,
            'data': recoursList,
            'pagination': null,
          };
        } else {
          // Nouveau format avec pagination
          final recoursResponse = RecoursResponse.fromJson(data);
          return {
            'success': true,
            'data': recoursResponse.recours,
            'pagination': {
              'count': recoursResponse.count,
              'next': recoursResponse.next,
              'previous': recoursResponse.previous,
            },
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Token d\'authentification invalide',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Erreur lors de la récupération des recours',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Créer un recours simple (sans documents)
  static Future<Map<String, dynamic>> creerRecours({
    String? token,
    required String typeRecours,
    required String motif,
    String? commentaires,
    Map<String, dynamic>? donneesSupplementaires,
  }) async {
    try {
      final authToken = token ?? await _getStoredToken();
      
      if (authToken == null) {
        return {
          'success': false,
          'error': 'Token d\'authentification manquant',
        };
      }

      final body = {
        'type_recours': typeRecours,
        'motif': motif,
        if (commentaires != null && commentaires.isNotEmpty)
          'commentaires': commentaires,
        if (donneesSupplementaires != null)
          ...donneesSupplementaires,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/recours'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final recours = Recours.fromJson(data);

        return {
          'success': true,
          'data': recours,
        };
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Données invalides',
          'details': errorData['details'],
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Token d\'authentification invalide',
        };
      } else if (response.statusCode == 409) {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Un recours existe déjà pour cette candidature',
        };
      } else if (response.statusCode == 422) {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': 'Erreur de validation',
          'details': errorData['errors'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Erreur lors de la création du recours',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Validation des données de recours
  static Map<String, String?> validateRecoursData({
    required String typeRecours,
    required String motif,
    String? commentaires,
  }) {
    Map<String, String?> errors = {};

    if (typeRecours.isEmpty) {
      errors['typeRecours'] = 'Le type de recours est obligatoire';
    }

    if (motif.isEmpty) {
      errors['motif'] = 'Le motif est obligatoire';
    } else if (motif.length < 10) {
      errors['motif'] = 'Le motif doit contenir au moins 10 caractères';
    }

    return errors;
  }

  /// Statistiques des recours
  static Map<String, int> getRecoursStats(List<Recours> recours) {
    Map<String, int> stats = {
      'total': recours.length,
      'en_attente': 0,
      'traite': 0,
    };

    for (var r in recours) {
      if (r.traite) {
        stats['traite'] = stats['traite']! + 1;
      } else {
        stats['en_attente'] = stats['en_attente']! + 1;
      }
    }

    return stats;
  }

  /// Validation des fichiers
  static Map<String, String?> validateFiles(List<File> files) {
    Map<String, String?> errors = {};

    if (files.isEmpty) {
      errors['files'] = 'Au moins un document est requis';
      return errors;
    }

    const int maxFileSize = 10 * 1024 * 1024; // 10 MB
    const int maxTotalSize = 50 * 1024 * 1024; // 50 MB
    const List<String> allowedExtensions = ['.pdf', '.jpg', '.jpeg', '.png', '.doc', '.docx'];

    int totalSize = 0;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileSize = file.lengthSync();
      final fileName = file.path.split('/').last;
      final extension = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));

      totalSize += fileSize;

      if (fileSize > maxFileSize) {
        errors['file_$i'] = 'Le fichier $fileName est trop volumineux (max: 10 MB)';
      }

      if (!allowedExtensions.contains(extension)) {
        errors['file_$i'] = 'Format de fichier non autorisé: $extension';
      }
    }

    if (totalSize > maxTotalSize) {
      errors['total_size'] = 'La taille totale des fichiers dépasse 50 MB';
    }

    if (files.length > 10) {
      errors['file_count'] = 'Maximum 10 fichiers autorisés';
    }

    return errors;
  }

  /// Format de taille de fichier lisible
  static String getFormattedFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Récupérer les types de recours disponibles
  static Future<Map<String, dynamic>> getRecoursType({String? token}) async {
    try {
      final authToken = token ?? await _getStoredToken();
      
      if (authToken == null) {
        return {
          'success': false,
          'error': 'Token d\'authentification manquant',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/recours/types'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur lors de la récupération des types de recours',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Labels des documents requis
  static Map<String, String> getDocumentsLabels() {
    return {
      'piece_identite': 'Pièce d\'identité',
      'releve_notes': 'Relevé de notes',
      'justificatif_domicile': 'Justificatif de domicile',
      'lettre_motivation': 'Lettre de motivation',
      'cv': 'Curriculum Vitae',
      'diplomes': 'Diplômes et certifications',
      'autre': 'Autre document',
    };
  }

  /// Validation des documents de recours
  static Map<String, String?> validateRecoursDocuments({
    required List<File> files,
    required List<String> documentsRequis,
  }) {
    Map<String, String?> errors = {};

    // Validation des fichiers
    final fileErrors = validateFiles(files);
    errors.addAll(fileErrors);

    // Vérification des documents requis
    if (documentsRequis.isNotEmpty && files.length < documentsRequis.length) {
      errors['documents_manquants'] = 'Certains documents requis sont manquants';
    }

    return errors;
  }

  /// Détermine si on doit utiliser le nouveau système de recours
  static Future<bool> shouldUseNewRecoursSystem({String? token}) async {
    // Pour l'instant, on utilise toujours le nouveau système
    return true;
  }

  /// Récupère la liste des documents requis pour un recours
  static Future<List<String>> getDocumentsRequis({String? token}) async {
    try {
      final authToken = token ?? await _getStoredToken();
      
      if (authToken == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/recours/documents-requis'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['documents'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Soumettre un recours avec des documents (nouvel endpoint)
  static Future<Map<String, dynamic>> submitRecoursWithDocuments({
    String? token,
    required String motifRejet,
    required String justification,
    required List<File> documents,
    required List<String> documentTypes,
  }) async {
    try {
      final authToken = token ?? await _getStoredToken();
      
      if (authToken == null) {
        return {
          'success': false,
          'error': 'Token d\'authentification manquant',
        };
      }

      // Utiliser MultipartRequest pour envoyer les fichiers
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/recrutement/recours/'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $authToken',
      });

      // Ajouter les champs de base
      request.fields['motif_rejet'] = motifRejet;
      request.fields['justification'] = justification;

      // Ajouter les fichiers
      for (int i = 0; i < documents.length && i < documentTypes.length; i++) {
        final file = documents[i];
        final docType = documentTypes[i];
        
        final multipartFile = await http.MultipartFile.fromPath(
          docType, // Utiliser le type de document comme nom de champ
          file.path,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        return {
          'success': true,
          'data': data,
          'message': 'Recours soumis avec succès',
        };
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['justification']?.first ?? 'Données invalides',
          'details': errorData,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Token d\'authentification invalide',
        };
      } else if (response.statusCode == 403) {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Accès refusé',
        };
      } else if (response.statusCode == 413) {
        return {
          'success': false,
          'error': 'Fichiers trop volumineux (max 5 Mo par fichier)',
        };
      } else if (response.statusCode == 422) {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': 'Erreur de validation',
          'details': errorData,
        };
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'error': errorData['error'] ?? 'Erreur inconnue',
            'status_code': response.statusCode,
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Erreur HTTP ${response.statusCode}',
            'status_code': response.statusCode,
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: $e',
      };
    }
  }
}
