import 'dart:io';
import 'package:ena_mobile_front/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class RecoursScreen extends StatefulWidget {
  const RecoursScreen({super.key});

  @override
  State<RecoursScreen> createState() => _RecoursScreenState();
}

class _RecoursScreenState extends State<RecoursScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motifController = TextEditingController();
  final _messageController = TextEditingController();

  String selectedMotif = '';
  bool loading = false;
  List<File> attachedFiles = [];

  final List<String> motifsRecours = [
    'Erreur dans l\'évaluation du dossier',
    'Non-respect des critères annoncés',
    'Discrimination ou traitement inéquitable',
    'Problème technique lors de la soumission',
    'Documents non pris en compte',
    'Autre motif',
  ];

  @override
  void dispose() {
    _motifController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          attachedFiles.add(File(picked.path));
        });
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection du fichier');
    }
  }

  void _removeFile(int index) {
    setState(() {
      attachedFiles.removeAt(index);
    });
  }

  Future<void> _submitRecours() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedMotif.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner un motif de recours');
      return;
    }

    setState(() => loading = true);

    try {
      // Simulation d'envoi - Remplacer par l'API réelle
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/recours/'),
      );

      // Ajouter les champs
      request.fields['motif'] = selectedMotif;
      request.fields['message'] = _messageController.text;

      // Ajouter les fichiers
      for (var file in attachedFiles) {
        request.files.add(
          await http.MultipartFile.fromPath('documents', file.path),
        );
      }

      // Simulation - En réalité, faire l'appel API
      await Future.delayed(const Duration(seconds: 2));

      // final response = await request.send();
      // if (response.statusCode == 200) {
      //   _showSuccessDialog();
      // } else {
      //   _showErrorSnackBar('Erreur lors de l\'envoi du recours');
      // }

      // Pour la simulation
      _showSuccessDialog();
    } catch (e) {
      _showErrorSnackBar('Erreur de connexion au serveur');
    } finally {
      setState(() => loading = false);
    }
  }

  void _showSuccessDialog() {
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
        content: const Text(
          'Votre recours a été envoyé avec succès. Vous recevrez une réponse dans les 15 jours ouvrables.',
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
          'Faire un recours',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.5,
                                ),
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
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Message détaillé
                          Text(
                            'Message détaillé *',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _messageController,
                            maxLines: 8,
                            maxLength: 3000,
                            decoration: InputDecoration(
                              hintText:
                                  'Décrivez en détail les raisons de votre recours...',
                              hintStyle: GoogleFonts.poppins(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outline.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              contentPadding: const EdgeInsets.all(16),
                              counterStyle: GoogleFonts.poppins(fontSize: 12),
                            ),
                            style: GoogleFonts.poppins(fontSize: 14),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez saisir votre message';
                              }
                              if (value.trim().length < 50) {
                                return 'Le message doit contenir au moins 50 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Pièces justificatives
                          Text(
                            'Pièces justificatives (optionnel)',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Bouton d'ajout de fichier
                          OutlinedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Joindre un fichier'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                            ),
                          ),

                          // Liste des fichiers joints
                          if (attachedFiles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...attachedFiles.asMap().entries.map((entry) {
                              int index = entry.key;
                              File file = entry.value;
                              String fileName = file.path.split('/').last;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.description,
                                      color: Colors.green.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        fileName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.green.shade800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _removeFile(index),
                                      icon: Icon(
                                        Icons.close,
                                        color: Colors.red.shade600,
                                        size: 18,
                                      ),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],

                          const SizedBox(height: 30),

                          // Bouton d'envoi
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: loading ? null : _submitRecours,
                              icon: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                              label: Text(
                                loading
                                    ? 'Envoi en cours...'
                                    : 'Envoyer le recours',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                textStyle: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Note informative
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
            ),
          ),
        ],
      ),
    );
  }
}
