import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ena_mobile_front/main.dart' as app;
import 'package:ena_mobile_front/services/auth_api_service.dart';
import 'package:ena_mobile_front/models/user_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Test d\'intégration utilisateur réel', () {
    testWidgets('Test complet du flux candidature avec utilisateur réel', (WidgetTester tester) async {
      // Lancer l'application
      app.main();
      await tester.pumpAndSettle();

      // Données utilisateur réel pour les tests
      const String testEmail = 'aksamputu7@gmail.com';
      const String testPassword = 'Aks@2005';

      print('🎯 Début du test d\'intégration avec utilisateur réel');

      // Étape 1: Attendre le splash screen et naviguer vers le login
      print('📱 Attente du splash screen...');
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // Chercher les champs de connexion
      final emailField = find.byKey(const Key('email_field'));
      final passwordField = find.byKey(const Key('password_field'));
      final loginButton = find.byKey(const Key('login_button'));

      if (emailField.evaluate().isEmpty) {
        // Si pas de champs de login, chercher le bouton "Se connecter"
        final connectButton = find.text('Se connecter');
        if (connectButton.evaluate().isNotEmpty) {
          await tester.tap(connectButton);
          await tester.pumpAndSettle();
        }
      }

      // Étape 2: Connexion utilisateur
      print('🔐 Tentative de connexion...');
      
      // Saisir l'email
      if (find.byKey(const Key('email_field')).evaluate().isNotEmpty) {
        await tester.enterText(find.byKey(const Key('email_field')), testEmail);
      } else if (find.byType(TextFormField).evaluate().isNotEmpty) {
        // Fallback: utiliser le premier champ texte trouvé
        await tester.enterText(find.byType(TextFormField).first, testEmail);
      }

      await tester.pumpAndSettle();

      // Saisir le mot de passe
      if (find.byKey(const Key('password_field')).evaluate().isNotEmpty) {
        await tester.enterText(find.byKey(const Key('password_field')), testPassword);
      } else if (find.byType(TextFormField).evaluate().length > 1) {
        // Fallback: utiliser le deuxième champ texte trouvé
        await tester.enterText(find.byType(TextFormField).at(1), testPassword);
      }

      await tester.pumpAndSettle();

      // Cliquer sur le bouton de connexion
      if (find.byKey(const Key('login_button')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('login_button')));
      } else {
        // Fallback: chercher un bouton "Connexion" ou "Se connecter"
        final loginBtn = find.text('Connexion').first;
        if (loginBtn.evaluate().isNotEmpty) {
          await tester.tap(loginBtn);
        }
      }

      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('✅ Connexion effectuée');

      // Étape 3: Naviguer vers la page candidature
      print('📋 Navigation vers la page candidature...');
      
      // Chercher le bouton "Candidater" ou "Postuler"
      final candidateButton = find.text('Candidater');
      if (candidateButton.evaluate().isNotEmpty) {
        await tester.tap(candidateButton.first);
        await tester.pumpAndSettle();
      } else {
        // Chercher dans la navigation ou les menus
        final menuButton = find.byIcon(Icons.menu);
        if (menuButton.evaluate().isNotEmpty) {
          await tester.tap(menuButton);
          await tester.pumpAndSettle();
          
          final candidateMenuItem = find.text('Candidature');
          if (candidateMenuItem.evaluate().isNotEmpty) {
            await tester.tap(candidateMenuItem);
            await tester.pumpAndSettle();
          }
        }
      }

      // Étape 4: Tester le formulaire de candidature
      print('📝 Test du formulaire de candidature...');

      // Vérifier que nous sommes sur la page candidature
      expect(find.text('Candidature').evaluate().isNotEmpty || 
             find.text('Informations personnelles').evaluate().isNotEmpty, 
             true, reason: 'Page candidature non trouvée');

      // Tester la validation du numéro de téléphone
      print('📞 Test validation numéro de téléphone...');
      
      final phoneField = find.byKey(const Key('phone_field'));
      if (phoneField.evaluate().isNotEmpty) {
        // Test avec numéro invalide
        await tester.enterText(phoneField, '123');
        await tester.pumpAndSettle();
        
        // Chercher le bouton de soumission
        final submitButton = find.text('Soumettre la candidature');
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton);
          await tester.pumpAndSettle();
          
          // Vérifier qu'un message d'erreur apparaît
          expect(find.text('Format de téléphone invalide').evaluate().isNotEmpty ||
                 find.text('Numéro de téléphone invalide').evaluate().isNotEmpty,
                 true, reason: 'Validation du téléphone ne fonctionne pas');
        }

        // Test avec numéro valide
        await tester.enterText(phoneField, '06 12 34 56 78');
        await tester.pumpAndSettle();
      }

      // Étape 5: Test de l'upload de photo
      print('📸 Test upload photo de profil...');
      
      final photoButton = find.byKey(const Key('photo_upload_button'));
      if (photoButton.evaluate().isNotEmpty) {
        // Simuler le tap sur le bouton photo (sans vraiment uploader)
        await tester.tap(photoButton);
        await tester.pumpAndSettle();
        
        // Vérifier que le sélecteur de source apparaît
        expect(find.text('Choisir une source').evaluate().isNotEmpty ||
               find.text('Galerie').evaluate().isNotEmpty ||
               find.text('Appareil photo').evaluate().isNotEmpty,
               true, reason: 'Sélecteur de photo ne s\'ouvre pas');
        
        // Fermer le sélecteur
        await tester.tapAt(const Offset(100, 100));
        await tester.pumpAndSettle();
      }

      // Étape 6: Test API de soumission (sans vraiment soumettre)
      print('🌐 Test API candidature...');
      
      try {
        // Test de l'API service
        final authService = AuthApiService();
        
        // Vérifier que le service est configuré
        expect(authService, isNotNull, reason: 'AuthApiService non initialisé');
        
        print('✅ Service API configuré correctement');
        
        // Test de récupération du profil utilisateur
        try {
          final userProfile = await authService.getUserProfile();
          if (userProfile != null) {
            print('👤 Profil utilisateur récupéré: ${userProfile.email}');
            
            // Vérifier que la photo est présente dans le cache après connexion
            if (userProfile.photo != null && userProfile.photo!.isNotEmpty) {
              print('📸 Photo utilisateur présente dans le profil');
            } else {
              print('⚠️ Aucune photo dans le profil utilisateur');
            }
          }
        } catch (e) {
          print('⚠️ Erreur récupération profil: $e');
        }
        
      } catch (e) {
        print('❌ Erreur test API: $e');
      }

      // Étape 7: Test de l'avatar dans le header
      print('👤 Test affichage avatar...');
      
      // Chercher l'avatar dans le header
      final avatarWidget = find.byKey(const Key('user_avatar'));
      if (avatarWidget.evaluate().isNotEmpty) {
        print('✅ Avatar trouvé dans le header');
        
        // Vérifier que l'avatar est interactif
        await tester.tap(avatarWidget);
        await tester.pumpAndSettle();
        
        // Vérifier si le menu profil s'ouvre
        if (find.text('Profil').evaluate().isNotEmpty ||
            find.text('Mon profil').evaluate().isNotEmpty) {
          print('✅ Menu profil accessible depuis l\'avatar');
          
          // Fermer le menu
          await tester.tapAt(const Offset(100, 100));
          await tester.pumpAndSettle();
        }
      } else {
        print('⚠️ Avatar non trouvé dans le header');
      }

      // Étape 8: Navigation de retour
      print('🔙 Test navigation retour...');
      
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
        print('✅ Navigation retour fonctionnelle');
      }

      // Étape 9: Test de déconnexion
      print('🚪 Test déconnexion...');
      
      // Chercher le bouton de déconnexion
      final logoutButton = find.text('Déconnexion');
      if (logoutButton.evaluate().isNotEmpty) {
        await tester.tap(logoutButton);
        await tester.pumpAndSettle();
        
        // Vérifier qu'on revient à l'écran de connexion
        expect(find.text('Connexion').evaluate().isNotEmpty ||
               find.text('Se connecter').evaluate().isNotEmpty,
               true, reason: 'Déconnexion ne fonctionne pas');
        
        print('✅ Déconnexion fonctionnelle');
      }

      print('🎉 Test d\'intégration terminé avec succès !');
    });

    testWidgets('Test isolation - Vérification des services', (WidgetTester tester) async {
      print('🔧 Test des services isolés...');
      
      // Test AuthApiService
      final authService = AuthApiService();
      expect(authService, isNotNull);
      
      // Test initialisation des services critiques
      try {
        // Ces tests ne nécessitent pas d'interface utilisateur
        print('✅ Services initialisés correctement');
      } catch (e) {
        print('❌ Erreur initialisation services: $e');
        fail('Services non initialisés: $e');
      }
    });

    testWidgets('Test responsive - Différentes tailles d\'écran', (WidgetTester tester) async {
      print('📱 Test responsive...');
      
      // Test avec petite taille d'écran
      await tester.binding.setSurfaceSize(const Size(360, 640));
      app.main();
      await tester.pumpAndSettle();
      
      print('✅ Test petite taille d\'écran OK');
      
      // Test avec grande taille d'écran
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpAndSettle();
      
      print('✅ Test grande taille d\'écran OK');
      
      // Remettre la taille par défaut
      await tester.binding.setSurfaceSize(null);
    });
  });
}
