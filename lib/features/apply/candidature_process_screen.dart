import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../services/auth_api_service.dart';
import '../../services/pdf_generator_service.dart';
import '../../services/image_cache_service.dart';
import '../../services/profile_update_notification_service.dart';
import '../../models/candidature_pdf_data.dart';

class CandidatureProcessScreen extends StatefulWidget {
  const CandidatureProcessScreen({super.key});
  @override
  State<CandidatureProcessScreen> createState() =>
      _CandidatureProcessScreenState();
}

class _CandidatureProcessScreenState extends State<CandidatureProcessScreen> {
  int currentStep = 0;
  bool loading = false;
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  // === TextEditingControllers
  final nomController = TextEditingController();
  final postnomController = TextEditingController();
  final prenomController = TextEditingController();
  final lieuNaissanceController = TextEditingController();
  final dateNaissanceController = TextEditingController();
  final villeController = TextEditingController();
  final numeroPieceController = TextEditingController();
  final adresseController = TextEditingController();
  final telephoneController = TextEditingController();

  final anneeObtentionController = TextEditingController();
  final etablissementController = TextEditingController();
  final autreFiliereController = TextEditingController();
  final matriculeController = TextEditingController();
  final fonctionController = TextEditingController();
  final entrepriseController = TextEditingController();
  final ministereController = TextEditingController();
  final administrationAttacheController = TextEditingController();

  // Dropdown
  String genre = "";
  String nationalite = "";
  String provinceOrigine = "";
  String provinceResidence = "";
  String etatCivil = "";
  String diplome = "";
  String filiere = "";
  double pourcentage = 60;
  String statutPro = "";
  String grade = "";
  String indicatif = "+243"; // Valeur par défaut pour la RDC
  String autreFiliere = "";
  String typePieceIdentite = "";

  // Fichiers
  File? photo,
      carteId,
      lettreMotivation,
      cv,
      acteAdmission,
      diplomeFichier,
      aptitudeFichier,
      releveNotes;

  final List<String> provinces = [
    "Bas-Uele",
    "Équateur",
    "Haut-Katanga",
    "Haut-Lomami",
    "Haut-Uele",
    "Ituri",
    "Kasaï",
    "Kasaï Central",
    "Kasaï Oriental",
    "Kinshasa",
    "Kwango",
    "Kwilu",
    "Lomami",
    "Lualaba",
    "Mai-Ndombe",
    "Maniema",
    "Mongala",
    "Nord-Kivu",
    "Nord-Ubangi",
    "Sankuru",
    "Sud-Kivu",
    "Sud-Ubangi",
    "Tanganyika",
    "Tshopo",
    "Tshuapa",
  ];
  final List<String> indicatifs = ["+243", "+33", "+32", "+1", "+44"];
  final List<String> diplomes = [
    "Diplome d'Etat",
    "Bac+3",
    "Bac+5",
    "Master",
    "Doctorat",
  ];
  List<String> filieres = [
    "Administration",
    "Administration publique",
    "Aménagement et gestion des ressources naturelles / Environnement",
    "Anthropologie",
    "Architecture",
    "Arts dramatiques et cinématographie",
    "Arts plastiques",
    "Aviation civile",
    "Bâtiments et travaux publics",
    "Biologie médicale",
    "Chimie",
    "Cinéma",
    "Communication",
    "Comptabilité",
    "Criminologie",
    "Design textile, stylisme et création de mode",
    "Développement",
    "Diplôme MITEL",
    "Droit",
    "Écologie",
    "Économie",
    "Électronique",
    "Environnement",
    "Environnement et développement durable",
    "Exploitation aéronautique",
    "Exploitation et production pétrolière",
    "Finance, Banques et Assurances",
    "Fiscalité",
    "Foresterie",
    "Génie civil",
    "Génie des mines",
    "Génie électrique",
    "Génie informatique",
    "Génie logiciel",
    "Génie mécanique",
    "Génie textile",
    "Géographie",
    "Géologie",
    "Géotechnique et Hydrogéologie",
    "Gestion de l'Environnement",
    "Gestion financière",
    "Gestion des entreprises et organisation du travail / GRH",
    "Histoire et archivistique",
    "Hôtellerie et tourisme",
    "Informatique",
    "Kinésithérapie",
    "Langues et littératures africaines",
    "Langues étrangères (français, anglais, espagnol, chinois, allemand, etc.)",
    "Lettres et Sciences humaines",
    "Management des organisations",
    "Marketing",
    "Mathématique",
    "Mathématique-Informatique",
    "Médecine",
    "Médecine générale",
    "Médecine vétérinaire",
    "Métallurgie",
    "Musique",
    "Nutrition et technologie alimentaire",
    "Odontologie (chirurgie dentaire)",
    "Pêche et Aquaculture",
    "Philosophie",
    "Pharmacie",
    "Photographie",
    "Pédagogie",
    "Physique",
    "Pétrole et gaz",
    "Psychologie",
    "Relations Internationales",
    "Réseau et Télécommunications",
    "Santé publique",
    "Sciences de la communication et journalisme",
    "Sciences de l'Éducation",
    "Sciences infirmières",
    "Sciences politiques et administratives",
    "Sciences et technologies de l'information",
    "Sociologie",
    "Statistique",
    "Télécommunications",
    "Théâtre",
    "Transport et logistique",
    "Urbanisme",
    "Urbanisme et aménagement du territoire",
    "Zootechnie",
    "Autre",
  ];
  final List<String> grades = [
    "Huissier",
    "Agents d'administration de 2ème classe",
    "Agent d'administration de 1ère classe",
    "Attaché d'administration de 2ème classe",
    "Attaché d'administration de 1ère classe",
    "Chef de Bureau",
    "Chef de Division",
    "Directeur",
    "Secrétaire Général",
  ];
  final List<String> statuts = [
    "Fonctionnaire",
    "Employé privé",
    "Sans emploi",
  ];

  DateTime? dateNaissance;
  final ScrollController _scrollController = ScrollController();

  // Auto-sauvegarde
  Timer? _autoSaveTimer;
  static const String _autoSaveKey = 'candidature_form_autosave';
  static const Duration _autoSaveInterval = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    _loadAutoSavedData();
    _startAutoSave();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _saveFormData();
    nomController.dispose();
    postnomController.dispose();
    prenomController.dispose();
    lieuNaissanceController.dispose();
    dateNaissanceController.dispose();
    villeController.dispose();
    numeroPieceController.dispose();
    adresseController.dispose();
    telephoneController.dispose();
    anneeObtentionController.dispose();
    etablissementController.dispose();
    autreFiliereController.dispose();
    matriculeController.dispose();
    fonctionController.dispose();
    entrepriseController.dispose();
    ministereController.dispose();
    administrationAttacheController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ===================== VALIDATION DU TÉLÉPHONE =====================
  
