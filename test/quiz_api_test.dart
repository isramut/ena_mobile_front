import 'package:flutter_test/flutter_test.dart';
import 'package:ena_mobile_front/services/auth_api_service.dart';
import 'package:ena_mobile_front/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  group('Test API Quiz - Exploration Endpoint', () {
    
    test('Explorer l\'endpoint /api/recrutement/quiz/modules/complete/', () async {
      print('\n🧪 TEST EXPLORATION ENDPOINT QUIZ\n');
      
      try {
        // 1. Connexion avec les credentials fournis
        print('🔐 Connexion avec isramut7@gmail.com...');
        final loginResult = await AuthApiService.login(
          email: 'isramut7@gmail.com',
          password: 'Isr@mut7',
        );

        if (loginResult['success'] != true) {
          print('❌ Échec de la connexion: ${loginResult['message']}');
          print('📝 Détails: ${loginResult}');
          return;
        }

        final token = loginResult['data']['access'];
        print('✅ Connexion réussie, token obtenu');
        print('🎯 Token: ${token.substring(0, 50)}...');

        // 2. Test de l'endpoint quiz spécifique
        print('\n📡 Test de l\'endpoint /api/recrutement/quiz/modules/complete/');
        final quizUrl = '${ApiConfig.baseUrl}/api/recrutement/quiz/modules/complete/';
        print('🌐 URL complète: $quizUrl');
        
        final response = await http.get(
          Uri.parse(quizUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        print('🎯 Status Code: ${response.statusCode}');
        print('📄 Response Headers: ${response.headers}');
        print('📄 Response Body: ${response.body}');

        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);
            print('✅ Réponse JSON décodée avec succès');
            print('📊 Type de données: ${data.runtimeType}');
            print('📊 Structure des données:');
            _printJsonStructure(data, 0);
            
            // Analyser spécifiquement pour le quiz
            _analyzeQuizData(data);
            
          } catch (e) {
            print('❌ Erreur lors du décodage JSON: $e');
            print('📝 Réponse brute: ${response.body}');
          }
        } else {
          print('❌ Erreur API: ${response.statusCode}');
          print('📝 Message d\'erreur: ${response.body}');
          
          // Si 404, essayons d'autres variations de l'endpoint
          if (response.statusCode == 404) {
            print('\n🔍 Endpoint non trouvé, essayons des variations...');
            await _tryAlternativeEndpoints(token);
          }
        }

      } catch (e) {
        print('❌ Erreur lors du test: $e');
        print('📚 Stack trace: ${StackTrace.current}');
      }
    });

    test('Explorer d\'autres endpoints quiz disponibles', () async {
      print('\n🔍 EXPLORATION D\'AUTRES ENDPOINTS QUIZ\n');
      
      try {
        // Connexion
        final loginResult = await AuthApiService.login(
          email: 'isramut7@gmail.com',
          password: 'Isr@mut7',
        );

        if (loginResult['success'] != true) {
          print('❌ Échec de la connexion');
          return;
        }

        final token = loginResult['data']['access'];
        print('✅ Connexion réussie');

        // Liste des endpoints à tester
        final endpoints = [
          '/api/recrutement/quiz/subjects/',
          '/api/recrutement/quiz/modules/',
          '/api/recrutement/quiz/modules/progress/',
          '/api/recrutement/quiz/candidate/modules/',
          '/api/recrutement/quiz/modules/complete/',
          '/api/recrutement/quiz/',
          '/api/quiz/',
          '/api/quiz/modules/',
          '/api/quiz/questions/',
        ];

        for (final endpoint in endpoints) {
          print('\n📡 Test de $endpoint');
          final url = '${ApiConfig.baseUrl}$endpoint';
          
          try {
            final response = await http.get(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            );

            print('   Status: ${response.statusCode}');
            
            if (response.statusCode == 200) {
              try {
                final data = json.decode(response.body);
                print('   ✅ Succès - Type: ${data.runtimeType}');
                
                if (data is List) {
                  print('   📋 Liste de ${data.length} éléments');
                  if (data.isNotEmpty) {
                    print('   🔍 Premier élément: ${data[0] is Map ? (data[0] as Map).keys.toList() : data[0].runtimeType}');
                    if (data[0] is Map) {
                      _printJsonStructure(data[0], 2);
                    }
                  }
                } else if (data is Map) {
                  print('   🗂️ Objet avec clés: ${data.keys.toList()}');
                  _printJsonStructure(data, 2);
                }
              } catch (e) {
                print('   ⚠️ Erreur JSON: $e');
                print('   📝 Réponse brute: ${response.body.substring(0, 200)}...');
              }
            } else if (response.statusCode == 404) {
              print('   ❌ Non trouvé (404)');
            } else {
              print('   ❌ Erreur: ${response.statusCode} - ${response.body.substring(0, 100)}');
            }
          } catch (e) {
            print('   ⚠️ Exception: $e');
          }
          
          // Petite pause entre les requêtes
          await Future.delayed(Duration(milliseconds: 100));
        }

      } catch (e) {
        print('❌ Erreur générale: $e');
      }
    });
  });
}

