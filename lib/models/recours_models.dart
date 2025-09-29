// Modèles pour les données de recours provenant de l'API
import 'dart:io';

// Nouveau modèle pour la candidature récupérée
class CandidatureStatus {
  final String id;
  final String titre;
  final String numeroCandidature;
  final String statut;
  final DateTime dateCreation;
  final String candidat;
  final String? commentaireAdmin;
  final List<String> documentsNonConformes;

  CandidatureStatus({
    required this.id,
    required this.titre,
    required this.numeroCandidature,
    required this.statut,
    required this.dateCreation,
    required this.candidat,
    this.commentaireAdmin,
    required this.documentsNonConformes,
  });

  factory CandidatureStatus.fromJson(Map<String, dynamic> json) {
    return CandidatureStatus(
      id: json['id'].toString(),
      titre: json['titre'] ?? '',
      numeroCandidature: json['numero_candidature'] ?? json['id'].toString(),
      statut: json['statut'] ?? '',
      dateCreation: DateTime.parse(json['date_creation']),
      candidat: json['candidat'].toString(),
      commentaireAdmin: json['commentaire_admin'],
      documentsNonConformes: List<String>.from(json['documents_non_conformes'] ?? []),
    );
  }

  bool get estRejete => statut == 'rejete';
  bool get peutDeposerRecours => estRejete && documentsNonConformes.isNotEmpty;
}

// Modèle pour le candidat dans la réponse recours
class CandidatInfo {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? telephone;

  CandidatInfo({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.telephone,
  });

  factory CandidatInfo.fromJson(Map<String, dynamic> json) {
    return CandidatInfo(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      middleName: json['middle_name'],
      telephone: json['telephone'],
    );
  }
}

// Modèle pour la candidature dans la réponse recours
class CandidatureRecours {
  final String id;
  final CandidatInfo candidat;
  final String numeroCandidature;
  final String statut;
  final String? commentaireAdmin;
  final List<String> documentsNonConformes;
  final DateTime? dateCreation;
  final String? aptitudePhysique;
  final String? cv;
  final String? diplome;
  final String? lettreMotivation;
  final String? pieceIdentite;
  final String? relevesNotes;

  CandidatureRecours({
    required this.id,
    required this.candidat,
    required this.numeroCandidature,
    required this.statut,
    this.commentaireAdmin,
    this.documentsNonConformes = const [],
    this.dateCreation,
    this.aptitudePhysique,
    this.cv,
    this.diplome,
    this.lettreMotivation,
    this.pieceIdentite,
    this.relevesNotes,
  });

  factory CandidatureRecours.fromJson(Map<String, dynamic> json) {
    return CandidatureRecours(
      id: json['id'].toString(),
      candidat: CandidatInfo.fromJson(json['candidat']),
      numeroCandidature: json['numero_candidature'] ?? '',
      statut: json['statut'] ?? '',
      commentaireAdmin: json['commentaire_admin'],
      documentsNonConformes: json['documents_non_conformes'] != null 
          ? List<String>.from(json['documents_non_conformes'])
          : [],
      dateCreation: json['date_creation'] != null 
          ? DateTime.tryParse(json['date_creation']) 
          : null,
      aptitudePhysique: json['aptitude_physique'],
      cv: json['cv'],
      diplome: json['diplome'],
      lettreMotivation: json['lettre_motivation'],
      pieceIdentite: json['piece_identite'],
      relevesNotes: json['releves_notes'],
    );
  }
}

// Modèle pour la personne qui a traité le recours
class TraitePar {
  final String id;
  final String email;

  TraitePar({
    required this.id,
    required this.email,
  });

  factory TraitePar.fromJson(Map<String, dynamic> json) {
    return TraitePar(
      id: json['id'].toString(),
      email: json['email'] ?? '',
    );
  }
}

