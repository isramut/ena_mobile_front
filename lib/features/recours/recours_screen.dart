import 'dart:io';
import 'package:ena_mobile_front/models/recours_models.dart';
import 'package:ena_mobile_front/services/recours_api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecoursScreen extends StatefulWidget {
  const RecoursScreen({super.key});

  @override
  State<RecoursScreen> createState() => _RecoursScreenState();
}

class _RecoursScreenState extends State<RecoursScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motifController = TextEditingController();
  final _justificationController = TextEditingController();
  final _messageController = TextEditingController();

  String selectedMotif = '';
  bool loading = false;
  bool isLoadingRecours = true;
  List<File> attachedFiles = [];
  List<Recours> mesRecours = [];
  String? errorMessage;
  bool hasError = false;
  RecoursValidationError? validationErrors;

  final List<String> motifsRecours = [
    'Erreur dans l\'évaluation du dossier',
    'Non-respect des critères annoncés',
    'Discrimination ou traitement inéquitable',
    'Problème technique lors de la soumission',
    'Documents non pris en compte',
    'Autre motif',
  ];

  @override
  void initState() {
    super.initState();
    _loadMesRecours();
  }

  /// Charge les recours existants depuis l'API
  Future<void> _loadMesRecours() async {
    setState(() {
      isLoadingRecours = true;
      hasError = false;
    });

    try {
      final result = await RecoursApiService.getMesRecoursWithCache();
      
      if (result['success'] == true) {
        final RecoursResponse response = result['data'];
        setState(() {
          mesRecours = response.recours;
          isLoadingRecours = false;
        });
        print('✅ Recours chargés: ${mesRecours.length} éléments');
      } else {
        setState(() {
          isLoadingRecours = false;
          hasError = true;
          errorMessage = result['error'] ?? 'Erreur lors du chargement';
        });
      }
    } catch (e) {
      setState(() {
        isLoadingRecours = false;
        hasError = true;
        errorMessage = 'Erreur de connexion: $e';
      });
    }
  }

  @override
  void dispose() {
    _motifController.dispose();
    _justificationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRecours() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedMotif.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner un motif de recours');
      return;
    }

    // Validation côté client
    final clientValidationErrors = RecoursApiService.validateRecoursData(
      motifRejet: selectedMotif,
      justification: _justificationController.text,
    );

    if (clientValidationErrors.isNotEmpty) {
      setState(() {
        validationErrors = RecoursValidationError(errors: {
          for (var entry in clientValidationErrors.entries)
            entry.key: [entry.value!]
        });
      });
      return;
    }

    setState(() {
      loading = true;
      validationErrors = null;
    });

    try {
      final result = await RecoursApiService.creerRecours(
        motifRejet: selectedMotif,
        justification: _justificationController.text,
        documents: [], // TODO: Gérer l'upload de fichiers
      );

      if (result['success'] == true) {
        final Recours nouveauRecours = result['data'];
        _showSuccessDialog(nouveauRecours);
        
        // Recharger la liste des recours
        await _loadMesRecours();
        
        // Réinitialiser le formulaire
        _resetForm();
      } else {
        if (result.containsKey('validation_errors')) {
          setState(() {
            // Convertir les erreurs de validation depuis l'API en RecoursValidationError
            final Map<String, dynamic> apiErrors = result['validation_errors'];
            final Map<String, List<String>> convertedErrors = {};
            
            for (var entry in apiErrors.entries) {
              if (entry.value is List) {
                convertedErrors[entry.key] = List<String>.from(entry.value);
              } else if (entry.value is String) {
                convertedErrors[entry.key] = [entry.value];
              }
            }
            
            validationErrors = RecoursValidationError(errors: convertedErrors);
          });
        } else {
          _showErrorSnackBar(result['error'] ?? 'Erreur lors de l\'envoi du recours');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur de connexion au serveur');
    } finally {
      setState(() => loading = false);
    }
  }

  void _resetForm() {
    setState(() {
      selectedMotif = '';
      _motifController.clear();
      _justificationController.clear();
      attachedFiles.clear();
      validationErrors = null;
    });
  }

  void _showSuccessDialog(Recours recours) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            const Text('Recours envoyé'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre recours a été envoyé avec succès.',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Numéro de recours: ${recours.id}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'Statut: ${recours.statutFormate}',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  Text(
                    'Date: ${recours.dateCreationFormatee}',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Vous recevrez une réponse dans les 15 jours ouvrables.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Retourner à la page précédente
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Mes recours',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMesRecours,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section des recours existants
                if (isLoadingRecours)
                  _buildLoadingSection()
                else if (hasError)
                  _buildErrorSection()
                else
                  _buildRecoursExistants(),

                const SizedBox(height: 24),

                // Section nouveau recours
                _buildNouveauRecoursSection(theme, primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section de chargement
  Widget _buildLoadingSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Chargement de vos recours...',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  /// Section d'erreur
  Widget _buildErrorSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Une erreur s\'est produite',
              style: GoogleFonts.poppins(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMesRecours,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Section des recours existants
  Widget _buildRecoursExistants() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mes recours (${mesRecours.length})',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        
        if (mesRecours.isEmpty)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun recours trouvé',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vous n\'avez pas encore déposé de recours.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...mesRecours.map((recours) => _buildRecoursCard(recours)).toList(),
      ],
    );
  }

  /// Card pour afficher un recours individuel
  Widget _buildRecoursCard(Recours recours) {
    Color statusColor;
    IconData statusIcon;
    
    switch (recours.statut) {
      case 'en_attente':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'en_cours':
        statusColor = Colors.blue;
        statusIcon = Icons.timelapse;
        break;
      case 'accepte':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejete':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        recours.statutFormate,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  recours.dateCreationFormatee,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Motif: ${recours.motifRejet}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recours.justification,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (recours.reponseAdmin != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Réponse de l\'administration:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recours.reponseAdmin!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    if (recours.dateTraitementFormatee != null)
                      Text(
                        'Traitée le: ${recours.dateTraitementFormatee}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.blue.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Section pour créer un nouveau recours
  Widget _buildNouveauRecoursSection(ThemeData theme, Color primaryColor) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nouveau recours',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          
          // Bandeau d'information
          Card(
            color: Colors.blue.shade50,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Le recours doit être déposé dans les 48h suivant la notification d\'élimination.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Formulaire principal
          Card(
            color: theme.colorScheme.surface,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Formulaire de recours',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Motif du recours
                  Text(
                    'Motif du recours *',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Afficher les erreurs de validation pour le motif
                  if (validationErrors?.hasErrorForField('motif_rejet') == true)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        validationErrors!.getErrorsForField('motif_rejet').join(', '),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: validationErrors?.hasErrorForField('motif_rejet') == true
                            ? Colors.red
                            : theme.colorScheme.outline.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: motifsRecours.map((motif) {
                        return RadioListTile<String>(
                          title: Text(
                            motif,
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          value: motif,
                          groupValue: selectedMotif,
                          activeColor: primaryColor,
                          onChanged: (value) {
                            setState(() {
                              selectedMotif = value!;
                              // Effacer les erreurs de validation
                              if (validationErrors != null) {
                                validationErrors!.errors.remove('motif_rejet');
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Justification détaillée
                  Text(
                    'Justification détaillée *',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Afficher les erreurs de validation pour la justification
                  if (validationErrors?.hasErrorForField('justification') == true)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        validationErrors!.getErrorsForField('justification').join(', '),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  
                  TextFormField(
                    controller: _justificationController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Expliquez en détail les raisons de votre recours...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: validationErrors?.hasErrorForField('justification') == true
                              ? Colors.red
                              : theme.colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: validationErrors?.hasErrorForField('justification') == true
                              ? Colors.red
                              : theme.colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: validationErrors?.hasErrorForField('justification') == true
                              ? Colors.red
                              : primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La justification est obligatoire';
                      }
                      if (value.trim().length < 50) {
                        return 'La justification doit contenir au moins 50 caractères';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Effacer les erreurs de validation
                      if (validationErrors != null) {
                        validationErrors!.errors.remove('justification');
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Section pièces jointes (TODO: À implémenter)
                  Text(
                    'Pièces justificatives (optionnel)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload de fichiers bientôt disponible',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Bouton de soumission
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submitRecours,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: loading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Envoi en cours...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Soumettre le recours',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Informations importantes
          const SizedBox(height: 20),
          Card(
            color: Colors.orange.shade50,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Important',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Le recours sera examiné par une commission indépendante\n'
                    '• Vous recevrez une réponse dans les 15 jours ouvrables\n'
                    '• La décision de la commission est définitive',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
