import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../services/in_app_message_service.dart';

/// Handler pour messages en background (fonction top-level requise par FCM)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background message: ${message.notification?.title}');
}

/// Service de gestion des notifications push Firebase Cloud Messaging
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  static String? _fcmToken;
  
  // Callback pour navigation depuis notification
  static void Function(String?)? onNotificationTap;
  
  // Context global pour afficher dialogs (sera set par main.dart)
  static BuildContext? _globalContext;
  
  /// Set le context global (appelé depuis main.dart)
  static void setContext(BuildContext context) {
    _globalContext = context;
  }

  /// Initialiser le service de notifications push
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 Initializing Push Notification Service...');
      
      // 1. Demander permission (iOS uniquement, Android auto depuis API 33-)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted permission for notifications');
      } else {
        debugPrint('❌ User declined or has not accepted notification permissions');
        return;
      }

      // 2. Configurer notifications locales (affichage en foreground)
      await _initializeLocalNotifications();

      // 3. Obtenir FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('🔑 FCM Token: $_fcmToken');
      
      // Sauvegarder token localement
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }

      // 4. Écouter les refresh de token
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token refreshed: $newToken');
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('fcm_token', newToken);
        });
      });

      // 5. S'abonner aux topics par défaut
      await subscribeToTopic('ena_general');

      // 6. Gérer notifications en différents états
      _setupMessageHandlers();

      // 7. Configurer handler background
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      _isInitialized = true;
      debugPrint('✅ Push Notification Service initialized successfully');
      
      // Analytics
      await FirebaseAnalytics.instance.logEvent(
        name: 'push_notifications_enabled',
      );
      
    } catch (e) {
      debugPrint('❌ Error initializing push notifications: $e');
    }
  }

  /// Initialiser les notifications locales (Flutter Local Notifications)
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Créer le canal Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'ena_notifications',
        'Notifications ENA',
        description: 'Notifications importantes de l\'École Nationale d\'Administration',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  /// Configuration des handlers de messages
  static void _setupMessageHandlers() {
    // 1. Message reçu en FOREGROUND (app ouverte)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 2. Message cliqué quand app en BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // 3. Message cliqué quand app FERMÉE (vérifier au démarrage)
    _checkInitialMessage();
  }

  /// Gérer message en foreground (afficher dialog in-app)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📩 Notification reçue en foreground: ${message.notification?.title}');

    final notification = message.notification;
    if (notification != null && _globalContext != null) {
      // Afficher dialog in-app au lieu d'une notification système
      await InAppMessageService.showPushNotificationDialog(
        _globalContext!,
        title: notification.title ?? 'ENA',
        message: notification.body ?? '',
        type: message.data['type'] ?? 'info',
        link: message.data['link'],
      );

      // Analytics
      await FirebaseAnalytics.instance.logEvent(
        name: 'notification_received_foreground',
        parameters: {'type': message.data['type'] ?? 'info'},
      );
    }
  }

  /// Gérer tap sur notification (background)
  static void _handleBackgroundMessageTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped from background');
    _navigateFromNotification(message.data['link']);
    
    FirebaseAnalytics.instance.logEvent(
      name: 'notification_tapped',
      parameters: {'source': 'background'},
    );
  }

  /// Vérifier si app ouverte via notification (terminated state)
  static Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 App ouvert via notification');
      _navigateFromNotification(initialMessage.data['link']);
      
      FirebaseAnalytics.instance.logEvent(
        name: 'notification_tapped',
        parameters: {'source': 'terminated'},
      );
    }
  }

  /// Navigation depuis notification
  static void _navigateFromNotification(String? link) {
    if (link != null && onNotificationTap != null) {
      onNotificationTap!(link);
    }
  }

  /// Callback pour tap sur notification locale
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Local notification tapped: ${response.payload}');
    _navigateFromNotification(response.payload);
  }

  /// S'abonner à un topic FCM
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
      
      await FirebaseAnalytics.instance.logEvent(
        name: 'subscribed_to_topic',
        parameters: {'topic': topic},
      );
    } catch (e) {
      debugPrint('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Se désabonner d'un topic FCM
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
      
      await FirebaseAnalytics.instance.logEvent(
        name: 'unsubscribed_from_topic',
        parameters: {'topic': topic},
      );
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Supprimer le token (logout)
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      _fcmToken = null;
      debugPrint('🗑️ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }

  /// Obtenir le token FCM actuel
  static String? get fcmToken => _fcmToken;
  
  /// Vérifier si le service est initialisé
  static bool get isInitialized => _isInitialized;
}
