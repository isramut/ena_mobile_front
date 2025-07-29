/// Base de données de guidage pour l'application MyENA
/// Contient toutes les informations pour aider les utilisateurs à naviguer dans l'app
library;

class AppNavigationGuide {
  
  /// Structure principale de navigation MyENA
  static const Map<String, dynamic> navigationStructure = {
    'main_tabs': {
      'count': 5,
      'tabs': [
        {
          'index': 0,
          'name': 'Accueil',
          'icon': 'home_rounded',
          'description': 'Tableau de bord, résumé de la progression et notifications',
          'features': [
            'Résumé du profil utilisateur',
            'État de candidature',
            'Notifications récentes',
            'Événements du programme',
            'Accès rapide aux fonctionnalités',
            'Bouton flottant de chat ENA',
          ]
        },
        {
          'index': 1,
          'name': 'Actualités',
          'icon': 'newspaper_rounded',
          'description': 'Dernières nouvelles, annonces et événements ENA',
          'features': [
            'Articles d\'actualité ENA',
            'Annonces officielles',
            'Événements à venir',
            'Flux Twitter @EnaRDC_Officiel',
            'Photos et vidéos',
          ]
        },
        {
          'index': 2,
          'name': 'Inscription',
          'icon': 'assignment_rounded',
          'description': 'Nouvelle candidature, évolution de la candidature',
          'features': [
            'Formulaire de candidature',
            'Suivi du dossier',
            'Upload de documents',
            'Statut de validation',
            'Génération PDF du dossier',
            'Système de recours',
          ]
        },
        {
          'index': 3,
          'name': 'Prépa-ENA',
          'icon': 'school_rounded',
          'description': 'Préparation au concours, guide et quiz d\'entraînement',
          'features': [
            'Quiz interactifs par matière',
            'Conseils de préparation',
            'Ressources pédagogiques',
            'Suivi de progression',
            'Statistiques de performance',
          ]
        },
        {
          'index': 4,
          'name': 'Contact',
          'icon': 'mail_rounded',
          'description': 'Contact, infos utiles et FAQ',
          'features': [
            'Informations de contact ENA',
            'FAQ détaillée',
            'Liens réseaux sociaux',
            'Formulaire de contact',
            'Numéros utiles',
          ]
        },
      ]
    },
    
    'header_features': {
      'avatar': {
        'location': 'En haut à gauche',
        'function': 'Accéder au profil ou se déconnecter',
        'description': 'Photo de profil cliquable'
      },
      'notifications': {
        'location': 'En haut à droite avec icône cloche 🔔',
        'function': 'Voir les notifications non lues',
        'description': 'Badge rouge indique le nombre de notifications'
      },
      'menu': {
        'location': 'Icône menu burger (≡) en haut à droite',
        'function': 'Ouvrir le menu principal de navigation',
        'description': 'Accès aux 5 sections principales'
      }
    },
    
    'additional_screens': [
      {
        'name': 'Profil',
        'access': 'Cliquer sur l\'avatar en haut à gauche',
        'features': [
          'Modifier les informations personnelles',
          'Changer la photo de profil',
          'Modifier le mot de passe',
          'Paramètres de sécurité biométrique',
        ]
      },
      {
        'name': 'Paramètres',
        'access': 'Via le menu burger → Paramètres',
        'features': [
          'Thème sombre/clair',
          'Paramètres de transition',
          'Préférences de notification',
          'Paramètres biométriques',
        ]
      },
      {
        'name': 'Notifications',
        'access': 'Icône cloche 🔔 en haut à droite',
        'features': [
          'Liste de toutes les notifications',
          'Marquer comme lu',
          'Filtrer par type',
          'Notifications push',
        ]
      },
      {
        'name': 'Chat ENA',
        'access': 'Bouton flottant bleu avec icône chat sur toutes les pages',
        'features': [
          'Assistant virtuel intelligent',
          'Réponses sur l\'ENA et ses formations',
          'Guide d\'utilisation de l\'application',
          'Support conversationnel 24/7',
        ]
      },
      {
        'name': 'Recours',
        'access': 'Section Inscription → Bouton "Faire un recours"',
        'features': [
          'Déposer un recours administratif',
          'Upload de fichiers Word (.doc, .docx)',
          'Limite de 5MB par fichier',
          'Suivi du statut du recours',
        ]
      },
    ]
  };
  
