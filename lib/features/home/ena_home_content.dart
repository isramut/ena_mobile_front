import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import '../../widgets/ena_twitter_widget.dart';
import '../../services/auth_api_service.dart';
import '../../services/program_events_api_service.dart';
import '../../services/profile_update_notification_service.dart';
import '../../utils/app_navigator.dart';
import '../../services/image_cache_service.dart';
import '../../models/user_info.dart';
import '../../models/candidature_info.dart';
import '../../models/notification.dart';
import '../../models/program_event.dart';
import '../../models/recours_models.dart';
import '../../widgets/program_events_popup.dart';
import '../../features/recours/recours_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import 'package:intl/intl.dart';

class AccueilScreen extends StatefulWidget {
  final Function(int)? onMenuChanged;

  const AccueilScreen({super.key, this.onMenuChanged});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  UserInfo? _userInfo;
  CandidatureInfo? _candidatureInfo;
  List<NotificationModel> _notifications = [];
  List<ProgramEvent> _programEvents = [];
  bool _isLoading = true;
  bool _hasApplied = false;
  bool _isLoadingEvents = false;
  HasSubmittedRecours? _recoursInfo;

  @override
  void initState() {
    super.initState();
    _loadUserInfoWithCache();
  }

  /// � PULL-TO-REFRESH : Recharge complète des données et invalidation du cache
  Future<void> _refreshHomeData() async {
    if (!mounted) return;
    
    try {
      // 1️⃣ Invalider tous les caches
      await _invalidateAllCaches();
      
      // 2️⃣ Notifier le header via ProfileUpdateNotificationService pour recharger l'avatar et les données utilisateur
      ProfileUpdateNotificationService().notifyProfileUpdated(
        photoUpdated: true,
        personalInfoUpdated: true,
        contactInfoUpdated: true,
      );
      
      // 3️⃣ Recharger toutes les données depuis l'API (forcer le refresh)
      await _loadUserInfoWithCache(forceRefresh: true);
      
    } catch (e) {
      
      // En cas d'erreur, essayer de recharger normalement
      await _loadUserInfoWithCache();
    }
  }
  
  /// Invalide tous les caches pour forcer un rechargement complet
  Future<void> _invalidateAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Supprimer les caches principaux
      await Future.wait([
        prefs.remove('user_info_cache'),
        prefs.remove('notifications_cache'),
        prefs.remove('candidature_cache'),
        prefs.remove('program_events_cache'),
      ]);
      
