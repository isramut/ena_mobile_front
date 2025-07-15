import 'package:flutter_test/flutter_test.dart';
import 'package:ena_mobile_front/services/auth_api_service.dart';
import 'package:ena_mobile_front/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// Test de diagnostic pour identifier l'erreur backend dans la soumission de candidature
void main() {
  group('Diagnostic candidature - Bug backend identifié', () {
    late String authToken;

    setUpAll(() async {
      print('\n🔍 DIAGNOSTIC ERREUR CANDIDATURE\n');
      
      // Connexion avec l'utilisateur réel
      const String testEmail = 'isramut7@gmail.com';
      const String testPassword = 'Isr@mut#7';
      
      print('🔐 Connexion utilisateur test...');
      final loginResult = await AuthApiService.login(
        email: testEmail,
        password: testPassword,
      );
      
      expect(loginResult['success'], true, reason: 'Connexion doit réussir');
      
      if (loginResult['data'] is Map && loginResult['data']['access'] != null) {
        authToken = loginResult['data']['access'];
      } else if (loginResult['token'] != null) {
        authToken = loginResult['token'];
      } else {
        throw Exception('Token non trouvé: $loginResult');
      }
      
      print('✅ Connexion réussie, token: ${authToken.substring(0, 20)}...');
    });

    test('Étape 1: Test PATCH profil candidat avec logs détaillés', () async {
      print('\n📝 TEST PATCH PROFIL CANDIDAT AVEC LOGS DÉTAILLÉS\n');
      
      // ============ DONNÉES DE TEST COMPLÈTES ============
      final profileData = {
        "numero_piece_identite": "OP188839",
        "type_piece_identite": "passeport", // Ajout du type de pièce
        "nom": "NYEMBWA",
        "postnom": "MUTOMBO", 
        "prenom": "Israël",
        "genre": "M",
        "etat_civil": "C",
        "lieu_de_naissance": "Mbuji-Mayi", // Lieu supposé pour Kasaï Oriental
        "date_de_naissance": "2000-06-04",
        "adresse_physique": "lushi 50",
        "province_de_residence": "Kinshasa",
        "ville_de_residence": "Kinshasa",
        "province_d_origine": "Kasaï Oriental",
        "nationalite": "RDC",
        "niveau_etude": "maitrise", // Master = maitrise dans le code
        "domaine_etude": "Génie logiciel",
        "universite_frequentee": "UCC",
        "score_obtenu": 72,
        "annee_de_graduation": 2022,
        "statut_professionnel": "sans_emploi",
        "telephone": "+243825007071",
        // Champs optionnels pour "sans emploi" (vides)
        "matricule": "",
        "grade": "",
        "fonction": "",
        "administration_d_attache": "",
        "ministere": "",
        "entreprise": "",
      };
      
      print('🔍 ANALYSE DES CHAMPS AVANT ENVOI:');
      print('   📋 Nombre de champs: ${profileData.length}');
      
      // Vérification des champs requis
      final champsRequis = [
        'numero_piece_identite',
        'type_piece_identite',
        'nom', 
        'postnom',
        'prenom',
        'genre',
        'etat_civil',
        'lieu_de_naissance',
        'date_de_naissance',
        'nationalite',
        'telephone',
        'province_de_residence',
        'ville_de_residence',
        'province_d_origine',
        'niveau_etude',
        'domaine_etude',
        'universite_frequentee',
        'score_obtenu',
        'annee_de_graduation',
        'statut_professionnel'
      ];
      
      print('   ✅ Vérification des champs requis:');
      for (final champ in champsRequis) {
        final valeur = profileData[champ];
        final estVide = valeur == null || valeur.toString().trim().isEmpty;
        print('      $champ: ${estVide ? "❌ VIDE" : "✅ ${valeur}"}');
      }
      
      // Vérification des formats
      print('   🔍 Vérification des formats:');
      final dateNaissance = profileData['date_de_naissance'];
      final regexDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      print('      Date format YYYY-MM-DD: ${regexDate.hasMatch(dateNaissance.toString()) ? "✅" : "❌"} ($dateNaissance)');
      
      final telephone = profileData['telephone'];
      final regexTel = RegExp(r'^\+243\d{9}$');
      print('      Téléphone format +243XXXXXXXXX: ${regexTel.hasMatch(telephone.toString()) ? "✅" : "❌"} ($telephone)');
      
      final scoreObtenu = profileData['score_obtenu'];
      final estNombre = scoreObtenu is int && scoreObtenu >= 0 && scoreObtenu <= 100;
      print('      Score (0-100): ${estNombre ? "✅" : "❌"} ($scoreObtenu)');
      
      final anneeGraduation = profileData['annee_de_graduation'];
      final estAnneeValide = anneeGraduation is int && anneeGraduation >= 1950 && anneeGraduation <= DateTime.now().year;
      print('      Année graduation: ${estAnneeValide ? "✅" : "❌"} ($anneeGraduation)');
      
      // Vérifications spécifiques aux données de l'utilisateur
      final typePiece = profileData['type_piece_identite'];
      print('      Type pièce identité: ${typePiece != null && typePiece.toString().isNotEmpty ? "✅" : "❌"} ($typePiece)');
      
      final provinceOrigine = profileData['province_d_origine'];
      final provinceResidence = profileData['province_de_residence'];
      print('      Province origine: ${provinceOrigine != null ? "✅" : "❌"} ($provinceOrigine)');
      print('      Province résidence: ${provinceResidence != null ? "✅" : "❌"} ($provinceResidence)');
      
      final niveauEtude = profileData['niveau_etude'];
      print('      Niveau étude (Master=maitrise): ${niveauEtude == "maitrise" ? "✅" : "❌"} ($niveauEtude)');

      
      try {
        final patchUri = Uri.parse(ApiConfig.profilCandidatUrl);
        print('\n🔗 URL: $patchUri');
        
        final patchRequest = http.MultipartRequest('PATCH', patchUri);
        patchRequest.headers['Authorization'] = 'Bearer $authToken';
        patchRequest.headers['Content-Type'] = 'multipart/form-data';
        
        // Ajout des champs avec validation
        print('\n📤 AJOUT DES CHAMPS À LA REQUÊTE:');
        int champsAjoutes = 0;
        profileData.forEach((k, v) {
          final valueStr = v.toString();
          if (valueStr.isNotEmpty) {
            patchRequest.fields[k] = valueStr;
            print('   ✅ $k: $valueStr');
            champsAjoutes++;
          } else {
            print('   ❌ $k: IGNORÉ (vide)');
          }
        });
        
        print('\n📊 RÉSUMÉ REQUÊTE:');
        print('   Champs ajoutés: $champsAjoutes/${profileData.length}');
        print('   Headers: ${patchRequest.headers}');

        print('\n📡 ENVOI DE LA REQUÊTE PATCH...');
        final patchResp = await patchRequest.send();
        final patchRespBody = await patchResp.stream.bytesToString();
        
        print('\n� RÉPONSE PATCH:');
        print('   Status Code: ${patchResp.statusCode}');
        print('   Headers: ${patchResp.headers}');
        print('   Body Length: ${patchRespBody.length} caractères');
        print('   Body: $patchRespBody');
        
        if (patchResp.statusCode >= 400) {
          print('\n❌ ANALYSE DE L\'ERREUR PATCH:');
          
          // Analyse détaillée de l'erreur
          if (patchRespBody.isNotEmpty) {
            try {
              final errorJson = json.decode(patchRespBody);
              print('   📋 Erreur JSON décodée:');
              
              // Analyser les erreurs de champs spécifiques
              if (errorJson is Map) {
                errorJson.forEach((key, value) {
                  print('      🔍 $key: $value');
                  
                  // Identifier les champs problématiques
                  if (key == 'non_field_errors') {
                    print('         → Erreur générale du formulaire');
                  } else if (value is List && value.isNotEmpty) {
                    print('         → Problème avec le champ "$key": ${value.join(", ")}');
                  } else if (value is String) {
                    print('         → Problème avec le champ "$key": $value');
                  }
                });
              }
              
            } catch (e) {
              print('   📝 Erreur texte brute: $patchRespBody');
            }
          }
          
          // Suggestions basées sur le code d'erreur
          print('\n💡 DIAGNOSTIC SELON LE CODE D\'ERREUR:');
          switch (patchResp.statusCode) {
            case 400:
              print('   400 BAD REQUEST → Données invalides ou champs manquants');
              print('   🔍 Vérifier: formats de date, types de données, champs requis');
              break;
            case 401:
              print('   401 UNAUTHORIZED → Token expiré ou invalide');
              break;
            case 403:
              print('   403 FORBIDDEN → Permissions insuffisantes');
              break;
            case 404:
              print('   404 NOT FOUND → Endpoint ou ressource inexistant');
              break;
            case 422:
              print('   422 UNPROCESSABLE ENTITY → Erreur de validation');
              break;
            default:
              print('   ${patchResp.statusCode} → Erreur serveur');
          }
          
        } else {
          print('✅ PATCH RÉUSSI !');
          
          // Analyser la réponse de succès
          if (patchRespBody.isNotEmpty) {
            try {
              final successJson = json.decode(patchRespBody);
              print('   📋 Données retournées: $successJson');
            } catch (e) {
              print('   📝 Réponse texte: $patchRespBody');
            }
          }
        }
        
      } catch (e, stackTrace) {
        print('\n💥 EXCEPTION PATCH:');
        print('   Type: ${e.runtimeType}');
        print('   Message: $e');
        print('   StackTrace: $stackTrace');
        
        // Diagnostic selon le type d'exception
        if (e.toString().contains('SocketException')) {
          print('   🌐 Problème de connectivité réseau');
        } else if (e.toString().contains('TimeoutException')) {
          print('   ⏱️ Délai d\'attente dépassé');
        } else if (e.toString().contains('FormatException')) {
          print('   📋 Erreur de format de données');
        }
      }
    });

    test('Étape 2: Test POST candidature avec logs détaillés', () async {
      print('\n📎 TEST POST CANDIDATURE AVEC LOGS DÉTAILLÉS\n');
      
      try {
        // Créer des fichiers de test temporaires
        final tempDir = Directory.systemTemp;
        final testFiles = <String, File>{};
        
        // Mapping exact des noms de fichiers attendus par l'API
        final fileMapping = {
          'piece_identite': 'passeport_OP188839.pdf',
          'diplome': 'diplome_master_UCC_2022.pdf', 
          'lettre_motivation': 'lettre_motivation_israel_nyembwa.pdf',
          'aptitude_physique': 'certificat_aptitude_physique.pdf',
          'cv': 'cv_israel_nyembwa_genie_logiciel.pdf',
          'releves_notes': 'releves_notes_master_UCC.pdf'
        };
        
        print('📄 CRÉATION DES FICHIERS DE TEST:');
        for (final entry in fileMapping.entries) {
          final fieldName = entry.key;
          final fileName = entry.value;
          final file = File('${tempDir.path}/$fileName');
          
          // Créer un contenu PDF-like plus réaliste selon le type de document
          String content;
          switch (fieldName) {
            case 'piece_identite':
              content = '''%PDF-1.4
RÉPUBLIQUE DÉMOCRATIQUE DU CONGO
PASSEPORT / PASSPORT
Nom/Name: NYEMBWA
Prénom/Given Names: MUTOMBO ISRAËL
Date de naissance/Date of birth: 04/06/2000
Lieu de naissance/Place of birth: Mbuji-Mayi
Numéro/Number: OP188839
Type: P (Passeport ordinaire)
%%EOF''';
              break;
            case 'diplome':
              content = '''%PDF-1.4
UNIVERSITÉ CATHOLIQUE DU CONGO (UCC)
DIPLÔME DE MASTER
Nom: NYEMBWA MUTOMBO Israël
Filière: Génie Logiciel
Année d'obtention: 2022
Pourcentage obtenu: 72%
Mention: Distinction
%%EOF''';
              break;
            case 'lettre_motivation':
              content = '''%PDF-1.4
LETTRE DE MOTIVATION
Candidature à l'École Nationale d'Administration

Monsieur le Directeur,

Je soussigné NYEMBWA MUTOMBO Israël, titulaire d'un Master en Génie Logiciel de l'UCC,
ai l'honneur de solliciter mon admission à l'École Nationale d'Administration.

Mes compétences en développement logiciel et ma passion pour le service public
m'amènent à vouloir contribuer à la modernisation de l'administration congolaise.

Veuillez agréer mes salutations distinguées.

Israël NYEMBWA MUTOMBO
%%EOF''';
              break;
            case 'cv':
              content = '''%PDF-1.4
CURRICULUM VITAE
NYEMBWA MUTOMBO Israël

INFORMATIONS PERSONNELLES:
- Date de naissance: 04/06/2000
- Adresse: lushi 50, Kinshasa
- Téléphone: +243 825007071
- Nationalité: Congolaise

FORMATION:
2022 - Master en Génie Logiciel, UCC (72%)

COMPÉTENCES:
- Développement logiciel
- Programmation orientée objet
- Base de données
- Gestion de projets IT
%%EOF''';
              break;
            case 'aptitude_physique':
              content = '''%PDF-1.4
CERTIFICAT D'APTITUDE PHYSIQUE

Patient: NYEMBWA MUTOMBO Israël
Date d'examen: 15/07/2025

RÉSULTATS:
- Tension artérielle: Normale
- Fréquence cardiaque: Normale
- Vision: Bonne
- Audition: Bonne
- Aptitude générale: APTE

Dr. MEDICAL
%%EOF''';
              break;
            case 'releves_notes':
              content = '''%PDF-1.4
RELEVÉ DE NOTES - MASTER GÉNIE LOGICIEL
UCC - Année académique 2021-2022

Étudiant: NYEMBWA MUTOMBO Israël

MATIÈRES:
- Algorithmique avancée: 15/20
- Génie logiciel: 16/20
- Base de données: 14/20
- Programmation orientée objet: 15/20
- Gestion de projets: 13/20

MOYENNE GÉNÉRALE: 14.4/20 (72%)
MENTION: Distinction
%%EOF''';
              break;
            default:
              content = '''%PDF-1.4
Document de test pour $fieldName
Utilisateur: NYEMBWA MUTOMBO Israël
Date: ${DateTime.now().toIso8601String()}
%%EOF''';
          }
          
          await file.writeAsString(content);
          testFiles[fieldName] = file;
          
          final fileSize = await file.length();
          print('   ✅ $fieldName → $fileName (${fileSize} bytes)');
          
          // Vérification de l'existence du fichier
          if (await file.exists()) {
            print('      📄 Fichier créé et accessible');
          } else {
            print('      ❌ Erreur: Fichier non créé');
          }
        }

        final postUri = Uri.parse(ApiConfig.candidatureAddUrl);
        print('\n🔗 URL POST: $postUri');
        
        final postRequest = http.MultipartRequest('POST', postUri);
        postRequest.headers['Authorization'] = 'Bearer $authToken';
        postRequest.headers['Content-Type'] = 'multipart/form-data';

        print('\n📎 AJOUT DES FICHIERS À LA REQUÊTE:');
        int fichiersAjoutes = 0;
        
        for (final entry in testFiles.entries) {
          final fieldName = entry.key;
          final file = entry.value;
          
          try {
            final multipartFile = await http.MultipartFile.fromPath(fieldName, file.path);
            postRequest.files.add(multipartFile);
            
            print('   ✅ $fieldName:');
            print('      📁 Path: ${file.path}');
            print('      📏 Size: ${multipartFile.length} bytes');
            print('      🎯 Content-Type: ${multipartFile.contentType}');
            
            fichiersAjoutes++;
          } catch (e) {
            print('   ❌ $fieldName: ERREUR - $e');
          }
        }
        
        print('\n� RÉSUMÉ REQUÊTE POST:');
        print('   Fichiers ajoutés: $fichiersAjoutes/${testFiles.length}');
        print('   Headers: ${postRequest.headers}');
        print('   URL: ${postRequest.url}');
        print('   Method: ${postRequest.method}');

        print('\n📡 ENVOI DE LA CANDIDATURE...');
        final postResponse = await postRequest.send();
        final postRespBody = await postResponse.stream.bytesToString();

        print('\n� RÉPONSE POST:');
        print('   Status Code: ${postResponse.statusCode}');
        print('   Headers: ${postResponse.headers}');
        print('   Body Length: ${postRespBody.length} caractères');
        print('   Body: $postRespBody');

        if (postResponse.statusCode == 201 || postResponse.statusCode == 200) {
          print('\n✅ CANDIDATURE SOUMISE AVEC SUCCÈS !');
          
          // Analyser la réponse de succès
          if (postRespBody.isNotEmpty) {
            try {
              final successJson = json.decode(postRespBody);
              print('   📋 Données retournées: $successJson');
            } catch (e) {
              print('   📝 Réponse texte: $postRespBody');
            }
          }
          
        } else {
          print('\n❌ ERREUR SOUMISSION CANDIDATURE');
          
          // Analyse détaillée de l'erreur POST
          print('\n🔍 ANALYSE DÉTAILLÉE DE L\'ERREUR:');
          print('   Code d\'erreur: ${postResponse.statusCode}');
          
          if (postRespBody.isNotEmpty) {
            try {
              final errorData = json.decode(postRespBody);
              print('   📋 Erreur JSON décodée:');
              
              if (errorData is Map) {
                errorData.forEach((key, value) {
                  print('      🔍 $key: $value');
                  
                  // Identifier les problèmes spécifiques
                  if (key.contains('file') || key.contains('fichier')) {
                    print('         → Problème avec les fichiers');
                  } else if (key.contains('candidature')) {
                    print('         → Problème avec la candidature elle-même');
                  } else if (key.contains('user') || key.contains('utilisateur')) {
                    print('         → Problème avec l\'utilisateur');
                  }
                });
              }
              
            } catch (e) {
              print('   � Erreur texte brute: $postRespBody');
              
              // Rechercher des mots-clés dans l'erreur
              final errorLower = postRespBody.toLowerCase();
              if (errorLower.contains('duplicate') || errorLower.contains('unique')) {
                print('   🔍 Détecté: Candidature en double');
              } else if (errorLower.contains('file') || errorLower.contains('fichier')) {
                print('   🔍 Détecté: Problème avec les fichiers');
              } else if (errorLower.contains('permission') || errorLower.contains('forbidden')) {
                print('   🔍 Détecté: Problème de permissions');
              } else if (errorLower.contains('field') || errorLower.contains('champ')) {
                print('   🔍 Détecté: Problème avec un champ spécifique');
              }
            }
          }
          
          // Diagnostic selon le code d'erreur
          print('\n💡 DIAGNOSTIC SELON LE CODE D\'ERREUR:');
          switch (postResponse.statusCode) {
            case 400:
              print('   400 BAD REQUEST → Fichiers invalides ou données manquantes');
              print('   🔍 Vérifier: formats de fichiers, tailles, champs requis');
              break;
            case 409:
              print('   409 CONFLICT → Candidature déjà existante pour cet utilisateur');
              break;
            case 413:
              print('   413 PAYLOAD TOO LARGE → Fichiers trop volumineux');
              break;
            case 422:
              print('   422 UNPROCESSABLE ENTITY → Erreur de validation des fichiers');
              break;
            case 500:
              print('   500 INTERNAL SERVER ERROR → Erreur côté serveur');
              break;
            default:
              print('   ${postResponse.statusCode} → Code d\'erreur inhabituel');
          }
        }

        // Nettoyage des fichiers de test
        print('\n🧹 NETTOYAGE DES FICHIERS DE TEST...');
        for (final file in testFiles.values) {
          if (await file.exists()) {
            await file.delete();
            print('   🗑️ Supprimé: ${file.path}');
          }
        }
        
      } catch (e, stackTrace) {
        print('\n💥 EXCEPTION POST:');
        print('   Type: ${e.runtimeType}');
        print('   Message: $e');
        print('   StackTrace: $stackTrace');
      }
    });

    test('Étape 3: Test des endpoints alternatifs', () async {
      print('\n🔄 TEST ENDPOINTS ALTERNATIFS\n');
      
      final alternativeUrls = [
        '${ApiConfig.baseUrl}/api/recrutement/candidature/',
        '${ApiConfig.baseUrl}/api/recrutement/candidatures/',
        '${ApiConfig.baseUrl}/api/candidature/add/',
        '${ApiConfig.baseUrl}/api/candidatures/add/',
      ];
      
      for (final url in alternativeUrls) {
        print('🔍 Test endpoint: $url');
        
        try {
          final response = await http.post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
            body: json.encode({'test': 'data'}),
          );
          
          print('   Status: ${response.statusCode}');
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            print('   ✅ Endpoint valide !');
          } else if (response.statusCode == 404) {
            print('   ❌ Endpoint non trouvé');
          } else if (response.statusCode == 405) {
            print('   ⚠️ Méthode non autorisée');
          } else {
            print('   ⚠️ Autre erreur: ${response.body}');
          }
          
        } catch (e) {
          print('   💥 Exception: $e');
        }
      }
    });

    test('Étape 4: Vérification du statut utilisateur', () async {
      print('\n👤 VÉRIFICATION STATUT UTILISATEUR\n');
      
      try {
        final userInfoResult = await AuthApiService.getUserInfo(token: authToken);
        
        if (userInfoResult['success'] == true && userInfoResult['data'] != null) {
          final userData = userInfoResult['data'];
          
          print('📋 Informations utilisateur:');
          print('   ID: ${userData['id']}');
          print('   Email: ${userData['email']}');
          print('   Has applied: ${userData['has_applied']}');
          print('   Created: ${userData['date_joined']}');
          
          // Si has_applied = true, c'est peut-être pour ça que la soumission échoue
          if (userData['has_applied'] == true) {
            print('\n⚠️ PROBLÈME IDENTIFIÉ:');
            print('   L\'utilisateur a déjà soumis une candidature');
            print('   Cela explique pourquoi les nouvelles soumissions échouent');
          }
          
        } else {
          print('❌ Impossible de récupérer les infos utilisateur');
        }
        
      } catch (e) {
        print('💥 Exception getUserInfo: $e');
      }
    });
  });
}