class Recours {
  final String id;
  final String numero;
  final String titre;
  final dynamic candidature; // String ou CandidatureRecours
  final String? motifRejet;
  final String justification;
  final DateTime dateSoumission;
  final String statut;
  final DateTime? dateModification;
  final String? commentaireAdmin;
  final TraitePar? traitePar;
  final String? aptitudePhysique;
  final String? cv;
  final String? diplome;
  final String? lettreMotivation;
  final String? pieceIdentite;
  final String? relevesNotes;
  final List<String> documentsInvalides;

  Recours({
    required this.id,
    required this.numero,
    required this.titre,
    required this.candidature,
    this.motifRejet,
    required this.justification,
    required this.dateSoumission,
    required this.statut,
    this.dateModification,
    this.commentaireAdmin,
    this.traitePar,
    this.aptitudePhysique,
    this.cv,
    this.diplome,
    this.lettreMotivation,
    this.pieceIdentite,
    this.relevesNotes,
    this.documentsInvalides = const [],
  });

  factory Recours.fromJson(Map<String, dynamic> json) {
    try {
      return Recours(
        id: json['id'].toString(),
        numero: json['numero'] ?? '',
        titre: json['titre'] ?? 'Recours sans titre',
        candidature: json['candidature'] is String 
            ? json['candidature']
            : (json['candidature'] != null 
                ? CandidatureRecours.fromJson(json['candidature'])
                : 'Candidature non spécifiée'),
        motifRejet: json['motif_rejet'],
        justification: json['justification'] ?? '',
        dateSoumission: json['date_soumission'] != null
            ? DateTime.parse(json['date_soumission'])
            : DateTime.now(),
        statut: json['statut'] ?? 'en_attente',
        dateModification: json['date_modification'] != null 
            ? DateTime.parse(json['date_modification'])
            : null,
        commentaireAdmin: json['commentaire_admin'],
        traitePar: json['traite_par'] != null 
            ? TraitePar.fromJson(json['traite_par'])
            : null,
        aptitudePhysique: json['aptitude_physique'],
        cv: json['cv'],
        diplome: json['diplome'],
        lettreMotivation: json['lettre_motivation'],
        pieceIdentite: json['piece_identite'],
        relevesNotes: json['releves_notes'],
        documentsInvalides: json['documents_invalides'] != null
            ? List<String>.from(json['documents_invalides'])
            : [],
      );
    } catch (e) {
      print('⚠️ Erreur parsing Recours: $e');
      // Fallback avec des valeurs par défaut
      return Recours(
        id: json['id']?.toString() ?? 'unknown',
        numero: json['numero'] ?? json['ordre'] ?? 'N/A',
        titre: json['titre'] ?? 'Recours',
        candidature: 'Erreur de parsing',
        motifRejet: json['motif_rejet'],
        justification: json['justification'] ?? '',
        dateSoumission: DateTime.now(),
        statut: json['statut'] ?? (json['traite'] == true ? 'traite' : 'en_attente'),
        dateModification: null,
        commentaireAdmin: json['commentaire_admin'],
        traitePar: null,
      );
    }
  }

  // Getters utiles pour l'affichage
  String get statutFormate {
    switch (statut.toLowerCase()) {
      case 'valide':
        return 'Validé';
      case 'rejete':
        return 'Rejeté';
      case 'en_attente':
        return 'En attente de traitement';
      case 'traite':
        return 'Traité';
      default:
        return 'En attente de traitement';
    }
  }

  // Getters pour compatibilité avec l'ancien code
  String get ordre => numero;
  bool get traite => statut == 'valide' || statut == 'rejete' || statut == 'traite';
  DateTime? get dateTraitement => dateModification;

  String get dateSoumissionFormatee {
    return '${dateSoumission.day}/${dateSoumission.month}/${dateSoumission.year}';
  }

  // Getter pour la compatibilité avec l'ancien code
  String get dateCreationFormatee {
    return dateSoumissionFormatee;
  }

  String? get dateTraitementFormatee {
    if (dateTraitement == null) return null;
    return '${dateTraitement!.day}/${dateTraitement!.month}/${dateTraitement!.year}';
  }

