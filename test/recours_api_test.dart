import 'package:flutter_test/flutter_test.dart';
import 'package:ena_mobile_front/services/auth_api_service.dart';
import 'package:ena_mobile_front/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  group('Test API Recours - Exploration Endpoint', () {
    
    test('Explorer l\'endpoint /api/recrutement/recours/ en GET', () async {
      print('\n🧪 TEST EXPLORATION ENDPOINT RECOURS - GET\n');
      
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

        // 2. Test de l'endpoint recours en GET
        print('\n📡 Test de l\'endpoint GET /api/recrutement/recours/');
        final recoursUrl = '${ApiConfig.baseUrl}/api/recrutement/recours/';
        print('🌐 URL complète: $recoursUrl');
        
        final response = await http.get(
          Uri.parse(recoursUrl),
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
            
            // Analyser spécifiquement pour les recours
            _analyzeRecoursData(data);
            
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
            await _tryAlternativeRecoursEndpoints(token);
          }
        }

      } catch (e) {
        print('❌ Erreur lors du test: $e');
        print('📚 Stack trace: ${StackTrace.current}');
      }
    });

    test('Tester l\'endpoint /api/recrutement/recours/ en POST', () async {
      print('\n🧪 TEST EXPLORATION ENDPOINT RECOURS - POST\n');
      
      try {
        // 1. Connexion
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

        // 2. Test POST avec des données d'exemple
        print('\n📡 Test de l\'endpoint POST /api/recrutement/recours/');
        final recoursUrl = '${ApiConfig.baseUrl}/api/recrutement/recours/';
        
        // Données d'exemple pour un recours
        final testData = {
          'motif': 'Test de l\'endpoint - Veuillez ignorer',
          'description': 'Ceci est un test automatisé pour explorer la structure de l\'API recours. Ce recours peut être supprimé.',
          'candidature': null, // Sera déterminé selon la structure attendue
          'documents': [], // Documents de justification
        };

        print('📤 Données de test: ${json.encode(testData)}');

        final response = await http.post(
          Uri.parse(recoursUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(testData),
        );

        print('🎯 Status Code: ${response.statusCode}');
        print('📄 Response Headers: ${response.headers}');
        print('📄 Response Body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          try {
            final data = json.decode(response.body);
            print('✅ Réponse POST décodée avec succès');
            print('📊 Structure de la réponse POST:');
            _printJsonStructure(data, 0);
            
            // Analyser la structure de création
            _analyzePostResponse(data);
            
          } catch (e) {
            print('❌ Erreur lors du décodage JSON POST: $e');
            print('📝 Réponse brute: ${response.body}');
          }
        } else {
          print('❌ Erreur POST: ${response.statusCode}');
          print('📝 Message d\'erreur: ${response.body}');
          
          // Analyser les erreurs pour comprendre la structure attendue
          try {
            final errorData = json.decode(response.body);
            print('\n🔍 Analyse des erreurs pour comprendre la structure:');
            _printJsonStructure(errorData, 0);
            _analyzeErrorStructure(errorData);
          } catch (e) {
            print('📝 Erreur non-JSON: ${response.body}');
          }
        }

      } catch (e) {
        print('❌ Erreur lors du test POST: $e');
      }
    });

    test('Explorer d\'autres endpoints recours disponibles', () async {
      print('\n🔍 EXPLORATION D\'AUTRES ENDPOINTS RECOURS\n');
      
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
          '/api/recrutement/recours/',
          '/api/recrutement/recours/candidat/',
          '/api/recrutement/recours/me/',
          '/api/recrutement/recours/statut/',
          '/api/recours/',
          '/api/recours/candidat/',
          '/api/candidature/recours/',
          '/api/recrutement/candidature/recours/',
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

void _analyzeRecoursData(dynamic data) {
  print('\n🎯 ANALYSE SPÉCIFIQUE POUR LES RECOURS:\n');
  
  if (data is List) {
    print('📋 Structure de liste détectée');
    print('   → Parfait pour une liste de recours existants');
    print('   → Nombre de recours: ${data.length}');
    
    if (data.isNotEmpty) {
      final firstElement = data[0];
      if (firstElement is Map) {
        print('   → Champs disponibles: ${firstElement.keys.toList()}');
        
        // Chercher des champs typiques de recours
        final recoursFields = ['motif', 'description', 'statut', 'candidature', 'date_creation', 'documents'];
        final foundFields = recoursFields.where((field) => firstElement.containsKey(field)).toList();
        
        if (foundFields.isNotEmpty) {
          print('   → Champs de recours détectés: $foundFields');
        }
      }
    }
  } else if (data is Map) {
    print('🗂️ Structure d\'objet détectée');
    print('   → Clés principales: ${data.keys.toList()}');
    
    // Chercher des structures typiques de recours
    if (data.containsKey('recours')) {
      print('   → ✅ Contient des recours !');
    }
    if (data.containsKey('candidature')) {
      print('   → ✅ Lié à une candidature !');
    }
    if (data.containsKey('statut')) {
      print('   → ✅ Contient un statut !');
    }
  }
  
  print('\n💡 RECOMMANDATIONS POUR L\'INTÉGRATION:');
  print('   1. Créer un modèle Dart Recours basé sur cette structure');
  print('   2. Ajouter un service API pour récupérer et soumettre les recours');
  print('   3. Modifier la page recours pour utiliser les données du backend');
  print('   4. Implémenter la validation et la soumission dynamique');
}

void _analyzePostResponse(dynamic data) {
  print('\n📤 ANALYSE DE LA RÉPONSE POST:');
  
  if (data is Map) {
    print('✅ Recours créé avec succès');
    print('🔑 Champs retournés: ${data.keys.toList()}');
    
    // Identifier les champs importants
    if (data.containsKey('id')) {
      print('   → ID du recours: ${data['id']}');
    }
    if (data.containsKey('statut')) {
      print('   → Statut initial: ${data['statut']}');
    }
    if (data.containsKey('date_creation')) {
      print('   → Date de création: ${data['date_creation']}');
    }
  }
}

void _analyzeErrorStructure(dynamic errorData) {
  print('\n🚨 ANALYSE DES ERREURS POUR COMPRENDRE LA STRUCTURE ATTENDUE:');
  
  if (errorData is Map) {
    errorData.forEach((field, errors) {
      if (errors is List) {
        print('   → Champ "$field": ${errors.join(', ')}');
      } else {
        print('   → Champ "$field": $errors');
      }
    });
    
    print('\n💡 Champs requis identifiés: ${errorData.keys.toList()}');
  }
}

Future<void> _tryAlternativeRecoursEndpoints(String token) async {
  final alternatives = [
    '/api/recrutement/recours',  // Sans slash final
    '/api/recours/',             // Sans recrutement
    '/api/candidature/recours/', // Via candidature
    '/api/recrutement/candidature/recours/', // Chemin alternatif
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
