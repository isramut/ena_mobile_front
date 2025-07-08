import 'dart:async';

/// Service pour notifier les changements du profil utilisateur
/// Permet la communication entre le ProfileScreen et le header (EnaMainLayout)
class ProfileUpdateNotificationService {
  static final ProfileUpdateNotificationService _instance = 
      ProfileUpdateNotificationService._internal();
  
  factory ProfileUpdateNotificationService() => _instance;
  
  ProfileUpdateNotificationService._internal();
  
  // StreamController pour les mises à jour du profil
  final StreamController<ProfileUpdateEvent> _profileUpdateController = 
      StreamController<ProfileUpdateEvent>.broadcast();
  
  /// Stream pour écouter les mises à jour du profil
  Stream<ProfileUpdateEvent> get profileUpdateStream => 
      _profileUpdateController.stream;
  
  /// Notifier qu'une mise à jour du profil a eu lieu
  void notifyProfileUpdated({
    bool photoUpdated = false,
    bool personalInfoUpdated = false,
    bool contactInfoUpdated = false,
    Map<String, dynamic>? updatedData,
  }) {
    final event = ProfileUpdateEvent(
      photoUpdated: photoUpdated,
      personalInfoUpdated: personalInfoUpdated,
      contactInfoUpdated: contactInfoUpdated,
      updatedData: updatedData,
      timestamp: DateTime.now(),
    );
    
    _profileUpdateController.add(event);
    print('🔄 ProfileUpdateNotificationService: Profile update notified');
    print('   - Photo updated: $photoUpdated');
    print('   - Personal info updated: $personalInfoUpdated');
    print('   - Contact info updated: $contactInfoUpdated');
  }
  
  /// Fermer le service (à appeler lors de la destruction de l'app)
  void dispose() {
    _profileUpdateController.close();
  }
}

/// Événement de mise à jour du profil
class ProfileUpdateEvent {
  final bool photoUpdated;
  final bool personalInfoUpdated;
  final bool contactInfoUpdated;
  final Map<String, dynamic>? updatedData;
  final DateTime timestamp;
  
  const ProfileUpdateEvent({
    required this.photoUpdated,
    required this.personalInfoUpdated,
    required this.contactInfoUpdated,
    this.updatedData,
    required this.timestamp,
  });
  
  /// Vérifie si des données visuelles ont été mises à jour (nécessite un refresh de l'UI)
  bool get requiresUIRefresh => photoUpdated || personalInfoUpdated;
  
  @override
  String toString() {
    return 'ProfileUpdateEvent(photo: $photoUpdated, personal: $personalInfoUpdated, contact: $contactInfoUpdated, timestamp: $timestamp)';
  }
}
