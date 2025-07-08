import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/program_event.dart';

/// Service pour gérer les appels API des événements du programme
class ProgramEventsApiService {
  
  /// Récupère tous les événements du programme
  static Future<Map<String, dynamic>> getProgramEvents({
    String? token,
  }) async {
    try {
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      // Ajouter le token d'authentification si fourni
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse(ApiConfig.programEventsUrl),
        headers: headers,
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        // Convertir les données en liste d'événements
        List<ProgramEvent> events = [];
        
        if (data is List) {
          events = data.map((eventJson) => ProgramEvent.fromJson(eventJson as Map<String, dynamic>)).toList();
        } else if (data is Map && data['results'] != null) {
          // Si les données sont paginées
          final results = data['results'] as List;
          events = results.map((eventJson) => ProgramEvent.fromJson(eventJson as Map<String, dynamic>)).toList();
        }
        
        return {
          'success': true,
          'data': events,
          'raw_data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? data['error'] ?? 'Erreur lors de la récupération des événements',
          'details': data,
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

  /// Récupère les événements actifs et à venir
  static Future<Map<String, dynamic>> getUpcomingEvents({
    String? token,
    int? limit,
  }) async {
    try {
      final result = await getProgramEvents(token: token);
      
      if (result['success'] == true) {
        final List<ProgramEvent> allEvents = result['data'] as List<ProgramEvent>;
        
        // Filtrer les événements actifs et à venir
        final upcomingEvents = allEvents
            .where((event) => event.isActive && event.isUpcoming)
            .toList();
        
        // Trier par date de début (les plus récents en premier)
        upcomingEvents.sort((a, b) => a.startDatetime.compareTo(b.startDatetime));
        
        // Limiter le nombre d'événements si demandé
        final limitedEvents = limit != null && limit > 0 
            ? upcomingEvents.take(limit).toList()
            : upcomingEvents;
        
        return {
          'success': true,
          'data': limitedEvents,
          'total_count': upcomingEvents.length,
        };
      } else {
        return result;
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur lors du filtrage des événements',
        'details': e.toString(),
      };
    }
  }

  /// Récupère les 3 derniers événements à venir pour la home
  static Future<Map<String, dynamic>> getHomeEvents({String? token}) async {
    return getUpcomingEvents(token: token, limit: 3);
  }
}
