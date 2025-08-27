import '../config/api_config.dart';

/// Modèle pour les informations de l'utilisateur
class UserInfo {
  final String id;
  final String email;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String username;
  final String role;
  final bool isActive;
  final DateTime dateJoined;
  final DateTime? lastLogin;
  final String? telephone;
  final bool hasApplied;
  final String? profilePicture;
  final String? adressePhysique;
  final DateTime? applicationStartDate;
  final bool? canSubmitCandidature;
  final bool? canPublish;
  final String? numero;
  final DateTime? dateCreation;
  final bool isStaff;
  final bool isSuperuser;
  final bool canSubmitRecours;
  final bool hasSubmittedRecours;
  final DateTime? debutSession;
  final DateTime? finSession;
  final DateTime? debutSoumissionCandidature;
  final DateTime? finSoumissionCandidature;
  final DateTime? debutSoumissionRecours;
  final DateTime? finSoumissionRecours;
  final int? sessionPromotion;
  final String? sessionDenomination;

  UserInfo({
    required this.id,
    required this.email,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.username,
    required this.role,
    required this.isActive,
    required this.dateJoined,
    this.lastLogin,
    this.telephone,
    required this.hasApplied,
    this.profilePicture,
    this.adressePhysique,
    this.applicationStartDate,
    this.canSubmitCandidature,
    this.canPublish,
    this.numero,
    this.dateCreation,
    required this.isStaff,
    required this.isSuperuser,
    required this.canSubmitRecours,
    required this.hasSubmittedRecours,
    this.debutSession,
    this.finSession,
    this.debutSoumissionCandidature,
    this.finSoumissionCandidature,
    this.debutSoumissionRecours,
    this.finSoumissionRecours,
    this.sessionPromotion,
    this.sessionDenomination,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'],
      lastName: json['last_name'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      isActive: json['is_active'] ?? false,
      dateJoined: DateTime.tryParse(json['date_joined'] ?? '') ?? DateTime.now(),
      lastLogin: json['last_login'] != null ? DateTime.tryParse(json['last_login']) : null,
      telephone: json['telephone'],
      hasApplied: json['has_applied'] ?? false,
      profilePicture: json['profile_picture'],
      adressePhysique: json['adresse_physique'],
      applicationStartDate: json['application_start_date'] != null 
          ? DateTime.tryParse(json['application_start_date']) 
          : null,
      canSubmitCandidature: json['can_submit_candidature'],
      canPublish: json['can_publish'],
      numero: json['numero'],
      dateCreation: json['date_creation'] != null 
          ? DateTime.tryParse(json['date_creation']) 
          : null,
      isStaff: json['is_staff'] ?? false,
      isSuperuser: json['is_superuser'] ?? false,
      canSubmitRecours: json['can_submit_recours'] ?? false,
      hasSubmittedRecours: json['has_submitted_recours'] ?? false,
      debutSession: json['debut_session'] != null 
          ? DateTime.tryParse(json['debut_session']) 
          : null,
      finSession: json['fin_session'] != null 
          ? DateTime.tryParse(json['fin_session']) 
          : null,
      debutSoumissionCandidature: json['debut_soumission_candidature'] != null 
          ? DateTime.tryParse(json['debut_soumission_candidature']) 
          : null,
      finSoumissionCandidature: json['fin_soumission_candidature'] != null 
          ? DateTime.tryParse(json['fin_soumission_candidature']) 
          : null,
      debutSoumissionRecours: json['debut_soumission_recours'] != null 
          ? DateTime.tryParse(json['debut_soumission_recours']) 
          : null,
      finSoumissionRecours: json['fin_soumission_recours'] != null 
          ? DateTime.tryParse(json['fin_soumission_recours']) 
          : null,
      sessionPromotion: json['session_promotion'],
      sessionDenomination: json['session_denomination'],
    );
  }

  /// Retourne les initiales de l'utilisateur (prénom + nom)
  String get initials {
    String firstInitial = '';
    String lastInitial = '';
    
    // Essaie d'abord avec firstName et lastName
    if (firstName.isNotEmpty) {
      firstInitial = firstName[0].toUpperCase();
    }
    if (lastName.isNotEmpty) {
      lastInitial = lastName[0].toUpperCase();
    }
    
    // Si on n'a pas d'initiales, utilise username
    if (firstInitial.isEmpty && lastInitial.isEmpty && username.isNotEmpty) {
      firstInitial = username[0].toUpperCase();
      if (username.length > 1) {
        lastInitial = username[1].toUpperCase();
      }
    }
    
    // Si on n'a toujours rien, utilise email
    if (firstInitial.isEmpty && lastInitial.isEmpty && email.isNotEmpty) {
      firstInitial = email[0].toUpperCase();
    }
    
    // Fallback final
    if (firstInitial.isEmpty && lastInitial.isEmpty) {
      return 'U';
    }
    
    return firstInitial + lastInitial;
  }

  /// Retourne le nom complet formaté
  String get fullName {
    List<String> nameParts = [];
    
    if (firstName.isNotEmpty) {
      nameParts.add(firstName);
    }
    
    if (middleName != null && middleName!.isNotEmpty) {
      // Si le nom du milieu est trop long, on prend juste l'initiale
      if (middleName!.length > 8) {
        nameParts.add('${middleName![0].toUpperCase()}.');
      } else {
        nameParts.add(middleName!);
      }
    }
    
    if (lastName.isNotEmpty) {
      nameParts.add(lastName);
    }
    
    return nameParts.join(' ').trim();
  }

  /// Retourne le nom complet court (prénom + nom seulement)
  String get shortName {
    List<String> nameParts = [];
    
    if (firstName.isNotEmpty) {
      nameParts.add(firstName);
    }
    
    if (lastName.isNotEmpty) {
      nameParts.add(lastName);
    }
    
    return nameParts.join(' ').trim();
  }

  /// Retourne l'URL complète de la photo de profil
  String? get fullProfilePictureUrl {
    if (profilePicture == null || profilePicture!.isEmpty) {
      return null;
    }
    
    if (profilePicture!.startsWith('http')) {
      return profilePicture;
    }
    
    return '${ApiConfig.baseUrl}$profilePicture';
  }

  /// Méthode de débogage pour vérifier la construction de l'URL
  void debugProfilePictureUrl() {
  }

  /// Vérifie si nous sommes dans la période de soumission des recours
  bool get isInRecoursSubmissionPeriod {
    if (debutSoumissionRecours == null || finSoumissionRecours == null) {
      return false;
    }
    
    final now = DateTime.now();
    return now.isAfter(debutSoumissionRecours!) && now.isBefore(finSoumissionRecours!);
  }

  /// Vérifie si nous sommes dans la période de soumission des candidatures
  bool get isInCandidatureSubmissionPeriod {
    if (debutSoumissionCandidature == null || finSoumissionCandidature == null) {
      return false;
    }
    
    final now = DateTime.now();
    return now.isAfter(debutSoumissionCandidature!) && now.isBefore(finSoumissionCandidature!);
  }

  /// Retourne le nombre de jours restants pour soumettre un recours
  int? get daysLeftForRecours {
    if (finSoumissionRecours == null) return null;
    
    final now = DateTime.now();
    final difference = finSoumissionRecours!.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  /// Vérifie si l'utilisateur peut actuellement soumettre un recours
  bool get canCurrentlySubmitRecours {
    return canSubmitRecours && 
           !hasSubmittedRecours && 
           isInRecoursSubmissionPeriod;
  }
}
