import 'dart:async';
import 'package:dart_openai/dart_openai.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class EnaMwindaChatService {
  static bool _isInitialized = false;
  static List<OpenAIChatCompletionChoiceMessageModel> _conversationHistory = [];
  static int _offTopicCount = 0;

  // Cache des informations importantes pour éviter les recherches répétées
  static final Map<String, String> _infoCache = {};
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheValidityDuration = Duration(hours: 6);

  static final List<String> _welcomeMessages = [
    '''Bonjour et bienvenue ! 👋

Je suis ENA, votre assistant virtuel de l'École Nationale d'Administration de la République Démocratique du Congo.

Mon rôle est de vous accompagner et répondre à toutes vos questions concernant notre institution d'excellence.

Quelle est votre préoccupation aujourd'hui ? 😊''',

    '''Salutations ! 🎓

ENA à votre service ! Je suis l'assistant virtuel officiel de l'École Nationale d'Administration de la RDC.

Je suis là pour éclairer vos interrogations sur notre école, nos formations, et tout ce qui concerne l'ENA.

Comment puis-je vous être utile ? 💫''',

    '''Bonsoir/Bonjour ! ✨

Je me présente : ENA, votre guide virtuel pour l'École Nationale d'Administration du Congo.

Ma mission est de vous fournir toutes les informations dont vous avez besoin sur notre prestigieuse institution.

Dites-moi, que souhaitez-vous savoir ? 🌟''',
  ];

  static const String systemPrompt = '''Tu es ENA, l'assistant virtuel officiel de l'École Nationale d'Administration de la République Démocratique du Congo (ENA RDC).

🎯 TON RÔLE ET PERSONNALITÉ :
- Tu es un assistant institutionnel COOL mais PROFESSIONNEL
- Tu représentes l'excellence et le prestige de l'ENA RDC
- Tu es serviable, courtois et à l'écoute
- Ton ton est chaleureux mais garde toujours la dignité institutionnelle
- Tu tutoyes naturellement mais avec respect
- Tu réponds NATURELLEMENT aux salutations et conversations courantes
- Tu es CONVERSATIONNEL et HUMAIN dans tes interactions
- Tu es aussi le GUIDE EXPERT de l'application MyENA

💬 RÉPONSES AUX SALUTATIONS ET CONVERSATIONS :
- Pour "Bonjour" ou "Salut" : Réponds chaleureusement et propose ton aide
- Pour "Ça va ?" : Réponds de façon amicale et redirige vers l'ENA naturellement
- Pour "Merci" : Réponds poliment et propose d'autres questions
- Sois toujours naturel et évite les réponses robotiques
- EXEMPLE : "Bonjour ! Ça va très bien merci ! 😊 Je suis là pour t'aider avec toutes tes questions sur l'ENA. Que veux-tu savoir ?"

�️ GUIDE DE NAVIGATION MyENA - TON EXPERTISE PRINCIPALE :

**STRUCTURE PRINCIPALE :**
1. **Accueil** (🏠) - Tableau de bord, profil, notifications, état candidature
2. **Actualités** (📰) - News ENA, annonces, flux Twitter @EnaRDC_Officiel
3. **Inscription** (📝) - Candidature, suivi dossier, PDF, recours
4. **Prépa-ENA** (🎓) - Quiz, préparation concours, ressources
5. **Contact** (📧) - Infos contact, FAQ, réseaux sociaux

**ÉLÉMENTS D'INTERFACE :**
- **Avatar** (haut-gauche) → Profil, déconnexion
- **Cloche 🔔** (haut-droite) → Notifications (badge rouge = non lues)
- **Menu burger ≡** (haut-droite) → Navigation principale
- **Chat flottant bleu** → Moi ! Toujours disponible 😊

**FONCTIONNALITÉS CLÉS À EXPLIQUER :**
- Voir candidature : Onglet "Inscription" → statut et détails
- Faire recours : "Inscription" → "Faire un recours" → upload Word (5MB max)
- Quiz prépa : "Prépa-ENA" → choisir matière
- PDF dossier : "Inscription" → "Télécharger PDF"
- Changer thème : Menu burger → Paramètres → Mode sombre
- Notifications : Icône cloche 🔔
- Modifier profil : Avatar → Profil

�📚 TES CAPACITÉS DE RECHERCHE AVANCÉE :
- Tu exploites INTELLIGEMMENT les informations des sites officiels ENA
- Tu SYNTHÉTISES les données trouvées pour donner des réponses PRÉCISES
- Tu EXTRAIS les informations clés (noms, dates, fonctions) des contenus web
- Tu COMBINES ces données avec tes connaissances pour des réponses complètes
- Quand tu as des informations récentes des sites, tu les utilises PRIORITAIREMENT

🎯 TES SOURCES OFFICIELLES :
- Site principal : www.ena.cd (avec pages spécialisées direction, organisation)
- Ministère Fonction Publique : https://fonctionpublique.gouv.cd  
- Twitter officiel : @EnaRDC_Officiel
- YouTube officiel : @ena-rdc
- Application MyENA

📋 INFORMATIONS INSTITUTIONNELLES ACTUALISÉES :

🏛️ DIRECTION ACTUELLE (2024-2025) :
- Directeur Général : Cédrick TOMBOLA MUKE (depuis décembre 2024)
  • Économiste, ancien DG CNSSAP, consultant Banque mondiale
- Directeur Général Adjoint : Henry MAHANGU MONGA MAMBILI
- Président Conseil d'Administration : Pierre BIDUAYA BEYA

📚 FORMATIONS DISPONIBLES :
- Formation initiale : 12 mois, ~100 étudiants/promotion, concours (18-35 ans, BAC+5)
- Formation continue : modules pour fonctionnaires en poste
- Masters avec Université Senghor : GMP et MAITENA

🎯 ADMISSION 2025 :
- Gratuit, nationalité congolaise, BAC+5, <35 ans
- Épreuves : dissertation (4h) + entretien (30min)
- Dossier : ID, CV, motivation, diplôme, aptitude physique

📍 CONTACTS :
- Email : info@ena.cd | Tél : +243 832 222 920
- Adresse : Bât. Fonction Publique, 3e niveau, Gombe, Kinshasa

🎮 RÉPONSES DE NAVIGATION - EXEMPLES TYPES :
- "Où voir mes notes ?" → "Va dans l'onglet **Prépa-ENA** 🎓 pour voir tes résultats de quiz et ton suivi de progression !"
- "Comment postuler ?" → "Clique sur l'onglet **Inscription** 📝 en bas de l'écran pour accéder au formulaire de candidature !"
- "Mes notifications ?" → "Clique sur l'icône cloche 🔔 en haut à droite ! Un badge rouge te montre le nombre de notifications non lues."
- "Changer de thème ?" → "Menu burger ≡ → **Paramètres** → Active le **Mode sombre** selon tes préférences ! 🌙"

⚠️ RÈGLES POUR QUESTIONS VRAIMENT HORS-SUJET :
1. PREMIÈRE question hors ENA : Réponds brièvement ET demande de revenir à l'ENA dans le MÊME message
2. DEUXIÈME question hors ENA : Ne réponds PAS, demande seulement de parler de l'ENA
3. Reste toujours courtois et institutionnel
4. ATTENTION : Les salutations, remerciements et conversation naturelle ne sont JAMAIS hors-sujet !

💬 TON STYLE DE RÉPONSE OPTIMISÉ :
- Utilise PRIORITAIREMENT les informations récentes des sites officiels
- Pour la navigation app : Sois PRÉCIS avec les icônes et emplacements
- Cite tes sources quand tu utilises des données web : "Selon le site officiel..."
- Donne des réponses précises avec noms exacts, dates, détails
- Termine par "📍 Pour plus d'informations détaillées, consultez www.ena.cd"
- Reste concis mais informatif (3-4 phrases max)
- Évite les répétitions et va à l'essentiel
- Sois NATUREL et CONVERSATIONNEL
- Utilise des émojis pour rendre les explications plus claires

🔍 EXEMPLES DE RÉPONSES ATTENDUES AVEC DONNÉES WEB :
- "Le Directeur Général de l'ENA est Cédrick TOMBOLA MUKE (depuis décembre 2024), économiste et ancien DG de la CNSSAP. Il est assisté de Henry MAHANGU MONGA MAMBILI comme DG Adjoint..."
- "L'ENA a été créée en 1960 sous le nom d'ENDA, restructurée en ENAP en 2001, puis établie définitivement par décret n°13/013 du 16 avril 2013..."
- "Pour 2025, l'admission à l'ENA requiert BAC+5, nationalité congolaise, moins de 35 ans. Épreuves : dissertation 4h + entretien 30min. Gratuit - surveiller ena.cd..."

❌ NE DIS JAMAIS "je n'ai pas accès à cette information" si des données sont fournies par la recherche web.
✅ UTILISE TOUJOURS les informations trouvées pour construire ta réponse de façon CONCISE et PRÉCISE.
✅ SOIS NATUREL ET CONVERSATIONNEL dans toutes tes interactions.
✅ GUIDE EXPERTEMENT les utilisateurs dans l'application MyENA avec des instructions CLAIRES et des émojis.''';

  static Future<void> initialize() async {
    OpenAI.apiKey = ApiConfig.openaiApiKey;
    OpenAI.requestsTimeOut = const Duration(seconds: 30);
    
    // Ajouter le prompt système à l'historique
    _conversationHistory.add(
      OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPrompt)
        ],
        role: OpenAIChatMessageRole.system,
      ),
    );
    
    _isInitialized = true;
  }

  static Future<String> sendMessage(String userMessage) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // D'abord, vérifier si c'est une question de navigation dans l'app
      final navigationResponse = _checkNavigationQuestion(userMessage);
      if (navigationResponse != null) {
        return navigationResponse;
      }

      // Vérifier si la question est hors-sujet
      bool isOffTopic = _isQuestionOffTopic(userMessage);

      if (isOffTopic) {
        _offTopicCount++;

        if (_offTopicCount == 1) {
          // Première fois : réponse directe + redirection
          return '''Je peux vous aider avec cela, mais mon expertise se concentre principalement sur l'École Nationale d'Administration de la RDC.

Revenons plutôt à l'ENA : avez-vous des questions sur nos formations, les procédures d'admission, ou les actualités de notre école ? 🎓''';
        } else if (_offTopicCount >= 2) {
          return _getSecondOffTopicResponse();
        }
      } else {
        _offTopicCount = 0; // Reset si la question est pertinente
      }

      // Pour les questions ENA, améliorer le contexte avec recherche web OPTIMISÉE
      String enhancedMessage = userMessage;
      String webContext = '';

      if (_containsEnaKeywords(userMessage)) {
        // Vérifier d'abord le cache
        webContext = _getCachedInfo(userMessage);

        if (webContext.isEmpty) {
          // Recherche web ciblée et rapide
          webContext = await _searchWebInformationOptimized(userMessage);
          if (webContext.isNotEmpty) {
            _cacheInfo(userMessage, webContext);
          }
        }

        // Enrichir le contexte avec les données institutionnelles
        webContext = _enrichWithInstitutionalData(userMessage, webContext);

        if (webContext.isNotEmpty) {
          enhancedMessage =
              "$userMessage\n\nCONTEXTE RÉCENT TROUVÉ :\n$webContext\n\nRÉPONDS de façon CONCISE en utilisant ces informations récentes.";
        } else {
          enhancedMessage =
              "$userMessage\n\nRÉPONDS de façon CONCISE avec tes connaissances sur l'ENA.";
        }
      }

      // Ajouter le message utilisateur à l'historique
      _conversationHistory.add(
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(enhancedMessage)
          ],
          role: OpenAIChatMessageRole.user,
        ),
      );

      // Appel à l'API OpenAI
      final response = await OpenAI.instance.chat.create(
        model: "gpt-4o-mini",
        messages: _conversationHistory,
        temperature: 0.6,
        maxTokens: 250,
        topP: 0.9,
      );

      String botResponse = response.choices.first.message.content?.first.text ?? 
                          "Désolé, je n'ai pas pu traiter votre demande.";

      // Ajouter la réponse du bot à l'historique
      _conversationHistory.add(
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(botResponse)
          ],
          role: OpenAIChatMessageRole.assistant,
        ),
      );

      return botResponse;
    } catch (e) {
      return "Une erreur s'est produite. Veuillez réessayer dans un moment.";
    }
  }

  static String getWelcomeMessage() {
    _welcomeMessages.shuffle();
    return _welcomeMessages.first;
  }

  /// Recherche web optimisée - plus rapide et ciblée
  static Future<String> _searchWebInformationOptimized(String query) async {
    try {
      // URLs prioritaires basées sur le type de question
      List<String> targetUrls = _getTargetUrls(query);

      String context = '';
      List<Future<String>> futures = [];

      // Recherche en parallèle sur maximum 3 sites pour la rapidité
      for (int i = 0; i < targetUrls.length && i < 3; i++) {
        futures.add(_fetchSinglePage(targetUrls[i], query));
      }

      // Attendre toutes les réponses avec timeout global
      try {
        List<String> results = await Future.wait(
          futures,
          eagerError: false,
        ).timeout(Duration(seconds: 8));

        for (String result in results) {
          if (result.isNotEmpty) {
            context += result;
          }
        }
      } catch (e) {
        // Timeout ou erreur - continuer avec ce qu'on a
      }

      return context;
    } catch (e) {
      return '';
    }
  }

  /// Récupère une seule page de façon optimisée
  static Future<String> _fetchSinglePage(String url, String query) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Mobile; rv:40.0) Gecko/40.0 Firefox/40.0',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            },
          )
          .timeout(Duration(seconds: 4)); // Timeout réduit

      if (response.statusCode == 200) {
        String content = response.body;

        // Nettoyage HTML optimisé
        content = content.replaceAll(
          RegExp(r'<script[^>]*>.*?</script>', dotAll: true),
          '',
        );
        content = content.replaceAll(
          RegExp(r'<style[^>]*>.*?</style>', dotAll: true),
          '',
        );
        content = content.replaceAll(RegExp(r'<[^>]*>'), ' ');
        content = content.replaceAll(RegExp(r'&[a-zA-Z0-9#]+;'), ' ');
        content = content.replaceAll(RegExp(r'\s+'), ' ');

        // Extraction ciblée et intelligente
        List<String> relevantSentences = _extractRelevantSentences(
          content,
          query,
        );

        if (relevantSentences.isNotEmpty) {
          return "📍 Source $url:\n${relevantSentences.take(2).join('. ')}\n\n";
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Extrait les phrases les plus pertinentes
  static List<String> _extractRelevantSentences(String content, String query) {
    List<String> relevantSentences = [];
    final keywords = _extractKeywords(query);

    // Diviser en phrases
    List<String> sentences = content.split(RegExp(r'[.!?]+'));

    for (String sentence in sentences) {
      sentence = sentence.trim();
      if (sentence.length > 20 && sentence.length < 200) {
        // Priorité spéciale pour les informations sur le DG
        if (_isDirectorQuery(query) && _containsDirectorInfo(sentence)) {
          relevantSentences.insert(0, sentence); // Insérer au début
          continue;
        }

        // Recherche par mots-clés avec score
        int score = _calculateRelevanceScore(sentence, keywords);
        if (score >= 2) {
          relevantSentences.add(sentence);
        }
      }

      if (relevantSentences.length >= 4) break;
    }

    return relevantSentences;
  }

  /// Calcule un score de pertinence pour une phrase
  static int _calculateRelevanceScore(String sentence, List<String> keywords) {
    final lowerSentence = sentence.toLowerCase();
    int score = 0;

    for (String keyword in keywords) {
      if (lowerSentence.contains(keyword)) {
        score++;
      }
    }

    // Bonus si contient ENA
    if (lowerSentence.contains('ena')) score += 2;

    // Bonus pour des mots importants
    if (lowerSentence.contains('directeur') || lowerSentence.contains('dg')) {
      score += 2;
    }
    if (lowerSentence.contains('création') || lowerSentence.contains('fondé')) {
      score += 1;
    }

    return score;
  }

  /// Obtient les URLs cibles selon le type de question
  static List<String> _getTargetUrls(String query) {
    final lowerQuery = query.toLowerCase();

    if (_isDirectorQuery(query)) {
      return [
        'https://www.ena.cd/direction',
        'https://www.ena.cd/organisation',
        'https://www.ena.cd',
      ];
    } else if (lowerQuery.contains('formation') ||
        lowerQuery.contains('cursus')) {
      return [
        'https://www.ena.cd/formation',
        'https://www.ena.cd',
        'https://fonctionpublique.gouv.cd',
      ];
    } else if (lowerQuery.contains('actualité') ||
        lowerQuery.contains('nouvelle')) {
      return [
        'https://www.ena.cd/actualites',
        'https://www.ena.cd',
        'https://fonctionpublique.gouv.cd',
      ];
    } else {
      return [
        'https://www.ena.cd',
        'https://www.ena.cd/about',
        'https://fonctionpublique.gouv.cd',
      ];
    }
  }

  /// Gestion du cache pour éviter les recherches répétées
  static String _getCachedInfo(String query) {
    if (_lastCacheUpdate == null ||
        DateTime.now().difference(_lastCacheUpdate!) > _cacheValidityDuration) {
      _infoCache.clear();
      return '';
    }

    final queryKey = _normalizeQuery(query);
    return _infoCache[queryKey] ?? '';
  }

  static void _cacheInfo(String query, String info) {
    final queryKey = _normalizeQuery(query);
    _infoCache[queryKey] = info;
    _lastCacheUpdate = DateTime.now();
  }

  static String _normalizeQuery(String query) {
    final lowerQuery = query.toLowerCase();
    if (_isDirectorQuery(query)) return 'directeur_general';
    if (lowerQuery.contains('création')) return 'creation_ena';
    if (lowerQuery.contains('formation')) return 'formation_ena';
    return 'general_info';
  }

  static bool _isQuestionOffTopic(String message) {
    final lowerMessage = message.toLowerCase();

    // Salutations et conversation naturelle - JAMAIS hors-sujet
    final conversationKeywords = [
      'bonjour',
      'bonsoir',
      'salut',
      'hello',
      'hi',
      'ça va',
      'comment allez',
      'comment tu vas',
      'bonne journée',
      'bonne soirée',
      'merci',
      'mercie',
      'ok',
      'okay',
      'd\'accord',
      'parfait',
      'super',
      'excellent',
      'bien',
      'compris',
      'clair',
    ];

    // Navigation et utilisation de l'app - JAMAIS hors-sujet
    final navigationKeywords = [
      'app',
      'application',
      'myena',
      'naviguer',
      'navigation',
      'menu',
      'onglet',
      'notification',
      'profil',
      'avatar',
      'candidature',
      'inscription',
      'quiz',
      'prépa',
      'prepa',
      'pdf',
      'télécharger',
      'recours',
      'thème',
      'theme',
      'paramètre',
      'chat',
      'aide',
      'actualité',
      'contact',
      'où',
      'comment',
      'guide',
      'utiliser',
      'trouve',
      'cloche',
      'bouton',
      'écran',
      'page',
    ];

    // Si c'est une conversation naturelle ou navigation, ce n'est PAS hors-sujet
    if (conversationKeywords.any((keyword) => lowerMessage.contains(keyword)) ||
        navigationKeywords.any((keyword) => lowerMessage.contains(keyword))) {
      return false;
    }

    // Mots-clés liés à l'ENA (plus complets)
    final enaKeywords = [
      'ena',
      'école',
      'administration',
      'concours',
      'formation',
      'étude',
      'cursus',
      'diplôme',
      'calendrier',
      'date',
      'nouvelle',
      'annonce',
      'dossier',
      'document',
      'directeur',
      'dg',
      'staff',
      'personnel',
      'enseignant',
      'campus',
      'kinshasa',
      'rdc',
      'congo',
      'fonctionnaire',
      'ministère',
      'gouvernement',
      'public',
      'service',
      'admission',
      'sélection',
      'test',
      'examen',
    ];

    return !enaKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  static bool _containsEnaKeywords(String message) {
    return !_isQuestionOffTopic(message);
  }

  /// Détecte les questions de navigation dans l'application MyENA
  static String? _checkNavigationQuestion(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Détection des questions de navigation avec réponses directes
    final navigationPatterns = {
      // Navigation générale
      RegExp(r'\b(comment|où|navigation|naviguer|menu|onglet)\b.*\b(app|application|myena)\b'): 
        'Pour naviguer dans MyENA, utilise le **menu burger ≡** en haut à droite ! 📱\n\nTu as 5 onglets principaux :\n🏠 **Accueil** - Tableau de bord\n📰 **Actualités** - News ENA\n📝 **Inscription** - Candidature\n🎓 **Prépa-ENA** - Quiz\n📧 **Contact** - Infos utiles',
      
      // Notifications
      RegExp(r'\b(notification|notif|cloche|alerte)\b'): 
        'Tes notifications se trouvent en cliquant sur l\'icône **cloche 🔔** en haut à droite ! 📬\n\nUn badge rouge indique le nombre de notifications non lues. Tu peux les marquer comme lues et les filtrer par type.',
      
      // Profil
      RegExp(r'\b(profil|avatar|photo|compte|déconnect)\b'): 
        'Pour accéder à ton profil, clique sur ton **avatar** (photo) en haut à gauche ! 👤\n\nTu peux :\n• Modifier tes infos personnelles\n• Changer ta photo\n• Modifier ton mot de passe\n• Te déconnecter',
      
      // Candidature/Inscription
      RegExp(r'\b(candidature|inscription|dossier|postuler|état|statut)\b'): 
        'Pour voir ta candidature, va dans l\'onglet **Inscription** 📝 en bas de l\'écran !\n\nTu y trouveras :\n• Le statut de ton dossier\n• Tes documents uploadés\n• Le bouton "Télécharger PDF"\n• L\'option "Faire un recours"',
      
      // Quiz/Prépa
      RegExp(r'\b(quiz|prépa|prepa|test|exercice|matière|note|résultat)\b'): 
        'Pour les quiz de préparation, clique sur **Prépa-ENA** 🎓 !\n\nTu peux :\n• Choisir une matière\n• Faire des quiz interactifs\n• Voir tes résultats\n• Suivre ta progression',
      
      // PDF/Téléchargement
      RegExp(r'\b(pdf|télécharger|download|document)\b'): 
        'Pour télécharger ton dossier en PDF : **Inscription** 📝 → **"Télécharger PDF"** 📄\n\nLe PDF contient toutes tes informations de candidature et documents uploadés !',
      
      // Recours
      RegExp(r'\b(recours|réclamation|plainte|contester)\b'): 
        'Pour faire un recours : **Inscription** 📝 → **"Faire un recours"** ⚖️\n\nTu peux uploader des fichiers Word (.doc/.docx) de maximum 5MB pour appuyer ta demande.',
      
      // Thème/Paramètres
      RegExp(r'\b(thème|theme|sombre|clair|paramètre|setting)\b'): 
        'Pour changer le thème : **Menu burger ≡** → **Paramètres** → **Mode sombre** 🌙\n\nTu peux aussi personnaliser les transitions et notifications !',
      
      // Chat/Aide
      RegExp(r'\b(chat|aide|assistant|bot|ici)\b'): 
        'Tu me trouves toujours via le **bouton bleu flottant** 💬 présent sur toutes les pages !\n\nJe peux t\'aider avec l\'ENA et te guider dans l\'application. N\'hésite pas à me poser tes questions ! 😊',
      
      // Actualités
      RegExp(r'\b(actualité|actus|news|nouvelle|annonce|twitter)\b'): 
        'Les actualités ENA sont dans l\'onglet **Actualités** 📰 !\n\nTu y trouveras :\n• Les dernières nouvelles\n• Les annonces officielles\n• Le flux Twitter @EnaRDC_Officiel\n• Photos et vidéos',
      
      // Contact
      RegExp(r'\b(contact|contacter|téléphone|email|adresse)\b'): 
        'Pour contacter l\'ENA : onglet **Contact** 📧 !\n\nTu y trouveras :\n• Email : info@ena.cd\n• Tél : +243 832 222 920\n• Adresse complète\n• Liens réseaux sociaux\n• FAQ détaillée',
    };
    
    // Recherche de correspondances
    for (final entry in navigationPatterns.entries) {
      if (entry.key.hasMatch(lowerMessage)) {
        return entry.value;
      }
    }
    
    // Questions très générales sur l'utilisation
    if (RegExp(r'\b(comment.*utiliser|aide.*app|guide.*app|pas.*trouve)\b').hasMatch(lowerMessage)) {
      return 'Je suis là pour t\'aider à naviguer dans MyENA ! 🗺️\n\n**Navigation :** Menu burger ≡ pour les 5 onglets principaux\n**Notifications :** Cloche 🔔 en haut à droite\n**Profil :** Avatar en haut à gauche\n**Chat :** Bouton bleu flottant (moi ! 😊)\n\nQue cherches-tu précisément ?';
    }
    
    return null; // Pas une question de navigation
  }

  static List<String> _extractKeywords(String query) {
    final lowerQuery = query.toLowerCase();
    List<String> keywords = lowerQuery.split(' ');

    // Ajout de synonymes et variantes
    if (lowerQuery.contains('directeur') || lowerQuery.contains('dg')) {
      keywords.addAll(['directeur', 'général', 'dg', 'direction', 'dirigeant']);
    }
    if (lowerQuery.contains('création') || lowerQuery.contains('créé')) {
      keywords.addAll(['création', 'créé', 'fondé', 'établi', 'histoire']);
    }
    if (lowerQuery.contains('formation')) {
      keywords.addAll(['formation', 'cursus', 'programme', 'études']);
    }

    return keywords;
  }

  static bool _isDirectorQuery(String query) {
    final lowerQuery = query.toLowerCase();
    return lowerQuery.contains('directeur') ||
        lowerQuery.contains('dg') ||
        lowerQuery.contains('dirigeant');
  }

  static bool _containsDirectorInfo(String sentence) {
    final lowerSentence = sentence.toLowerCase();
    return (lowerSentence.contains('directeur') ||
            lowerSentence.contains('dg') ||
            lowerSentence.contains('direction')) &&
        (lowerSentence.contains('général') ||
            lowerSentence.contains('ena') ||
            lowerSentence.contains('école'));
  }

  static String _getSecondOffTopicResponse() {
    return '''Je vous remercie pour votre compréhension. Mon mandat se limite aux questions concernant l'École Nationale d'Administration de la RDC.

Comment puis-je vous accompagner dans vos démarches liées à l'ENA ? ✨''';
  }

  static void resetChat() {
    _conversationHistory.clear();
    _offTopicCount = 0;
    _infoCache.clear();
    _isInitialized = false;
  }
  // Base de données institutionnelle enrichie
  static const Map<String, String> _institutionalData = {
    'direction_equipe': '''ÉQUIPE DIRIGEANTE ENA (2024-2025) :
• Directeur Général : Cédrick TOMBOLA MUKE (depuis décembre 2024)
  - Économiste de formation, ancien DG de la CNSSAP
  - Ancien consultant Banque mondiale
  - Remplace Guillaume Banga
• Directeur Général Adjoint : Henry MAHANGU MONGA MAMBILI
• Président du Conseil d'Administration : Pierre BIDUAYA BEYA''',

    'historique_creation': '''HISTOIRE DE L'ENA :
• 1960 : Création sous le nom d'École Nationale de Droit et d'Administration (ENDA)
• 2001 : Restructuration en ENAP (École Nationale d'Administration Publique)
• 2007 : Rebaptisée ENA (École Nationale d'Administration)
• 2013 : Établissement définitif par décret n°13/013 du 16 avril 2013
• Statut : Établissement public à caractère administratif
• Mission : Professionnaliser la haute fonction publique congolaise et moderniser l'administration publique''',

    'formations_programmes': '''PROGRAMMES DE FORMATION ENA :
🎓 FORMATION INITIALE :
• Durée : 12 mois (1 an)
• Capacité : ~100 étudiants par promotion
• Public : Cadres d'État et diplômés universitaires (18-35 ans)
• Accès : Concours d'entrée

📚 FORMATION CONTINUE :
• Modules et ateliers pour fonctionnaires en poste
• Sessions techniques et managériales
• Formations spécialisées (gouvernance, budget, retraite)

🎯 MASTERS (avec Université Senghor d'Alexandrie) :
• Master 2 en Gouvernance et Management Public (GMP)
• Master 2 en Maîtrise d'Ouvrage de Projets de Développement en Afrique (MAITENA)''',

    'admission_concours': '''CONDITIONS D'ADMISSION ENA 2025 :
✅ CRITÈRES :
• Nationalité congolaise obligatoire
• Plénitude des droits civiques
• Diplôme minimum BAC+5
• Âge maximum : 35 ans (nés après 1er janvier 1990 pour 2025)

📁 DOSSIER REQUIS :
• Pièce d'identité (Carte électeur/Passeport) certifiée conforme
• CV avec photo récente
• Lettre de motivation manuscrite au DG de l'ENA
• Diplôme BAC+5 + relevé de notes (certifiés conformes)
• Attestation d'aptitude physique (hôpital public, <3 mois)

📝 ÉPREUVES :
• Écrit : Dissertation (4 heures)
• Oral : Entretien (~30 minutes)

💰 FRAIS : Gratuit (aucun frais de candidature)''',

    'contacts_pratiques': '''INFORMATIONS PRATIQUES ENA :
📍 ADRESSE :
Bâtiment Fonction Publique, 3ᵉ niveau, aile droite
Commune de la Gombe, Kinshasa - RDC

📞 CONTACTS :
• Email officiel : info@ena.cd
• Téléphone : +243 832 222 920
• Site web : www.ena.cd

📅 INSCRIPTIONS 2025 :
• Lancées par le Vice-Premier Ministre/Ministre de la Fonction Publique
• Surveiller ena.cd rubrique "Concours"
• Dates officielles à venir''',

    'actualites_recentes': '''ACTUALITÉS ENA RÉCENTES :
📈 PARTENARIATS ET ÉVÉNEMENTS 2025 :
• 20 juin 2025 : Signature protocole avec Ministère des Finances
• 30 mai 2025 : Conférence KOICA (coopération internationale)
• 22 mai 2025 : Réunion DGDA & Enabel (coopération belge)

🤝 COLLABORATIONS :
• Université Senghor d'Alexandrie (programmes Masters)
• Ministère des Finances (modernisation)
• Organismes internationaux (KOICA, Enabel)'''
  };

  /// Enrichit la réponse avec des données institutionnelles spécifiques
  static String _enrichWithInstitutionalData(String query, String baseContext) {
    String enrichedContext = baseContext;
    final lowerQuery = query.toLowerCase();
    
    // Questions sur la direction et l'équipe dirigeante
    if (lowerQuery.contains('directeur') || lowerQuery.contains('dg') || 
        lowerQuery.contains('dirigeant') || lowerQuery.contains('direction') ||
        lowerQuery.contains('équipe') || lowerQuery.contains('tombola') ||
        lowerQuery.contains('mahangu') || lowerQuery.contains('biduaya')) {
      enrichedContext += '\n\nÉQUIPE DIRIGEANTE :\n${_institutionalData['direction_equipe']!}';
    }
    
    // Questions sur l'histoire et création
    if (lowerQuery.contains('histoire') || lowerQuery.contains('création') || 
        lowerQuery.contains('fondation') || lowerQuery.contains('origine') ||
        lowerQuery.contains('enda') || lowerQuery.contains('enap') ||
        lowerQuery.contains('2013') || lowerQuery.contains('décret')) {
      enrichedContext += '\n\nHISTORIQUE :\n${_institutionalData['historique_creation']!}';
    }
    
    // Questions sur les formations et programmes
    if (lowerQuery.contains('formation') || lowerQuery.contains('programme') || 
        lowerQuery.contains('master') || lowerQuery.contains('cycle') ||
        lowerQuery.contains('cours') || lowerQuery.contains('étude') ||
        lowerQuery.contains('senghor') || lowerQuery.contains('gmp') ||
        lowerQuery.contains('maitena')) {
      enrichedContext += '\n\nFORMATIONS :\n${_institutionalData['formations_programmes']!}';
    }
    
    // Questions sur l'admission et concours
    if (lowerQuery.contains('admission') || lowerQuery.contains('concours') || 
        lowerQuery.contains('candidature') || lowerQuery.contains('inscription') ||
        lowerQuery.contains('critère') || lowerQuery.contains('condition') ||
        lowerQuery.contains('épreuve') || lowerQuery.contains('examen') ||
        lowerQuery.contains('dossier') || lowerQuery.contains('bac+5') ||
        lowerQuery.contains('35 ans') || lowerQuery.contains('2025')) {
      enrichedContext += '\n\nADMISSION :\n${_institutionalData['admission_concours']!}';
    }
    
    // Questions sur les contacts et informations pratiques
    if (lowerQuery.contains('contact') || lowerQuery.contains('adresse') || 
        lowerQuery.contains('téléphone') || lowerQuery.contains('email') ||
        lowerQuery.contains('gombe') || lowerQuery.contains('kinshasa') ||
        lowerQuery.contains('localisation') || lowerQuery.contains('où') ||
        lowerQuery.contains('situe') || lowerQuery.contains('fonction publique')) {
      enrichedContext += '\n\nCONTACTS :\n${_institutionalData['contacts_pratiques']!}';
    }
    
    // Questions sur les actualités récentes
    if (lowerQuery.contains('actualité') || lowerQuery.contains('nouveau') || 
        lowerQuery.contains('récent') || lowerQuery.contains('événement') ||
        lowerQuery.contains('partenariat') || lowerQuery.contains('koica') ||
        lowerQuery.contains('enabel') || lowerQuery.contains('finances') ||
        lowerQuery.contains('2025') || lowerQuery.contains('juin') ||
        lowerQuery.contains('mai')) {
      enrichedContext += '\n\nACTUALITÉS :\n${_institutionalData['actualites_recentes']!}';
    }
    
    return enrichedContext;
  }
}
