import 'package:ena_mobile_front/models/ma_candidature.dart';
import 'package:ena_mobile_front/models/recours_models.dart';
import 'package:ena_mobile_front/services/auth_api_service.dart';
import 'package:ena_mobile_front/services/recours_api_service.dart';
import 'package:ena_mobile_front/features/recours/submit_recours_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Classe pour regrouper les informations d'un document
class DocumentInfo {
  final String nom;
  final List<String> raisons;
  final String? url;

  DocumentInfo({
    required this.nom,
    required this.raisons,
    this.url,
  });
}

class RecoursScreen extends StatefulWidget {
  const RecoursScreen({super.key});

  @override
  State<RecoursScreen> createState() => _RecoursScreenState();
}

class _RecoursScreenState extends State<RecoursScreen> {
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  MaCandidature? maCandidature;
  HasSubmittedRecours? hasSubmittedRecours;
  List<Recours>? mesRecours;

  @override
  void initState() {
    super.initState();
    _loadMaCandidature();
  }

  Future<void> _loadMaCandidature() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
        errorMessage = null;
      });
      
      // 1. D'abord vérifier si l'utilisateur a soumis un recours
      final hasRecoursResult = await AuthApiService.hasSubmittedRecours();
      
      if (hasRecoursResult['success'] != true) {
        setState(() {
          hasError = true;
          errorMessage = hasRecoursResult['error']?.toString() ?? 'Erreur lors de la vérification du recours';
          isLoading = false;
        });
        return;
      }

      final hasSubmitted = hasRecoursResult['data'] as HasSubmittedRecours;
      setState(() {
        hasSubmittedRecours = hasSubmitted;
      });

      if (hasSubmitted.hasRecours) {
        // 2. Si l'utilisateur a soumis un recours, récupérer ses détails
        final recoursResult = await RecoursApiService.getMesRecours();
        
        if (recoursResult['success'] == true && recoursResult['data'] != null) {
          setState(() {
            mesRecours = recoursResult['data'] as List<Recours>;
            isLoading = false;
          });
        } else {
          setState(() {
            hasError = true;
            errorMessage = recoursResult['error']?.toString() ?? 'Erreur lors du chargement du recours';
            isLoading = false;
          });
        }
      } else {
        // 3. Si pas de recours, charger les informations de candidature pour afficher les raisons de rejet
        final candidatureResult = await AuthApiService.getMaCandidature();
        
        if (candidatureResult['success'] == true && candidatureResult['data'] != null) {
          setState(() {
            maCandidature = candidatureResult['data'] as MaCandidature;
            isLoading = false;
          });
        } else {
          setState(() {
            hasError = true;
            errorMessage = candidatureResult['error']?.toString() ?? 'Erreur inconnue';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Erreur de connexion: $e';
        isLoading = false;
      });
    }
  }

  /// Combine les documents et leurs raisons pour un affichage unifié
  Map<String, DocumentInfo> _getDocumentsAvecRaisons() {
    if (maCandidature?.commentaireAdmin == null || maCandidature!.commentaireAdmin!.isEmpty) {
      return {};
    }
    
    final parts = maCandidature!.commentaireAdmin!.split(';');
    Map<String, DocumentInfo> documentsMap = {};
    
    for (String part in parts) {
      final trimmedPart = part.trim();
      if (trimmedPart.contains(':')) {
        final splitPart = trimmedPart.split(':');
        if (splitPart.length >= 2) {
          final document = splitPart[0].trim();
          final raison = splitPart[1].trim();
          
          if (!documentsMap.containsKey(document)) {
            documentsMap[document] = DocumentInfo(
              nom: document,
              raisons: [],
              url: _getDocumentUrl(document),
            );
          }
          documentsMap[document]!.raisons.add(raison);
        } else if (splitPart.isNotEmpty) {
          // Document sans raison spécifique
          final document = splitPart[0].trim();
          if (!documentsMap.containsKey(document)) {
            documentsMap[document] = DocumentInfo(
              nom: document,
              raisons: [],
              url: _getDocumentUrl(document),
            );
          }
        }
      }
    }
    
    // Ajouter le document statique "Relevé de notes"
    documentsMap['Relevé des notes de la dernière année'] = DocumentInfo(
      nom: 'Relevé des notes de la dernière année',
      raisons: ['Document non fourni'],
      url: 'non_disponible', // URL spéciale pour indiquer que le document n'est pas disponible
    );
    
    return documentsMap;
  }

  /// Mappe le nom du document vers son URL dans le modèle
  String? _getDocumentUrl(String documentName) {
    if (maCandidature == null) return null;
    
    final docLower = documentName.toLowerCase();
    
    if (docLower.contains('cv')) return maCandidature!.cv;
    if (docLower.contains('diplôme') || docLower.contains('diplome')) return maCandidature!.diplome;
    if (docLower.contains('lettre')) return maCandidature!.lettreMotivation;
    if (docLower.contains('pièce') || docLower.contains('piece') || 
        docLower.contains('identité') || docLower.contains('identite')) return maCandidature!.pieceIdentite;
    if (docLower.contains('aptitude')) return maCandidature!.aptitudePhysique;
    
    return null;
  }

  /// Ouvre l'URL du document ou affiche un message si non disponible
  Future<void> _openDocumentWithCheck(String? url) async {
    if (url == null) {
      // Document sans URL
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'URL du document non disponible',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    if (url == 'non_disponible') {
      // Document marqué comme non disponible
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Document non disponible',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    // Document disponible, ouvrir normalement
    await _openDocument(url);
  }

  /// Ouvre l'URL du document
  Future<void> _openDocument(String url) async {
    try {
      // Ouvrir l'URL du document
      
      // Compléter l'URL si elle est relative
      String completeUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        // Ajouter le domaine de base si l'URL est relative
        completeUrl = 'https://ena.gouv.cd$url';
      }
      
      final uri = Uri.parse(completeUrl);
      
      // Vérifier si l'URL peut être lancée
      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Essayer d'autres modes de lancement
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e2) {
          try {
            await launchUrl(uri, mode: LaunchMode.inAppWebView);
          } catch (e3) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Impossible d\'ouvrir le document\nURL: $completeUrl',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de l\'ouverture du document: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mes recours',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMaCandidature,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMaCandidature,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 14 : isMediumScreen ? 20 : 32,
                vertical: isSmallScreen ? 12 : 16,
              ),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isSmallScreen ? double.infinity : 900,
                  ),
                  child: _buildContent(theme, isSmallScreen),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isSmallScreen) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement de votre candidature...',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 14 : 16,
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ],
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: theme.colorScheme.error.withAlpha(20),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: isSmallScreen ? 48 : 56,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage ?? 'Une erreur est survenue',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: theme.colorScheme.onSurface.withAlpha(180),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadMaCandidature,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    'Réessayer',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Logique conditionnelle principale
    if (hasSubmittedRecours != null && hasSubmittedRecours!.hasRecours) {
      // Cas 1: L'utilisateur a déjà soumis un recours - afficher les détails du recours
      return _buildRecoursContent(theme, isSmallScreen);
    } else {
      // Cas 2: L'utilisateur n'a pas soumis de recours - afficher les raisons de rejet
      return _buildCandidatureRejectionContent(theme, isSmallScreen);
    }
  }

  /// Construit le contenu pour afficher les détails du recours soumis
  Widget _buildRecoursContent(ThemeData theme, bool isSmallScreen) {
    // Vérification de sécurité supplémentaire
    if (mesRecours == null) {
      return Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: theme.colorScheme.error.withAlpha(20),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: isSmallScreen ? 48 : 56,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de données',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les données du recours ne sont pas disponibles.',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: theme.colorScheme.onSurface.withAlpha(180),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (mesRecours!.isEmpty) {
      return Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: theme.colorScheme.onSurface.withAlpha(120),
                  size: isSmallScreen ? 48 : 56,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun recours trouvé',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucun recours n\'a été trouvé pour votre candidature.',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: theme.colorScheme.onSurface.withAlpha(180),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final recours = mesRecours!.first; // Prendre le premier recours
    
    // Vérifier le type de candidature et gérer les cas appropriés
    if (recours.candidature is! CandidatureRecours) {
      return Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: theme.colorScheme.error.withAlpha(20),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: isSmallScreen ? 48 : 56,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de format des données',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les données du recours ne sont pas dans le format attendu.',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: theme.colorScheme.onSurface.withAlpha(180),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    final candidatureRecours = recours.candidature as CandidatureRecours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card principale avec informations du recours
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre de la section
                Row(
                  children: [
                    Icon(
                      Icons.assignment_turned_in,
                      color: theme.colorScheme.primary,
                      size: isSmallScreen ? 22 : 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mon recours soumis',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Informations du candidat
                _buildInfoRow(
                  Icons.account_circle,
                  'Nom complet',
                  '${candidatureRecours.candidat.firstName} ${candidatureRecours.candidat.lastName}',
                  theme,
                  isSmallScreen,
                ),
                
                _buildInfoRow(
                  Icons.email,
                  'Email',
                  candidatureRecours.candidat.email,
                  theme,
                  isSmallScreen,
                ),
                
                _buildInfoRow(
                  Icons.confirmation_number,
                  'N° candidature',
                  candidatureRecours.numeroCandidature,
                  theme,
                  isSmallScreen,
                ),
                
                _buildInfoRow(
                  Icons.assignment,
                  'N° recours',
                  recours.ordre,
                  theme,
                  isSmallScreen,
                ),
                
                _buildInfoRow(
                  Icons.calendar_today,
                  'Date de soumission',
                  recours.dateSoumissionFormatee,
                  theme,
                  isSmallScreen,
                ),
                
                // Statut du recours
                _buildRecoursStatusRow(recours, theme, isSmallScreen),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Card avec les documents non conformes
        if (candidatureRecours.documentsNonConformes.isNotEmpty) ...[
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: theme.colorScheme.error.withAlpha(15),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: theme.colorScheme.error,
                        size: isSmallScreen ? 22 : 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Documents non conformes',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...candidatureRecours.documentsNonConformes.map((doc) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              doc,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 13 : 14,
                                color: theme.colorScheme.onSurface,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Card avec la justification
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: theme.colorScheme.primary,
                      size: isSmallScreen ? 22 : 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ma justification',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withAlpha(50),
                    ),
                  ),
                  child: Text(
                    recours.justification,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: theme.colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Si le recours est traité, afficher les détails
        if (recours.traite) ...[
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.green.shade50,
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: isSmallScreen ? 22 : 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Recours traité',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (recours.dateTraitementFormatee != null)
                    _buildInfoRow(
                      Icons.calendar_month,
                      'Date de traitement',
                      recours.dateTraitementFormatee!,
                      theme,
                      isSmallScreen,
                    ),
                  
                  if (recours.commentaireAdmin != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Commentaire de l\'administration :',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.shade300,
                        ),
                      ),
                      child: Text(
                        recours.commentaireAdmin!,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: Colors.green.shade800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Construit le contenu pour afficher les raisons de rejet (logique existante)
  Widget _buildCandidatureRejectionContent(ThemeData theme, bool isSmallScreen) {
    if (maCandidature == null) {
      return Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  color: theme.colorScheme.onSurface.withAlpha(120),
                  size: isSmallScreen ? 48 : 56,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune candidature trouvée',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous n\'avez pas encore soumis de candidature.',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: theme.colorScheme.onSurface.withAlpha(180),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Affichage des informations de candidature
    final candidature = maCandidature!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card principale avec informations candidature
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre de la section
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.primary,
                      size: isSmallScreen ? 22 : 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Informations de candidature',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Nom complet
                _buildInfoRow(
                  Icons.account_circle,
                  'Nom complet',
                  candidature.candidatFullName,
                  theme,
                  isSmallScreen,
                ),
                
                // Numéro de candidature
                _buildInfoRow(
                  Icons.confirmation_number,
                  'N° candidature',
                  candidature.numero,
                  theme,
                  isSmallScreen,
                ),
                
                // Date de soumission
                _buildInfoRow(
                  Icons.calendar_today,
                  'Date de soumission',
                  candidature.dateCreationFormatee,
                  theme,
                  isSmallScreen,
                ),
                
                // Statut avec badge coloré
                _buildStatusRow(theme, isSmallScreen),
              ],
            ),
          ),
        ),
        
        if (candidature.estRejetee) ...[
          const SizedBox(height: 16),
          // Card unifiée avec les raisons de rejet
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: theme.colorScheme.error.withAlpha(15),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre de la section
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: theme.colorScheme.error,
                        size: isSmallScreen ? 22 : 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Raisons de rejet',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Contenu principal avec documents et raisons
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.error.withAlpha(40),
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        final documentsAvecRaisons = _getDocumentsAvecRaisons();
                        if (documentsAvecRaisons.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Documents concernés et raisons :',
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...documentsAvecRaisons.values.map((docInfo) => 
                                _buildDocumentCompletItem(docInfo, theme, isSmallScreen)
                              ),
                            ],
                          );
                        }
                        return Text(
                          'Aucune information détaillée disponible',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 13 : 14,
                            color: theme.colorScheme.onSurface,
                            height: 1.4,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Bouton pour déposer un recours
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (maCandidature != null) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubmitRecoursScreen(
                        candidature: maCandidature!,
                      ),
                    ),
                  );
                  
                  // Si le recours a été soumis avec succès, recharger les données
                  if (result == true) {
                    _loadMaCandidature();
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Impossible de charger les données de candidature',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.assignment_outlined),
              label: Text(
                'Déposer un recours',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 14 : 16,
                  horizontal: isSmallScreen ? 20 : 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 20),
          // Card quand pas de rejet
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.green.shade50,
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: isSmallScreen ? 24 : 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Candidature en cours',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Votre candidature est actuellement en cours de traitement. Aucun recours n\'est nécessaire.',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 13 : 14,
                            color: Colors.green.shade700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Ligne d'information standard
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
    bool isSmallScreen,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.onSurface.withAlpha(150),
            size: isSmallScreen ? 18 : 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ligne du statut avec badge coloré
  Widget _buildStatusRow(ThemeData theme, bool isSmallScreen) {
    final statut = maCandidature!.statut;
    Color statusColor;
    Color statusBgColor;
    
    // Mapper le statut pour un meilleur affichage
    String displayStatut;
    if (statut == 'rejete') {
      displayStatut = 'Candidature rejetée';
      statusColor = theme.colorScheme.error;
      statusBgColor = theme.colorScheme.error.withAlpha(30);
    } else {
      displayStatut = statut;
      statusColor = Colors.green.shade700;
      statusBgColor = Colors.green.shade100;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.onSurface.withAlpha(150),
            size: isSmallScreen ? 18 : 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              'Situation',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withAlpha(60)),
              ),
              child: Text(
                displayStatut,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Item complet pour un document avec ses raisons et lien
  Widget _buildDocumentCompletItem(DocumentInfo docInfo, ThemeData theme, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom du document
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  docInfo.nom,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: theme.colorScheme.onSurface,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          // Raisons si disponibles
          if (docInfo.raisons.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Text(
                'Raisons : ${docInfo.raisons.join(', ')}',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 12 : 13,
                  color: theme.colorScheme.onSurface.withAlpha(180),
                  height: 1.3,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          
          // Lien vers le document si disponible
          if (docInfo.url != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: GestureDetector(
                onTap: () => _openDocumentWithCheck(docInfo.url),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.open_in_new,
                      size: isSmallScreen ? 14 : 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Voir le document',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Ligne du statut spécifique aux recours
  Widget _buildRecoursStatusRow(Recours recours, ThemeData theme, bool isSmallScreen) {
    final statut = recours.statutFormate;
    Color statusColor;
    Color statusBgColor;
    
    if (recours.traite) {
      statusColor = Colors.green.shade700;
      statusBgColor = Colors.green.shade100;
    } else {
      statusColor = Colors.orange.shade700;
      statusBgColor = Colors.orange.shade100;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.onSurface.withAlpha(150),
            size: isSmallScreen ? 18 : 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              'Statut',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withAlpha(60)),
              ),
              child: Text(
                statut,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