void _printJsonStructure(dynamic data, int indent) {
  final spaces = '  ' * indent;
  
  if (data is Map) {
    print('${spaces}📦 Map avec ${data.length} clés:');
    data.forEach((key, value) {
      if (value is Map || value is List) {
        print('${spaces}  🔑 $key: ${value.runtimeType}');
        if (indent < 3) { // Limiter la profondeur
          _printJsonStructure(value, indent + 2);
        }
      } else {
        print('${spaces}  🔑 $key: ${value.runtimeType} = $value');
      }
    });
  } else if (data is List) {
    print('${spaces}📋 Liste de ${data.length} éléments');
    if (data.isNotEmpty && indent < 3) {
      print('${spaces}  🔍 Premier élément:');
      _printJsonStructure(data[0], indent + 1);
    }
  } else {
    print('${spaces}📝 Valeur: $data (${data.runtimeType})');
  }
}

void _analyzeQuizData(dynamic data) {
  print('\n🎯 ANALYSE SPÉCIFIQUE POUR LE QUIZ:\n');
  
  if (data is List) {
    print('📋 Structure de liste détectée');
    print('   → Parfait pour une liste de modules/questions');
    print('   → Nombre d\'éléments: ${data.length}');
    
    if (data.isNotEmpty) {
      final firstElement = data[0];
      if (firstElement is Map) {
        print('   → Champs disponibles: ${firstElement.keys.toList()}');
        
        // Chercher des champs typiques de quiz
        final quizFields = ['question', 'questions', 'title', 'name', 'module', 'subject', 'options', 'answers'];
        final foundFields = quizFields.where((field) => firstElement.containsKey(field)).toList();
        
        if (foundFields.isNotEmpty) {
          print('   → Champs de quiz détectés: $foundFields');
        }
      }
    }
  } else if (data is Map) {
    print('🗂️ Structure d\'objet détectée');
    print('   → Clés principales: ${data.keys.toList()}');
    
    // Chercher des structures typiques de quiz
    if (data.containsKey('modules')) {
      print('   → ✅ Contient des modules !');
    }
    if (data.containsKey('questions')) {
      print('   → ✅ Contient des questions !');
    }
    if (data.containsKey('quiz')) {
      print('   → ✅ Contient un quiz !');
    }
  }
  
  print('\n💡 RECOMMANDATIONS POUR L\'INTÉGRATION:');
  print('   1. Créer un modèle Dart basé sur cette structure');
  print('   2. Ajouter un service API pour récupérer les données');
  print('   3. Modifier la page quiz pour utiliser les données du backend');
  print('   4. Implémenter le cache local pour les performances');
}

Future<void> _tryAlternativeEndpoints(String token) async {
  final alternatives = [
    '/api/recrutement/quiz/modules/complete',  // Sans slash final
    '/api/recrutement/quiz/modules/',          // Module parent
    '/api/recrutement/quiz/complete/',         // Sans modules
    '/api/quiz/modules/complete/',             // Sans recrutement
  ];
  
  for (final endpoint in alternatives) {
    print('🔍 Essai: $endpoint');
    final url = '${ApiConfig.baseUrl}$endpoint';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        print('   ✅ TROUVÉ ! Status: ${response.statusCode}');
        print('   📄 Réponse: ${response.body.substring(0, 200)}...');
        return;
      } else {
        print('   ❌ Status: ${response.statusCode}');
      }
    } catch (e) {
      print('   ⚠️ Erreur: $e');
    }
  }
}
