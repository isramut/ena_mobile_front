import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'aggressive_cache_service.dart';

/// Service pour gérer les appels API d'authentification
class AuthApiService {
  /// Méthode utilitaire pour gérer les réponses HTTP
  static Map<String, dynamic> _handleHttpResponse(http.Response response) {
    // Vérifier le content-type de la réponse
    final contentType = response.headers['content-type'];
    if (contentType != null && !contentType.contains('application/json')) {
      // Le serveur n'a pas renvoyé du JSON
      return {
        'success': false,
        'error': 'Erreur serveur (${response.statusCode})',
        'details': 'Le serveur a renvoyé une réponse non-JSON. Vérifiez l\'URL et le serveur.',
      };
    }

    try {
      final data = json.decode(response.body);
      return data;
    } catch (jsonError) {
      // Erreur de parsing JSON
      return {
        'success': false,
        'error': 'Réponse serveur invalide',
        'details': 'Le serveur a renvoyé une réponse qui n\'est pas un JSON valide. Code: ${response.statusCode}',
      };
    }
  }

  /// Traitement des réponses HTTP pour les appels API
  static Map<String, dynamic> _processHttpResponse(http.Response response, String apiName) {
    final data = _handleHttpResponse(response);
    
    if (data.containsKey('success') && data['success'] == false) {
      // Erreur de parsing déjà gérée
      return data;
    }
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': data,
      };
    } else {
      return {
        'success': false,
        'error': data['message'] ?? data['error'] ?? 'Erreur lors de l\'opération $apiName',
        'details': data,
      };
    }
  }

  /// Inscription d'un nouvel utilisateur
  static Future<Map<String, dynamic>> register({
    required String firstName,
    String middleName = '',
    required String lastName,
    required String email,
    required String password,
    String telephone = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'first_name': firstName,
          'middle_name': middleName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'telephone': telephone,
        }),
      );

      final data = _handleHttpResponse(response);
      
      // Si la méthode utilitaire a détecté une erreur, la retourner
      if (data['success'] == false) {
        return data;
      }
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? data['error'] ?? 'Erreur lors de l\'inscription',
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

  /// Vérification OTP pour inscription ou mot de passe oublié
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.otpUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'otp': otp,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? data['error'] ?? 'Code OTP invalide',
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

  /// Connexion utilisateur
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = _handleHttpResponse(response);
      
      // Si la méthode utilitaire a détecté une erreur, la retourner
      if (data['success'] == false) {
        return data;
      }
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
          'token': data['access'] ?? data['token'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? data['error'] ?? 'Email ou mot de passe incorrect',
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

  /// Demande de réinitialisation de mot de passe
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      print("🔵 forgotPassword: Envoi de la requête vers ${ApiConfig.forgotPasswordUrl}");
      print("🔵 forgotPassword: Email = $email");
      
      final response = await http.post(
        Uri.parse(ApiConfig.forgotPasswordUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
      );

      print("🔵 forgotPassword: Status code = ${response.statusCode}");
      print("🔵 forgotPassword: Response body = ${response.body}");

      return _processHttpResponse(response, 'forgotPassword');
    } catch (e) {
      print("🔴 forgotPassword: Erreur = $e");
      return {
        'success': false,
        'error': 'Erreur de connexion au serveur',
        'details': e.toString(),
      };
    }
  }

  /// Renvoi du code OTP (inscription ou mot de passe oublié)
  static Future<Map<String, dynamic>> resendOtp({
    required String email,
    String action = 'registration', // 'registration' ou 'reset_password'
  }) async {
    try {
      print("🔵 resendOtp: Envoi de la requête vers ${ApiConfig.otpUrl}");
      print("🔵 resendOtp: Email = $email, Action = $action");
      
      final response = await http.post(
        Uri.parse(ApiConfig.otpUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'action': action,
        }),
      );

      print("🔵 resendOtp: Status code = ${response.statusCode}");
      print("🔵 resendOtp: Response body = ${response.body}");

      return _processHttpResponse(response, 'resendOtp');
    } catch (e) {
      print("🔴 resendOtp: Erreur = $e");
      return {
        'success': false,
        'error': 'Erreur de connexion au serveur',
        'details': e.toString(),
      };
    }
  }

  /// Réinitialisation du mot de passe
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resetPasswordUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': newPassword, // "password" selon votre spécification
          'otp': otp,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? data['error'] ?? 'Erreur lors de la réinitialisation',
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

  /// Récupération des informations de l'utilisateur connecté
  static Future<Map<String, dynamic>> getUserInfo({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.userInfoUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? data['error'] ?? 'Erreur lors de la récupération des informations',
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

  /// Mise à jour du profil candidat (avec photo optionnelle)
  static Future<Map<String, dynamic>> updateUserInfo({
    required String token,
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? telephone,
    String? adressePhysique,
    String? profilePicturePath, // Nouveau paramètre pour la photo
  }) async {
    try {
      // Si une photo est fournie, utiliser MultipartRequest
      if (profilePicturePath != null) {
        var request = http.MultipartRequest(
          'PATCH',
          Uri.parse(ApiConfig.profilCandidatUrl),
        );

        request.headers['Authorization'] = 'Bearer $token';
        
        // Mapper les champs vers l'API profil-candidat
        if (firstName != null) request.fields['prenom'] = firstName;
        if (middleName != null) request.fields['postnom'] = middleName;
        if (lastName != null) request.fields['nom'] = lastName;
        if (adressePhysique != null) request.fields['adresse_physique'] = adressePhysique;
        // Note: email et telephone ne sont pas dans l'API profil-candidat
        
        // Ajouter le fichier photo
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo',
            profilePicturePath,
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        final data = json.decode(response.body);

        if (response.statusCode == 200) {
          return {
            'success': true,
            'data': data,
          };
        } else {
          return {
            'success': false,
            'error': data['message'] ?? data['error'] ?? 'Erreur lors de la mise à jour',
            'details': data,
          };
        }
      } else {
        // Pas de photo - utiliser la méthode JSON classique
        final Map<String, dynamic> updateData = {};
        if (firstName != null) updateData['prenom'] = firstName;
        if (middleName != null) updateData['postnom'] = middleName;
        if (lastName != null) updateData['nom'] = lastName;
        if (adressePhysique != null) updateData['adresse_physique'] = adressePhysique;
        // Note: email et telephone ne sont pas dans l'API profil-candidat

        final response = await http.patch(
          Uri.parse(ApiConfig.profilCandidatUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(updateData),
        );

        final data = json.decode(response.body);
        
        if (response.statusCode == 200) {
          return {
            'success': true,
            'data': data,
          };
        } else {
          return {
            'success': false,
            'error': data['message'] ?? data['error'] ?? 'Erreur lors de la mise à jour',
            'details': data,
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion au serveur',
        'details': e.toString(),
      };
    }
  }

  /// Récupération des notifications de l'utilisateur
  static Future<Map<String, dynamic>> getUserNotifications({
    required String token,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.notificationsUrl}?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? data['error'] ?? 'Erreur lors de la récupération des notifications',
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

  /// Récupérer les notifications de l'utilisateur
  static Future<Map<String, dynamic>> getNotifications({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/notifications/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? data['error'] ?? 'Erreur lors de la récupération des notifications',
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

  /// Marquer une notification comme lue
  static Future<Map<String, dynamic>> markNotificationAsRead({
    required String token,
    required String notificationId,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/users/notifications/$notificationId/read/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? data['error'] ?? 'Erreur lors du marquage de la notification',
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

  /// Marquer toutes les notifications comme lues
  static Future<Map<String, dynamic>> markAllNotificationsAsRead({
    required String token,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/users/notifications/mark-all-read/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? data['error'] ?? 'Erreur lors de la mise à jour des notifications',
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

  /// Récupérer le statut et les détails de la candidature de l'utilisateur
  static Future<Map<String, dynamic>> getCandidatureStatut({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/recrutement/candidature/statut/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? data['error'] ?? 'Erreur lors de la récupération du statut de candidature',
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

  /// Changement de mot de passe pour l'utilisateur connecté
  static Future<Map<String, dynamic>> selfResetPassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.selfResetPasswordUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Mot de passe modifié avec succès',
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? data['error'] ?? 'Erreur lors du changement de mot de passe',
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

  /// Mise à jour des informations utilisateur (email, téléphone) via l'endpoint user-info
  static Future<Map<String, dynamic>> updateUserContactInfo({
    required String token,
    String? email,
    String? telephone,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      if (email != null) updateData['email'] = email;
      if (telephone != null) updateData['telephone'] = telephone;

      // Si aucun champ à mettre à jour, retourner succès
      if (updateData.isEmpty) {
        return {'success': true, 'data': {}};
      }

      final response = await http.patch(
        Uri.parse(ApiConfig.userInfoUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? data['error'] ?? 'Erreur lors de la mise à jour des informations de contact',
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

  /// 🚀 NOUVELLE MÉTHODE : Chargement parallélisé de toutes les données dashboard
  static Future<Map<String, dynamic>> loadDashboardDataParallel({
    required String token,
  }) async {
    try {
      print('🚀 Starting parallel dashboard data loading...');
      final stopwatch = Stopwatch()..start();

      // Lancer tous les appels en parallèle
      final results = await Future.wait([
        getUserInfo(token: token),
        getUserNotifications(token: token, limit: 10),
        getCandidatureStatut(token: token),
      ], eagerError: false); // Continue même si une erreur survient

      stopwatch.stop();
      print('🚀 Parallel loading completed in ${stopwatch.elapsedMilliseconds}ms');

      return {
        'success': true,
        'data': {
          'userInfo': results[0],
          'notifications': results[1],
          'candidatureStatus': results[2],
        },
        'loadTime': stopwatch.elapsedMilliseconds,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur lors du chargement parallèle des données',
        'details': e.toString(),
      };
    }
  }

  /// 🚀 NOUVELLE MÉTHODE : Chargement avec cache agressif + parallélisation
  static Future<Map<String, dynamic>> loadDashboardDataWithCache({
    required String token,
    bool forceRefresh = false,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // 1️⃣ Vérifier le cache d'abord (affichage immédiat)
      if (!forceRefresh) {
        final cachedData = await _loadFromCache();
        if (cachedData != null) {
          print('⚡ Loaded from cache in ${stopwatch.elapsedMilliseconds}ms');
          
          // Lancer la mise à jour en arrière-plan
          _updateCacheInBackground(token);
          
          return {
            'success': true,
            'data': cachedData,
            'source': 'cache',
            'loadTime': stopwatch.elapsedMilliseconds,
          };
        }
      }

      // 2️⃣ Pas de cache valide, charger depuis l'API en parallèle
      final apiResult = await loadDashboardDataParallel(token: token);
      
      // 3️⃣ Mettre en cache pour la prochaine fois
      if (apiResult['success'] == true) {
        await _saveToCacheAsync(apiResult['data']);
      }

      stopwatch.stop();
      return {
        ...apiResult,
        'source': 'api',
        'loadTime': stopwatch.elapsedMilliseconds,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur lors du chargement avec cache',
        'details': e.toString(),
      };
    }
  }

  /// 🚀 NOUVELLE MÉTHODE : Pré-chargement pendant l'authentification
  static Future<void> preloadDuringAuth({
    required String token,
  }) async {
    try {
      print('🔄 Starting preload during authentication...');
      
      // Charger les données statiques qui changent rarement
      final preloadFutures = [
        // Données utilisateur (change rarement)
        getUserInfo(token: token),
        // Statut candidature (change occasionnellement)  
        getCandidatureStatut(token: token),
      ];

      // Lancer en parallèle sans attendre
      Future.wait(preloadFutures).then((results) async {
        // Sauvegarder en cache
        if (results[0]['success'] == true) {
          await AggressiveCacheService.cacheUserInfo(results[0]['data']);
        }
        if (results[1]['success'] == true) {
          await AggressiveCacheService.cacheCandidatureStatus(results[1]['data']);
        }
        print('✅ Preload completed and cached');
      }).catchError((e) {
        print('⚠️ Preload failed: $e');
      });
      
    } catch (e) {
      print('❌ Preload error: $e');
    }
  }

  /// Méthode utilitaire pour charger depuis le cache
  static Future<Map<String, dynamic>?> _loadFromCache() async {
    try {
      final cacheData = await AggressiveCacheService.getAllDashboardCache();
      
      // Vérifier si on a au moins les données essentielles
      if (cacheData['userInfo'] != null) {
        return {
          'userInfo': {'success': true, 'data': cacheData['userInfo']},
          'notifications': cacheData['notifications'] != null 
            ? {'success': true, 'data': cacheData['notifications']}
            : {'success': false, 'error': 'No cached notifications'},
          'candidatureStatus': cacheData['candidatureStatus'] != null
            ? {'success': true, 'data': cacheData['candidatureStatus']}
            : {'success': false, 'error': 'No cached candidature status'},
        };
      }
      
      return null;
    } catch (e) {
      print('❌ Cache load error: $e');
      return null;
    }
  }

  /// Méthode utilitaire pour sauvegarder en cache (async)
  static Future<void> _saveToCacheAsync(Map<String, dynamic> data) async {
    try {
      final futures = <Future<void>>[];
      
      if (data['userInfo']?['success'] == true) {
        futures.add(AggressiveCacheService.cacheUserInfo(data['userInfo']['data']));
      }
      
      if (data['notifications']?['success'] == true) {
        futures.add(AggressiveCacheService.cacheNotifications(data['notifications']['data']));
      }
      
      if (data['candidatureStatus']?['success'] == true) {
        futures.add(AggressiveCacheService.cacheCandidatureStatus(data['candidatureStatus']['data']));
      }

      await Future.wait(futures);
      print('✅ Data cached successfully');
    } catch (e) {
      print('⚠️ Cache save error: $e');
    }
  }

  /// Méthode utilitaire pour mettre à jour le cache en arrière-plan
  static void _updateCacheInBackground(String token) {
    // Utiliser un isolate ou simplement un Future non-attendu
    Future.delayed(Duration(milliseconds: 100), () async {
      try {
        print('🔄 Background cache update started...');
        final result = await loadDashboardDataParallel(token: token);
        
        if (result['success'] == true) {
          await _saveToCacheAsync(result['data']);
          print('✅ Background cache update completed');
        }
      } catch (e) {
        print('⚠️ Background cache update failed: $e');
      }
    });
  }
}
