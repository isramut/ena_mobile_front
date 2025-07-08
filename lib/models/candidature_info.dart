class CandidatureInfo {
  final String id;
  final String numero;
  final String titre;
  final String lettreMotivation;
  final String cv;
  final String diplome;
  final String aptitudePhysique;
  final String pieceIdentite;
  final String statut;
  final String step;
  final String commentaireAdmin;
  final DateTime dateCreation;
  final DateTime dateModification;
  final String candidat;

  CandidatureInfo({
    required this.id,
    required this.numero,
    required this.titre,
    required this.lettreMotivation,
    required this.cv,
    required this.diplome,
    required this.aptitudePhysique,
    required this.pieceIdentite,
    required this.statut,
    required this.step,
    required this.commentaireAdmin,
    required this.dateCreation,
    required this.dateModification,
    required this.candidat,
  });

  factory CandidatureInfo.fromJson(Map<String, dynamic> json) {
    return CandidatureInfo(
      id: json['id'] ?? '',
      numero: json['numero'] ?? '',
      titre: json['titre'] ?? '',
      lettreMotivation: json['lettre_motivation'] ?? '',
      cv: json['cv'] ?? '',
      diplome: json['diplome'] ?? '',
      aptitudePhysique: json['aptitude_physique'] ?? '',
      pieceIdentite: json['piece_identite'] ?? '',
      statut: json['statut'] ?? '',
      step: json['step'] ?? '',
      commentaireAdmin: json['commentaire_admin'] ?? '',
      dateCreation: DateTime.tryParse(json['date_creation'] ?? '') ?? DateTime.now(),
      dateModification: DateTime.tryParse(json['date_modification'] ?? '') ?? DateTime.now(),
      candidat: json['candidat'] ?? '',
    );
  }
}