  /// Valide le numéro de téléphone selon les critères:
  /// - Exactement 9 chiffres
  /// - Ne commence pas par 0
  /// - Contient uniquement des chiffres
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Numéro de téléphone requis";
    }
    
    String cleanedValue = value.trim();
    
    // Vérifier que c'est uniquement des chiffres
    if (!RegExp(r'^\d+$').hasMatch(cleanedValue)) {
      return "Le téléphone ne doit contenir que des chiffres";
    }
    
    // Vérifier que c'est exactement 9 chiffres
    if (cleanedValue.length != 9) {
      return "Le téléphone doit contenir exactement 9 chiffres";
    }
    
    // Vérifier que ça ne commence pas par 0
    if (cleanedValue.startsWith('0')) {
      return "Le téléphone ne doit pas commencer par 0";
    }
    
    return null;
  }

  // ===================== AUTO-SAUVEGARDE =====================

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (timer) {
      _saveFormData();
    });
  }

  void _saveFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      Map<String, dynamic> formData = {
        'currentStep': currentStep,
        'nom': nomController.text,
        'postnom': postnomController.text,
        'prenom': prenomController.text,
        'lieuNaissance': lieuNaissanceController.text,
        'dateNaissance': dateNaissanceController.text,
        'ville': villeController.text,
        'numeroPiece': numeroPieceController.text,
        'adresse': adresseController.text,
        'telephone': telephoneController.text,
        'anneeObtention': anneeObtentionController.text,
        'etablissement': etablissementController.text,
        'autreFiliereValue': autreFiliereController.text,
        'matricule': matriculeController.text,
        'fonction': fonctionController.text,
        'entreprise': entrepriseController.text,
        'ministere': ministereController.text,
        'administrationAttache': administrationAttacheController.text,
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
        'dateNaissanceTimestamp': dateNaissance?.millisecondsSinceEpoch,
        'photoPath': photo?.path,
        'carteIdPath': carteId?.path,
        'lettreMotivationPath': lettreMotivation?.path,
        'cvPath': cv?.path,
        'acteAdmissionPath': acteAdmission?.path,
        'diplomeFichierPath': diplomeFichier?.path,
        'aptitudeFichierPath': aptitudeFichier?.path,
        'releveNotesPath': releveNotes?.path,
        'saveTimestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(_autoSaveKey, jsonEncode(formData));
      debugPrint('✅ Auto-sauvegarde effectuée');
    } catch (e) {
      debugPrint('❌ Erreur auto-sauvegarde: $e');
    }
  }

  void _loadAutoSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDataString = prefs.getString(_autoSaveKey);
      
      if (savedDataString != null) {
        final Map<String, dynamic> savedData = jsonDecode(savedDataString);
        
        final saveTimestamp = savedData['saveTimestamp'] as int?;
        if (saveTimestamp != null) {
          final saveDate = DateTime.fromMillisecondsSinceEpoch(saveTimestamp);
          final daysSinceSave = DateTime.now().difference(saveDate).inDays;
          
          if (daysSinceSave > 7) {
            await _clearAutoSavedData();
            return;
          }
        }
        
        setState(() {
          currentStep = savedData['currentStep'] ?? 0;
          nomController.text = savedData['nom'] ?? '';
          postnomController.text = savedData['postnom'] ?? '';
          prenomController.text = savedData['prenom'] ?? '';
          lieuNaissanceController.text = savedData['lieuNaissance'] ?? '';
          dateNaissanceController.text = savedData['dateNaissance'] ?? '';
          villeController.text = savedData['ville'] ?? '';
          numeroPieceController.text = savedData['numeroPiece'] ?? '';
          adresseController.text = savedData['adresse'] ?? '';
          telephoneController.text = savedData['telephone'] ?? '';
          anneeObtentionController.text = savedData['anneeObtention'] ?? '';
          etablissementController.text = savedData['etablissement'] ?? '';
          autreFiliereController.text = savedData['autreFiliereValue'] ?? '';
          matriculeController.text = savedData['matricule'] ?? '';
          fonctionController.text = savedData['fonction'] ?? '';
          entrepriseController.text = savedData['entreprise'] ?? '';
          ministereController.text = savedData['ministere'] ?? '';
          administrationAttacheController.text = savedData['administrationAttache'] ?? '';
          genre = savedData['genre'] ?? '';
          nationalite = savedData['nationalite'] ?? '';
          provinceOrigine = savedData['provinceOrigine'] ?? '';
          provinceResidence = savedData['provinceResidence'] ?? '';
          etatCivil = savedData['etatCivil'] ?? '';
          diplome = savedData['diplome'] ?? '';
          filiere = savedData['filiere'] ?? '';
          pourcentage = savedData['pourcentage']?.toDouble() ?? 60.0;
          statutPro = savedData['statutPro'] ?? '';
          grade = savedData['grade'] ?? '';
          indicatif = savedData['indicatif'] ?? '';
          autreFiliere = savedData['autreFiliere'] ?? '';
          typePieceIdentite = savedData['typePieceIdentite'] ?? '';
          
          final dateTimestamp = savedData['dateNaissanceTimestamp'] as int?;
          if (dateTimestamp != null) {
            dateNaissance = DateTime.fromMillisecondsSinceEpoch(dateTimestamp);
          }
          
          _restoreFileFromPath(savedData['photoPath'], (file) => photo = file);
          _restoreFileFromPath(savedData['carteIdPath'], (file) => carteId = file);
          _restoreFileFromPath(savedData['lettreMotivationPath'], (file) => lettreMotivation = file);
          _restoreFileFromPath(savedData['cvPath'], (file) => cv = file);
          _restoreFileFromPath(savedData['acteAdmissionPath'], (file) => acteAdmission = file);
          _restoreFileFromPath(savedData['diplomeFichierPath'], (file) => diplomeFichier = file);
          _restoreFileFromPath(savedData['aptitudeFichierPath'], (file) => aptitudeFichier = file);
          _restoreFileFromPath(savedData['releveNotesPath'], (file) => releveNotes = file);
        });
        
        debugPrint('✅ Données restaurées');
        
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
      debugPrint('❌ Erreur chargement: $e');
    }
  }

  void _restoreFileFromPath(String? path, Function(File) onFileRestored) {
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        onFileRestored(file);
      }
    }
  }

  Future<void> _clearAutoSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_autoSaveKey);
      debugPrint('✅ Données supprimées');
    } catch (e) {
      debugPrint('❌ Erreur suppression: $e');
    }
  }

  // Validation stricte pour administration et ministère
  String? _validateAdministrationMinistere(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName requis";
    }
    
    // Regex encore plus stricte : lettres, espaces, apostrophes, tirets et points uniquement
    final RegExp strictTextRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s'\-.]+$");
    
    if (!strictTextRegex.hasMatch(value.trim())) {
      return "$fieldName ne doit contenir que des lettres (pas de chiffres ni caractères spéciaux)";
    }
    
    // Vérifier qu'il n'y a pas de chiffres
    if (RegExp(r'\d').hasMatch(value.trim())) {
      return "$fieldName ne doit pas contenir de chiffres";
    }
    
    // Vérifier qu'il n'y a pas de caractères spéciaux interdits
    if (RegExp(r'[!@#$%^&*()_+=\[\]{}|;:",.<>?/~`]').hasMatch(value.trim())) {
      return "$fieldName ne doit pas contenir de caractères spéciaux";
    }
    
    return null;
  }

  // ===================== VALIDATION DES STEPS =====================
  bool _validateCurrentStep() {
    switch (currentStep) {
      case 0:
        // Step 1: Informations personnelles - tous les champs obligatoires
        bool formValid = _formKey1.currentState?.validate() ?? false;
        if (!formValid) return false;
        
        // Vérification des champs requis
        return photo != null &&
               nomController.text.trim().isNotEmpty &&
               postnomController.text.trim().isNotEmpty &&
               prenomController.text.trim().isNotEmpty &&
               genre.isNotEmpty &&
               lieuNaissanceController.text.trim().isNotEmpty &&
               dateNaissanceController.text.trim().isNotEmpty &&
               etatCivil.isNotEmpty &&
               nationalite.isNotEmpty &&
               provinceOrigine.isNotEmpty &&
               provinceResidence.isNotEmpty &&
               villeController.text.trim().isNotEmpty &&
               typePieceIdentite.isNotEmpty &&
               numeroPieceController.text.trim().isNotEmpty &&
               adresseController.text.trim().isNotEmpty &&
               indicatif.isNotEmpty &&
               telephoneController.text.trim().isNotEmpty;
      case 1:
        // Validation du formulaire de base
        bool formValid = _formKey2.currentState?.validate() ?? false;
        if (!formValid) return false;
        
        // Validation des champs obligatoires de base
        if (diplome.isEmpty ||
            anneeObtentionController.text.trim().isEmpty ||
            etablissementController.text.trim().isEmpty ||
            filiere.isEmpty ||
            statutPro.isEmpty) {
          return false;
        }
        
        // Validation conditionnelle selon le statut professionnel
        if (statutPro == "Fonctionnaire") {
          return matriculeController.text.trim().isNotEmpty &&
                 grade.isNotEmpty &&
                 administrationAttacheController.text.trim().isNotEmpty &&
                 fonctionController.text.trim().isNotEmpty &&
                 ministereController.text.trim().isNotEmpty;
        } else if (statutPro == "Employé privé") {
          return fonctionController.text.trim().isNotEmpty &&
                 entrepriseController.text.trim().isNotEmpty;
        }
        
        return true; // Pour "Sans emploi", pas de champs supplémentaires requis
      case 2:
        // Validation des fichiers obligatoires
        bool allFilesPresent = carteId != null &&
            lettreMotivation != null &&
            cv != null &&
            diplomeFichier != null &&
            aptitudeFichier != null &&
            releveNotes != null;
            
        // Ajouter l'acte d'admission pour les fonctionnaires
        if (statutPro == "Fonctionnaire") {
          allFilesPresent = allFilesPresent && acteAdmission != null;
        }
        
        return allFilesPresent;
      case 3:
        return true; // Récapitulatif, pas de validation
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      setState(() => currentStep++);
      // Déplacer le scroll vers le haut pour que l'utilisateur voit le nouveau contenu
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    } else {
      final theme = Theme.of(context);
      String message;
      switch (currentStep) {
        case 0:
          if (!(_formKey1.currentState?.validate() ?? false)) {
            message = "Merci de compléter tous les champs obligatoires.";
          } else {
            message = "Merci d'ajouter une photo.";
          }
          break;
        case 1:
          // Messages spécifiques selon le statut professionnel
          if (statutPro == "Fonctionnaire") {
            message = "Merci de compléter tous les champs obligatoires pour les fonctionnaires : diplôme, année d'obtention, établissement, filière, matricule, grade, administration d'attache, fonction et ministère.";
          } else if (statutPro == "Employé privé") {
            message = "Merci de compléter tous les champs obligatoires pour les employés privés : diplôme, année d'obtention, établissement, filière, fonction et entreprise.";
          } else if (statutPro == "Sans emploi") {
            message = "Merci de compléter tous les champs obligatoires : diplôme, année d'obtention, établissement, filière et statut professionnel.";
          } else {
            message = "Merci de compléter tous les champs obligatoires.";
          }
          break;
        case 2:
          if (statutPro == "Fonctionnaire") {
            message = "Merci de joindre tous les fichiers obligatoires, y compris l'acte d'admission sous statut pour les fonctionnaires.";
          } else {
            message = "Merci de joindre tous les fichiers obligatoires.";
          }
          break;
        default:
          message = "Veuillez vérifier les informations saisies.";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: theme.colorScheme.primary,
        ),
      );
    }
  }

  // ==== UI HELPERS ====
  InputDecoration _inputDecoration(String label) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      filled: true,
      fillColor: theme.colorScheme.surface.withValues(alpha: 0.8),
      isDense: true,
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      floatingLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: theme.colorScheme.primary,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  // Validation de taille et format de fichier
  bool _validateFile(File file, {bool isImage = false}) {
    const maxSizeBytes = 5 * 1024 * 1024; // 5 MB
    
    // Vérifier la taille
    final fileSize = file.lengthSync();
    if (fileSize > maxSizeBytes) {
      _showErrorDialog("Le fichier dépasse la taille maximale autorisée de 5 MB.\nTaille du fichier: ${_getFileSize(file)}");
      return false;
    }

    // Vérifier le format
    final fileName = file.path.toLowerCase();
    if (isImage) {
      // Pour les images: PNG, JPG, JPEG
      if (!fileName.endsWith('.png') && 
          !fileName.endsWith('.jpg') && 
          !fileName.endsWith('.jpeg')) {
        _showErrorDialog("Format d'image non supporté.\nFormats acceptés: PNG, JPG, JPEG");
        return false;
      }
    } else {
      // Pour les documents: PDF, DOCX
      if (!fileName.endsWith('.pdf') && !fileName.endsWith('.docx')) {
        _showErrorDialog("Format de document non supporté.\nFormats acceptés: PDF, DOCX");
        return false;
      }
    }

    return true;
  }

  Future<void> _pickFile(Function(File) setter, {bool isImage = false}) async {
    // Montrer une boîte de dialogue pour choisir le type de fichier
    final choice = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Sélectionner un fichier",
            style: GoogleFonts.poppins(
              color: theme.textTheme.headlineSmall?.color,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isImage 
                  ? "Choisissez une image (PNG, JPG, JPEG) :"
                  : "Choisissez un document (PDF, DOCX) :",
                style: GoogleFonts.poppins(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Taille maximale : 5 MB",
                        style: GoogleFonts.poppins(
                          color: Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isImage) ...[
                _buildFileTypeOption(
                  context: context,
                  icon: Icons.photo_library,
                  title: "Galerie (Images)",
                  subtitle: "PNG, JPG, JPEG",
                  onTap: () => Navigator.of(context).pop('gallery'),
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildFileTypeOption(
                  context: context,
                  icon: Icons.camera_alt,
                  title: "Appareil photo",
                  subtitle: "Prendre une photo",
                  onTap: () => Navigator.of(context).pop('camera'),
                  theme: theme,
                ),
              ] else ...[
                _buildFileTypeOption(
                  context: context,
                  icon: Icons.picture_as_pdf,
                  title: "Fichiers PDF",
                  subtitle: "Documents PDF",
                  onTap: () => Navigator.of(context).pop('pdf'),
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildFileTypeOption(
                  context: context,
                  icon: Icons.description,
                  title: "Fichiers Word",
                  subtitle: "Documents DOCX",
                  onTap: () => Navigator.of(context).pop('docx'),
                  theme: theme,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Annuler",
                style: GoogleFonts.poppins(
                  color: theme.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (choice != null) {
      try {
        File? selectedFile;

        switch (choice) {
          case 'gallery':
            final picked = await ImagePicker().pickImage(
              source: ImageSource.gallery,
              imageQuality: 85, // Réduire la qualité pour limiter la taille
            );
            if (picked != null) {
              selectedFile = File(picked.path);
            }
            break;
          case 'camera':
            final picked = await ImagePicker().pickImage(
              source: ImageSource.camera,
              imageQuality: 85, // Réduire la qualité pour limiter la taille
            );
            if (picked != null) {
              selectedFile = File(picked.path);
            }
            break;
          case 'pdf':
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf'],
              allowMultiple: false,
            );
            if (result != null && result.files.single.path != null) {
              selectedFile = File(result.files.single.path!);
            }
            break;
          case 'docx':
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['docx'],
              allowMultiple: false,
            );
            if (result != null && result.files.single.path != null) {
              selectedFile = File(result.files.single.path!);
            }
            break;
        }

        if (selectedFile != null && mounted) {
          // Valider le fichier avant de l'accepter
          final file = selectedFile; // selectedFile est garanti non-null ici
          if (_validateFile(file, isImage: isImage)) {
            setState(() => setter(file));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur lors de la sélection du fichier: $e"),
              backgroundColor: Colors.red[400],
            ),
          );
        }
      }
    }
  }

  Widget _buildFileTypeOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                    : const Color(0xFF013068).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF013068),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.7,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showFiliereDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Autre filière"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Entrez votre filière"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                autreFiliere = controller.text.trim();
                autreFiliereController.text = autreFiliere;
                if (!filieres.contains(autreFiliere) &&
                    autreFiliere.isNotEmpty) {
                  filieres.insert(filieres.length - 1, autreFiliere);
                }
                filiere = autreFiliere;
              });
              Navigator.of(ctx).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget fichierWidget(String label, File? file, VoidCallback onPressed) {
    final theme = Theme.of(context);

    // Déterminer le type de fichier et l'icône
    IconData fileIcon = Icons.upload_file;
    String fileTypeText = "";
    Color iconColor = theme.colorScheme.primary.withValues(alpha: 0.8);

    if (file != null) {
      final fileName = file.path.split('/').last.toLowerCase();
      if (fileName.endsWith('.pdf')) {
        fileIcon = Icons.picture_as_pdf;
        fileTypeText = "PDF";
        iconColor = Colors.green[600] ?? Colors.green;
      } else if (fileName.endsWith('.docx')) {
        fileIcon = Icons.description;
        fileTypeText = "DOCX";
        iconColor = Colors.blue[600] ?? Colors.blue;
      } else if (fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg') ||
          fileName.endsWith('.png')) {
        fileIcon = Icons.image;
        fileTypeText = "Image";
        iconColor = Colors.green[600] ?? Colors.green;
      } else {
        fileIcon = Icons.insert_drive_file;
        fileTypeText = "Fichier";
        iconColor = Colors.grey[600] ?? Colors.grey;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: Icon(
                  file == null ? Icons.upload_file : fileIcon,
                  color: file == null
                      ? theme.colorScheme.primary.withValues(alpha: 0.8)
                      : iconColor,
                  size: 18,
                ),
                label: Text(
                  file == null ? "Joindre" : "Modif.",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: file == null
                        ? theme.colorScheme.primary.withValues(alpha: 0.8)
                        : iconColor,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: file == null
                      ? theme.colorScheme.primary.withValues(alpha: .15)
                      : iconColor.withValues(alpha: .2),
                  foregroundColor: file == null
                      ? theme.colorScheme.primary
                      : iconColor,
                  elevation: file == null ? 2 : 1,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: file == null
                        ? theme.colorScheme.primary.withValues(alpha: 0.3)
                        : iconColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                onPressed: onPressed,
              ),
            ],
          ),
          // Affichage des informations du fichier sélectionné
          if (file != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(fileIcon, color: iconColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.path.split('/').last,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                fileTypeText.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: iconColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getFileSize(file),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle, color: iconColor, size: 20),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) {
        return "$bytes B";
      } else if (bytes < 1024 * 1024) {
        return "${(bytes / 1024).toStringAsFixed(1)} KB";
      } else {
        return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
      }
    } catch (e) {
      return "Taille inconnue";
    }
  }

  // Stepper responsive corrigé
  // ===================== DIALOGUE DE SORTIE =====================
  void _showExitDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                "Quitter le formulaire",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Text(
            "Voulez-vous vraiment quitter le formulaire ?\n\nVos données seront automatiquement sauvegardées et vous pourrez reprendre plus tard.",
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Annuler",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Sauvegarder avant de quitter
                _saveFormData();
                Navigator.of(context).pop(); // Fermer le dialogue
                Navigator.of(context).pop(); // Retourner à l'écran précédent
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Quitter",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepper(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 400;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          return Row(
            children: [
              CircleAvatar(
                radius: isSmall ? 13 : 20,
                backgroundColor: i <= currentStep
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.5),
                child: Text(
                  "${i + 1}",
                  style: GoogleFonts.poppins(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmall ? 13 : 18,
                  ),
                ),
              ),
              if (i < 3)
                Container(
                  width: isSmall ? 22 : 46,
                  height: isSmall ? 2.5 : 4,
                  color: currentStep > i
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
            ],
          );
        }),
      ),
    );
  }

  // ===================== ÉTAPE 1 : Infos personnelles =====================
  Widget _step1(Color mainBlue, Color accentBlue) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxWidth = constraints.maxWidth > 540
            ? 540.0
            : constraints.maxWidth;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Form(
              key: _formKey1,
              child: Card(
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _pickFile((f) => photo = f, isImage: true),
                              child: CircleAvatar(
                                backgroundColor: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.1),
                                radius: 45,
                                backgroundImage: photo != null
                                    ? FileImage(photo!)
                                    : null,
                                child: photo == null
                                    ? Icon(
                                        Icons.camera_alt,
                                        color: theme.colorScheme.primary,
                                        size: 38,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Ajouter une photo",
                              style: GoogleFonts.poppins(
                                color: mainBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Flexible(
                            child: TextFormField(
                              controller: nomController,
                              decoration: _inputDecoration("Nom"),
                              validator: (v) =>
                                  (v == null || v.trim().length < 2)
                                  ? "Nom invalide"
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: TextFormField(
                              controller: postnomController,
                              decoration: _inputDecoration("Post-nom"),
                              validator: (v) =>
                                  (v == null || v.trim().length < 2)
                                  ? "Post-nom invalide"
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Flexible(
                            child: TextFormField(
                              controller: prenomController,
                              decoration: _inputDecoration("Prénom"),
                              validator: (v) =>
                                  (v == null || v.trim().length < 2)
                                  ? "Prénom invalide"
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: DropdownButtonFormField<String>(
                              decoration: _inputDecoration("Genre"),
                              value: genre.isEmpty ? null : genre,
                              items: ["Masculin", "Féminin"]
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => genre = v ?? ""),
                              validator: (v) => (v == null || v.isEmpty) 
                                  ? "Genre requis" 
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: lieuNaissanceController,
                        decoration: _inputDecoration("Lieu de naissance"),
                        validator: (v) =>
                            (v == null || v.trim().length < 2)
                            ? "Lieu de naissance requis"
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        readOnly: true,
                        decoration: _inputDecoration("Date de naissance")
                            .copyWith(
                              suffixIcon: const Icon(
                                Icons.calendar_today,
                                color: Color(0xFF1C3D8F),
                              ),
                            ),
                        controller: dateNaissanceController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                            ? "Date de naissance requise"
                            : null,
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1960),
                            lastDate: DateTime.now(),
                            locale: const Locale('fr'),
                          );
                          if (picked != null) {
                            setState(() {
                              dateNaissance = picked;
                              dateNaissanceController.text =
                                  "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration("État civil"),
                        value: etatCivil.isEmpty ? null : etatCivil,
                        items: ["Célibataire", "Marié", "Divorcé", "Veuf (ve)"]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => etatCivil = v ?? ""),
                        validator: (v) => (v == null || v.isEmpty) 
                            ? "État civil requis" 
                            : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration("Nationalité"),
                        value: nationalite.isEmpty ? null : nationalite,
                        items: ["Congolaise", "Autre"]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => nationalite = v ?? ""),
                        validator: (v) => (v == null || v.isEmpty) 
                            ? "Nationalité requise" 
                            : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration("Province d'origine"),
                        value: provinceOrigine.isEmpty ? null : provinceOrigine,
                        items: provinces
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => provinceOrigine = v ?? ""),
                        validator: (v) => (v == null || v.isEmpty) 
                            ? "Province d'origine requise" 
                            : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration("Province de résidence"),
                        value: provinceResidence.isEmpty
                            ? null
                            : provinceResidence,
                        items: provinces
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => provinceResidence = v ?? ""),
                        validator: (v) => (v == null || v.isEmpty) 
                            ? "Province de résidence requise" 
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: villeController,
                        decoration: _inputDecoration("Ville de résidence"),
                        validator: (v) => (v == null || v.trim().isEmpty) 
                            ? "Ville de résidence requise" 
                            : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration("Type de pièce d'identité"),
                        value: typePieceIdentite.isEmpty ? null : typePieceIdentite,
                        items: ["Carte d'électeur", "Passeport"]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => typePieceIdentite = v ?? ""),
                        validator: (v) => (v == null || v.isEmpty) 
                            ? "Type de pièce d'identité requis" 
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: numeroPieceController,
                        decoration: _inputDecoration(
                          "Numéro de la pièce d'identité",
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) 
                            ? "Numéro de pièce d'identité requis" 
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: adresseController,
                        decoration: _inputDecoration("Adresse complète"),
                        minLines: 2,
                        maxLines: 2,
                        validator: (v) => (v == null || v.trim().isEmpty) 
                            ? "Adresse complète requise" 
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Flexible(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              decoration: _inputDecoration("Indicatif"),
                              value: indicatif.isEmpty ? null : indicatif,
                              items: indicatifs
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(
                                        v,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => indicatif = v ?? ""),
                              validator: (v) => (v == null || v.isEmpty) 
                                  ? "Indicatif requis" 
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            flex: 6,
                            child: TextFormField(
                              controller: telephoneController,
                              decoration: _inputDecoration("Téléphone")
                                  .copyWith(
                                hintText: "Ex: 123456789 (9 chiffres, sans 0)",
                                helperText: "Format: 9 chiffres sans le 0 initial",
                              ),
                              keyboardType: TextInputType.phone,
                              maxLength: 9,
                              validator: _validatePhoneNumber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===================== ÉTAPE 2 : Infos académiques & Statut professionnel =====================
  Widget _step2(Color mainBlue, Color accentBlue) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxWidth = constraints.maxWidth > 540
            ? 540.0
            : constraints.maxWidth;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Form(
              key: _formKey2,
              child: Card(
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration("Plus haut diplôme"),
                        value: diplome.isEmpty ? null : diplome,
                        validator: (v) => v == null || v.isEmpty ? "Diplôme requis" : null,
                        items: diplomes
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => diplome = v ?? ""),
                      ),
                      const SizedBox(height: 13),
                      TextFormField(
                        controller: anneeObtentionController,
                        decoration: _inputDecoration("Année d'obtention"),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "Année d'obtention requise";
                          }
                          final year = int.tryParse(v.trim());
                          if (year == null) {
                            return "Année invalide";
                          }
                          if (year < 2013) {
                            return "L'année doit être ≥ 2013";
                          }
                          if (year > DateTime.now().year) {
                            return "L'année ne peut pas être future";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 13),
                      TextFormField(
                        controller: etablissementController,
                        decoration: _inputDecoration("Établissement"),
                        validator: (v) =>
                            (v == null || v.trim().length < 2)
                            ? "Établissement requis"
                            : null,
                      ),
                      const SizedBox(height: 13),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration("Filière d'études"),
                        value: filieres.contains(filiere) ? filiere : null,
                        isExpanded: true,
                        validator: (v) => v == null || v.isEmpty ? "Filière requise" : null,
                        items: filieres
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Text(
                                  v,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            filiere = v ?? "";
                            if (filiere == "Autre") _showFiliereDialog();
                          });
                        },
                      ),
                      const SizedBox(height: 13),
                      if (filiere == autreFiliere && filiere.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Filière saisie : $autreFiliere",
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 13),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pourcentage obtenu : ${pourcentage.toInt()}%",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Slider(
                            min: 50,
                            max: 99,
                            divisions: 49,
                            value: pourcentage,
                            label: "${pourcentage.toInt()}%",
                            onChanged: (v) => setState(() => pourcentage = v),
                            activeColor: accentBlue,
                            inactiveColor: Colors.grey[300],
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration("Statut professionnel"),
                        value: statutPro.isEmpty ? null : statutPro,
                        items: statuts
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => statutPro = v ?? ""),
                        validator: (v) => (v == null || v.isEmpty) 
                            ? "Statut professionnel requis" 
                            : null,
                      ),
                      const SizedBox(height: 10),
                      if (statutPro == "Fonctionnaire") ...[
                        TextFormField(
                          controller: matriculeController,
                          decoration: _inputDecoration("Matricule"),
                          validator: (v) => (v == null || v.trim().isEmpty) 
                              ? "Matricule requis" : null,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration("Grade"),
                          isExpanded: true,
                          value: grade.isEmpty ? null : grade,
                          validator: (v) => v == null || v.isEmpty ? "Grade requis" : null,
                          items: grades
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(
                                    g,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => grade = v ?? ""),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: administrationAttacheController,
                          decoration: _inputDecoration(
                            "Administration d'attache",
                          ),
                          validator: (v) => _validateAdministrationMinistere(v, "Administration d'attache"),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: fonctionController,
                          decoration: _inputDecoration("Fonction"),
                          validator: (v) => (v == null || v.trim().isEmpty) 
                              ? "Fonction requise" : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: ministereController,
                          decoration: _inputDecoration("Ministère"),
                          validator: (v) => _validateAdministrationMinistere(v, "Ministère"),
                        ),
                      ] else if (statutPro == "Employé privé") ...[
                        TextFormField(
                          controller: fonctionController,
                          decoration: _inputDecoration("Fonction"),
                          validator: (v) => (v == null || v.trim().isEmpty) 
                              ? "Fonction requise" : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: entrepriseController,
                          decoration: _inputDecoration("Entreprise"),
                          validator: (v) => (v == null || v.trim().isEmpty) 
                              ? "Entreprise requise" : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===================== ÉTAPE 3 : Pièces à joindre =====================
  Widget _step3(Color mainBlue, Color accentBlue) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxWidth = constraints.maxWidth > 540
            ? 540.0
            : constraints.maxWidth;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Card(
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fichierWidget(
                      "Carte d'identité (électeur/passeport)",
                      carteId,
                      () => _pickFile((f) => carteId = f),
                    ),
                    fichierWidget(
                      "Lettre de motivation manuscrite",
                      lettreMotivation,
                      () => _pickFile((f) => lettreMotivation = f),
                    ),
                    fichierWidget(
                      "CV avec photo",
                      cv,
                      () => _pickFile((f) => cv = f),
                    ),
                    fichierWidget(
                      "Diplôme Bac+5 ou équivalent",
                      diplomeFichier,
                      () => _pickFile((f) => diplomeFichier = f),
                    ),
                    fichierWidget(
                      "Attestation d'aptitude physique (<3 mois)",
                      aptitudeFichier,
                      () => _pickFile((f) => aptitudeFichier = f),
                    ),
                    fichierWidget(
                      "Relevés des notes",
                      releveNotes,
                      () => _pickFile((f) => releveNotes = f),
                    ),
                    if (statutPro == "Fonctionnaire")
                      fichierWidget(
                        "Acte d'admission sous statut",
                        acteAdmission,
                        () => _pickFile((f) => acteAdmission = f),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===================== ÉTAPE 4 : Récapitulatif de toutes les infos =====================
  Widget _step4(Color mainBlue, Color accentBlue, Color red) {
    final theme = Theme.of(context);
    TextStyle label = GoogleFonts.poppins(
      fontWeight: FontWeight.bold,
      fontSize: 13,
      color: theme.colorScheme.onSurface,
    );
    TextStyle value = GoogleFonts.poppins(
      fontSize: 13.2,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
    );

    Widget ligne(String l, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text("$l :", style: label)),
          Expanded(child: Text(v, style: value)),
        ],
      ),
    );
    Widget fileLine(String l, File? f) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text("$l :", style: label)),
          Expanded(
            child: f != null
                ? Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Fichier joint: ${f.path.split('/').last}",
                          style: value.copyWith(color: Colors.green),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Text("Non joint", style: value.copyWith(color: red)),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxWidth = constraints.maxWidth > 540
            ? 540.0
            : constraints.maxWidth;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Card(
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (photo != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: CircleAvatar(
                              radius: 35,
                              backgroundImage: FileImage(photo!),
                            ),
                          ),
                        ),
                      ligne("Nom", nomController.text),
                      ligne("Post-nom", postnomController.text),
                      ligne("Prénom", prenomController.text),
                      ligne("Genre", genre),
                      ligne("Lieu de naissance", lieuNaissanceController.text),
                      ligne("Date de naissance", dateNaissanceController.text),
                      ligne("État civil", etatCivil),
                      ligne("Nationalité", nationalite),
                      ligne("Province d'origine", provinceOrigine),
                      ligne("Province de résidence", provinceResidence),
                      ligne("Ville de résidence", villeController.text),
                      ligne(
                        "Type pièce d'identité",
                        typePieceIdentite,
                      ),
                      ligne("Numéro pièce", numeroPieceController.text),
                      ligne("Adresse complète", adresseController.text),
                      ligne(
                        "Téléphone",
                        "$indicatif ${telephoneController.text}",
                      ),
                      ligne("Diplôme", diplome),
                      ligne("Année d'obtention", anneeObtentionController.text),
                      ligne("Établissement", etablissementController.text),
                      ligne("Filière", filiere),
                      ligne("Pourcentage", "${pourcentage.toInt()}%"),
                      ligne("Statut professionnel", statutPro),
                      if (statutPro == "Fonctionnaire") ...[
                        ligne("Matricule", matriculeController.text),
                        ligne("Grade", grade),
                        ligne(
                          "Administration d'attache",
                          administrationAttacheController.text,
                        ),
                        ligne("Fonction", fonctionController.text),
                        ligne("Ministère", ministereController.text),
                      ],
                      if (statutPro == "Employé privé") ...[
                        ligne("Fonction", fonctionController.text),
                        ligne("Entreprise", entrepriseController.text),
                      ],
                      fileLine("Carte d'identité", carteId),
                      fileLine("Lettre de motivation", lettreMotivation),
                      fileLine("CV", cv),
                      fileLine("Diplôme Bac+5", diplomeFichier),
                      fileLine("Attestation aptitude", aptitudeFichier),
                      fileLine("Relevés de notes", releveNotes),
                      if (statutPro == "Fonctionnaire")
                        fileLine("Acte admission", acteAdmission),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===================== BOUTONS NAVIGATION + LOADER =====================
  Widget navigationButtons(
    Color mainBlue,
    Color accentBlue, {
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, left: 8, right: 8, bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentStep > 0)
            SizedBox(
              width: 120,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accentBlue),
                  backgroundColor: Colors.white,
                  foregroundColor: accentBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => setState(() => currentStep--),
                child: const Text("Précédent"),
              ),
            )
          else
            const SizedBox(width: 120),
          SizedBox(
            width: 120,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: loading
                  ? null
                  : (isLast ? _onSubmit : _nextStep),
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(isLast ? "Soumettre" : "Suivant"),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFE74C3C),
              size: 54,
            ),
            const SizedBox(height: 12),
            Text(
              "Erreur",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: const Color(0xFFE74C3C),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE74C3C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "Compris",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 54),
            const SizedBox(height: 12),
            Text(
              "Candidature envoyée !",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              "Votre dossier a été transmis avec succès. Le PDF de votre candidature a été généré automatiquement.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C3D8F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  "Retour à l'accueil",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Fermer le dialog
                  Navigator.of(context).popUntil((route) => route.isFirst); // Retourner à la page home
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== SOUMISSION PATCH/POST API =====================
  Future<void> _onSubmit() async {
    final theme = Theme.of(context);
    final mainBlue = theme.colorScheme.primary;

    if (!_formKey1.currentState!.validate() ||
        !_formKey2.currentState!.validate()) {
      setState(() {
        currentStep = (!_formKey1.currentState!.validate()) ? 0 : 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Merci de compléter tous les champs obligatoires.",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: mainBlue,
        ),
      );
      return;
    }
    if (carteId == null ||
        lettreMotivation == null ||
        cv == null ||
        diplomeFichier == null ||
        aptitudeFichier == null ||
        releveNotes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Merci de joindre tous les fichiers obligatoires.",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: mainBlue,
        ),
      );
      setState(() => currentStep = 2);
      return;
    }

    setState(() => loading = true);

    try {
      // Récupérer le token d'authentification
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null || token.isEmpty) {
        _showErrorDialog("Session expirée. Veuillez vous reconnecter.");
        setState(() => loading = false);
        return;
      }

      // ============ CODIFICATION DES DONNÉES =============
      String genreCode = _getGenreCode(genre);
      String etatCivilCode = _getEtatCivilCode(etatCivil);
      String nationaliteCode = _getNationaliteCode(nationalite);
      String statutProCode = _getStatutProfessionnelCode(statutPro);
      String diplomeCode = _getDiplomeCode(diplome);
      String dateFormatted = _formatDateForBackend(dateNaissanceController.text);

      // ============ PATCH Profil Candidat =============
      final profileData = {
        "numero_piece_identite": numeroPieceController.text,
        "nom": nomController.text.toUpperCase(),
        "postnom": postnomController.text.toUpperCase(),
        "prenom": _capitalizeFirstLetter(prenomController.text),
        "genre": genreCode,
        "etat_civil": etatCivilCode,
        "lieu_de_naissance": lieuNaissanceController.text,
        "date_de_naissance": dateFormatted,
        "adresse_physique": adresseController.text,
        "province_de_residence": provinceResidence,
        "ville_de_residence": villeController.text,
        "province_d_origine": provinceOrigine,
        "nationalite": nationaliteCode,
        "niveau_etude": diplomeCode,
        "domaine_etude": filiere,
        "universite_frequentee": etablissementController.text,
        "score_obtenu": pourcentage.toInt(),
        "annee_de_graduation": int.tryParse(anneeObtentionController.text),
        "statut_professionnel": statutProCode,
        "matricule": matriculeController.text,
        "grade": grade,
        "fonction": fonctionController.text,
        "administration_d_attache": administrationAttacheController.text,
        "ministere": ministereController.text,
        "entreprise": entrepriseController.text,
        "telephone": "$indicatif${telephoneController.text}",
      };

      final patchUri = Uri.parse(ApiConfig.profilCandidatUrl);
      final patchRequest = http.MultipartRequest('PATCH', patchUri);
      patchRequest.headers['Authorization'] = 'Bearer $token';

      profileData.forEach((k, v) {
        if (v != null && v.toString().isNotEmpty && k != "photo") {
          patchRequest.fields[k] = v.toString();
        }
      });
      if (photo != null) {
        patchRequest.files.add(
          await http.MultipartFile.fromPath('photo', photo!.path),
        );
      }

      final patchResp = await patchRequest.send();
      
      if (patchResp.statusCode >= 400) {
        _showErrorDialog("Erreur lors de la mise à jour de votre profil. Veuillez réessayer.");
        setState(() => loading = false);
        return;
      }

      // ============ POST Candidature =============
      final postUri = Uri.parse(ApiConfig.candidatureAddUrl);
      final postRequest = http.MultipartRequest('POST', postUri);
      postRequest.headers['Authorization'] = 'Bearer $token';

      if (carteId != null) {
        postRequest.files.add(
          await http.MultipartFile.fromPath('piece_identite', carteId!.path),
        );
      }
      if (diplomeFichier != null) {
        postRequest.files.add(
          await http.MultipartFile.fromPath('diplome', diplomeFichier!.path),
        );
      }
      if (lettreMotivation != null) {
        postRequest.files.add(
          await http.MultipartFile.fromPath(
            'lettre_motivation',
            lettreMotivation!.path,
          ),
        );
      }
      if (aptitudeFichier != null) {
        postRequest.files.add(
          await http.MultipartFile.fromPath(
            'aptitude_physique',
            aptitudeFichier!.path,
          ),
        );
      }
      if (cv != null) {
        postRequest.files.add(
          await http.MultipartFile.fromPath('cv', cv!.path),
        );
      }
      if (releveNotes != null) {
        postRequest.files.add(
          await http.MultipartFile.fromPath('releves_notes', releveNotes!.path),
        );
      }
      if (acteAdmission != null && statutPro == "Fonctionnaire") {
        postRequest.files.add(
          await http.MultipartFile.fromPath(
            'acte_admission',
            acteAdmission!.path,
          ),
        );
      }

      final postResponse = await postRequest.send();
      final postRespBody = await postResponse.stream.bytesToString();

      if (postResponse.statusCode == 201 || postResponse.statusCode == 200) {
        // Supprimer les données sauvegardées après succès
        await _clearAutoSavedData();
        
        // 🔄 MISE À JOUR DU CACHE UTILISATEUR AVEC LA NOUVELLE PHOTO
        await _updateUserCacheWithPhoto(token);
        
        // Générer automatiquement le PDF
        try {
          final pdfData = await _preparePdfData();
          final pdfService = PdfGeneratorService();
          await pdfService.generateAndPreviewPdf(pdfData);
        } catch (e) {
          debugPrint('Erreur lors de la génération du PDF: $e');
          // Continuer même si le PDF échoue
        }
        
        _showSuccessDialog();
      } else {
        final errorData = postRespBody.isNotEmpty ? postRespBody : "Erreur lors de la soumission de la candidature";
        
        // Vérifier si c'est une erreur de candidature en double
        if (errorData.toLowerCase().contains("unique") || 
            errorData.toLowerCase().contains("duplicate") || 
            errorData.toLowerCase().contains("already exists") ||
            errorData.toLowerCase().contains("déjà") ||
            postResponse.statusCode == 409) {
          _showErrorDialog("Vous avez déjà soumis une candidature. Une seule candidature par personne est autorisée.");
        } else {
          _showErrorDialog("Une erreur s'est produite lors de l'envoi de votre candidature. Veuillez réessayer plus tard.");
        }
      }
    } catch (e) {
      _showErrorDialog("Une erreur technique s'est produite. Veuillez vérifier votre connexion et réessayer.");
    } finally {
      setState(() => loading = false);
    }
  }

  /// Met à jour le cache utilisateur avec les nouvelles informations après soumission de candidature
  Future<void> _updateUserCacheWithPhoto(String token) async {
    try {
      debugPrint('🔄 Mise à jour du cache utilisateur après candidature...');
      
      // Récupérer les informations utilisateur mises à jour depuis l'API
      final result = await AuthApiService.getUserInfo(token: token);
      
      if (result['success'] == true && result['data'] != null) {
        final prefs = await SharedPreferences.getInstance();
        
        // Mettre à jour le cache local avec les nouvelles données
        await prefs.setString('user_info_cache', jsonEncode(result['data']));
        
        // Invalider le cache d'images pour forcer le rechargement de la photo
        ImageCacheService.invalidateUserImageCache();
        
        // Notifier les autres composants de la mise à jour
        ProfileUpdateNotificationService().notifyProfileUpdated(
          photoUpdated: true,
          personalInfoUpdated: true,
          contactInfoUpdated: false,
          updatedData: result['data'],
        );
        
        debugPrint('✅ Cache utilisateur mis à jour avec la nouvelle photo');
      } else {
        debugPrint('❌ Échec de la récupération des informations utilisateur mises à jour');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour du cache utilisateur: $e');
      // Ne pas faire échouer la candidature pour cette erreur
    }
  }

  // ============ MÉTHODES DE CODIFICATION =============
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _getGenreCode(String genre) {
    switch (genre) {
      case "Masculin":
        return "M";
      case "Féminin":
        return "F";
      default:
        return "M";
    }
  }

  String _getEtatCivilCode(String etatCivil) {
    switch (etatCivil) {
      case "Célibataire":
        return "C";
      case "Marié":
        return "M";
      case "Divorcé":
        return "D";
      case "Veuf (ve)":
        return "V";
      default:
        return "C";
    }
  }

  String _getNationaliteCode(String nationalite) {
    switch (nationalite) {
      case "Congolaise":
        return "RDC";
      case "Autre":
        return "AUTRE";
      default:
        return "RDC";
    }
  }

  String _getStatutProfessionnelCode(String statutPro) {
    switch (statutPro) {
      case "Fonctionnaire":
        return "fonctionnaire";
      case "Sans emploi":
        return "sans_emploi";
      case "Employé privé":
        return "employe_prive";
      default:
        return "sans_emploi";
    }
  }

  String _getDiplomeCode(String diplome) {
    switch (diplome) {
      case "Diplome d'Etat":
        return "diplome_etat";
      case "Bac+3":
        return "graduat";
      case "Bac+5":
        return "licence_bac+5";
      case "Master":
        return "maitrise";
      case "Doctorat":
        return "doctorat";
      default:
        return "licence_bac+5";
    }
  }

  String _formatDateForBackend(String dateString) {
    try {
      // dateString est au format "DD/MM/YYYY"
      if (dateString.isEmpty) return "";
      
      final parts = dateString.split('/');
      if (parts.length != 3) return "";
      
      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      final year = parts[2];
      
      return "$year-$month-$day"; // Format YYYY-MM-DD
    } catch (e) {
      return "";
    }
  }

  // ============ RÉCUPÉRATION EMAIL UTILISATEUR =====================
  Future<String> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') ?? 'candidat@ena.cd';
  }

  // ============ GÉNÉRATION PDF =============
  Future<CandidaturePdfData> _preparePdfData() async {
    final now = DateTime.now();
    final dateFormatted = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
    final timeFormatted = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final userEmail = await _getUserEmail();
    
    // Récupérer le numéro de candidat depuis les informations utilisateur
    String? numeroCandidat;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        final result = await AuthApiService.getUserInfo(token: token);
        if (result['success'] == true && result['data'] != null) {
          numeroCandidat = result['data']['numero'];
        }
      }
    } catch (e) {
      // Ignorer l'erreur silencieusement
    }
    
    return CandidaturePdfData(
      nom: nomController.text.toUpperCase(),
      postnom: postnomController.text.toUpperCase(),
      prenom: prenomController.text,
      genre: genre,
      lieuNaissance: lieuNaissanceController.text,
      dateNaissance: dateNaissanceController.text,
      etatCivil: etatCivil,
      nationalite: nationalite,
      provinceOrigine: provinceOrigine,
      provinceResidence: provinceResidence,
      villeResidence: villeController.text,
      typePieceIdentite: typePieceIdentite,
      numeroPiece: numeroPieceController.text,
      adresse: adresseController.text,
      indicatif: indicatif,
      telephone: telephoneController.text,
      email: userEmail, // Email de l'utilisateur connecté
      diplome: diplome,
      anneeObtention: anneeObtentionController.text,
      etablissement: etablissementController.text,
      filiere: filiere,
      pourcentage: pourcentage.toInt(),
      statutProfessionnel: statutPro,
      matricule: matriculeController.text,
      grade: grade,
      fonction: fonctionController.text,
      administration: administrationAttacheController.text,
      ministere: ministereController.text,
      entreprise: entrepriseController.text,
      photoJointe: photo != null ? "Oui" : "Non",
      carteIdJointe: carteId != null ? "Oui" : "Non",
      lettreMotivationJointe: lettreMotivation != null ? "Oui" : "Non",
      cvJoint: cv != null ? "Oui" : "Non",
      diplomeFichierJoint: diplomeFichier != null ? "Oui" : "Non",
      aptitudeFichierJoint: aptitudeFichier != null ? "Oui" : "Non",
      releveNotesJoint: releveNotes != null ? "Oui" : "Non",
      acteAdmissionJoint: acteAdmission != null ? "Oui" : "Non",
      dateSoumission: dateFormatted,
      heureSoumission: timeFormatted,
      numero: numeroCandidat, // Numéro de candidat récupéré de l'API
    );
  }

  // ====================== BUILD FINAL ======================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainBlue = theme.colorScheme.primary;
    final accentBlue = theme.colorScheme.secondary;
    final red = theme.colorScheme.error;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Candidature ENA",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showExitDialog(context),
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              size: 24,
            ),
            tooltip: "Quitter",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepper(context),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    IndexedStack(
                      index: currentStep,
                      children: [
                        _step1(mainBlue, accentBlue),
                        _step2(mainBlue, accentBlue),
                        _step3(mainBlue, accentBlue),
                        _step4(mainBlue, accentBlue, red),
                      ],
                    ),
                    const SizedBox(height: 10), // Espace réduit
                  ],
                ),
              ),
            ),
            if (loading)
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(mainBlue),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Envoi en cours...",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Veuillez patienter",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            navigationButtons(mainBlue, accentBlue, isLast: currentStep == 3),
          ],
        ),
      ),
    );
  }
}
