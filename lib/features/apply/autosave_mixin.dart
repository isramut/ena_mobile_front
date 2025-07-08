import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mixin pour gérer l'auto-sauvegarde du formulaire de candidature
mixin AutoSaveMixin on State {
  Timer? autoSaveTimer;
  static const String autoSaveKey = 'candidature_form_autosave';
  static const Duration autoSaveInterval = Duration(minutes: 1);

  // Getters abstraits - doivent être implémentés par la classe qui utilise ce mixin
  int get currentStep;
  set currentStep(int value);
  
  TextEditingController get nomController;
  TextEditingController get postnomController;
  TextEditingController get prenomController;
  TextEditingController get lieuNaissanceController;
  TextEditingController get dateNaissanceController;
  TextEditingController get villeController;
  TextEditingController get numeroPieceController;
  TextEditingController get adresseController;
  TextEditingController get telephoneController;
  TextEditingController get anneeObtentionController;
  TextEditingController get etablissementController;
  TextEditingController get autreFiliereController;
  TextEditingController get matriculeController;
  TextEditingController get fonctionController;
  TextEditingController get entrepriseController;
  TextEditingController get ministereController;
  TextEditingController get administrationAttacheController;

  String get genre;
  set genre(String value);
  String get nationalite;
  set nationalite(String value);
  String get provinceOrigine;
  set provinceOrigine(String value);
  String get provinceResidence;
  set provinceResidence(String value);
  String get etatCivil;
  set etatCivil(String value);
  String get diplome;
  set diplome(String value);
  String get filiere;
  set filiere(String value);
  double get pourcentage;
  set pourcentage(double value);
  String get statutPro;
  set statutPro(String value);
  String get grade;
  set grade(String value);
  String get indicatif;
  set indicatif(String value);
  String get autreFiliere;
  set autreFiliere(String value);
  String get typePieceIdentite;
  set typePieceIdentite(String value);

  DateTime? get dateNaissance;
  set dateNaissance(DateTime? value);

  File? get photo;
  set photo(File? value);
  File? get carteId;
  set carteId(File? value);
  File? get lettreMotivation;
  set lettreMotivation(File? value);
  File? get cv;
  set cv(File? value);
  File? get acteAdmission;
  set acteAdmission(File? value);
  File? get diplomeFichier;
  set diplomeFichier(File? value);
  File? get aptitudeFichier;
  set aptitudeFichier(File? value);
  File? get releveNotes;
  set releveNotes(File? value);

  /// Démarre le timer d'auto-sauvegarde qui sauvegarde toutes les minutes
  void startAutoSave() {
    autoSaveTimer = Timer.periodic(autoSaveInterval, (timer) {
      saveFormData();
    });
  }

  /// Sauvegarde toutes les données du formulaire dans SharedPreferences
  void saveFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      Map<String, dynamic> formData = {
        // Étape actuelle
        'currentStep': currentStep,
        
        // Contrôleurs de texte - Étape 1
        'nom': nomController.text,
        'postnom': postnomController.text,
        'prenom': prenomController.text,
        'lieuNaissance': lieuNaissanceController.text,
        'dateNaissance': dateNaissanceController.text,
        'ville': villeController.text,
        'numeroPiece': numeroPieceController.text,
        'adresse': adresseController.text,
        'telephone': telephoneController.text,
        
        // Contrôleurs de texte - Étape 2
        'anneeObtention': anneeObtentionController.text,
        'etablissement': etablissementController.text,
        'autreFiliereValue': autreFiliereController.text,
        'matricule': matriculeController.text,
        'fonction': fonctionController.text,
        'entreprise': entrepriseController.text,
        'ministere': ministereController.text,
        'administrationAttache': administrationAttacheController.text,
        
        // Variables dropdown
        'genre': genre,
        'nationalite': nationalite,
        'provinceOrigine': provinceOrigine,
        'provinceResidence': provinceResidence,
        'etatCivil': etatCivil,
        'diplome': diplome,
        'filiere': filiere,
        'pourcentage': pourcentage,
        'statutPro': statutPro,
        'grade': grade,
        'indicatif': indicatif,
        'autreFiliere': autreFiliere,
        'typePieceIdentite': typePieceIdentite,
        
        // Date de naissance
        'dateNaissanceTimestamp': dateNaissance?.millisecondsSinceEpoch,
        
        // Chemins des fichiers (sauvegarde des chemins pour référence)
        'photoPath': photo?.path,
        'carteIdPath': carteId?.path,
        'lettreMotivationPath': lettreMotivation?.path,
        'cvPath': cv?.path,
        'acteAdmissionPath': acteAdmission?.path,
        'diplomeFichierPath': diplomeFichier?.path,
        'aptitudeFichierPath': aptitudeFichier?.path,
        'releveNotesPath': releveNotes?.path,
        
        // Timestamp de sauvegarde
        'saveTimestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(autoSaveKey, jsonEncode(formData));
      debugPrint('✅ Données du formulaire sauvegardées automatiquement');
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde automatique: $e');
    }
  }

  /// Charge les données sauvegardées et restaure l'état du formulaire
  void loadAutoSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDataString = prefs.getString(autoSaveKey);
      
      if (savedDataString != null) {
        final Map<String, dynamic> savedData = jsonDecode(savedDataString);
        
        // Vérifier si les données ne sont pas trop anciennes (ex: plus de 7 jours)
        final saveTimestamp = savedData['saveTimestamp'] as int?;
        if (saveTimestamp != null) {
          final saveDate = DateTime.fromMillisecondsSinceEpoch(saveTimestamp);
          final daysSinceSave = DateTime.now().difference(saveDate).inDays;
          
          if (daysSinceSave > 7) {
            // Données trop anciennes, on les supprime
            await clearAutoSavedData();
            return;
          }
        }
        
        setState(() {
          // Restaurer l'étape actuelle
          currentStep = savedData['currentStep'] ?? 0;
          
          // Restaurer les contrôleurs de texte - Étape 1
          nomController.text = savedData['nom'] ?? '';
          postnomController.text = savedData['postnom'] ?? '';
          prenomController.text = savedData['prenom'] ?? '';
          lieuNaissanceController.text = savedData['lieuNaissance'] ?? '';
          dateNaissanceController.text = savedData['dateNaissance'] ?? '';
          villeController.text = savedData['ville'] ?? '';
          numeroPieceController.text = savedData['numeroPiece'] ?? '';
          adresseController.text = savedData['adresse'] ?? '';
          telephoneController.text = savedData['telephone'] ?? '';
          
          // Restaurer les contrôleurs de texte - Étape 2
          anneeObtentionController.text = savedData['anneeObtention'] ?? '';
          etablissementController.text = savedData['etablissement'] ?? '';
          autreFiliereController.text = savedData['autreFiliereValue'] ?? '';
          matriculeController.text = savedData['matricule'] ?? '';
          fonctionController.text = savedData['fonction'] ?? '';
          entrepriseController.text = savedData['entreprise'] ?? '';
          ministereController.text = savedData['ministere'] ?? '';
          administrationAttacheController.text = savedData['administrationAttache'] ?? '';
          
          // Restaurer les variables dropdown
          genre = savedData['genre'] ?? 'Masculin';
          nationalite = savedData['nationalite'] ?? 'Congolaise';
          provinceOrigine = savedData['provinceOrigine'] ?? '';
          provinceResidence = savedData['provinceResidence'] ?? '';
          etatCivil = savedData['etatCivil'] ?? 'Célibataire';
          diplome = savedData['diplome'] ?? '';
          filiere = savedData['filiere'] ?? '';
          pourcentage = savedData['pourcentage']?.toDouble() ?? 60.0;
          statutPro = savedData['statutPro'] ?? 'Sans emploi';
          grade = savedData['grade'] ?? '';
          indicatif = savedData['indicatif'] ?? '+243';
          autreFiliere = savedData['autreFiliere'] ?? '';
          typePieceIdentite = savedData['typePieceIdentite'] ?? 'Carte d\'électeur';
          
          // Restaurer la date de naissance
          final dateTimestamp = savedData['dateNaissanceTimestamp'] as int?;
          if (dateTimestamp != null) {
            dateNaissance = DateTime.fromMillisecondsSinceEpoch(dateTimestamp);
          }
          
          // Restaurer les fichiers (si les chemins existent encore)
          restoreFileFromPath(savedData['photoPath'], (file) => photo = file);
          restoreFileFromPath(savedData['carteIdPath'], (file) => carteId = file);
          restoreFileFromPath(savedData['lettreMotivationPath'], (file) => lettreMotivation = file);
          restoreFileFromPath(savedData['cvPath'], (file) => cv = file);
          restoreFileFromPath(savedData['acteAdmissionPath'], (file) => acteAdmission = file);
          restoreFileFromPath(savedData['diplomeFichierPath'], (file) => diplomeFichier = file);
          restoreFileFromPath(savedData['aptitudeFichierPath'], (file) => aptitudeFichier = file);
          restoreFileFromPath(savedData['releveNotesPath'], (file) => releveNotes = file);
        });
        
        debugPrint('✅ Données du formulaire restaurées avec succès');
        
        // Afficher un message à l'utilisateur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Vos données précédentes ont été restaurées',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des données sauvegardées: $e');
    }
  }

  /// Aide à restaurer un fichier à partir de son chemin
  void restoreFileFromPath(String? path, Function(File) onFileRestored) {
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        onFileRestored(file);
      }
    }
  }

  /// Supprime les données sauvegardées (appelée après soumission réussie)
  Future<void> clearAutoSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(autoSaveKey);
      debugPrint('✅ Données sauvegardées supprimées');
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression des données sauvegardées: $e');
    }
  }

  /// Nettoie les ressources d'auto-sauvegarde
  void disposeAutoSave() {
    autoSaveTimer?.cancel();
    saveFormData(); // Sauvegarde finale
  }
}
