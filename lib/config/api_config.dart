// Configuration sécurisée pour les API keys
// Ne jamais commiter ce fichier avec de vraies clés !

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Clés API depuis variables d'environnement (sécurisées)
  static String get youtubeApiKey => dotenv.env['YOUTUBE_API_KEY'] ?? '';
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static String get twitterBearerToken => dotenv.env['TWITTER_BEARER_TOKEN'] ?? '';
  static String get facebookAccessToken => dotenv.env['FACEBOOK_ACCESS_TOKEN'] ?? '';

  // Base URL configurable via environnement
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? "https://ena.gouv.cd";
  
  // Endpoints d'authentification
  static const String registerEndpoint = "/api/users/register/";
  static const String otpEndpoint = "/api/users/otp/";
  static const String loginEndpoint = "/api/token/";
  static const String userInfoEndpoint = "/api/users/user-info/";
  static const String selfResetPasswordEndpoint = "/api/users/self-reset-password/";
  static const String forgotPasswordEndpoint = "/api/users/forgot-password/";
  static const String resetPasswordEndpoint = "/api/users/reset-password/";
  static const String notificationsEndpoint = "/api/users/notifications/";
  static const String markNotificationReadEndpoint = "/api/users/notifications/"; // <uuid>/read/ sera ajouté dynamiquement
  static const String accountDeletionEndpoint = "/api/users/request-account-deletion/";
  
  // Endpoints candidature
  static const String profilCandidatEndpoint = "/api/users/profil-candidat/";
  static const String candidatureAddEndpoint = "/api/recrutement/candidatures-add/";
  
  // Endpoints événements
  static const String programEventsEndpoint = "/api/recrutement/program-events/";
  
  // URLs complètes
  static String get registerUrl => "$baseUrl$registerEndpoint";
  static String get otpUrl => "$baseUrl$otpEndpoint";
  static String get loginUrl => "$baseUrl$loginEndpoint";
  static String get userInfoUrl => "$baseUrl$userInfoEndpoint";
  static String get selfResetPasswordUrl => "$baseUrl$selfResetPasswordEndpoint";
  static String get forgotPasswordUrl => "$baseUrl$forgotPasswordEndpoint";
  static String get resetPasswordUrl => "$baseUrl$resetPasswordEndpoint";
  static String get notificationsUrl => "$baseUrl$notificationsEndpoint";
  static String get markNotificationReadBaseUrl => "$baseUrl$markNotificationReadEndpoint";
  static String get profilCandidatUrl => "$baseUrl$profilCandidatEndpoint";
  static String get candidatureAddUrl => "$baseUrl$candidatureAddEndpoint";
  static String get programEventsUrl => "$baseUrl$programEventsEndpoint";
  static String get accountDeletionUrl => "$baseUrl$accountDeletionEndpoint";

  // IDs et URLs publiques (pas de problème de sécurité)
  static const String enaYtChannelId = 'UCxgeB2LaWwcnbTgdxHk2L_A';
  static const String youtubeChannelUrl = 'https://www.youtube.com/@ena-rdc';
  static const String facebookUrl = 'https://www.facebook.com/ENARDCOfficiel';
  static const String facebookPageId = 'ENARDCOfficiel';
  static const String linkedinUrl = 'https://www.linkedin.com/company/ena-rdc';
  static const String twitterUrl = 'https://x.com/EnaRDC_Officiel';
  static const String whatsappUrl =
      'https://whatsapp.com/channel/0029Vb6Na5uK5cDKslzxom3L';
}
