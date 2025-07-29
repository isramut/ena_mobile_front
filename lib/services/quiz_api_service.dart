import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ena_mobile_front/config/api_config.dart';
import 'package:ena_mobile_front/models/quiz_models.dart';

class QuizApiService {
  static const String _quizModulesEndpoint = '/api/recrutement/quiz/modules/complete/';

  /// Récupère le token d'authentification stocké
  static Future<String?> _getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {

      return null;
    }
  }

  /// Récupère tous les modules de quiz depuis l'API
  static Future<Map<String, dynamic>> getQuizModules() async {
    try {

      // Obtenir le token d'authentification
      final token = await _getStoredToken();
      if (token == null) {

        return {
          'success': false,
          'error': 'Utilisateur non connecté',
        };
      }

      final url = '${ApiConfig.baseUrl}$_quizModulesEndpoint';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final quizResponse = QuizResponse.fromJson(jsonData);


        return {
          'success': true,
          'data': quizResponse,
        };
      } else {


        return {
          'success': false,
          'error': 'Erreur lors de la récupération des modules de quiz',
          'statusCode': response.statusCode,
          'details': response.body,
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

  /// Récupère un module spécifique par son ID
  static Future<Map<String, dynamic>> getQuizModule(String moduleId) async {
    try {
      final result = await getQuizModules();
      
      if (result['success'] == true) {
        final QuizResponse quizResponse = result['data'];
        final module = quizResponse.modules.firstWhere(
          (module) => module.id == moduleId,
          orElse: () => throw Exception('Module non trouvé'),
        );
        
        return {
          'success': true,
          'data': module,
        };
      } else {
        return result;
      }
    } catch (e) {

      return {
        'success': false,
        'error': 'Module non trouvé',
        'details': e.toString(),
      };
    }
  }

  /// Soumet les réponses d'un quiz (pour future implémentation)
  static Future<Map<String, dynamic>> submitQuizAnswers({
    required String moduleId,
    required List<UserQuizAnswer> answers,
  }) async {
    try {

      // Pour l'instant, on simule la soumission
      // TODO: Implémenter l'endpoint de soumission quand il sera disponible
      
      await Future.delayed(const Duration(seconds: 1)); // Simulation
      
      return {
        'success': true,
        'message': 'Réponses soumises avec succès',
        'data': {
          'submitted_at': DateTime.now().toIso8601String(),
          'answers_count': answers.length,
        },
      };
    } catch (e) {

      return {
        'success': false,
        'error': 'Erreur lors de la soumission des réponses',
        'details': e.toString(),
      };
    }
  }

  /// Cache les modules localement pour améliorer les performances
  static Map<String, QuizResponse>? _cachedQuizData;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  static Future<Map<String, dynamic>> getQuizModulesWithCache() async {
    // Vérifier si le cache est encore valide
    if (_cachedQuizData != null && 
        _cacheTimestamp != null && 
        DateTime.now().difference(_cacheTimestamp!) < _cacheExpiry) {

      return {
        'success': true,
        'data': _cachedQuizData!['main'],
        'from_cache': true,
      };
    }

    // Récupérer depuis l'API
    final result = await getQuizModules();
    
    if (result['success'] == true) {
      // Mettre en cache
      _cachedQuizData = {'main': result['data']};
      _cacheTimestamp = DateTime.now();

    }

    return result;
  }

  /// Vide le cache
  static void clearCache() {
    _cachedQuizData = null;
    _cacheTimestamp = null;

  }

  /// Obtient les statistiques des modules
  static Map<String, dynamic> getQuizStatistics(QuizResponse quizResponse) {
    final modules = quizResponse.modules;
    
    // Calculer les statistiques
    final levelCounts = <String, int>{};
    final difficultyCounts = <int, int>{};
    int totalDuration = 0;
    
    for (final module in modules) {
      levelCounts[module.level] = (levelCounts[module.level] ?? 0) + 1;
      difficultyCounts[module.difficulty] = (difficultyCounts[module.difficulty] ?? 0) + 1;
      totalDuration += module.durationMinutes;
    }
    
    return {
      'total_modules': modules.length,
      'total_questions': quizResponse.summary.totalQuestions,
      'total_points': quizResponse.summary.totalPoints,
      'total_duration_minutes': totalDuration,
      'average_duration_per_module': modules.isNotEmpty ? totalDuration / modules.length : 0,
      'levels_distribution': levelCounts,
      'difficulty_distribution': difficultyCounts,
      'active_modules': modules.where((m) => m.isActive).length,
    };
  }
}
