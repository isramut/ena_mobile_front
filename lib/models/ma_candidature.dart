/// Modèle pour les données de candidature de l'utilisateur connecté
class MaCandidature {
  final String numero;
  final String titre;
  final String statut;
  final String candidatFullName;
  final DateTime dateCreation;
  final String? commentaireAdmin;
  final bool canEdit;
  final double completionRatio;
  
  // Documents URLs
  final String? cv;
  final String? lettreMotivation;
  final String? pieceIdentite;
  final String? aptitudePhysique;
  final String? diplome;

  MaCandidature({
    required this.numero,
    required this.titre,
    required this.statut,
    required this.candidatFullName,
    required this.dateCreation,
    this.commentaireAdmin,
    required this.canEdit,
    required this.completionRatio,
    this.cv,
    this.lettreMotivation,
    this.pieceIdentite,
    this.aptitudePhysique,
    this.diplome,
  });

  factory MaCandidature.fromJson(Map<String, dynamic> json) {
    return MaCandidature(
      numero: json['numero'] ?? '',
      titre: json['titre'] ?? '',
      statut: json['statut'] ?? '',
      candidatFullName: json['candidat_full_name'] ?? '',
      dateCreation: DateTime.parse(json['date_creation']),
      commentaireAdmin: json['commentaire_admin'],
      canEdit: json['can_edit'] ?? false,
      completionRatio: (json['completion_ratio'] ?? 0).toDouble(),
      cv: json['cv'],
      lettreMotivation: json['lettre_motivation'],
      pieceIdentite: json['piece_identite'],
      aptitudePhysique: json['aptitude_physique'],
      diplome: json['diplome'],
    );
  }

  /// Parse le commentaire admin pour extraire les raisons de rejet structurées
  List<DocumentRejet> get raisonsRejet {
    if (commentaireAdmin == null || commentaireAdmin!.isEmpty) return [];
    
    // Exemple: "Diplôme : Falsifié; CV : Non conforme; Lettre : Incomplète"
    final parts = commentaireAdmin!.split(';');
    List<DocumentRejet> rejets = [];
    
    for (String part in parts) {
      final trimmedPart = part.trim();
      if (trimmedPart.contains(':')) {
        final splitPart = trimmedPart.split(':');
        if (splitPart.length >= 2) {
          final document = splitPart[0].trim();
          final raison = splitPart[1].trim();
          
          // Mapper vers URL correspondante
          String? url = _getDocumentUrl(document);
          
          rejets.add(DocumentRejet(
            document: document,
            raison: raison,
            documentUrl: url,
          ));
        }
      }
    }
    return rejets;
  }

  /// Mappe le nom du document vers son URL
  String? _getDocumentUrl(String documentName) {
    final docLower = documentName.toLowerCase();
    
    if (docLower.contains('cv')) return cv;
    if (docLower.contains('diplôme') || docLower.contains('diplome')) return diplome;
    if (docLower.contains('lettre')) return lettreMotivation;
    if (docLower.contains('pièce') || docLower.contains('piece') || 
        docLower.contains('identité') || docLower.contains('identite')) {
      return pieceIdentite;
    }
    if (docLower.contains('aptitude')) return aptitudePhysique;
    
    return null;
  }

  /// Vérifie si la candidature est rejetée
  bool get estRejetee => statut == 'rejete';
  
  /// Retourne la liste des noms de documents non conformes (pour le formulaire de recours)
  List<String> get documentsNonConformes {
    if (commentaireAdmin == null || commentaireAdmin!.isEmpty) return [];
    
    final parts = commentaireAdmin!.split(';');
    Set<String> documentsSet = {}; // Utiliser Set pour éviter les doublons
    
    for (String part in parts) {
      final trimmedPart = part.trim();
      if (trimmedPart.contains(':')) {
        final splitPart = trimmedPart.split(':');
        if (splitPart.length >= 2) {
          final document = splitPart[0].trim();
          // Normaliser les noms de documents
          documentsSet.add(_normalizeDocumentName(document));
        }
      }
    }
    return documentsSet.toList();
  }
  
  /// Normalise les noms de documents pour correspondre aux clés API
  String _normalizeDocumentName(String documentName) {
    final docLower = documentName.toLowerCase();
    
    if (docLower.contains('cv')) return 'cv';
    if (docLower.contains('diplôme') || docLower.contains('diplome')) return 'diplome';
    if (docLower.contains('lettre')) return 'lettre_motivation';
    if (docLower.contains('pièce') || docLower.contains('piece') || 
        docLower.contains('identité') || docLower.contains('identite')) {
      return 'piece_identite';
    }
    if (docLower.contains('aptitude')) return 'aptitude_physique';
    
    // Si pas de correspondance, retourner le nom original
    return documentName;
  }
  
  /// Vérifie si on peut déposer un recours
  bool get peutDeposerRecours => estRejetee && raisonsRejet.isNotEmpty;

  /// Format la date de création pour affichage
  String get dateCreationFormatee {
    return '${dateCreation.day.toString().padLeft(2, '0')}/${dateCreation.month.toString().padLeft(2, '0')}/${dateCreation.year}';
  }

  /// Retourne la liste des documents disponibles
  List<DocumentInfo> get documentsDisponibles {
    List<DocumentInfo> documents = [];
    
    if (cv != null) documents.add(DocumentInfo('CV', cv!));
    if (lettreMotivation != null) documents.add(DocumentInfo('Lettre de motivation', lettreMotivation!));
    if (pieceIdentite != null) documents.add(DocumentInfo('Pièce d\'identité', pieceIdentite!));
    if (aptitudePhysique != null) documents.add(DocumentInfo('Aptitude physique', aptitudePhysique!));
    if (diplome != null) documents.add(DocumentInfo('Diplôme', diplome!));
    
    return documents;
  }
}

/// Modèle pour un document rejeté avec sa raison
class DocumentRejet {
  final String document;
  final String raison;
  final String? documentUrl;

  DocumentRejet({
    required this.document,
    required this.raison,
    this.documentUrl,
  });
}

/// Modèle pour les informations d'un document
class DocumentInfo {
  final String nom;
  final String url;

  DocumentInfo(this.nom, this.url);
}
