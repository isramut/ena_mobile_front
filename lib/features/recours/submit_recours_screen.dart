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
  
  // Variables pour le formulaire
  String? _selectedMotif;
  bool _isSubmitting = false;
  
  // Map pour stocker les fichiers sélectionnés par document
  Map<String, File?> _selectedFiles = {};
  Map<String, bool> _documentsToResubmit = {};
  
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

  Future<void> _submitRecours() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMotif == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez sélectionner un motif de recours',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier qu'au moins un document est sélectionné pour resoumission
    if (!_documentsToResubmit.values.any((selected) => selected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez sélectionner au moins un document à resoummettre',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérification OBLIGATOIRE du relevé des notes
    if (_selectedFiles['releves_notes'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📄 Le relevé des notes de la dernière année est obligatoire pour soumettre un recours',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

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

      // Combiner motif et justification comme une lettre officielle
      final lettreComplete = 'Objet : $_selectedMotif\n\n${_justificationController.text.trim()}';

      // Appeler l'API de soumission de recours
      final result = await RecoursApiService.submitRecoursWithDocuments(
        motifRejet: _selectedMotif!,
        justification: lettreComplete,
        documents: filesToUpload,
        documentTypes: documentTypes,
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Recours soumis avec succès',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Retourner true pour indiquer le succès
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['error'] ?? 'Erreur lors de la soumission du recours',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la soumission: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
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
              
                      // Documents à resoummettre
                      _buildDocumentsSection(theme, isSmallScreen, isDarkMode),
                      const SizedBox(height: 32),
              
                      // Bouton de soumission
                      _buildSubmitButton(theme, isSmallScreen, isDarkMode),
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
                  });
                },
              ),
            ),
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La justification est obligatoire';
                  }
                  if (value.trim().length < 20) {
                    return 'La justification doit contenir au moins 20 caractères';
                  }
                  return null;
                },
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
              'Documents à resoummettre',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez les documents que vous souhaitez resoummettre pour corriger les problèmes identifiés.',
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