  /// Questions fréquentes sur la navigation
  static const Map<String, String> navigationFAQ = {
    // Navigation générale
    'comment naviguer dans l\'application': 
      'Utilise le menu burger (≡) en haut à droite pour accéder aux 5 sections principales : Accueil, Actualités, Inscription, Prépa-ENA et Contact.',
    
    'où trouver mes notifications': 
      'Clique sur l\'icône cloche 🔔 en haut à droite de l\'écran. Un badge rouge indique le nombre de notifications non lues.',
    
    'comment accéder à mon profil': 
      'Clique sur ta photo de profil (avatar) en haut à gauche de l\'écran principal.',
    
    'comment changer le thème': 
      'Va dans Paramètres via le menu burger, puis active le "Mode sombre" selon tes préférences.',
    
    // Fonctionnalités spécifiques
    'où voir l\'état de ma candidature': 
      'Va dans l\'onglet "Inscription" (icône assignment). Tu verras le statut de ton dossier et tous les détails.',
    
    'comment faire un quiz de préparation': 
      'Va dans l\'onglet "Prépa-ENA" (icône école), puis choisis une matière pour commencer un quiz interactif.',
    
    'où télécharger mon dossier en PDF': 
      'Dans l\'onglet "Inscription", clique sur le bouton "Télécharger PDF" pour générer ton dossier complet.',
    
    'comment déposer un recours': 
      'Va dans "Inscription" → "Faire un recours". Tu peux uploader des fichiers Word (.doc/.docx) de max 5MB.',
    
    'où trouver les actualités ENA': 
      'Onglet "Actualités" (icône journal) pour voir les dernières nouvelles, annonces et le flux Twitter officiel.',
    
    'comment contacter l\'ENA': 
      'Onglet "Contact" (icône mail) pour les infos de contact, FAQ, et liens vers les réseaux sociaux.',
    
    // Chat et assistance
    'comment utiliser le chat ENA': 
      'Clique sur le bouton bleu flottant avec l\'icône chat. Il est disponible sur toutes les pages pour t\'assister.',
    
    'le chat peut-il m\'aider à naviguer': 
      'Oui ! Le chat ENA peut te guider dans l\'application et répondre à tes questions sur l\'utilisation des fonctionnalités.',
    
    // Sécurité et paramètres
    'comment activer l\'authentification biométrique': 
      'Va dans ton Profil → Paramètres de sécurité, puis active "Authentification biométrique" (empreinte/visage).',
    
    'comment me déconnecter': 
      'Clique sur ton avatar en haut à gauche, puis sélectionne "Déconnexion" dans le menu.',
    
    'où modifier mon mot de passe': 
      'Profil → "Modifier le mot de passe" pour changer tes identifiants de connexion.',
    
    // Problèmes courants
    'je ne trouve pas une option': 
      'Utilise le menu burger (≡) pour la navigation principale, ou demande au chat ENA de te guider vers la fonctionnalité recherchée.',
    
    'mes notifications ne s\'affichent pas': 
      'Vérifie l\'icône cloche 🔔 en haut à droite. Si le problème persiste, va dans Paramètres → Notifications.',
    
    'l\'application ne charge pas': 
      'Tire vers le bas sur l\'écran principal pour actualiser. Vérifie aussi ta connexion internet.',
  };
  
  /// Raccourcis et astuces pour l'utilisation
  static const List<Map<String, String>> usageTips = [
    {
      'title': 'Pull-to-refresh',
      'description': 'Tire vers le bas sur l\'écran principal pour actualiser les données',
      'icon': '⬇️'
    },
    {
      'title': 'Chat ENA toujours disponible',
      'description': 'Le bouton chat bleu est présent sur toutes les pages pour t\'aider',
      'icon': '💬'
    },
    {
      'title': 'Notifications en temps réel',
      'description': 'Active les notifications push pour être alerté des nouveautés',
      'icon': '🔔'
    },
    {
      'title': 'Mode hors-ligne',
      'description': 'Certaines données restent accessibles même sans internet',
      'icon': '📱'
    },
    {
      'title': 'Transitions personnalisables',
      'description': 'Personnalise les animations dans Paramètres → Transitions',
      'icon': '✨'
    },
  ];
  
  /// Recherche dans le guide par mots-clés
  static List<String> searchGuide(String query) {
    final results = <String>[];
    final lowerQuery = query.toLowerCase();
    
    // Recherche dans les FAQ
    navigationFAQ.forEach((question, answer) {
      if (question.toLowerCase().contains(lowerQuery) || 
          answer.toLowerCase().contains(lowerQuery)) {
        results.add('❓ **$question**\n\n$answer');
      }
    });
    
    // Recherche dans la structure de navigation
    final tabs = navigationStructure['main_tabs']['tabs'] as List;
    for (final tab in tabs) {
      final name = tab['name'] as String;
      final description = tab['description'] as String;
      final features = (tab['features'] as List).join(', ');
      
      if (name.toLowerCase().contains(lowerQuery) ||
          description.toLowerCase().contains(lowerQuery) ||
          features.toLowerCase().contains(lowerQuery)) {
        results.add('📱 **Onglet $name** (${tab['index']})\n\n$description\n\n**Fonctionnalités :** $features');
      }
    }
    
    return results;
  }
}
