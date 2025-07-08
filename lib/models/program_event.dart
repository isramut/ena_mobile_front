/// Modèle pour les événements du programme ENA
class ProgramEvent {
  final String id;
  final String name;
  final String description;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final String type;
  final String location;
  final String notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProgramEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.startDatetime,
    required this.endDatetime,
    required this.type,
    required this.location,
    required this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProgramEvent.fromJson(Map<String, dynamic> json) {
    return ProgramEvent(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      startDatetime: DateTime.tryParse(json['start_datetime'] ?? '') ?? DateTime.now(),
      endDatetime: DateTime.tryParse(json['end_datetime'] ?? '') ?? DateTime.now(),
      type: json['type'] ?? '',
      location: json['location'] ?? '',
      notes: json['notes'] ?? '',
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'start_datetime': startDatetime.toIso8601String(),
      'end_datetime': endDatetime.toIso8601String(),
      'type': type,
      'location': location,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Formate la date au format DD/MM/YYYY
  String get formattedStartDate {
    return "${startDatetime.day.toString().padLeft(2, '0')}/${startDatetime.month.toString().padLeft(2, '0')}/${startDatetime.year}";
  }

  /// Formate la date au format DD/MM/YYYY
  String get formattedEndDate {
    return "${endDatetime.day.toString().padLeft(2, '0')}/${endDatetime.month.toString().padLeft(2, '0')}/${endDatetime.year}";
  }

  /// Retourne le texte de la période formatée
  String get formattedPeriod {
    if (formattedStartDate == formattedEndDate) {
      return formattedStartDate;
    }
    return "$formattedStartDate - $formattedEndDate";
  }

  /// Vérifie si l'événement est encore en cours ou à venir
  bool get isUpcoming {
    final now = DateTime.now();
    return endDatetime.isAfter(now);
  }

  /// Vérifie si l'événement est en cours
  bool get isOngoing {
    final now = DateTime.now();
    return startDatetime.isBefore(now) && endDatetime.isAfter(now);
  }

  /// Retourne le statut de l'événement
  String get status {
    final now = DateTime.now();
    if (endDatetime.isBefore(now)) {
      return 'Terminé';
    } else if (startDatetime.isBefore(now) && endDatetime.isAfter(now)) {
      return 'En cours';
    } else {
      return 'À venir';
    }
  }
}