      // Invalider le cache d'images pour recharger les photos de profil
      ImageCacheService.invalidateUserImageCache();
    } catch (e) {
    }
  }

  /// �🚀 CHARGEMENT SYNCHRONISÉ : Cache agressif + données en parallèle
  Future<void> _loadUserInfoWithCache({bool forceRefresh = false}) async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // 1️⃣ AFFICHAGE IMMÉDIAT DEPUIS LE CACHE (sauf si refresh forcé)
      if (!forceRefresh) {
        await _showFromCache();
      }

      // 2️⃣ CHARGEMENT PARALLÈLE DES DONNÉES UTILISATEUR ET NOTIFICATIONS
      final results = await Future.wait([
        AuthApiService.getUserInfo(token: token),
        AuthApiService.getUserNotifications(token: token),
        ProgramEventsApiService.getRecentEventsForHome(token: token),
      ]);

      if (!mounted) return;

      // 3️⃣ TRAITEMENT DES RÉSULTATS
      final userInfoResult = results[0];
      final notificationsResult = results[1];
      final eventsResult = results[2];

      // Traitement des données utilisateur
      if (userInfoResult['success'] == true && userInfoResult['data'] != null) {
        final userInfo = UserInfo.fromJson(userInfoResult['data']);
        
        // 4️⃣ CHARGEMENT CONDITIONNEL DE LA CANDIDATURE
        CandidatureInfo? candidatureInfo;
        if (userInfo.hasApplied) {
          final candidatureResult = await AuthApiService.getCandidatureStatut(token: token);
          
          if (candidatureResult['success'] == true && candidatureResult['data'] != null) {
            final candidature = CandidatureInfo.fromJson(candidatureResult['data']);
            // JOINTURE : Vérifier que l'utilisateur connecté correspond au candidat de la candidature
            if (candidature.candidat == userInfo.id) {
              candidatureInfo = candidature;
            } else {
            }
          } else {
          }
        } else {
        }

        // Notifications
        List<NotificationModel> notifications = [];
        if (notificationsResult['success'] == true && notificationsResult['data'] != null) {
          // Utiliser la méthode de traitement des notifications
          await _processNotifications(notificationsResult['data']);
          notifications = _notifications; // Récupérer les notifications traitées
        }

        // Événements du programme
        List<ProgramEvent> programEvents = [];
        if (eventsResult['success'] == true && eventsResult['data'] != null) {
          programEvents = eventsResult['data'] as List<ProgramEvent>;
        }

        // Informations de recours si l'utilisateur en a soumis un
        HasSubmittedRecours? recoursInfo;
        if (userInfo.hasSubmittedRecours) {
          final recoursResult = await AuthApiService.hasSubmittedRecours();
          if (recoursResult['success'] == true && recoursResult['data'] != null) {
            recoursInfo = recoursResult['data'] as HasSubmittedRecours;
          }
        }

        // 5️⃣ MISE À JOUR SYNCHRONE DE TOUTE L'INTERFACE
        setState(() {
          _userInfo = userInfo;
          _hasApplied = userInfo.hasApplied;
          _candidatureInfo = candidatureInfo;
          _notifications = notifications;
          _programEvents = programEvents;
          _recoursInfo = recoursInfo;
          _isLoading = false;
        });

        // Mettre à jour le cache
        await _updateCache(userInfoResult['data'], notifications, candidatureInfo, programEvents);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // Fallback: essayer de charger les données une par une
      await _loadUserInfoFallback();
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Méthode de fallback en cas d'échec du cache
  Future<void> _loadUserInfoFallback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        // Étape 1: Récupérer les informations utilisateur
        final userResult = await AuthApiService.getUserInfo(token: token);
        
        if (mounted && userResult['success'] == true && userResult['data'] != null) {
          final userInfo = UserInfo.fromJson(userResult['data']);
          final hasApplied = userInfo.hasApplied;
          
          setState(() {
            _userInfo = userInfo;
            _hasApplied = hasApplied;
          });

          // Étape 2: Récupérer les notifications
          await _loadNotifications(token);

          // Étape 2.5: Charger les événements du programme
          await _loadProgramEvents(token);

          // Étape 3: Si l'utilisateur a postulé, récupérer les détails de candidature
          if (hasApplied) {
            final candidatureResult = await AuthApiService.getCandidatureStatut(token: token);
            
            if (mounted && candidatureResult['success'] == true && candidatureResult['data'] != null) {
              final candidature = CandidatureInfo.fromJson(candidatureResult['data']);
              
              // JOINTURE : Vérifier que l'utilisateur connecté correspond au candidat de la candidature
              if (candidature.candidat == userInfo.id) {
                setState(() {
                  _candidatureInfo = candidature;
                });
                
                // Étape 4: Si l'utilisateur a soumis un recours, récupérer les détails
                if (userInfo.hasSubmittedRecours) {
                  final recoursResult = await AuthApiService.hasSubmittedRecours();
                  if (mounted && recoursResult['success'] == true && recoursResult['data'] != null) {
                    setState(() {
                      _recoursInfo = recoursResult['data'] as HasSubmittedRecours;
                    });
                  }
                }
                
                setState(() => _isLoading = false);
              } else {
                setState(() => _isLoading = false);
              }
            } else {
              setState(() => _isLoading = false);
            }
          } else {
            setState(() => _isLoading = false);
          }
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadNotifications(String token) async {
    try {
      final notificationsResult = await AuthApiService.getNotifications(token: token);
      
      if (mounted && notificationsResult['success'] == true && notificationsResult['data'] != null) {
        // Utiliser la méthode de traitement des notifications
        await _processNotifications(notificationsResult['data']);
      }
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
  }

  Future<void> _loadProgramEvents(String token) async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingEvents = true;
    });
    
    try {
      final result = await ProgramEventsApiService.getRecentEventsForHome(token: token);
      
      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _programEvents = result['data'] as List<ProgramEvent>;
            _isLoadingEvents = false;
          });
        } else {
          setState(() {
            _programEvents = [];
            _isLoadingEvents = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _programEvents = [];
          _isLoadingEvents = false;
        });
      }
    }
  }

  String _getGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour >= 6 && hour < 18) {
      return "Bonjour";
    } else {
      return "Bonsoir";
    }
  }

  String _getUserDisplayName() {
    if (_userInfo != null) {
      final firstName = _userInfo!.firstName.isNotEmpty ? _userInfo!.firstName : '';
      final lastName = _userInfo!.lastName.isNotEmpty ? _userInfo!.lastName : '';
      
      if (firstName.isNotEmpty && lastName.isNotEmpty) {
        return '$firstName $lastName';
      } else if (firstName.isNotEmpty) {
        return firstName;
      } else if (lastName.isNotEmpty) {
        return lastName;
      }
    }
    return 'Utilisateur';
  }

  // Méthodes utilitaires pour la gestion dynamique de la candidature selon les spécifications métier
  double _getProgressValue() {
    // Si recours traité : progressbar = 100%
    if (_recoursInfo?.traite == true) {
      return 1.0;
    }
    
    // Si has_applied = false : progressbar = 0%
    if (!_hasApplied) {
      return 0.0;
    }

    // Si has_applied = true mais pas de candidature trouvée (attente du chargement)
    if (_candidatureInfo == null) {
      return 0.0;
    }

    // Si has_applied = true et candidature récupérée, on se base sur le statut
    switch (_candidatureInfo!.statut) {
      case 'envoye':
        return 0.2; // 20%
      case 'en_traitement':
        return 0.7; // 70%
      case 'valide':
      case 'rejete':
        // Afficher 100% uniquement si can_publish est true
        if (_userInfo?.canPublish == true) {
          return 1.0; // 100%
        } else {
          return 0.7; // Reste à 70% si can_publish est false
        }
      default:
        return 0.2; // Par défaut 20%
    }
  }

  String _getProgressText() {
    final progress = _getProgressValue();
    return '${(progress * 100).toInt()}%';
  }

  Color _getProgressTextColor() {
    // Si recours traité, afficher le texte en gris
    if (_recoursInfo?.traite == true) {
      return Colors.grey;
    }
    // Sinon, garder la couleur blanche par défaut
    return Colors.white;
  }

  Color _getProgressColor() {
    // Si recours traité : couleur grise
    if (_recoursInfo?.traite == true) {
      return Colors.grey;
    }
    
    // Si has_applied = false ou pas de candidature
    if (!_hasApplied || _candidatureInfo == null) return Colors.white;
    
    switch (_candidatureInfo!.statut) {
      case 'valide':
        // Afficher vert uniquement si can_publish est true
        if (_userInfo?.canPublish == true) {
          return const Color(0xFF27AE60); // Vert pour validé
        }
        return Colors.white; // Blanc si can_publish est false
      case 'rejete':
        // Afficher rouge uniquement si can_publish est true
        if (_userInfo?.canPublish == true) {
          return const Color(0xFFCD1719); // Rouge pour rejeté
        }
        return Colors.white; // Blanc si can_publish est false
      default:
        return Colors.white; // Blanc par défaut
    }
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  String? _getVerificationEndDate() {
    if (_candidatureInfo?.dateCreation != null) {
      final endDate = _candidatureInfo!.dateCreation.add(const Duration(days: 20));
      return _formatDate(endDate);
    }
    return null;
  }

  String? _getCurrentStepText() {
    // Si has_applied = false : afficher bouton "Soumettre ma candidature"
    if (!_hasApplied) return null;
    
    // Si has_applied = true mais pas de candidature trouvée
    if (_candidatureInfo == null) return "Étape en cours : Vérification des documents";
    
    switch (_candidatureInfo!.statut) {
      case 'envoye':
        return "Étape en cours : Vérification des documents";
      case 'en_traitement':
        return "Étape en cours : Vérification des documents";
      case 'valide':
        // Afficher message uniquement si can_publish est true
        if (_userInfo?.canPublish == true) {
          return null; // Message de félicitation à la place
        }
        return "Étape en cours : Vérification des documents"; // Si can_publish est false
      case 'rejete':
        // Afficher message uniquement si can_publish est true
        if (_userInfo?.canPublish == true) {
          return null; // Message de rejet à la place
        }
        return "Étape en cours : Vérification des documents"; // Si can_publish est false
      default:
        return "Étape en cours : Vérification des documents";
    }
  }

  String? _getSpecialMessage() {
    // Messages spéciaux selon le statut
    if (!_hasApplied || _candidatureInfo == null) return null;
    
    switch (_candidatureInfo!.statut) {
      case 'valide':
        // Afficher le message de validation uniquement si can_publish est true
        if (_userInfo?.canPublish == true) {
          return "🎉 Félicitations ! Votre candidature a été jugée valide. Vous serez contacté prochainement pour la suite de la procédure.";
        }
        return null; // Si can_publish est false, pas de message spécial
      case 'rejete':
        // Afficher le message de rejet uniquement si can_publish est true ET que l'utilisateur n'a pas soumis de recours
        if (_userInfo?.canPublish == true && !(_userInfo?.hasSubmittedRecours ?? false)) {
          return "Votre dossier de candidature n'a malheureusement pas répondu à toutes les exigences requises. Nous vous remercions de votre intérêt et de la confiance accordée à l'ENA. Un email vous sera envoyé vous notifiant les raisons du rejet et vous pouvez déposer un recours endéans 48h.";
        }
        return null; // Si can_publish est false ou recours déjà soumis, pas de message spécial
      default:
        return null;
    }
  }

  void _navigateToRecours() {
    AppNavigator.push(
      context,
      const RecoursScreen(),
    );
  }

  // Méthodes pour les notifications
  NotificationModel? get _latestAlertNotification {
    final alertNotifications = _notifications.where((n) => n.isAlert).toList();
    return alertNotifications.isNotEmpty ? alertNotifications.first : null;
  }

  NotificationModel? get _latestNonAlertNotification {
    final nonAlertNotifications = _notifications.where((n) => !n.isAlert).toList();
    return nonAlertNotifications.isNotEmpty ? nonAlertNotifications.first : null;
  }

  Future<void> _markNotificationAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        final result = await AuthApiService.markNotificationAsRead(
          token: token,
          notificationId: notification.id,
        );

        if (result['success'] == true) {
          setState(() {
            final index = _notifications.indexWhere((n) => n.id == notification.id);
            if (index != -1) {
              _notifications[index] = notification.copyWith(
                isRead: true,
                readAt: DateTime.now().toIso8601String(),
              );
            }
          });
        }
      }
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
  }

  void _showNotificationDialog(NotificationModel? notification) {
    // Si aucune notification spécifique, rediriger directement vers la page notifications
    if (notification == null) {
      AppNavigator.push(
        context,
        const NotificationsScreen(),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône et titre
                Row(
                  children: [
                    Icon(
                      notification.isAlert 
                          ? Icons.warning_rounded 
                          : Icons.info_rounded,
                      color: notification.isAlert 
                          ? const Color(0xFFCD1719) 
                          : const Color(0xFF3678FF),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notification.title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: notification.isAlert 
                              ? const Color(0xFFCD1719) 
                              : const Color(0xFF3678FF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Message complet
                Text(
                  notification.message,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.87)
                        : Colors.black.withValues(alpha: 0.87),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Boutons d'action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigation vers la page des notifications
                        AppNavigator.push(
                          context,
                          const NotificationsScreen(),
                        );
                      },
                      child: Text(
                        "Voir toutes",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF3678FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _markNotificationAsRead(notification);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3678FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Fermer",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Traite les données de notifications
  Future<void> _processNotifications(dynamic notificationsData) async {
    try {
      final List<dynamic> notificationsList = notificationsData is List 
        ? notificationsData 
        : (notificationsData as List<dynamic>? ?? []);
        
      final notifications = notificationsList
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      
      // Trier par date de création (plus récent en premier)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
    }
  }

  /// Affiche immédiatement les données depuis le cache
  Future<void> _showFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cache utilisateur
      final cachedUserInfo = prefs.getString('user_info_cache');
      if (cachedUserInfo != null && cachedUserInfo.isNotEmpty) {
        final userInfoData = json.decode(cachedUserInfo);
        final userInfo = UserInfo.fromJson(userInfoData);
        
        setState(() {
          _userInfo = userInfo;
          _hasApplied = userInfo.hasApplied;
        });
      }
      
      // Cache notifications
      final cachedNotifications = prefs.getString('notifications_cache');
      if (cachedNotifications != null && cachedNotifications.isNotEmpty) {
        final notificationsData = json.decode(cachedNotifications);
        final notifications = _parseNotifications(notificationsData);
        
        setState(() {
          _notifications = notifications;
        });
      }
      
      // Cache candidature
      if (_hasApplied) {
        final cachedCandidature = prefs.getString('candidature_cache');
        if (cachedCandidature != null && cachedCandidature.isNotEmpty) {
          final candidatureData = json.decode(cachedCandidature);
          final candidatureInfo = CandidatureInfo.fromJson(candidatureData);
          
          setState(() {
            _candidatureInfo = candidatureInfo;
          });
        }
      }
    } catch (e) {
    }
  }

  /// Parse les notifications depuis les données API
  List<NotificationModel> _parseNotifications(dynamic data) {
    try {
      if (data is List) {
        return data.map((item) => NotificationModel.fromJson(item)).toList();
      } else if (data is Map && data['results'] is List) {
        return (data['results'] as List).map((item) => NotificationModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Met à jour tous les caches avec les nouvelles données
  Future<void> _updateCache(
    Map<String, dynamic> userInfoData,
    List<NotificationModel> notifications,
    CandidatureInfo? candidatureInfo,
    List<ProgramEvent> programEvents,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cache utilisateur
      await prefs.setString('user_info_cache', json.encode(userInfoData));
      
      // Cache notifications
      final notificationsJson = notifications.map((n) => n.toJson()).toList();
      await prefs.setString('notifications_cache', json.encode(notificationsJson));
      
      // Cache candidature
      if (candidatureInfo != null) {
        // Créer un map basique pour le cache selon le modèle CandidatureInfo
        final candidatureMap = {
          'id': candidatureInfo.id,
          'numero': candidatureInfo.numero,
          'titre': candidatureInfo.titre,
          'lettre_motivation': candidatureInfo.lettreMotivation,
          'cv': candidatureInfo.cv,
          'diplome': candidatureInfo.diplome,
          'aptitude_physique': candidatureInfo.aptitudePhysique,
          'piece_identite': candidatureInfo.pieceIdentite,
          'statut': candidatureInfo.statut,
          'step': candidatureInfo.step,
          'commentaire_admin': candidatureInfo.commentaireAdmin,
          'date_creation': candidatureInfo.dateCreation.toIso8601String(),
          'date_modification': candidatureInfo.dateModification.toIso8601String(),
          'candidat': candidatureInfo.candidat,
        };
        await prefs.setString('candidature_cache', json.encode(candidatureMap));
      }
      
      // Cache événements
      final eventsJson = programEvents.map((e) => {
        'id': e.id,
        'name': e.name,
        'description': e.description,
        'start_datetime': e.startDatetime.toIso8601String(),
        'end_datetime': e.endDatetime.toIso8601String(),
        'location': e.location,
        'type': e.type,
        'notes': e.notes,
        'is_active': e.isActive,
      }).toList();
      await prefs.setString('program_events_cache', json.encode(eventsJson));
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 400; // Samsung Fold fermé ~344px
    final isVeryNarrowScreen = screenWidth < 350;
    
    // Padding adaptatif
    final horizontalPadding = isVeryNarrowScreen ? 8.0 : (isNarrowScreen ? 12.0 : 16.0);
    
    final gradient = const LinearGradient(
      colors: [Color(0xFF3678FF), Color.fromARGB(255, 147, 183, 255)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: RefreshIndicator(
        onRefresh: _refreshHomeData,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        strokeWidth: 2.5,
        displacement: 40.0,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Assure que le scroll est toujours possible pour le pull-to-refresh
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Assurer que tous les enfants prennent toute la largeur
            children: [
            // Bandeau d'accueil
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isVeryNarrowScreen ? 12 : 19),
              ),
              margin: EdgeInsets.only(
                bottom: isNarrowScreen ? 12 : 18, 
                top: 3
              ),
              child: Container(
                width: double.infinity, // Assurer que le contenu prend toute la largeur
                padding: EdgeInsets.symmetric(
                  vertical: isVeryNarrowScreen ? 12 : (isNarrowScreen ? 15 : 19),
                  horizontal: isVeryNarrowScreen ? 16 : (isNarrowScreen ? 20 : 24),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isVeryNarrowScreen ? 12 : 19),
                  gradient: gradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _isLoading
                        ? Container(
                            height: isNarrowScreen ? 18 : 22,
                            width: isVeryNarrowScreen ? 150 : (isNarrowScreen ? 180 : 200),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculer la taille de police optimale pour éviter la troncature
                              final greetingText = "${_getGreeting()}, ${_getUserDisplayName()} 👋";
                              double fontSize = isVeryNarrowScreen ? 16 : (isNarrowScreen ? 18 : 22);
                              
                              // Estimer la largeur du texte et ajuster la taille si nécessaire
                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: greetingText,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSize,
                                  ),
                                ),
                                maxLines: 1,
                                textDirection: ui.TextDirection.ltr,
                              );
                              textPainter.layout();
                              
                              // Si le texte dépasse, réduire la taille de police
                              if (textPainter.width > constraints.maxWidth) {
                                // Calculer la nouvelle taille pour qu'elle tienne
                                fontSize = fontSize * (constraints.maxWidth / textPainter.width) * 0.95;
                                // S'assurer que la taille ne descend pas en dessous d'un minimum
                                fontSize = fontSize.clamp(isVeryNarrowScreen ? 11 : 12, isVeryNarrowScreen ? 16 : (isNarrowScreen ? 18 : 22));
                              }
                              
                              return Text(
                                greetingText,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: fontSize,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 2),
                                      blurRadius: 7,
                                      color: Colors.black.withValues(alpha: .10),
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.visible,
                                maxLines: 1,
                              );
                            },
                          ),
                    SizedBox(height: isNarrowScreen ? 2 : 4),
                    Text(
                      "Retrouvez ici toutes les informations clés sur votre candidature à l'ENA.",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: .92),
                        fontSize: isVeryNarrowScreen ? 11 : (isNarrowScreen ? 12 : 14),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      maxLines: isVeryNarrowScreen ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ), // Fermeture Card (bandeau d'accueil)
            // Statut candidature
            _buildCandidatureCard(theme),
            // Notifications récentes
            _buildNotificationsCard(),
            // À la une / Actualités - Widget Twitter
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isVeryNarrowScreen ? 12 : 15),
              ),
              color: theme.brightness == Brightness.dark
                  ? theme.colorScheme.surface.withValues(alpha: 0.7)
                  : theme.colorScheme.surface,
              margin: EdgeInsets.only(bottom: isNarrowScreen ? 12 : 18),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: isVeryNarrowScreen ? 12 : 16,
                  horizontal: isVeryNarrowScreen ? 12 : 16,
                ),
                child: EnaTwitterWidget(
                  title: "À la une / Actualités",
                  showTitle: true,
                  maxTweets: isVeryNarrowScreen ? 3 : 5,
                ),
              ),
            ),
            // Programme & calendrier
            _buildProgrammeCard(),
            // Assistance rapide
            _buildAssistanceCard(theme),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildCandidatureCard(ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 400;
    final isVeryNarrowScreen = screenWidth < 350;
    
    final progressValue = _getProgressValue();
    final progressText = _getProgressText();
    final progressColor = _getProgressColor();
    final currentStepText = _getCurrentStepText();
    final specialMessage = _getSpecialMessage();

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isVeryNarrowScreen ? 12 : 16),
      ),
      color: const Color(0xFF1C3D8F),
      margin: EdgeInsets.only(bottom: isNarrowScreen ? 12 : 18),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isVeryNarrowScreen ? 16 : (isNarrowScreen ? 18 : 22),
          vertical: isVeryNarrowScreen ? 16 : (isNarrowScreen ? 18 : 20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Colors.white,
                  size: isVeryNarrowScreen ? 20 : 24,
                ),
                SizedBox(width: isVeryNarrowScreen ? 6 : 9),
                Expanded(
                  child: Text(
                    "Statut de votre candidature",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isVeryNarrowScreen ? 14 : (isNarrowScreen ? 15 : 17),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: isNarrowScreen ? 12 : 18),
            Text(
              "Progression générale",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: isVeryNarrowScreen ? 12 : (isNarrowScreen ? 13 : 14),
              ),
            ),
            SizedBox(height: isNarrowScreen ? 5 : 7),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progressValue,
                    color: progressColor,
                    backgroundColor: Colors.white24,
                    minHeight: isVeryNarrowScreen ? 5 : 7,
                    borderRadius: BorderRadius.circular(isVeryNarrowScreen ? 3 : 5),
                  ),
                ),
                SizedBox(width: isVeryNarrowScreen ? 8 : 13),
                Text(
                  progressText,
                  style: GoogleFonts.poppins(
                    color: _getProgressTextColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: isVeryNarrowScreen ? 12 : 14,
                  ),
                ),
              ],
            ),
            SizedBox(height: isNarrowScreen ? 6 : 8),
            
            // Bouton "Soumettre ma candidature" ou texte d'étape
            if (!_hasApplied) ...[
              SizedBox(height: isNarrowScreen ? 6 : 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.onMenuChanged != null) {
                      widget.onMenuChanged!(2); // Navigation vers PostulerContent
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1C3D8F),
                    padding: EdgeInsets.symmetric(
                      vertical: isVeryNarrowScreen ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Soumettre ma candidature",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: isVeryNarrowScreen ? 13 : (isNarrowScreen ? 14 : 15),
                    ),
                  ),
                ),
              ),
            ] else if (currentStepText != null) ...[
              Text(
                currentStepText,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: isVeryNarrowScreen ? 11 : (isNarrowScreen ? 12 : 13),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Message spécial (félicitation ou rejet)
            if (specialMessage != null) ...[
              SizedBox(height: isNarrowScreen ? 8 : 12),
              Container(
                padding: EdgeInsets.all(isVeryNarrowScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: _candidatureInfo?.statut == 'valide' 
                      ? const Color(0xFF27AE60).withValues(alpha: 0.2)
                      : const Color(0xFFCD1719).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _candidatureInfo?.statut == 'valide' 
                        ? const Color(0xFF27AE60)
                        : const Color(0xFFCD1719),
                    width: 1,
                  ),
                ),
                child: Text(
                  specialMessage,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isVeryNarrowScreen ? 11 : (isNarrowScreen ? 12 : 13),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
              
              // Bouton recours pour les candidatures rejetées (seulement si pas de recours soumis)
              if (_candidatureInfo?.statut == 'rejete' && !(_userInfo?.hasSubmittedRecours ?? false)) ...[
                SizedBox(height: isNarrowScreen ? 8 : 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _navigateToRecours,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCD1719),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isVeryNarrowScreen ? 10 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Déposer recours",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: isVeryNarrowScreen ? 13 : (isNarrowScreen ? 14 : 15),
                      ),
                    ),
                  ),
                ),
              ],
            ],

            SizedBox(height: isNarrowScreen ? 10 : 15),
            _buildDynamicStepRow(
              title: "Soumission",
              isSubmissionStep: true,
              isNarrowScreen: isNarrowScreen,
              isVeryNarrowScreen: isVeryNarrowScreen,
            ),
            _buildDynamicStepRow(
              title: "Vérification",
              isSubmissionStep: false,
              isNarrowScreen: isNarrowScreen,
              isVeryNarrowScreen: isVeryNarrowScreen,
            ),
            // Étape Recours si candidature rejetée et recours soumis
            if (_candidatureInfo?.statut == 'rejete' && _userInfo?.hasSubmittedRecours == true && _recoursInfo != null) ...[
              _buildStepRow(
                color: _recoursInfo!.traite == true ? const Color(0xFF27AE60) : const Color(0xFFFF8C00),
                icon: _recoursInfo!.traite == true ? Icons.check_circle : Icons.timelapse_rounded,
                title: "Recours",
                subtitle: _recoursInfo!.traite == true ? "Recours traité" : "",
                done: _recoursInfo!.traite == true,
                active: _recoursInfo!.traite != true,
                date: _recoursInfo!.dateSoumissionRecours != null ? _formatDate(_recoursInfo!.dateSoumissionRecours!) : null,
                customBadgeText: _recoursInfo!.traite == true ? "Traité" : "En cours de traitement",
                isNarrowScreen: isNarrowScreen,
                isVeryNarrowScreen: isVeryNarrowScreen,
              ),
            ],
            
            // Bouton "Voir décision" quand le recours est traité
            if (_recoursInfo?.traite == true) ...[
              SizedBox(height: isNarrowScreen ? 6 : 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _navigateToRecours,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3678FF), // Même bleu que le premier card
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isVeryNarrowScreen ? 12 : 16,
                      vertical: isVeryNarrowScreen ? 6 : 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    "Voir décision",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: isVeryNarrowScreen ? 11 : 12,
                    ),
                  ),
                ),
              ),
            ],

            
            // Séparateur simple et élégant
            Container(
              margin: EdgeInsets.symmetric(
                vertical: isVeryNarrowScreen ? 16 : 20,
                horizontal: isVeryNarrowScreen ? 20 : 30,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.more_horiz,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 14,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
            
            _buildStepRow(
              color: Colors.white.withValues(alpha: 0.45),
              icon: Icons.radio_button_unchecked,
              title: "Épreuve écrite",
              subtitle: "Convocation à venir",
              done: false,
              isNarrowScreen: isNarrowScreen,
              isVeryNarrowScreen: isVeryNarrowScreen,
            ),
            _buildStepRow(
              color: Colors.white.withValues(alpha: 0.45),
              icon: Icons.radio_button_unchecked,
              title: "Épreuve orale",
              subtitle: "À venir",
              done: false,
              isNarrowScreen: isNarrowScreen,
              isVeryNarrowScreen: isVeryNarrowScreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicStepRow({
    required String title,
    required bool isSubmissionStep,
    required bool isNarrowScreen,
    required bool isVeryNarrowScreen,
  }) {
    Color color;
    IconData icon;
    String subtitle;
    bool done = false;
    bool active = false;
    String? date;
    String? badgeText;

    if (isSubmissionStep) {
      // Étape SOUMISSION
      if (!_hasApplied) {
        // has_applied = false : bleu, non soumis
        color = const Color(0xFF3678FF); // Même bleu que "Vérification"
        icon = Icons.radio_button_unchecked; // Icône non soumis
        subtitle = "Hâtez-vous d'envoyer votre candidature";
        badgeText = "Non soumis";
        done = false;
        active = false;
        date = null; // Pas de date pour les non soumis
      } else {
        // has_applied = true : mais on attend la candidature pour confirmer
        if (_candidatureInfo == null) {
          // Candidature en cours de chargement
          color = const Color(0xFF3678FF);
          icon = Icons.timelapse_rounded;
          subtitle = "Chargement du statut...";
          badgeText = "En cours";
          done = false;
          active = true;
          date = null;
        } else {
          // Candidature chargée : terminé (vert)
          color = const Color(0xFF27AE60);
          icon = Icons.check_circle;
          subtitle = "Candidature soumise avec succès";
          badgeText = "Terminée";
          done = true;
          active = false;
          // Date de soumission OBLIGATOIRE (date_creation de la candidature)
          date = _formatDate(_candidatureInfo!.dateCreation);
        }
      }
    } else {
      // Étape VÉRIFICATION
      if (!_hasApplied) {
        // has_applied = false : en attente
        color = const Color(0xFF3678FF);
        icon = Icons.timelapse_rounded;
        subtitle = "Vérification des documents";
        badgeText = "En attente";
        done = false;
        active = false;
        date = null; // Pas de date pour les en attente
      } else {
        // has_applied = true : logique basée sur le statut
        if (_candidatureInfo == null) {
          // Candidature en cours de chargement
          color = const Color(0xFF3678FF);
          icon = Icons.timelapse_rounded;
          subtitle = "Chargement du statut...";
          badgeText = "En cours";
          done = false;
          active = true;
          date = null;
        } else {
          switch (_candidatureInfo!.statut) {
            case 'envoye':
              color = const Color(0xFF3678FF);
              icon = Icons.timelapse_rounded;
              subtitle = "Vérification des documents";
              badgeText = "En cours";
              done = false;
              active = true;
              date = null; // Pas de date pour "En cours"
              break;
            case 'en_traitement':
              color = const Color(0xFF3678FF);
              icon = Icons.timelapse_rounded;
              subtitle = "Vérification des documents";
              badgeText = "En cours";
              done = false;
              active = true;
              date = null; // Pas de date pour "En cours"
              break;
            case 'valide':
            case 'rejete':
              // Si un recours a été soumis, la vérification est forcément terminée
              if (_userInfo?.hasSubmittedRecours == true) {
                color = const Color(0xFF27AE60);
                icon = Icons.check_circle;
                subtitle = "Terminée le ${_getVerificationEndDate() ?? 'Date inconnue'}";
                badgeText = "Terminée";
                done = true;
                active = false;
                date = null;
              } else if (_userInfo?.canPublish == true) {
                // Afficher comme terminé uniquement si can_publish est true
                color = const Color(0xFF27AE60);
                icon = Icons.check_circle;
                subtitle = "Terminée le ${_getVerificationEndDate() ?? 'Date inconnue'}";
                badgeText = "Terminée";
                done = true;
                active = false;
                date = null;
              } else {
                // Si can_publish est false et pas de recours, afficher comme en cours
                color = const Color(0xFF3678FF);
                icon = Icons.timelapse_rounded;
                subtitle = "Vérification des documents";
                badgeText = "En cours";
                done = false;
                active = true;
                date = null; // Pas de date pour "En cours"
              }
              break;
            default:
              color = const Color(0xFF3678FF);
              icon = Icons.timelapse_rounded;
              subtitle = "Vérification des documents";
              badgeText = "En cours";
              done = false;
              active = true;
          }
        }
      }
    }

    return _buildStepRow(
      color: color,
      icon: icon,
      title: title,
      subtitle: subtitle,
      done: done,
      active: active,
      date: date,
      customBadgeText: badgeText,
      isNarrowScreen: isNarrowScreen,
      isVeryNarrowScreen: isVeryNarrowScreen,
    );
  }

  Widget _buildStepRow({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    bool done = false,
    bool active = false,
    String? date,
    String? customBadgeText,
    required bool isNarrowScreen,
    required bool isVeryNarrowScreen,
  }) {
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isVeryNarrowScreen ? 4.0 : 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon, 
            color: color, 
            size: isVeryNarrowScreen ? 16 : (isNarrowScreen ? 17 : 19),
          ),
          SizedBox(width: isVeryNarrowScreen ? 5 : 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontWeight: done || active
                        ? FontWeight.bold
                        : FontWeight.w600,
                    fontSize: isVeryNarrowScreen ? 11 : (isNarrowScreen ? 12 : 13),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: done
                          ? Colors.white.withValues(alpha: .93)
                          : Colors.white70,
                      fontSize: isVeryNarrowScreen ? 10 : (isNarrowScreen ? 11 : 12),
                      height: 1.2,
                    ),
                    maxLines: isVeryNarrowScreen ? 2 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (date != null && (done || active)) ...[
                  Text(
                    "Complété le $date",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: .88),
                      fontSize: isVeryNarrowScreen ? 8 : (isNarrowScreen ? 9 : 10),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (customBadgeText != null)
            Container(
              margin: EdgeInsets.only(
                left: isVeryNarrowScreen ? 4 : 7, 
                top: 1,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isVeryNarrowScreen ? 6 : (isNarrowScreen ? 8 : 11), 
                vertical: isVeryNarrowScreen ? 2 : 3,
              ),
              decoration: BoxDecoration(
                color: done
                    ? const Color(0xFFCBF3E2)
                    : active
                        ? (color == const Color(0xFFFF8C00) // Si couleur orange (recours)
                            ? const Color(0xFFFFE4B5) // Fond orange clair
                            : const Color(0xFFD5E6FA)) // Fond bleu clair standard
                        : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(isVeryNarrowScreen ? 6 : 9),
              ),
              child: Text(
                customBadgeText,
                style: GoogleFonts.poppins(
                  color: done
                      ? const Color(0xFF27AE60)
                      : active
                          ? (color == const Color(0xFFFF8C00) // Si couleur orange (recours)
                              ? const Color(0xFFFF8C00) // Texte orange
                              : const Color(0xFF3678FF)) // Texte bleu standard
                          : Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: isVeryNarrowScreen ? 8 : (isNarrowScreen ? 9 : 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 400;
    final isVeryNarrowScreen = screenWidth < 350;
    
    final alertNotification = _latestAlertNotification;
    final nonAlertNotification = _latestNonAlertNotification;

    // Si aucune notification, afficher un message par défaut
    if (_notifications.isEmpty) {
      return GestureDetector(
        onTap: () {
          // Afficher le popup même sans notifications
          _showNotificationDialog(null);
        },
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isVeryNarrowScreen ? 12 : 16),
          ),
          color: const Color(0xFF3678FF),
          margin: EdgeInsets.only(bottom: isNarrowScreen ? 12 : 18),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isVeryNarrowScreen ? 12 : (isNarrowScreen ? 14 : 17),
              horizontal: isVeryNarrowScreen ? 12 : (isNarrowScreen ? 14 : 17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: isVeryNarrowScreen ? 20 : 24,
                    ),
                    SizedBox(width: isVeryNarrowScreen ? 5 : 7),
                    Expanded(
                      child: Text(
                        "Notifications récentes",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isVeryNarrowScreen ? 13 : (isNarrowScreen ? 14 : 15),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.touch_app_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: isVeryNarrowScreen ? 16 : 18,
                    ),
                  ],
                ),
                SizedBox(height: isNarrowScreen ? 8 : 12),
                Text(
                  "Aucune notification récente - Appuyez pour voir toutes les notifications",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: isVeryNarrowScreen ? 11 : (isNarrowScreen ? 12 : 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isVeryNarrowScreen ? 12 : 16),
      ),
      color: const Color(0xFF3678FF),
      margin: EdgeInsets.only(bottom: isNarrowScreen ? 12 : 18),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isVeryNarrowScreen ? 12 : (isNarrowScreen ? 14 : 17),
          horizontal: isVeryNarrowScreen ? 12 : (isNarrowScreen ? 14 : 17),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: isVeryNarrowScreen ? 20 : 24,
                ),
                SizedBox(width: isVeryNarrowScreen ? 5 : 7),
                Expanded(
                  child: Text(
                    "Notifications récentes",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isVeryNarrowScreen ? 13 : (isNarrowScreen ? 14 : 15),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: isVeryNarrowScreen ? 6 : 8),
            
            // Notification d'alerte (uniquement si elle existe)
            if (alertNotification != null) ...[
              _buildNotificationLine(
                context,
                notification: alertNotification,
                isAlert: true,
                isNarrowScreen: isNarrowScreen,
                isVeryNarrowScreen: isVeryNarrowScreen,
              ),
            ],
            
            // Notification normale (uniquement si elle existe)
            if (nonAlertNotification != null) ...[
              _buildNotificationLine(
                context,
                notification: nonAlertNotification,
                isAlert: false,
                isNarrowScreen: isNarrowScreen,
                isVeryNarrowScreen: isVeryNarrowScreen,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgrammeCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 400;
    final isVeryNarrowScreen = screenWidth < 350;
    
    return GestureDetector(
      onTap: () {
        // Ouvrir le popup avec les détails des événements
        ProgramEventsPopup.show(context, _programEvents);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isVeryNarrowScreen ? 12 : 15),
        ),
        color: const Color(0xFF3678FF),
        margin: EdgeInsets.only(bottom: isNarrowScreen ? 12 : 18),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: isVeryNarrowScreen ? 10 : (isNarrowScreen ? 11 : 13),
            horizontal: isVeryNarrowScreen ? 10 : (isNarrowScreen ? 11 : 13),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: isVeryNarrowScreen ? 20 : 24,
              ),
              SizedBox(width: isVeryNarrowScreen ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Programme & calendrier",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isVeryNarrowScreen ? 13 : (isNarrowScreen ? 14 : 15),
                            ),
                          ),
                        ),
                        if (_isLoadingEvents)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.7)),
                            ),
                          )
                        else
                          Icon(
                            Icons.touch_app_rounded,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: isVeryNarrowScreen ? 16 : 18,
                          ),
                      ],
                    ),
                    SizedBox(height: isVeryNarrowScreen ? 5 : 7),
                    _buildEventsList(isVeryNarrowScreen, isNarrowScreen),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList(bool isVeryNarrowScreen, bool isNarrowScreen) {
    if (_isLoadingEvents) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          "Chargement des événements...",
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: isVeryNarrowScreen ? 10 : (isNarrowScreen ? 11 : 12),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    if (_programEvents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          "Aucun programme disponible pour le moment",
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: isVeryNarrowScreen ? 10 : (isNarrowScreen ? 11 : 12),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _programEvents.map((event) {
        return _buildEventItem(
          event,
          isVeryNarrowScreen,
          isNarrowScreen,
        );
      }).toList(),
    );
  }

  Widget _buildEventItem(ProgramEvent event, bool isVeryNarrowScreen, bool isNarrowScreen) {
    // Déterminer la couleur et l'icône selon le statut
    Color statusColor;
    IconData statusIcon;
    
    switch (event.status) {
      case 'En cours':
        statusColor = const Color(0xFF10B981); // Vert
        statusIcon = Icons.play_circle_fill;
        break;
      case 'À venir':
        statusColor = const Color(0xFF3B82F6); // Bleu
        statusIcon = Icons.schedule;
        break;
      case 'Terminé':
        statusColor = Colors.white54;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.white70;
        statusIcon = Icons.circle;
    }
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: isVeryNarrowScreen ? 6 : 8, 
        left: isVeryNarrowScreen ? 2 : 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon, 
                color: statusColor, 
                size: isVeryNarrowScreen ? 12 : 14,
              ),
              SizedBox(width: isVeryNarrowScreen ? 6 : 8),
              Expanded(
                child: Text(
                  event.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isVeryNarrowScreen ? 11 : (isNarrowScreen ? 12 : 13),
                  ),
                  maxLines: isVeryNarrowScreen ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isVeryNarrowScreen ? 4 : 6,
                  vertical: isVeryNarrowScreen ? 1 : 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor, width: 0.5),
                ),
                child: Text(
                  event.status,
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: isVeryNarrowScreen ? 7 : 8,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isVeryNarrowScreen ? 2 : 3),
          Padding(
            padding: EdgeInsets.only(left: isVeryNarrowScreen ? 18 : 22),
            child: Text(
              "📅 ${event.formattedPeriod}",
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: isVeryNarrowScreen ? 9 : 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistanceCard(ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 400;
    final isVeryNarrowScreen = screenWidth < 350;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isVeryNarrowScreen ? 12 : 15),
      ),
      color: theme.brightness == Brightness.dark
          ? theme.colorScheme.surface.withValues(alpha: 0.6)
          : theme.colorScheme.surface,
      margin: EdgeInsets.only(bottom: isNarrowScreen ? 12 : 16),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isVeryNarrowScreen ? 10 : (isNarrowScreen ? 11 : 13),
          horizontal: isVeryNarrowScreen ? 10 : (isNarrowScreen ? 12 : 15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Assistance & liens utiles",
              style: GoogleFonts.poppins(
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.9)
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: isVeryNarrowScreen ? 13 : (isNarrowScreen ? 14 : 15),
              ),
            ),
            SizedBox(height: isVeryNarrowScreen ? 6 : 9),
            // Stratégie adaptative pour maintenir l'alignement horizontal
            _buildResponsiveActionIcons(context, widget.onMenuChanged, isVeryNarrowScreen, isNarrowScreen),
          ],
        ),
      ),
    );
  }

  static void _handleActionTap(
    BuildContext context,
    String label,
    Function(int)? onMenuChanged,
  ) {
    switch (label) {
      case "Prépa-ENA":
        // Naviguer vers la page Prepa-ENA (index 3 dans MainRouter)
        if (onMenuChanged != null) {
          onMenuChanged(3);
        }
        break;
      case "Contact":
        // Naviguer vers la page Contact (index 4 dans MainRouter)
        if (onMenuChanged != null) {
          onMenuChanged(4);
        }
        break;
      case "Guide":
        // Ouvrir le PDF du guide
        _openGuide();
        break;
      case "WhatsApp":
        // Ouvrir WhatsApp
        _openWhatsApp();
        break;
    }
  }

  static void _openGuide() async {
    // Ouvrir le PDF du guide
    final url = Uri.parse(
      'https://ena.cd/wp-content/uploads/2025/06/GUIDE-DE-PREPA-AU-CONCOURS-DENTREE-A-LENA-RDC-1-1.pdf',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Gérer l'erreur silencieusement ou via un SnackBar si nécessaire
    }
  }

  static void _openWhatsApp() async {
    // Ouvrir WhatsApp channel
    final url = Uri.parse(
      'https://whatsapp.com/channel/0029Vb6Na5uK5cDKslzxom3L',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Gérer l'erreur silencieusement ou via un SnackBar si nécessaire
    }
  }

  /// Construit les icônes d'action de manière responsive
  /// Garantit un alignement horizontal parfait sur tous les écrans
  Widget _buildResponsiveActionIcons(
    BuildContext context,
    Function(int)? onMenuChanged,
    bool isVeryNarrowScreen,
    bool isNarrowScreen,
  ) {
    // Calculer la largeur disponible pour déterminer la stratégie adaptative
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Définir les seuils d'adaptation
    final isExtremelyNarrow = screenWidth < 320; // Écrans très étroits (iPhone SE 1ère gen)
    final isVeryTight = screenWidth < 380; // Écrans serrés
    
    // Stratégie adaptative :
    // 1. Écrans normaux : 4 icônes, taille normale
    // 2. Écrans serrés : 4 icônes, taille réduite
    // 3. Écrans très étroits : 3 icônes (suppression Prépa-ENA), taille très réduite
    
    List<Map<String, dynamic>> icons = [
      {
        'icon': Icons.school_outlined,
        'label': 'Prépa-ENA',
        'priority': 4, // Priorité la plus basse, supprimé en premier
      },
      {
        'icon': Icons.mail_rounded,
        'label': 'Contact',
        'priority': 1, // Priorité haute, gardé en dernier
      },
      {
        'icon': Icons.info_outline_rounded,
        'label': 'Guide',
        'priority': 2, // Priorité moyenne-haute
      },
      {
        'icon': Icons.chat_rounded,
        'label': 'WhatsApp',
        'priority': 3, // Priorité moyenne
      },
    ];
    
    // Supprimer l'icône Prépa-ENA sur les écrans extrêmement étroits
    if (isExtremelyNarrow) {
      icons.removeWhere((icon) => icon['label'] == 'Prépa-ENA');
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: icons.map((iconData) {
        return _adaptiveActionIcon(
          context,
          iconData['icon'],
          iconData['label'],
          onMenuChanged,
          isExtremelyNarrow,
          isVeryTight,
          isVeryNarrowScreen,
          isNarrowScreen,
        );
      }).toList(),
    );
  }

  /// Icône d'action adaptative avec tailles variables selon l'écran
  Widget _adaptiveActionIcon(
    BuildContext context,
    IconData icon,
    String label,
    Function(int)? onMenuChanged,
    bool isExtremelyNarrow,
    bool isVeryTight,
    bool isVeryNarrowScreen,
    bool isNarrowScreen,
  ) {
    final theme = Theme.of(context);
    
    // Calcul adaptatif des tailles selon les niveaux d'écran
    double avatarRadius;
    double iconSize;
    double fontSize;
    
    if (isExtremelyNarrow) {
      // Écrans < 320px : tailles très réduites
      avatarRadius = 12;
      iconSize = 12;
      fontSize = 7; // Très réduit pour éviter les retours à la ligne
    } else if (isVeryTight) {
      // Écrans < 380px : tailles réduites
      avatarRadius = 14;
      iconSize = 14;
      fontSize = 8; // Réduit pour éviter les retours à la ligne
    } else if (isVeryNarrowScreen) {
      // Écrans < 350px : tailles légèrement réduites
      avatarRadius = 16;
      iconSize = 16;
      fontSize = 8; // Réduit pour éviter les retours à la ligne
    } else if (isNarrowScreen) {
      // Écrans moyens : tailles normales réduites
      avatarRadius = 18;
      iconSize = 18;
      fontSize = 9; // Réduit pour éviter les retours à la ligne
    } else {
      // Écrans larges : tailles normales
      avatarRadius = 20;
      iconSize = 20;
      fontSize = 10; // Réduit pour éviter les retours à la ligne
    }
    
    return GestureDetector(
      onTap: () => _handleActionTap(context, label, onMenuChanged),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            radius: avatarRadius,
            child: Icon(
              icon,
              color: Colors.white,
              size: iconSize,
            ),
          ),
          SizedBox(height: isExtremelyNarrow ? 2 : (isVeryTight ? 3 : (isVeryNarrowScreen ? 3 : 4))),
          Container(
            // Largeur adaptative optimisée pour éviter les retours à la ligne
            width: isExtremelyNarrow ? 42 : (isVeryTight ? 52 : (isVeryNarrowScreen ? 58 : (isNarrowScreen ? 65 : 70))),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationLine(
    BuildContext context, {
    required NotificationModel notification,
    required bool isAlert,
    required bool isNarrowScreen,
    required bool isVeryNarrowScreen,
  }) {
    // Couleurs selon le type et l'état de lecture
    Color backgroundColor;
    Color titleColor;
    Color textColor;

    if (isAlert) {
      if (notification.isRead) {
        // Alerte lue : couleur atténuée
        backgroundColor = const Color(0xFFCD1719).withValues(alpha: 0.1);
        titleColor = const Color(0xFFCD1719).withValues(alpha: 0.7);
        textColor = Colors.white.withValues(alpha: 0.7);
      } else {
        // Alerte non lue : couleur vive
        backgroundColor = const Color(0xFFFFE5E0);
        titleColor = const Color(0xFFCD1719);
        textColor = Colors.white;
      }
    } else {
      if (notification.isRead) {
        // Notification normale lue : couleur atténuée
        backgroundColor = Colors.white.withValues(alpha: 0.05);
        titleColor = Colors.white.withValues(alpha: 0.7);
        textColor = Colors.white.withValues(alpha: 0.6);
      } else {
        // Notification normale non lue : couleur normale
        backgroundColor = Colors.white.withValues(alpha: 0.1);
        titleColor = Colors.white;
        textColor = Colors.white.withValues(alpha: 0.8);
      }
    }

    return GestureDetector(
      onTap: () {
        _showNotificationDialog(notification);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isVeryNarrowScreen ? 5 : 7),
        padding: EdgeInsets.symmetric(
          vertical: isVeryNarrowScreen ? 5 : 7, 
          horizontal: isVeryNarrowScreen ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(isVeryNarrowScreen ? 6 : 9),
          border: isAlert && !notification.isRead
              ? Border.all(color: const Color(0xFFCD1719), width: 1.2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    notification.title,
                    style: GoogleFonts.poppins(
                      color: titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: isVeryNarrowScreen ? 11 : (isNarrowScreen ? 12 : 13),
                    ),
                    maxLines: isVeryNarrowScreen ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!notification.isRead) ...[
                  SizedBox(width: isVeryNarrowScreen ? 6 : 8),
                  Container(
                    width: isVeryNarrowScreen ? 6 : 8,
                    height: isVeryNarrowScreen ? 6 : 8,
                    decoration: BoxDecoration(
                      color: isAlert ? const Color(0xFFCD1719) : Colors.white,
                      borderRadius: BorderRadius.circular(isVeryNarrowScreen ? 3 : 4),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: isVeryNarrowScreen ? 1 : 2),
            Text(
              notification.getTruncatedMessage(
                maxLength: isVeryNarrowScreen ? 40 : (isNarrowScreen ? 50 : 60),
              ),
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: isVeryNarrowScreen ? 10 : (isNarrowScreen ? 11 : 12),
                height: 1.2,
              ),
              maxLines: isVeryNarrowScreen ? 3 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
