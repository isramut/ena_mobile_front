import 'dart:convert';
import 'dart:async';
import 'package:ena_mobile_front/models/user_info.dart';
import 'package:ena_mobile_front/models/notification.dart';
import 'package:ena_mobile_front/services/auth_api_service.dart';
import 'package:ena_mobile_front/services/profile_update_notification_service.dart';
import 'package:ena_mobile_front/widgets/avatar_widget.dart';
import 'package:ena_mobile_front/features/notifications/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/draggable_chat_button.dart';
import 'mobile_platform_config.dart';

// URLs réseaux sociaux
const String facebookUrl = 'https://www.facebook.com/ENARDCOfficiel';
const String linkedinUrl = 'https://www.linkedin.com/company/ena-rdc';
const String twitterUrl = 'https://x.com/EnaRDC_Officiel';
const String whatsappUrl =
    'https://whatsapp.com/channel/0029Vb6Na5uK5cDKslzxom3L';

typedef EnaPageBuilder = Widget Function(BuildContext context);

class EnaMainLayout extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onMenuChanged;
  final EnaPageBuilder pageBuilder;
  final int notificationCount;
  final VoidCallback onAvatarTap;

  const EnaMainLayout({
    super.key,
    required this.selectedIndex,
    required this.onMenuChanged,
    required this.pageBuilder,
    this.notificationCount = 0,
    required this.onAvatarTap,
  });

  @override
  State<EnaMainLayout> createState() => _EnaMainLayoutState();
}

class _EnaMainLayoutState extends State<EnaMainLayout> {
  bool _showNotifications = false;
  UserInfo? _userInfo;
  bool _isLoadingUserInfo = false;
  
  // Variables pour les notifications de l'API
  List<NotificationModel> _notifications = [];
  int _unreadNotificationCount = 0;
  
  // StreamSubscription pour écouter les mises à jour du profil
  StreamSubscription<ProfileUpdateEvent>? _profileUpdateSubscription;

