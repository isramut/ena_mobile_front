import 'dart:io';
import 'package:ena_mobile_front/models/ma_candidature.dart';
import 'package:ena_mobile_front/services/recours_api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubmitRecoursScreen extends StatefulWidget {
  final MaCandidature candidature;

  const SubmitRecoursScreen({
    super.key,
    required this.candidature,
  });

  @override
  State<SubmitRecoursScreen> createState() => _SubmitRecoursScreenState();
}

class _SubmitRecoursScreenState extends State<SubmitRecoursScreen> {
  final _formKey = GlobalKey<FormState>();
  final _justificationController = TextEditingController();
  final _autreMotifController = TextEditingController(); // Pour l'autre motif personnalisé
  
  // Variables pour le formulaire
  String? _selectedMotif;
  bool _isSubmitting = false;
  
  // Map pour stocker les fichiers sélectionnés par document
  final Map<String, File?> _selectedFiles = {};
  final Map<String, bool> _documentsToResubmit = {};
  
  // Liste des motifs de recours
  final List<String> _motifsRecours = [
    'Erreur dans l\'évaluation des documents',
    'Documents conformes mais rejetés par erreur',
    'Contestation de la décision de rejet',
    'Autre motif'
  ];

  // Map pour les noms d'affichage des documents
  final Map<String, String> _documentDisplayNames = {
    'cv': 'CV',
    'lettre_motivation': 'Lettre de motivation',
    'piece_identite': 'Pièce d\'identité',
    'aptitude_physique': 'Aptitude physique',
    'diplome': 'Diplôme',
    'releves_notes': 'Relevé des notes de la dernière année'
  };

  @override
  void initState() {
    super.initState();
    _initializeDocuments();
  }

  void _initializeDocuments() {
    // Initialiser les maps pour chaque document non conforme
    for (String doc in widget.candidature.documentsNonConformes) {
      _documentsToResubmit[doc] = false;
      _selectedFiles[doc] = null;
    }
    
    // Initialiser le relevé des notes (affiché statiquement)
    _documentsToResubmit['releves_notes'] = false;
    _selectedFiles['releves_notes'] = null;
  }