  // Getter pour la compatibilité avec l'ancien code
  String? get reponseAdmin {
    return commentaireAdmin;
  }

  bool get estTraite => traite;
  bool get estEnAttente => !traite;
}

// Modèle pour créer un nouveau recours avec documents spécifiques
class CreateRecoursDocumentsRequest {
  final String justification;
  final File? cv;
  final File? aptitudePhysique;
  final File? titreAcademique;
  final File? lettreDeMotivation;
  final File? pieceIdentite;
  final File? relevesNotes;

  CreateRecoursDocumentsRequest({
    required this.justification,
    this.cv,
    this.aptitudePhysique,
    this.titreAcademique,
    this.lettreDeMotivation,
    this.pieceIdentite,
    this.relevesNotes,
  });

  Map<String, dynamic> toFields() {
    final fields = <String, dynamic>{
      'justification': justification,
    };

    // Ajouter les noms des fichiers si ils existent
    if (cv != null) fields['cv'] = cv!.path.split('/').last;
    if (aptitudePhysique != null) fields['aptitude_physique'] = aptitudePhysique!.path.split('/').last;
    if (titreAcademique != null) fields['titre_academique'] = titreAcademique!.path.split('/').last;
    if (lettreDeMotivation != null) fields['lettre_de_motivation'] = lettreDeMotivation!.path.split('/').last;
    if (pieceIdentite != null) fields['piece_identite'] = pieceIdentite!.path.split('/').last;
    if (relevesNotes != null) fields['releves_notes'] = relevesNotes!.path.split('/').last;

    return fields;
  }

  List<File> getFiles() {
    final files = <File>[];
    if (cv != null) files.add(cv!);
    if (aptitudePhysique != null) files.add(aptitudePhysique!);
    if (titreAcademique != null) files.add(titreAcademique!);
    if (lettreDeMotivation != null) files.add(lettreDeMotivation!);
    if (pieceIdentite != null) files.add(pieceIdentite!);
    if (relevesNotes != null) files.add(relevesNotes!);
    return files;
  }
}

// Ancien modèle maintenu pour compatibilité
class CreateRecoursRequest {
  final String motifRejet;
  final String justification;
  final String? candidature;
  final List<String> documents;

  CreateRecoursRequest({
    required this.motifRejet,
    required this.justification,
    this.candidature,
    this.documents = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'motif_rejet': motifRejet,
      'justification': justification,
      'candidature': candidature,
      'documents': documents,
    };
  }
}

// Modèle pour les fichiers attachés localement (avant upload)
class AttachedFile {
  final File file;
  final String name;
  final int size;
  final String type;

  AttachedFile({
    required this.file,
    required this.name,
    required this.size,
    required this.type,
  });

  factory AttachedFile.fromFile(File file) {
    final name = file.path.split('/').last;
    final size = file.lengthSync();
    final extension = name.split('.').last.toLowerCase();
    
    String type;
    switch (extension) {
      case 'pdf':
        type = 'PDF';
        break;
      case 'jpg':
      case 'jpeg':
        type = 'JPEG';
        break;
      case 'png':
        type = 'PNG';
        break;
      case 'doc':
        type = 'DOC';
        break;
      case 'docx':
        type = 'DOCX';
        break;
      default:
        type = extension.toUpperCase();
    }

    return AttachedFile(
      file: file,
      name: name,
      size: size,
      type: type,
    );
  }

  String get formattedSize {
    if (size < 1024) {
      return "$size B";
    } else if (size < 1024 * 1024) {
      return "${(size / 1024).toStringAsFixed(1)} KB";
    } else {
      return "${(size / (1024 * 1024)).toStringAsFixed(1)} MB";
    }
  }
}

// Modèle pour la liste des recours avec métadonnées (format pagination Django)
class RecoursResponse {
  final int count;
  final String? next;
  final String? previous; 
  final List<Recours> results;

  RecoursResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory RecoursResponse.fromJson(dynamic json) {
    if (json is List) {
      // Ancien format: API retourne directement une liste
      return RecoursResponse(
        count: json.length,
        next: null,
        previous: null,
        results: json.map((item) => Recours.fromJson(item)).toList(),
      );
    } else {
      // Nouveau format: API retourne un objet paginé
      final jsonMap = json as Map<String, dynamic>;
      return RecoursResponse(
        count: jsonMap['count'] ?? 0,
        next: jsonMap['next'],
        previous: jsonMap['previous'],
        results: (jsonMap['results'] as List? ?? [])
            .map((item) => Recours.fromJson(item))
            .toList(),
      );
    }
  }

  // Constructor pour compatibilité avec l'ancien format (array direct)
  factory RecoursResponse.fromList(List<dynamic> list) {
    return RecoursResponse(
      count: list.length,
      next: null,
      previous: null,
      results: list.map((item) => Recours.fromJson(item)).toList(),
    );
  }

  // Getters pour compatibilité avec l'ancien code
  List<Recours> get recours => results;
  int get total => count;
  String get loadTimestamp => DateTime.now().toIso8601String();
}

// Modèle pour les erreurs de validation
class RecoursValidationError {
  final Map<String, List<String>> errors;

  RecoursValidationError({required this.errors});

  factory RecoursValidationError.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>> errors = {};
    json.forEach((key, value) {
      if (value is List) {
        errors[key] = List<String>.from(value);
      } else {
        errors[key] = [value.toString()];
      }
    });
    return RecoursValidationError(errors: errors);
  }

  List<String> getErrorsForField(String field) {
    return errors[field] ?? [];
  }

  bool hasErrorForField(String field) {
    return errors.containsKey(field) && errors[field]!.isNotEmpty;
  }

  List<String> get allErrors {
    List<String> allErrors = [];
    for (var fieldErrors in errors.values) {
      allErrors.addAll(fieldErrors);
    }
    return allErrors;
  }

  String get firstError {
    if (allErrors.isNotEmpty) {
      return allErrors.first;
    }
    return 'Erreur de validation';
  }
}

// Modèle pour la vérification si l'utilisateur a soumis un recours
class HasSubmittedRecours {
  final bool hasRecours;
  final String userId;
  final String userEmail;
  final String numeroCandidature;
  final DateTime? dateSoumissionRecours;
  final String? motifRejet;
  final bool? traite;
  final DateTime? dateModification;

  HasSubmittedRecours({
    required this.hasRecours,
    required this.userId,
    required this.userEmail,
    required this.numeroCandidature,
    this.dateSoumissionRecours,
    this.motifRejet,
    this.traite,
    this.dateModification,
  });

  factory HasSubmittedRecours.fromJson(Map<String, dynamic> json) {
    return HasSubmittedRecours(
      hasRecours: json['has_recours'] ?? false,
      userId: json['user_id'] ?? '',
      userEmail: json['user_email'] ?? '',
      numeroCandidature: json['numero_candidature'] ?? '',
      dateSoumissionRecours: json['date_soumission_recours'] != null 
          ? DateTime.parse(json['date_soumission_recours'])
          : null,
      motifRejet: json['motif_rejet'],
      traite: json['traite'],
      dateModification: json['date_modification'] != null 
          ? DateTime.parse(json['date_modification'])
          : null,
    );
  }

  // Getter pour la date formatée
  String? get dateSoumissionRecoursFormatee {
    if (dateSoumissionRecours == null) return null;
    return '${dateSoumissionRecours!.day}/${dateSoumissionRecours!.month}/${dateSoumissionRecours!.year}';
  }

  String? get dateModificationFormatee {
    if (dateModification == null) return null;
    return '${dateModification!.day}/${dateModification!.month}/${dateModification!.year}';
  }

  // Getter pour compatibilité avec l'ancien code
  String? get dateTraitementFormatee {
    return dateModificationFormatee;
  }
}