  @override
  void initState() {
    super.initState();
    // Charger immédiatement depuis le cache puis faire l'appel API en arrière-plan
    _loadUserInfoFromCacheFirst();
    // Charger les notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
    
    // 🔔 Écouter les mises à jour du profil pour rafraîchir le header
    _profileUpdateSubscription = ProfileUpdateNotificationService()
        .profileUpdateStream.listen(_onProfileUpdated);
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        final result = await AuthApiService.getUserNotifications(token: token);
        
        if (mounted && result['success'] == true && result['data'] != null) {
          final notificationsData = result['data'];
          List<NotificationModel> notifications = [];
          
          if (notificationsData is List) {
            notifications = notificationsData
                .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
                .toList();
          } else if (notificationsData is Map && notificationsData['results'] != null) {
            // Si les notifications sont dans un format paginé
            final results = notificationsData['results'] as List;
            notifications = results
                .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
                .toList();
          }
          
          setState(() {
            _notifications = notifications;
            _unreadNotificationCount = notifications.where((n) => !n.isRead).length;
          });
          
          // Sauvegarder en cache
          await prefs.setString('notifications_cache', jsonEncode(notifications.map((n) => n.toJson()).toList()));
        } else {
          // Charger depuis le cache en cas d'erreur
          await _loadNotificationsFromCache();
        }
      } else {
        // Pas de token, charger depuis le cache
        await _loadNotificationsFromCache();
      }
    } catch (e) {
      // En cas d'erreur, charger depuis le cache
      if (mounted) {
        await _loadNotificationsFromCache();
      }
    }
  }

  Future<void> _loadNotificationsFromCache() async {
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedNotifications = prefs.getString('notifications_cache');
      
      if (cachedNotifications != null && cachedNotifications.isNotEmpty) {
        final notificationsData = jsonDecode(cachedNotifications) as List;
        final notifications = notificationsData
            .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
            .toList();
        
        if (mounted) {
          setState(() {
            _notifications = notifications;
            _unreadNotificationCount = notifications.where((n) => !n.isRead).length;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _notifications = [];
            _unreadNotificationCount = 0;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notifications = [];
          _unreadNotificationCount = 0;
        });
      }
    }
  }

  Future<void> _markNotificationAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        final result = await AuthApiService.markNotificationAsRead(
          token: token,
          notificationId: notification.id,
        );

        if (result['success'] == true && mounted) {
          setState(() {
            final index = _notifications.indexWhere((n) => n.id == notification.id);
            if (index != -1) {
              _notifications[index] = notification.copyWith(isRead: true);
              _unreadNotificationCount = _notifications.where((n) => !n.isRead).length;
            }
          });
          
          // Mettre à jour le cache
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('notifications_cache', 
              jsonEncode(_notifications.map((n) => n.toJson()).toList()));
        }
      }
    } catch (e) {
      // Ignorer l'erreur mais marquer localement
      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = notification.copyWith(isRead: true);
            _unreadNotificationCount = _notifications.where((n) => !n.isRead).length;
          }
        });
      }
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        final result = await AuthApiService.markAllNotificationsAsRead(token: token);

        if (result['success'] == true && mounted) {
          setState(() {
            _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
            _unreadNotificationCount = 0;
          });
          
          // Mettre à jour le cache
          await prefs.setString('notifications_cache', 
              jsonEncode(_notifications.map((n) => n.toJson()).toList()));
        }
      }
    } catch (e) {
      // Ignorer l'erreur mais marquer localement
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
          _unreadNotificationCount = 0;
        });
      }
    }
  }

  Future<void> _loadUserInfoFromCacheFirst() async {
    if (!mounted) return;
    
    // Charger immédiatement depuis le cache pour un affichage rapide
    await _loadUserInfoFromCache();
    
    // Puis charger de l'API en arrière-plan pour mettre à jour si nécessaire
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserInfoFromAPI();
      }
    });
  }

  Future<void> _loadUserInfoFromAPI() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        final result = await AuthApiService.getUserInfo(token: token);
        
        if (mounted && result['success'] == true && result['data'] != null) {
          setState(() {
            _userInfo = UserInfo.fromJson(result['data']);
          });
          
          // Sauvegarder les informations en cache local
          await prefs.setString('user_info_cache', jsonEncode(result['data']));
        }
      }
    } catch (e) {
      // Ignorer les erreurs API, garder le cache
    }
  }

  Future<void> _loadUserInfoFromCache() async {
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserInfo = prefs.getString('user_info_cache');
      
      if (cachedUserInfo != null && cachedUserInfo.isNotEmpty) {
        final userInfoData = jsonDecode(cachedUserInfo);
        if (mounted) {
          setState(() {
            _userInfo = UserInfo.fromJson(userInfoData);
            _isLoadingUserInfo = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingUserInfo = false;
          });
        }
      }
    } catch (e) {
      // En cas d'erreur de parsing du cache, on charge des valeurs par défaut
      if (mounted) {
        setState(() {
          _userInfo = null;
          _isLoadingUserInfo = false;
        });
      }
    }
  }

  static final List<Map<String, String>> menuLabels = [
    {
      "title": "Accueil",
      "desc": "Tableau de bord, résumé de la progression et notifications",
    },
    {
      "title": "Actualités",
      "desc": "Dernières nouvelles, annonces et événements ENA",
    },
    {
      "title": "Inscription",
      "desc": "Nouvelle candidature, évolution de la candidature",
    },
    {
      "title": "Prépa-ENA",
      "desc": "Préparation au concours, guide et quiz d'entraînement",
    },
    {
      "title": "Contact",
      "desc": "Contact, infos utiles et FAQ",
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Configuration responsive pour mobiles
    final mobileConfig = MobilePlatformConfig.getMobileConfig(context);
    final isFoldable = MobilePlatformConfig.isFoldableDevice(context);
    final isLandscape = MobilePlatformConfig.isLandscape(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // HEADER OPTIMISÉ POUR MOBILE - HAUTEUR FLEXIBLE
                Container(
                  margin: EdgeInsets.fromLTRB(
                    mobileConfig.getOptimizedPadding() * 0.8,
                    mobileConfig.getOptimizedPadding() * 0.6,
                    mobileConfig.getOptimizedPadding() * 0.8,
                    mobileConfig.getOptimizedPadding() * 0.4,
                  ),
                  constraints: BoxConstraints(
                    minHeight: isFoldable ? 56 : 60,
                    // Pas de maxHeight pour éviter les débordements
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(
                      isLandscape && !isFoldable ? 16 : 20,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).shadowColor.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: mobileConfig.cardPadding * 0.8,
                    vertical: isFoldable ? 6 : 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.menu_rounded,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF013068),
                          size: mobileConfig.iconSize * 1.1, // Taille augmentée
                        ),
                        onPressed: () => _showMenuBottomSheet(context),
                        tooltip: "Menu",
                        constraints: BoxConstraints(
                          minWidth: mobileConfig.iconSize * 1.6,
                          minHeight: mobileConfig.iconSize * 1.6,
                        ),
                      ),
                      SizedBox(width: isFoldable ? 4 : 8),
                      Expanded(
                        flex: 3,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.35,
                            maxHeight: mobileConfig.iconSize * 1.6, // Contrainte de hauteur augmentée
                          ),
                          child: Image.asset(
                            Theme.of(context).brightness == Brightness.dark
                                ? "assets/images/ena_logo_blanc.png"
                                : "assets/images/ena_logo.png",
                            height: isFoldable
                                ? mobileConfig.iconSize * 1.3
                                : mobileConfig.iconSize * 1.5, // Taille augmentée
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.notifications_none_rounded,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF013068),
                              size: mobileConfig.iconSize * 1.1, // Taille augmentée
                            ),
                            onPressed: () => setState(() {
                              _showNotifications = !_showNotifications;
                            }),
                            constraints: BoxConstraints(
                              minWidth: mobileConfig.iconSize * 1.6,
                              minHeight: mobileConfig.iconSize * 1.6,
                            ),
                          ),
                          if (_unreadNotificationCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF87171),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    "$_unreadNotificationCount",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.clip,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: isFoldable ? 6 : 10),
                      // AVATAR RESPONSIVE AVEC MENU POPUP NATIF
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'profile':
                              widget.onMenuChanged(5);
                              break;
                            case 'settings':
                              widget.onMenuChanged(6);
                              break;
                            case 'logout':
                              _showLogoutDialog();
                              break;
                          }
                        },
                        offset: const Offset(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        color: Theme.of(context).cardColor,
                        itemBuilder: (BuildContext context) => [
                          // Header avec info utilisateur
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5, bottom: 6),
                              child: Row(
                                children: [
                                  UserAvatar(
                                    userInfo: _userInfo,
                                    size: 36,
                                    borderRadius: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _getDisplayName(),
                                          style: GoogleFonts.poppins(
                                            color: Theme.of(context).textTheme.headlineSmall?.color,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (_userInfo?.role != null && _userInfo!.role.isNotEmpty)
                                          Text(
                                            _userInfo!.role.toUpperCase(),
                                            style: GoogleFonts.poppins(
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? const Color(0xFF60A5FA)
                                                  : const Color(0xFF3678FF),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 9,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        if (_userInfo?.numero != null && _userInfo!.numero!.isNotEmpty)
                                          Text(
                                            _userInfo!.numero!,
                                            style: GoogleFonts.poppins(
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white70
                                                  : Colors.grey[600],
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF013068),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Mon profil",
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'settings',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.settings,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF013068),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Paramètres",
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.logout_rounded,
                                  color: Color(0xFFF87171),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Logout",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFF87171),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF013068),
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(isFoldable ? 2 : 3),
                          constraints: BoxConstraints(
                            maxWidth: mobileConfig.iconSize * 2.5, // Taille augmentée
                            maxHeight: mobileConfig.iconSize * 2.5, // Taille augmentée
                          ),
                          child: _buildAvatar(
                            size: isFoldable
                                ? mobileConfig.iconSize * 1.1 // Taille augmentée
                                : mobileConfig.iconSize * 1.3, // Taille augmentée
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // PAGE CONTENT
                Expanded(child: widget.pageBuilder(context)),
                // FOOTER - MARGES RÉDUITES
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Card(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF1C3D8F),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: Theme.of(
                      context,
                    ).shadowColor.withValues(alpha: 0.15),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Retrouvez-nous sur :",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          _buildResponsiveFooterIcons(),
                          const SizedBox(height: 6),
                          _buildResponsiveBottomRow(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Menus overlay - ordre important : le dernier affiché doit être au-dessus
            if (_showNotifications) _buildNotifications(context),
            // Bouton de chat déplaçable
            const DraggableChatButton(),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(EnaMainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // ⚠️ ÉVITER le rechargement du header lors du changement de page
    // Le header ne doit se rafraîchir QUE lors de :
    // 1. Premier chargement (initState)
    // 2. Mise à jour du profil (ProfileUpdateNotificationService)
    // 3. Reconnexion utilisateur
    
    // NE PAS recharger lors du changement de selectedIndex
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      print('📄 Page changed from ${oldWidget.selectedIndex} to ${widget.selectedIndex} - Header NOT refreshed');
      return; // Ne pas recharger le header
    }
    
    // Recharger seulement si changement d'utilisateur ou autre raison critique
    if (oldWidget.notificationCount != widget.notificationCount) {
      print('🔔 Notification count changed - Refreshing notifications only');
      _loadNotifications(); // Recharger seulement les notifications
    }
  }

  Widget _buildAvatar({double? size}) {
    final avatarRadius = size != null ? size / 2.0 : 18.0;
    // Contraindre la taille de l'avatar pour éviter les débordements mais permettre plus grand
    final constrainedRadius = avatarRadius.clamp(14.0, 26.0); // Taille max augmentée

    if (_isLoadingUserInfo) {
      return CircleAvatar(
        radius: constrainedRadius,
        backgroundColor: const Color(0xFF013068),
        child: SizedBox(
          width: constrainedRadius * 0.8,
          height: constrainedRadius * 0.8,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return UserAvatar(
      userInfo: _userInfo,
      size: constrainedRadius * 2,
      borderRadius: constrainedRadius,
    );
  }

  static Widget _footerIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double? size,
    double? splashRadius,
  }) {
    return IconButton(
      icon: Icon(icon, color: color, size: size ?? 22),
      onPressed: onTap,
      splashRadius: splashRadius ?? 18,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildResponsiveFooterIcons() {
    final screenWidth = MediaQuery.of(context).size.width;

    // Ajuster les tailles selon la largeur d'écran
    double iconSize = 22;
    double splashRadius = 18;
    double spacing = 8;

    if (screenWidth < 320) {
      // Très petits écrans (fold fermé)
      iconSize = 16;
      splashRadius = 12;
      spacing = 2;
    } else if (screenWidth < 400) {
      // Petits écrans
      iconSize = 18;
      splashRadius = 14;
      spacing = 4;
    } else if (screenWidth < 600) {
      // Écrans moyens
      iconSize = 20;
      splashRadius = 16;
      spacing = 6;
    }

    final List<Widget> socialIcons = [
      _footerIcon(
        icon: Icons.facebook,
        color: Colors.white,
        onTap: () => _launchURL(facebookUrl),
        size: iconSize,
        splashRadius: splashRadius,
      ),
      _footerIcon(
        icon: Icons.ondemand_video,
        color: Colors.white,
        onTap: () =>
            _launchURL("https://youtube.com/@ena-rdc?si=frH7Fh37HPuNbLno"),
        size: iconSize,
        splashRadius: splashRadius,
      ),
      _footerIcon(
        icon: Icons.link,
        color: Colors.white,
        onTap: () => _launchURL(linkedinUrl),
        size: iconSize,
        splashRadius: splashRadius,
      ),
      _footerIcon(
        icon: Icons.email,
        color: Colors.white,
        onTap: () => _launchURL("mailto:contact@ena.cd"),
        size: iconSize,
        splashRadius: splashRadius,
      ),
      _footerIcon(
        icon: Icons.message,
        color: Colors.white,
        onTap: () => _launchURL(whatsappUrl),
        size: iconSize,
        splashRadius: splashRadius,
      ),
    ];

    // Garder la disposition horizontale sur tous les écrans
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: socialIcons
          .map(
            (icon) => Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: icon,
            ),
          )
          .toList(),
    );
  }

  void _showMenuBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        minHeight: 200,
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle pour indiquer qu'on peut glisser
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ...List.generate(
                    menuLabels.length,
                    (i) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0,
                          ),
                          leading: Icon(
                            i == 0
                                ? Icons.home_rounded
                                : i == 1
                                ? Icons.newspaper_rounded
                                : i == 2
                                ? Icons.assignment_rounded
                                : i == 3
                                ? Icons.school_rounded
                                : Icons.mail_rounded,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF013068),
                            size: 27,
                          ),
                          title: Text(
                            menuLabels[i]["title"]!,
                            style: GoogleFonts.poppins(
                              fontWeight: i == widget.selectedIndex
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 16,
                              color: i == widget.selectedIndex
                                  ? (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF60A5FA)
                                        : const Color(0xFF3678FF))
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onMenuChanged(i);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 64, bottom: 8),
                          child: Text(
                            menuLabels[i]["desc"]!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Espace en bas pour éviter que le dernier élément soit coupé
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotifications(BuildContext context) {
    return Stack(
      children: [
        // Zone transparente cliquable pour fermer le menu (couvre tout l'écran)
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _showNotifications = false),
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.black.withValues(alpha: 0.04),
            ),
          ),
        ),
        // Menu positionné
        Positioned(
          top: 65,
          right: 18,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
                minWidth: 280,
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 16, bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF3678FF),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            "Notifications",
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).textTheme.headlineSmall?.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _showNotifications = false);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const NotificationsScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Voir tout",
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF60A5FA)
                                  : const Color(0xFF3678FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 0, color: Theme.of(context).dividerColor),
                  
                  // Contenu scrollable
                  Flexible(
                    child: _notifications.isEmpty 
                        ? _buildEmptyNotifications()
                        : _buildNotificationsList(),
                  ),
                  
                  if (_notifications.isNotEmpty) ...[
                    Divider(color: Theme.of(context).dividerColor),
                    TextButton(
                      onPressed: _markAllNotificationsAsRead,
                      child: Text(
                        "Marquer tout comme lu",
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF3678FF),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyNotifications() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white54
                : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "Vous n'avez pas encore de notification",
            style: GoogleFonts.poppins(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    // Filtrer seulement les notifications non lues pour le menu header
    final unreadNotifications = _notifications.where((n) => !n.isRead).toList();
    // Prendre seulement les 3 premières notifications non lues pour le menu déroulant
    final limitedNotifications = unreadNotifications.take(3).toList();
    
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 180, // Hauteur pour environ 3 notifications
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: limitedNotifications.length,
        itemBuilder: (context, index) {
          final notification = limitedNotifications[index];
          return _buildNotificationTile(notification);
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    return Material(
      color: notification.isRead 
          ? Theme.of(context).cardColor
          : (Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E3A8A)
              : const Color(0xFFEDF2FD)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: notification.typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            notification.typeIcon,
            color: notification.typeColor,
            size: 18,
          ),
        ),
        title: Text(
          notification.title,
          style: GoogleFonts.poppins(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: notification.typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                notification.type.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: notification.typeColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notification.truncatedMessage,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              notification.formattedDate,
              style: GoogleFonts.poppins(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: notification.typeColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: () {
          _markNotificationAsRead(notification);
          setState(() => _showNotifications = false);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          );
        },
      ),
    );
  }

  void _launchURL(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Lien non accessible.")));
      }
    }
  }

  Widget _buildResponsiveBottomRow() {
    final screenWidth = MediaQuery.of(context).size.width;

    // Ajuster les tailles de texte selon la largeur d'écran
    double fontSize = 11;
    if (screenWidth < 320) {
      fontSize = 9;
    } else if (screenWidth < 400) {
      fontSize = 10;
    }

    // Si l'écran est très petit, empiler verticalement
    if (screenWidth < 300) {
      return Column(
        children: [
          Text(
            "© 2025 Tous droits réservés",
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.87),
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _launchURL("https://www.ena.cd"),
            child: Text(
              "Site web : www.ena.cd",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: fontSize,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    // Sinon, garder la disposition horizontale avec texte flexible
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            "© 2025 Tous droits réservés",
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.87),
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: GestureDetector(
            onTap: () => _launchURL("https://www.ena.cd"),
            child: Text(
              "Site web : www.ena.cd",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: fontSize,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          "Déconnexion",
          style: TextStyle(
            color: Theme.of(context).textTheme.headlineSmall?.color,
          ),
        ),
        content: Text(
          "Voulez-vous vraiment vous déconnecter ?",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              "Annuler",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              "Se déconnecter",
              style: TextStyle(color: Color(0xFFF87171)),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      widget.onAvatarTap();
    }
  }

  /// Retourne le nom affiché dans l'ordre : prénom, nom, postnom
  String _getDisplayName() {
    if (_userInfo == null) return "Utilisateur";
    
    List<String> nameParts = [];
    
    // Prénom
    if (_userInfo!.firstName.isNotEmpty) {
      nameParts.add(_userInfo!.firstName);
    }
    
    // Nom
    if (_userInfo!.lastName.isNotEmpty) {
      nameParts.add(_userInfo!.lastName);
    }
    
    // Postnom
    if (_userInfo!.middleName != null && _userInfo!.middleName!.isNotEmpty) {
      nameParts.add(_userInfo!.middleName!);
    }
    
    return nameParts.isNotEmpty ? nameParts.join(' ') : "Utilisateur";
  }

  /// Gère les événements de mise à jour du profil
  void _onProfileUpdated(ProfileUpdateEvent event) {
    if (!mounted) return;
    
    print('🔄 EnaMainLayout: Profile update received');
    print('   - Event: $event');
    
    // Si des données visuelles ont été mises à jour, rafraîchir depuis le cache
    if (event.requiresUIRefresh) {
      _loadUserInfoFromCache();
      print('   - Header UI refreshed from cache');
    }
  }
  
  @override
  void dispose() {
    _profileUpdateSubscription?.cancel();
    super.dispose();
  }
}