  @override
  void dispose() {
    _justificationController.dispose();
    _autreMotifController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        File file = File(result.files.first.path!);
        
        // Vérifier la taille du fichier (5 Mo max)
        int fileSizeInBytes = await file.length();
        double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
        
        if (fileSizeInMB > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Le fichier ne doit pas dépasser 5 Mo',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFiles[documentType] = file;
          _documentsToResubmit[documentType] = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la sélection du fichier: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ========== MÉTHODE POUR AFFICHER LE POP-UP DE VALIDATION ==========
  Future<void> _showValidationErrorDialog(List<String> champsManquants) async {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: isSmallScreen ? 24 : 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Champs manquants',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 16 : 18,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Veuillez compléter les éléments suivants :',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...champsManquants.map((champ) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    champ,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: Colors.red.shade700,
                      height: 1.3,
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
            child: Text(
              'Fermer',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ========== MÉTHODE POUR AFFICHER LES ERREURS DE SOUMISSION ==========
  Future<void> _showSubmissionErrorDialog(String titre, String message, {IconData? icone}) async {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              icone ?? Icons.error_outline,
              color: Colors.red,
              size: isSmallScreen ? 24 : 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titre,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 16 : 18,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SingleChildScrollView(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 14 : 16,
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
            child: Text(
              'Fermer',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ========== MÉTHODE POUR AFFICHER LE SUCCÈS ==========
  Future<void> _showSuccessDialog() async {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: isSmallScreen ? 24 : 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Succès',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 16 : 18,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Votre recours a été soumis avec succès. Vous recevrez une confirmation par email.',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 14 : 16,
            color: theme.colorScheme.onSurface,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer le dialog
              Navigator.of(context).pop(true); // Retourner à l'écran précédent
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRecours() async {
    // ========== VALIDATION COMPLÈTE ==========
    List<String> champsManquants = [];

    // 1. Validation motif
    if (_selectedMotif == null) {
      champsManquants.add("• Motif du recours");
    } else if (_selectedMotif == "Autre motif" && _autreMotifController.text.trim().isEmpty) {
      champsManquants.add("• Autre motif (description)");
    }

    // 2. Validation justification
    final justificationText = _justificationController.text.trim();
    if (justificationText.isEmpty) {
      champsManquants.add("• Justification détaillée");
    } else if (justificationText.length < 20) {
      champsManquants.add("• Justification trop courte (minimum 20 caractères)");
    }

    // 3. Validation STRICTE des documents à resoumettre
    // TOUS les documents non conformes DOIVENT être resoumis
    for (String docType in _documentsToResubmit.keys) {
      String displayName = _documentDisplayNames[docType] ?? docType;
      
      // Vérifier si le document est coché pour resoumission
      if (_documentsToResubmit[docType] != true) {
        champsManquants.add("• Document obligatoire à resoumettre : $displayName");
      } 
      // Si coché, vérifier qu'un fichier est uploadé
      else if (_selectedFiles[docType] == null) {
        champsManquants.add("• Fichier manquant pour : $displayName");
      }
    }

    // 4. Validation obligatoire du relevé des notes
    if (_selectedFiles['releves_notes'] == null) {
      champsManquants.add("• Relevé des notes de la dernière année (obligatoire)");
    }

    // 5. Affichage des erreurs si nécessaire
    if (champsManquants.isNotEmpty) {
      await _showValidationErrorDialog(champsManquants);
      return;
    }

    // ========== SOUMISSION ==========
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Préparer les fichiers sélectionnés
      List<File> filesToUpload = [];
      List<String> documentTypes = [];
      
      for (String docType in _documentsToResubmit.keys) {
        if (_documentsToResubmit[docType] == true && _selectedFiles[docType] != null) {
          filesToUpload.add(_selectedFiles[docType]!);
          documentTypes.add(docType);
        }
      }

      // ✅ S'assurer que le relevé des notes est inclus s'il a été sélectionné
      if (_selectedFiles['releves_notes'] != null && 
          _documentsToResubmit['releves_notes'] == true &&
          !documentTypes.contains('releves_notes')) {
        filesToUpload.add(_selectedFiles['releves_notes']!);
        documentTypes.add('releves_notes');
      }

      // Déterminer le motif final à utiliser
      final motifFinal = _selectedMotif == "Autre motif" 
          ? _autreMotifController.text.trim() 
          : _selectedMotif!;

      // Combiner motif et justification comme une lettre officielle
      final lettreComplete = 'Objet : $motifFinal\n\n${_justificationController.text.trim()}';

      // Appeler l'API de soumission de recours
      final result = await RecoursApiService.submitRecoursWithDocuments(
        motifRejet: motifFinal,
        justification: lettreComplete,
        documents: filesToUpload,
        documentTypes: documentTypes,
      );

      if (mounted) {
        if (result['success'] == true) {
          await _showSuccessDialog();
        } else {
          String errorMessage = result['error'] ?? 'Une erreur inattendue s\'est produite lors de la soumission du recours.';
          await _showSubmissionErrorDialog(
            'Erreur de soumission',
            errorMessage,
            icone: Icons.cloud_off_outlined,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Déterminer le type d'erreur pour un message approprié
        String titre = 'Erreur de connexion';
        String message;
        IconData icone = Icons.wifi_off_outlined;
        
        if (e.toString().contains('network') || e.toString().contains('connection')) {
          titre = 'Problème de connexion';
          message = 'Vérifiez votre connexion internet et réessayez.';
          icone = Icons.wifi_off_outlined;
        } else if (e.toString().contains('timeout')) {
          titre = 'Délai d\'attente dépassé';
          message = 'Le serveur met trop de temps à répondre. Veuillez réessayer.';
          icone = Icons.access_time_outlined;
        } else if (e.toString().contains('server')) {
          titre = 'Erreur serveur';
          message = 'Le serveur rencontre un problème temporaire. Veuillez réessayer plus tard.';
          icone = Icons.dns_outlined;
        } else {
          titre = 'Erreur technique';
          message = 'Une erreur technique s\'est produite.\n\nDétails : $e';
          icone = Icons.bug_report_outlined;
        }
        
        await _showSubmissionErrorDialog(titre, message, icone: icone);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final isMediumScreen = MediaQuery.of(context).size.width < 900;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? theme.scaffoldBackgroundColor : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Soumettre un recours',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : isMediumScreen ? 24 : 32,
              vertical: isSmallScreen ? 16 : 24,
            ),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isSmallScreen ? double.infinity : 800,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations de la candidature
                      _buildCandidatureInfo(theme, isSmallScreen, isDarkMode),
                      const SizedBox(height: 24),
                      
                      // Sélection du motif
                      _buildMotifSelection(theme, isSmallScreen, isDarkMode),
                      const SizedBox(height: 24),
              
                      // Champ de justification
                      _buildJustificationField(theme, isSmallScreen, isDarkMode),
                      const SizedBox(height: 24),
              
                      // Documents à resoumettre
                      _buildDocumentsSection(theme, isSmallScreen, isDarkMode),
                      const SizedBox(height: 32),
              
                      // Bouton de soumission
                      _buildSubmitButton(theme, isSmallScreen, isDarkMode),
                      
                      // Espacement pour éviter que le bouton soit masqué par la barre de navigation
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCandidatureInfo(ThemeData theme, bool isSmallScreen, bool isDarkMode) {
    return Card(
      elevation: isDarkMode ? 8 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? theme.cardColor : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de la candidature',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Numéro', widget.candidature.numero),
            _buildInfoRow('Statut', widget.candidature.statut.toUpperCase()),
            _buildInfoRow('Date de création', widget.candidature.dateCreationFormatee),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label :',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? theme.colorScheme.onSurface.withValues(alpha: 0.7) : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: isDarkMode ? theme.colorScheme.onSurface : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotifSelection(ThemeData theme, bool isSmallScreen, bool isDarkMode) {
    return Card(
      elevation: isDarkMode ? 8 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? theme.cardColor : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Objet du recours *',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                value: _selectedMotif,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Sélectionnez le motif de votre recours',
                  hintStyle: GoogleFonts.poppins(
                    color: isDarkMode ? theme.colorScheme.onSurface.withValues(alpha: 0.6) : Colors.grey[600],
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode ? theme.colorScheme.outline : Colors.grey[300]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode ? theme.colorScheme.outline : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16, 
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                  filled: true,
                  fillColor: isDarkMode ? theme.colorScheme.surface : Colors.white,
                ),
                items: _motifsRecours.map((motif) {
                  return DropdownMenuItem<String>(
                    value: motif,
                    child: Container(
                      width: double.infinity,
                      child: Text(
                        motif,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: isDarkMode ? theme.colorScheme.onSurface : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMotif = value;
                    // Vider le champ "Autre motif" si on change de sélection
                    if (value != "Autre motif") {
                      _autreMotifController.clear();
                    }
                  });
                },
              ),
            ),
            
            // ========== CHAMP "AUTRE MOTIF" CONDITIONNEL ==========
            if (_selectedMotif == "Autre motif") ...[
              const SizedBox(height: 16),
              Text(
                'Précisez votre motif *',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _autreMotifController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Décrivez votre motif personnalisé...',
                  hintStyle: GoogleFonts.poppins(
                    color: isDarkMode ? theme.colorScheme.onSurface.withValues(alpha: 0.6) : Colors.grey[600],
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode ? theme.colorScheme.outline : Colors.grey[300]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode ? theme.colorScheme.outline : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12, 
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                  filled: true,
                  fillColor: isDarkMode ? theme.colorScheme.surface : Colors.white,
                ),
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: isDarkMode ? theme.colorScheme.onSurface : Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJustificationField(ThemeData theme, bool isSmallScreen, bool isDarkMode) {
    return Card(
      elevation: isDarkMode ? 8 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? theme.cardColor : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Justification *',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: BoxConstraints(
                minHeight: isSmallScreen ? 120 : 150,
                maxHeight: isSmallScreen ? 200 : 250,
              ),
              child: TextFormField(
                controller: _justificationController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Décrivez en détail les raisons de votre recours...',
                  hintStyle: GoogleFonts.poppins(
                    color: isDarkMode ? theme.colorScheme.onSurface.withValues(alpha: 0.6) : Colors.grey[600],
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode ? theme.colorScheme.outline : Colors.grey[300]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode ? theme.colorScheme.outline : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  filled: true,
                  fillColor: isDarkMode ? theme.colorScheme.surface : Colors.white,
                ),
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: isDarkMode ? theme.colorScheme.onSurface : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection(ThemeData theme, bool isSmallScreen, bool isDarkMode) {
    return Card(
      elevation: isDarkMode ? 8 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? theme.cardColor : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documents à resoumettre',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez les documents que vous souhaitez resoumettre pour corriger les problèmes identifiés.',
              style: GoogleFonts.poppins(
                color: isDarkMode ? theme.colorScheme.onSurface.withValues(alpha: 0.7) : Colors.grey[600],
                fontSize: isSmallScreen ? 13 : 14,
              ),
            ),
            const SizedBox(height: 16),
            
            if (widget.candidature.documentsNonConformes.isEmpty)
              Center(
                child: Text(
                  'Aucun document non conforme identifié',
                  style: GoogleFonts.poppins(
                    color: isDarkMode ? theme.colorScheme.onSurface.withValues(alpha: 0.6) : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...widget.candidature.documentsNonConformes.map((docType) {
                return _buildDocumentUploadRow(docType, theme, isSmallScreen, isDarkMode);
              }).toList(),
            
            // Champ statique pour le relevé des notes
            const SizedBox(height: 8),
            _buildDocumentUploadRow('releves_notes', theme, isSmallScreen, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUploadRow(String docType, ThemeData theme, bool isSmallScreen, bool isDarkMode) {
    final displayName = _documentDisplayNames[docType] ?? docType;
    final isSelected = _documentsToResubmit[docType] ?? false;
    final selectedFile = _selectedFiles[docType];

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected 
            ? theme.colorScheme.primary 
            : isDarkMode ? theme.colorScheme.outline : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected 
          ? theme.colorScheme.primary.withValues(alpha: isDarkMode ? 0.15 : 0.05) 
          : isDarkMode ? theme.colorScheme.surface : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    _documentsToResubmit[docType] = value ?? false;
                    if (!value!) {
                      _selectedFiles[docType] = null;
                    }
                  });
                },
                activeColor: theme.colorScheme.primary,
              ),
              Expanded(
                child: Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: isSmallScreen ? 14 : 16,
                    color: isSelected 
                      ? theme.colorScheme.primary 
                      : isDarkMode ? theme.colorScheme.onSurface : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          
          if (isSelected) ...[
            SizedBox(height: isSmallScreen ? 8 : 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _pickFile(docType),
                icon: Icon(Icons.attach_file, size: isSmallScreen ? 16 : 18),
                label: Text(
                  selectedFile == null ? 'Sélectionner un fichier' : 'Changer le fichier',
                  style: GoogleFonts.poppins(fontSize: isSmallScreen ? 13 : 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16, 
                    vertical: isSmallScreen ? 8 : 10,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            
            if (selectedFile != null) ...[
              SizedBox(height: isSmallScreen ? 6 : 8),
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.green[900]?.withValues(alpha: 0.3) : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? Colors.green[400]! : Colors.green[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle, 
                      color: isDarkMode ? Colors.green[400] : Colors.green[600], 
                      size: isSmallScreen ? 14 : 16,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Expanded(
                      child: Text(
                        selectedFile.path.split('/').last,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: isDarkMode ? Colors.green[300] : Colors.green[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              'Formats acceptés: PDF, Word, JPG, JPEG, PNG (max 5 Mo)',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 11 : 12,
                color: isDarkMode ? theme.colorScheme.onSurface.withValues(alpha: 0.6) : Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme, bool isSmallScreen, bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRecours,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDarkMode 
            ? theme.colorScheme.outline 
            : Colors.grey[400],
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 16 : 18,
            horizontal: isSmallScreen ? 20 : 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: _isSubmitting ? 2 : 4,
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: isSmallScreen ? 18 : 20,
                    height: isSmallScreen ? 18 : 20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 12),
                  Text(
                    'Soumission en cours...',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 15 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                'Soumettre le recours',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 15 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
