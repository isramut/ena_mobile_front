import 'package:flutter_test/flutter_test.dart';
import '../lib/models/user_info.dart';
import '../lib/config/api_config.dart';

void main() {
  group('Avatar Photo Debug Tests', () {
    test('Devrait construire correctement l\'URL de la photo de profil', () {
      // Test avec différents formats d'URL de photo de profil
      final testCases = [
        {
          'profilePicture': '/media/candidats/photos/test.jpg',
          'expected': '${ApiConfig.baseUrl}/media/candidats/photos/test.jpg',
        },
        {
          'profilePicture': 'https://ena.gouv.cd/media/candidats/photos/test.jpg',
          'expected': 'https://ena.gouv.cd/media/candidats/photos/test.jpg',
        },
        {
          'profilePicture': null,
          'expected': null,
        },
        {
          'profilePicture': '',
          'expected': null,
        },
      ];

      for (final testCase in testCases) {
        final userInfo = UserInfo(
          id: '1',
          email: 'test@ena.cd',
          firstName: 'Jean',
          lastName: 'Dupont',
          username: 'jean_dupont',
          role: 'candidat',
          isActive: true,
          dateJoined: DateTime.now(),
          hasApplied: true,
          profilePicture: testCase['profilePicture'] as String?,
        );

        expect(
          userInfo.fullProfilePictureUrl,
          testCase['expected'],
          reason: 'Erreur pour profilePicture: ${testCase['profilePicture']}',
        );
      }
    });

    test('Devrait générer les bonnes initiales', () {
      final testCases = [
        {
          'firstName': 'Jean',
          'lastName': 'Dupont',
          'expected': 'JD',
        },
        {
          'firstName': 'Marie',
          'lastName': '',
          'username': 'marie_test',
          'expected': 'MT',
        },
        {
          'firstName': '',
          'lastName': '',
          'username': 'test',
          'email': 'example@ena.cd',
          'expected': 'TE',
        },
        {
          'firstName': '',
          'lastName': '',
          'username': '',
          'email': 'example@ena.cd',
          'expected': 'E',
        },
      ];

      for (final testCase in testCases) {
        final userInfo = UserInfo(
          id: '1',
          email: testCase['email'] as String? ?? 'test@ena.cd',
          firstName: testCase['firstName'] as String? ?? '',
          lastName: testCase['lastName'] as String? ?? '',
          username: testCase['username'] as String? ?? '',
          role: 'candidat',
          isActive: true,
          dateJoined: DateTime.now(),
          hasApplied: true,
        );

        expect(
          userInfo.initials,
          testCase['expected'],
          reason: 'Erreur pour les initiales de ${testCase['firstName']} ${testCase['lastName']}',
        );
      }
    });

    test('Devrait identifier les problèmes potentiels d\'URL de photo', () {
      // Simule des réponses API problématiques
      final problematicCases = [
        {
          'profilePicture': 'media/candidats/photos/test.jpg', // Manque le '/' initial
          'description': 'URL relative sans slash initial',
        },
        {
          'profilePicture': '/static/media/candidats/photos/test.jpg', // Chemin incorrect
          'description': 'Chemin avec /static/',
        },
        {
          'profilePicture': 'candidats/photos/test.jpg', // Manque /media/
          'description': 'Chemin sans /media/',
        },
      ];

      for (final testCase in problematicCases) {
        final userInfo = UserInfo(
          id: '1',
          email: 'test@ena.cd',
          firstName: 'Jean',
          lastName: 'Dupont',
          username: 'jean_dupont',
          role: 'candidat',
          isActive: true,
          dateJoined: DateTime.now(),
          hasApplied: true,
          profilePicture: testCase['profilePicture'] as String,
        );

        print('=== ${testCase['description']} ===');
        print('profilePicture: ${userInfo.profilePicture}');
        print('fullProfilePictureUrl: ${userInfo.fullProfilePictureUrl}');
        print('baseUrl: ${ApiConfig.baseUrl}');
        print('================================');
      }
    });
  });
}
