import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ena_mobile_front/features/prepa/quiz_content.dart';

class PrepaEnaContent extends StatelessWidget {
  final Function(int)? onMenuChanged;

  const PrepaEnaContent({super.key, this.onMenuChanged});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1024;
    final isDesktop = screenSize.width >= 1024;
    
    // Padding adaptatif selon la taille d'écran
    final horizontalPadding = isSmallScreen ? 16.0 : isTablet ? 24.0 : 40.0;
    final verticalPadding = isSmallScreen ? 16.0 : 24.0;
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête principal
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.school,
                  size: isSmallScreen ? 48 : isTablet ? 56 : 64,
                  color: Colors.white,
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  'Préparation au Concours ENA',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 20 : isTablet ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Text(
                  'Préparez-vous efficacement au concours d\'entrée à l\'École Nationale d\'Administration',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 12 : isTablet ? 14 : 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 20 : 32),

          // Section À propos du concours
          _buildSection(
            title: 'À propos du concours ENA',
            icon: Icons.info_outline,
            context: context,
            isSmallScreen: isSmallScreen,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  'Épreuves du concours',
                  'Le concours d\'entrée à l\'ENA comprend plusieurs épreuves écrites et orales couvrant différents domaines.',
                  Icons.description,
                  context,
                  isSmallScreen: isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildInfoCard(
                  'Conditions d\'admission',
                  'Diplôme universitaire requis, âge limite, nationalité congolaise et autres critères spécifiques.',
                  Icons.checklist,
                  context,
                  isSmallScreen: isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildInfoCard(
                  'Calendrier',
                  'Inscriptions, dates des épreuves, résultats et calendrier de formation.',
                  Icons.calendar_today,
                  context,
                  isSmallScreen: isSmallScreen,
                ),
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 20 : 32),

          // Section Matières d'étude
          _buildSection(
            title: 'Matières d\'étude',
            icon: Icons.library_books,
            context: context,
            isSmallScreen: isSmallScreen,
            content: _buildSubjectsGrid(context, isSmallScreen, isTablet, isDesktop),
          ),

          SizedBox(height: isSmallScreen ? 20 : 32),

          // Boutons d'action principaux
          _buildActionButtons(context, isSmallScreen),

          SizedBox(height: isSmallScreen ? 20 : 32),

          // Section Conseils
          _buildSection(
            title: 'Conseils de préparation',
            icon: Icons.lightbulb_outline,
            context: context,
            isSmallScreen: isSmallScreen,
            content: Column(
              children: [
                _buildTipCard(
                  'Planifiez votre révision',
                  'Établissez un planning d\'étude régulier et respectez-le.',
                  Icons.schedule,
                  context,
                  isSmallScreen: isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildTipCard(
                  'Pratiquez avec des QCM',
                  'Entraînez-vous régulièrement avec notre système de quiz.',
                  Icons.quiz,
                  context,
                  isSmallScreen: isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildTipCard(
                  'Restez informé',
                  'Suivez l\'actualité politique, économique et sociale de la RDC.',
                  Icons.newspaper,
                  context,
                  isSmallScreen: isSmallScreen,
                ),
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 32 : 48),
        ],
      ),
    );
  }

  Widget _buildSubjectsGrid(BuildContext context, bool isSmallScreen, bool isTablet, bool isDesktop) {
    final subjects = [
      {'name': 'Droit Public', 'icon': Icons.gavel},
      {'name': 'Économie', 'icon': Icons.trending_up},
      {'name': 'Sciences Politiques', 'icon': Icons.policy},
      {'name': 'Histoire de la RDC', 'icon': Icons.history_edu},
      {'name': 'Culture Générale', 'icon': Icons.public},
      {'name': 'Gestion Publique', 'icon': Icons.business},
    ];

    if (isSmallScreen) {
      return Column(
        children: subjects.map((subject) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSubjectCard(
              subject['name'] as String,
              subject['icon'] as IconData,
              context,
              isSmallScreen: isSmallScreen,
            ),
          )
        ).toList(),
      );
    } else {
      final crossAxisCount = isTablet ? 2 : 3;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isTablet ? 1.3 : 1.5,
        ),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          return _buildSubjectCard(
            subject['name'] as String,
            subject['icon'] as IconData,
            context,
            isSmallScreen: isSmallScreen,
          );
        },
      );
    }
  }

  Widget _buildActionButtons(BuildContext context, bool isSmallScreen) {
    return Column(
      children: [
        // Bouton Guide PDF
        SizedBox(
          width: double.infinity,
          height: isSmallScreen ? 56 : 64,
          child: ElevatedButton(
            onPressed: () => _openGuideENA(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.picture_as_pdf, size: isSmallScreen ? 20 : 24),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Flexible(
                  child: Text(
                    'Télécharger le Guide de préparation',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: isSmallScreen ? 12 : 16),

        // Bouton Quiz
        SizedBox(
          width: double.infinity,
          height: isSmallScreen ? 56 : 64,
          child: ElevatedButton(
            onPressed: () => _navigateToQuiz(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz, size: isSmallScreen ? 20 : 24),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Text(
                  'Commencer le Quiz',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget content,
    required BuildContext context,
    required bool isSmallScreen,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: isSmallScreen ? 20 : 24),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String description,
    IconData icon,
    BuildContext context, {
    required bool isSmallScreen,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: isSmallScreen ? 18 : 20),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 13 : 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
    String subject,
    IconData icon,
    BuildContext context, {
    required bool isSmallScreen,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: isSmallScreen ? 24 : 32),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            subject,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 11 : 12,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(
    String title,
    String description,
    IconData icon,
    BuildContext context, {
    required bool isSmallScreen,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: isSmallScreen ? 18 : 20),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 13 : 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openGuideENA(BuildContext context) async {
    // URL du guide ENA officiel
    const String guideUrl =
        "https://ena.cd/wp-content/uploads/2025/06/GUIDE-DE-PREPA-AU-CONCOURS-DENTREE-A-LENA-RDC-1-1.pdf";

    try {
      final Uri uri = Uri.parse(guideUrl);

      // Essayer d'abord avec le mode platformDefault
      bool success = await launchUrl(uri);

      if (!success) {
        // Si ça ne marche pas, essayer avec externalApplication
        success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (!success) {
        // Si ça ne marche toujours pas, essayer avec inAppWebView
        success = await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }

      if (!success) {
        // Notification d'erreur si aucune méthode ne fonctionne
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Impossible d'ouvrir le guide PDF. Vérifiez votre connexion internet.",
            ),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: "Réessayer",
              onPressed: () => _openGuideENA(context),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToQuiz(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuizContent()),
    );
  }
}
