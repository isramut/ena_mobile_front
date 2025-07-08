// Fichier de configuration API - Exemple
// Copiez ce fichier vers api_config.dart et ajoutez vos vraies clés API

class ApiConfig {
  // Gemini AI pour le chatbot ENA
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';

  // Twitter API pour les tweets @EnaRDC_Officiel
  static const String twitterBearerToken = 'YOUR_TWITTER_BEARER_TOKEN_HERE';

  // URL de base de l'API backend ENA
  static const String baseUrl = 'https://ena.gouv.cd';

  // Configuration du chatbot
  static const String chatbotName = 'ENA';
  static const String twitterUsername = 'EnaRDC_Officiel';

  // Timeout des requêtes (en secondes)
  static const int requestTimeout = 30;
}
