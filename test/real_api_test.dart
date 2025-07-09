import 'package:flutter_test/flutter_test.dart';
import 'package:ena_mobile_front/services/auth_api_service.dart';
import 'package:ena_mobile_front/models/user_info.dart';
import 'package:ena_mobile_front/models/candidature_info.dart';

void main() {
  group('Test avec utilisateur réel', () {
    late String authToken;
    
    setUpAll(() async {
      // Connexion avec les vraies credentials
      print('🔐 Connexion avec les credentials réels...');
      final loginResult = await AuthApiService.login(
        email: 'isramut7@gmail.com',
        password: 'Isr@el12345',
      );
      
      print('📡 Réponse login: $loginResult');
      expect(loginResult['success'], true, reason: 'La connexion doit réussir');
      
      // Gestion flexible de la structure de réponse
      if (loginResult['data'] is Map && loginResult['data']['access'] != null) {
        authToken = loginResult['data']['access'];
      } else if (loginResult['token'] != null) {
        authToken = loginResult['token'];
      } else {
        throw Exception('Token non trouvé dans la réponse: $loginResult');
      }
      
      print('✅ Connexion réussie, token: ${authToken.substring(0, 20)}...');
    });

    test('Test des endpoints user-info et candidature', () async {
      print('\n🔍 Test des deux endpoints avec utilisateur réel...');
      
      // 1. Test /api/users/user-info/
      print('\n1️⃣ Appel /api/users/user-info/');
      final userInfoResult = await AuthApiService.getUserInfo(token: authToken);
      
      print('📡 Réponse user-info:');
      print('   - Success: ${userInfoResult['success']}');
      print('   - Data présent: ${userInfoResult['data'] != null}');
      
      expect(userInfoResult['success'], true, reason: 'getUserInfo doit réussir');
      expect(userInfoResult['data'], isNotNull, reason: 'getUserInfo doit retourner des données');
      
      final userInfo = UserInfo.fromJson(userInfoResult['data']);
      print('   - ID utilisateur: ${userInfo.id}');
      print('   - Email: ${userInfo.email}');
      print('   - Nom: ${userInfo.firstName} ${userInfo.lastName}');
      print('   - Has applied: ${userInfo.hasApplied}');
      
      // 2. Test /api/recrutement/candidature/statut/
      print('\n2️⃣ Appel /api/recrutement/candidature/statut/');
      final candidatureResult = await AuthApiService.getCandidatureStatut(token: authToken);
      
      print('📡 Réponse candidature:');
      print('   - Success: ${candidatureResult['success']}');
      print('   - Data présent: ${candidatureResult['data'] != null}');
      
      if (candidatureResult['success'] == true && candidatureResult['data'] != null) {
        final candidatureInfo = CandidatureInfo.fromJson(candidatureResult['data']);
        print('   - ID candidature: ${candidatureInfo.id}');
        print('   - Statut: ${candidatureInfo.statut}');
        print('   - Date création: ${candidatureInfo.dateCreation}');
        print('   - Candidat ID: ${candidatureInfo.candidat}');
        
        // 3. Vérification de la jointure
        print('\n3️⃣ Vérification de la jointure:');
        print('   - User ID: ${userInfo.id}');
        print('   - Candidat ID: ${candidatureInfo.candidat}');
        print('   - Jointure valide: ${userInfo.id == candidatureInfo.candidat}');
        
        if (userInfo.id == candidatureInfo.candidat) {
          print('✅ JOINTURE VALIDE !');
        } else {
          print('❌ JOINTURE INVALIDE !');
          print('   → L\'utilisateur connecté (${userInfo.id}) ne correspond pas au candidat (${candidatureInfo.candidat})');
        }
        
        // 4. Test logique d'affichage
        print('\n4️⃣ Logique d\'affichage selon les spécifications:');
        print('   - has_applied: ${userInfo.hasApplied}');
        if (userInfo.hasApplied) {
          if (userInfo.id == candidatureInfo.candidat) {
            switch (candidatureInfo.statut) {
              case 'envoye':
                print('   → Progressbar: 20%');
                print('   → Date de soumission: ${candidatureInfo.dateCreation.day.toString().padLeft(2, '0')}/${candidatureInfo.dateCreation.month.toString().padLeft(2, '0')}/${candidatureInfo.dateCreation.year}');
                break;
              case 'en_traitement':
                print('   → Progressbar: 70%');
                break;
              case 'valide':
                print('   → Progressbar: 100% (vert)');
                print('   → Message de félicitation');
                break;
              case 'rejete':
                print('   → Progressbar: 100% (rouge)');
                print('   → Message de rejet + bouton recours');
                break;
              default:
                print('   → Statut inconnu: ${candidatureInfo.statut}');
            }
          } else {
            print('   → ERREUR: Jointure invalide, impossible de déterminer le statut');
          }
        } else {
          print('   → Progressbar: 0%');
          print('   → Bouton "Soumettre ma candidature"');
        }
        
      } else {
        print('   - Erreur: ${candidatureResult['error'] ?? 'Erreur inconnue'}');
        
        if (userInfo.hasApplied) {
          print('\n⚠️ PROBLÈME DÉTECTÉ:');
          print('   - has_applied = true mais impossible de récupérer la candidature');
          print('   - Cela peut expliquer pourquoi la progressbar reste à 0%');
        }
      }
      
      print('\n📋 RÉSUMÉ DU TEST:');
      print('   - Connexion: ✅');
      print('   - User-info: ${userInfoResult['success'] ? '✅' : '❌'}');
      print('   - Candidature: ${candidatureResult['success'] ? '✅' : '❌'}');
      if (candidatureResult['success'] == true && candidatureResult['data'] != null) {
        final candidatureInfo = CandidatureInfo.fromJson(candidatureResult['data']);
        print('   - Jointure: ${userInfo.id == candidatureInfo.candidat ? '✅' : '❌'}');
      }
    });
  });
}
