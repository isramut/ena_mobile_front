// Modèles pour les données de recours provenant de l'API

class Recours {
  final String id;
  final String motifRejet;
  final String justification;
  final String? candidature;
  final List<String> documents;
  final String statut;
  final DateTime dateCreation;
  final DateTime? dateTraitement;
  final String? reponseAdmin;
  final String candidat;

  Recours({
    required this.id,
    required this.motifRejet,
    required this.justification,
    this.candidature,
    required this.documents,
    required this.statut,
    required this.dateCreation,
    this.dateTraitement,
    this.reponseAdmin,
    required this.candidat,
  });

  factory Recours.fromJson(Map<String, dynamic> json) {
    return Recours(
      id: json['id'].toString(),
      motifRejet: json['motif_rejet'] ?? '',
      justification: json['justification'] ?? '',
      candidature: json['candidature']?.toString(),
      documents: List<String>.from(json['documents'] ?? []),
      statut: json['statut'] ?? 'en_attente',
      dateCreation: DateTime.parse(json['date_creation']),
      dateTraitement: json['date_traitement'] != null 
          ? DateTime.parse(json['date_traitement'])
          : null,
      reponseAdmin: json['reponse_admin'],
      candidat: json['candidat'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'motif_rejet': motifRejet,
      'justification': justification,
      'candidature': candidature,
      'documents': documents,
      'statut': statut,
      'date_creation': dateCreation.toIso8601String(),
      'date_traitement': dateTraitement?.toIso8601String(),
      'reponse_admin': reponseAdmin,
      'candidat': candidat,
    };
  }

  // Getters utiles pour l'affichage
  String get statutFormate {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'en_cours':
        return 'En cours de traitement';
      case 'accepte':
        return 'Accepté';
      case 'rejete':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  String get dateCreationFormatee {
    return '${dateCreation.day}/${dateCreation.month}/${dateCreation.year}';
  }

  String? get dateTraitementFormatee {
    if (dateTraitement == null) return null;
    return '${dateTraitement!.day}/${dateTraitement!.month}/${dateTraitement!.year}';
  }

  bool get estTraite {
    return statut == 'accepte' || statut == 'rejete';
  }

  bool get estEnAttente {
    return statut == 'en_attente';
  }

  bool get estEnCours {
    return statut == 'en_cours';
  }
}

// Modèle pour créer un nouveau recours
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

// Modèle pour la liste des recours avec métadonnées
class RecoursResponse {
  final List<Recours> recours;
  final int total;
  final String loadTimestamp;

  RecoursResponse({
    required this.recours,
    required this.total,
    required this.loadTimestamp,
  });

  factory RecoursResponse.fromJson(dynamic json) {
    if (json is List) {
      // Si l'API retourne directement une liste
      return RecoursResponse(
        recours: json
            .map((item) => Recours.fromJson(item))
            .toList(),
        total: json.length,
        loadTimestamp: DateTime.now().toIso8601String(),
      );
    } else {
      // Si l'API retourne un objet avec des métadonnées
      final jsonMap = json as Map<String, dynamic>;
      return RecoursResponse(
        recours: (jsonMap['results'] as List? ?? jsonMap['recours'] as List? ?? [])
            .map((item) => Recours.fromJson(item))
            .toList(),
        total: jsonMap['total'] ?? jsonMap['count'] ?? 0,
        loadTimestamp: jsonMap['timestamp'] ?? DateTime.now().toIso8601String(),
      );
    }
  }
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
    errors.values.forEach((fieldErrors) {
      allErrors.addAll(fieldErrors);
    });
    return allErrors;
  }

  String get firstError {
    if (allErrors.isNotEmpty) {
      return allErrors.first;
    }
    return 'Erreur de validation';
  }
}
