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
                  'Le concours d\'entrée à l\'ENA comprend une épreuve écrite de dissertation (4h) et une épreuve orale (20 min maximum).',
                  Icons.description,
                  context,
                  isSmallScreen: isSmallScreen,
                  cardColor: const Color(0xFF3B82F6), // Bleu
                  onTap: () => _showInfoDialog(context, 'epreuves'),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildInfoCard(
                  'Conditions d\'admission',
                  'Diplôme universitaire requis, âge limite, nationalité congolaise et autres critères spécifiques.',
                  Icons.checklist,
                  context,
                  isSmallScreen: isSmallScreen,
                  cardColor: const Color(0xFF10B981), // Vert
                  onTap: () => _showInfoDialog(context, 'conditions'),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildInfoCard(
                  'Calendrier',
                  'Inscriptions, dates des épreuves, résultats et calendrier de formation.',
                  Icons.calendar_today,
                  context,
                  isSmallScreen: isSmallScreen,
                  cardColor: const Color(0xFFF59E0B), // Orange
                  onTap: () => _showInfoDialog(context, 'calendrier'),
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
                  cardColor: const Color(0xFF8B5CF6), // Violet
                  onTap: () => _showTipDialog(context, 'planning'),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildTipCard(
                  'Pratiquez avec des QCM',
                  'Entraînez-vous régulièrement avec notre système de quiz.',
                  Icons.quiz,
                  context,
                  isSmallScreen: isSmallScreen,
                  cardColor: const Color(0xFF06B6D4), // Cyan
                  onTap: () => _showTipDialog(context, 'practice'),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _buildTipCard(
                  'Restez informé',
                  'Suivez l\'actualité politique, économique et sociale de la RDC.',
                  Icons.newspaper,
                  context,
                  isSmallScreen: isSmallScreen,
                  cardColor: const Color(0xFFEC4899), // Rose
                  onTap: () => _showTipDialog(context, 'information'),
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
      {'name': 'Droit Public', 'icon': Icons.gavel, 'color': const Color(0xFF3B82F6)}, // Bleu
      {'name': 'Économie', 'icon': Icons.trending_up, 'color': const Color(0xFF10B981)}, // Vert
      {'name': 'Sciences Politiques', 'icon': Icons.policy, 'color': const Color(0xFF8B5CF6)}, // Violet
      {'name': 'Histoire de la RDC', 'icon': Icons.history_edu, 'color': const Color(0xFFF59E0B)}, // Orange
      {'name': 'Culture Générale', 'icon': Icons.public, 'color': const Color(0xFFEF4444)}, // Rouge
      {'name': 'Gestion Publique', 'icon': Icons.business, 'color': const Color(0xFF06B6D4)}, // Cyan
    ];

    // Configuration de la grille selon la taille d'écran
    final int crossAxisCount;
    final double childAspectRatio;
    final double spacing = isSmallScreen ? 12.0 : 16.0;
    
    if (isSmallScreen) {
      crossAxisCount = 2; // 2 colonnes sur mobile
      childAspectRatio = 1.0; // Ratio carré
    } else if (isTablet) {
      crossAxisCount = 3; // 3 colonnes sur tablette
      childAspectRatio = 1.1;
    } else {
      crossAxisCount = 3; // 3 colonnes sur desktop
      childAspectRatio = 1.2;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return _buildSubjectCard(
          subject['name'] as String,
          subject['icon'] as IconData,
          subject['color'] as Color,
          context,
          isSmallScreen: isSmallScreen,
          onTap: () => _showSubjectDialog(context, subject['name'] as String),
        );
      },
    );
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
    Color? cardColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Couleur de base adaptée au thème
    final baseColor = cardColor ?? theme.colorScheme.secondary;
    final backgroundColor = isDark 
        ? baseColor.withValues(alpha: 0.15)
        : baseColor.withValues(alpha: 0.08);
    final borderColor = isDark
        ? baseColor.withValues(alpha: 0.3)
        : baseColor.withValues(alpha: 0.2);
    final iconColor = isDark
        ? baseColor.withValues(alpha: 0.9)
        : baseColor;
        
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon, 
                color: iconColor, 
                size: isSmallScreen ? 18 : 20,
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
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
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                  if (onTap != null) ...[
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Row(
                      children: [
                        Text(
                          'Voir les détails',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 10 : 11,
                            fontWeight: FontWeight.w500,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: isSmallScreen ? 10 : 12,
                          color: iconColor,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(
    String subject,
    IconData icon,
    Color subjectColor,
    BuildContext context, {
    required bool isSmallScreen,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Couleurs adaptées au thème
    final backgroundColor = isDark 
        ? subjectColor.withValues(alpha: 0.15)
        : subjectColor.withValues(alpha: 0.08);
    final borderColor = isDark
        ? subjectColor.withValues(alpha: 0.3)
        : subjectColor.withValues(alpha: 0.2);
    final iconColor = isDark
        ? subjectColor.withValues(alpha: 0.9)
        : subjectColor;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: subjectColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon, 
                color: iconColor, 
                size: isSmallScreen ? 24 : 32,
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              subject,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 11 : 13,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (onTap != null) ...[
              SizedBox(height: isSmallScreen ? 4 : 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: isSmallScreen ? 10 : 12,
                    color: iconColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Détails',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 9 : 10,
                      fontWeight: FontWeight.w500,
                      color: iconColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(
    String title,
    String description,
    IconData icon,
    BuildContext context, {
    required bool isSmallScreen,
    Color? cardColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Couleur de base adaptée au thème
    final baseColor = cardColor ?? theme.colorScheme.secondary;
    final backgroundColor = isDark 
        ? baseColor.withValues(alpha: 0.15)
        : baseColor.withValues(alpha: 0.08);
    final borderColor = isDark
        ? baseColor.withValues(alpha: 0.3)
        : baseColor.withValues(alpha: 0.2);
    final iconColor = isDark
        ? baseColor.withValues(alpha: 0.9)
        : baseColor;
        
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon, 
                color: iconColor, 
                size: isSmallScreen ? 18 : 20,
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
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
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                  if (onTap != null) ...[
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Row(
                      children: [
                        Text(
                          'Voir les conseils détaillés',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 10 : 11,
                            fontWeight: FontWeight.w500,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: isSmallScreen ? 10 : 12,
                          color: iconColor,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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

  // Méthode pour afficher les dialogues d'information
  void _showInfoDialog(BuildContext context, String type) {
    final Map<String, Map<String, dynamic>> dialogData = {
      'epreuves': {
        'title': 'Épreuves du concours ENA',
        'icon': Icons.description,
        'color': const Color(0xFF3B82F6),
        'content': _buildEpreuvesContent(context),
      },
      'conditions': {
        'title': 'Conditions d\'admission',
        'icon': Icons.checklist,
        'color': const Color(0xFF10B981),
        'content': _buildConditionsContent(context),
      },
      'calendrier': {
        'title': 'Calendrier du concours',
        'icon': Icons.calendar_today,
        'color': const Color(0xFFF59E0B),
        'content': _buildCalendrierContent(context),
      },
    };

    final data = dialogData[type];
    if (data == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête du dialogue
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: data['color'].withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        data['icon'],
                        color: data['color'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Fermer',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Contenu du dialogue
                Expanded(
                  child: SingleChildScrollView(
                    child: data['content'],
                  ),
                ),
                const SizedBox(height: 16),
                // Bouton de fermeture
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: data['color'],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Compris',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Contenu pour le dialogue des épreuves
  Widget _buildEpreuvesContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionItem(
          'Épreuves écrites',
          [
            'Cette épreuve contient un sujet de dissertation que les candidats doivent développer pendant 4 heures. Elle est organisée en même temps dans chaque chef-lieu de province de la République Démocratique du Congo.',
          ],
          Icons.edit,
          const Color(0xFF3B82F6),
          context,
        ),
        const SizedBox(height: 16),
        _buildSectionItem(
          'Épreuve orale',
          [
            'Considérée comme une interview, la durée maximum de cette épreuve est de 20 minutes. Les critères d\'évaluation sont les suivants :',
            '• Présentation et motivation',
            '• Formation et compétence',
            '• Test de personnalité',
            '• Ethique, déontologie et bonne gouvernance dans l\'administration publique',
            '• Test d\'opinion et culture générale.',
          ],
          Icons.mic,
          const Color(0xFF3B82F6),
          context,
        ),
        const SizedBox(height: 16),
        _buildInfoBox(
          'Durée totale : 4 heures d\'épreuve écrite + 20 minutes d\'entretien oral',
          Icons.schedule,
          const Color(0xFF3B82F6),
          context,
        ),
      ],
    );
  }

  // Contenu pour le dialogue des conditions
  Widget _buildConditionsContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConditionCard('Nationalité', 'Être de nationalité congolaise (RDC)', Icons.flag, context),
        _buildConditionCard('Âge', 'Avoir entre 18 ans minimum et 35 ans maximum à la date du début de la scolarité', Icons.cake, context),
        _buildConditionCard('Diplôme', 'Licence universitaire ou équivalent', Icons.school, context),
        _buildConditionCard('Santé', 'Certificat médical d\'aptitude physique établi dans un hôpital public', Icons.health_and_safety, context),
        _buildConditionCard('Relevé des notes', 'Relevé des notes de la dernière année', Icons.grade, context),
        _buildConditionCard('Engagement', 'Servir l\'État pendant au moins 7 ans', Icons.handshake, context),
        const SizedBox(height: 16),
        _buildInfoBox(
          'Tous les documents doivent être authentifiés et en cours de validité',
          Icons.verified_user,
          const Color(0xFF10B981),
          context,
        ),
      ],
    );
  }

  // Contenu pour le dialogue du calendrier
  Widget _buildCalendrierContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendrierCard('Inscriptions', 'Janvier - Février', 'Dépôt des dossiers', Icons.app_registration, context),
        _buildCalendrierCard('Clôture', 'Mars', 'Date limite de candidature', Icons.close, context),
        _buildCalendrierCard('Épreuves écrites', 'Avril - Mai', 'Examens dans les centres', Icons.edit, context),
        _buildCalendrierCard('Résultats écrits', 'Juin', 'Liste des admissibles', Icons.article, context),
        _buildCalendrierCard('Épreuve orale', 'Juillet', 'Entretiens avec le jury', Icons.mic, context),
        _buildCalendrierCard('Résultats finaux', 'Août', 'Liste définitive des admis', Icons.emoji_events, context),
        _buildCalendrierCard('Rentrée', 'Septembre', 'Début de la formation', Icons.school, context),
        const SizedBox(height: 16),
        _buildInfoBox(
          'Les dates peuvent varier selon les décisions du Ministère',
          Icons.info,
          const Color(0xFFF59E0B),
          context,
        ),
      ],
    );
  }

  // Widgets helper
  Widget _buildSectionItem(String title, List<String> items, IconData icon, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildConditionCard(String title, String description, IconData icon, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: const Color(0xFF10B981), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendrierCard(String title, String periode, String description, IconData icon, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: const Color(0xFFF59E0B), size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          periode,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String text, IconData icon, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour afficher les dialogues d'information sur les matières
  void _showSubjectDialog(BuildContext context, String subject) {
    final Map<String, Map<String, dynamic>> subjectData = {
      'Droit Public': {
        'color': const Color(0xFF3B82F6),
        'icon': Icons.gavel,
        'description': 'Étude des règles juridiques qui régissent l\'organisation et le fonctionnement de l\'État et de ses institutions.',
        'topics': [
          'Droit constitutionnel congolais',
          'Droit administratif',
          'Institutions publiques de la RDC',
          'Procédures administratives',
          'Contentieux administratif',
          'Service public et administration',
        ],
        'importance': 'Matière fondamentale pour comprendre le cadre juridique de l\'administration publique congolaise.',
      },
      'Économie': {
        'color': const Color(0xFF10B981),
        'icon': Icons.trending_up,
        'description': 'Analyse des mécanismes économiques et de la gestion des finances publiques.',
        'topics': [
          'Microéconomie et macroéconomie',
          'Économie du développement',
          'Finances publiques',
          'Politique budgétaire',
          'Économie congolaise',
          'Commerce international',
        ],
        'importance': 'Essentielle pour la compréhension des enjeux économiques du pays et la gestion publique.',
      },
      'Sciences Politiques': {
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.policy,
        'description': 'Étude des systèmes politiques, des institutions et des relations de pouvoir.',
        'topics': [
          'Systèmes politiques comparés',
          'Relations internationales',
          'Politique congolaise',
          'Géopolitique africaine',
          'Organisations internationales',
          'Diplomatie et négociation',
        ],
        'importance': 'Cruciale pour comprendre l\'environnement politique national et international.',
      },
      'Histoire de la RDC': {
        'color': const Color(0xFFF59E0B),
        'icon': Icons.history_edu,
        'description': 'Étude approfondie de l\'histoire du Congo de la période précoloniale à nos jours.',
        'topics': [
          'Congo précolonial et royaumes',
          'Période coloniale belge',
          'Indépendance et première République',
          'Ère Mobutu (Zaïre)',
          'Guerres et transitions',
          'République Démocratique moderne',
        ],
        'importance': 'Fondamentale pour comprendre les enjeux actuels et l\'identité nationale.',
      },
      'Culture Générale': {
        'color': const Color(0xFFEF4444),
        'icon': Icons.public,
        'description': 'Connaissances générales sur le monde contemporain, les arts, les sciences et la société.',
        'topics': [
          'Actualité nationale et internationale',
          'Géographie mondiale et africaine',
          'Sciences et technologies',
          'Arts et littérature',
          'Philosophie et sociologie',
          'Religions et cultures',
        ],
        'importance': 'Nécessaire pour développer une vision globale et une capacité d\'analyse critique.',
      },
      'Gestion Publique': {
        'color': const Color(0xFF06B6D4),
        'icon': Icons.business,
        'description': 'Principes et techniques de management appliqués à l\'administration publique.',
        'topics': [
          'Management public moderne',
          'Planification stratégique',
          'Gestion des ressources humaines',
          'Contrôle de gestion publique',
          'Évaluation des politiques publiques',
          'Réformes administratives',
        ],
        'importance': 'Essentielle pour moderniser et améliorer l\'efficacité de l\'administration.',
      },
    };

    final data = subjectData[subject];
    if (data == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête du dialogue
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: data['color'].withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        data['icon'],
                        color: data['color'],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Matière d\'étude ENA',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: data['color'],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Fermer',
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Description
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: data['color'].withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data['description'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Sujets d'étude
                Text(
                  'Sujets d\'étude principaux',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: (data['topics'] as List<String>).map((topic) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: data['color'],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  topic,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Importance
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: data['color'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: data['color'].withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb, color: data['color'], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['importance'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Bouton de fermeture
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: data['color'],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Compris',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Méthode pour afficher les dialogues de conseils de préparation
  void _showTipDialog(BuildContext context, String tipType) {
    final Map<String, Map<String, dynamic>> tipData = {
      'planning': {
        'title': 'Planification de révision',
        'icon': Icons.schedule,
        'color': const Color(0xFF8B5CF6),
        'description': 'Créez un planning d\'étude structuré et efficace pour maximiser vos chances de réussite au concours ENA.',
        'tips': [
          {
            'title': 'Évaluation initiale',
            'content': 'Faites un bilan de vos connaissances dans chaque matière pour identifier vos points forts et faibles.',
            'icon': Icons.assessment,
          },
          {
            'title': 'Planning personnalisé',
            'content': 'Consacrez plus de temps aux matières où vous êtes faible tout en maintenant vos points forts.',
            'icon': Icons.calendar_view_week,
          },
          {
            'title': 'Objectifs réalistes',
            'content': 'Fixez-vous des objectifs quotidiens et hebdomadaires atteignables pour maintenir votre motivation.',
            'icon': Icons.flag,
          },
          {
            'title': 'Pauses régulières',
            'content': 'Intégrez des pauses de 15-20 minutes toutes les 2 heures pour optimiser votre concentration.',
            'icon': Icons.coffee,
          },
          {
            'title': 'Révisions cycliques',
            'content': 'Révisez régulièrement les sujets déjà étudiés pour ancrer durablement vos connaissances.',
            'icon': Icons.refresh,
          },
        ],
        'bonus': 'Utilisez la technique Pomodoro : 25 minutes d\'étude intensive suivies de 5 minutes de pause.',
      },
      'practice': {
        'title': 'Pratique avec les QCM',
        'icon': Icons.quiz,
        'color': const Color(0xFF06B6D4),
        'description': 'Maîtrisez l\'art des questionnaires à choix multiples pour exceller aux épreuves du concours ENA.',
        'tips': [
          {
            'title': 'Entraînement quotidien',
            'content': 'Consacrez au moins 1 heure par jour à la résolution de QCM dans différentes matières.',
            'icon': Icons.timer,
          },
          {
            'title': 'Analyse des erreurs',
            'content': 'Analysez chaque erreur pour comprendre la logique et éviter de la répéter à l\'avenir.',
            'icon': Icons.analytics,
          },
          {
            'title': 'Gestion du temps',
            'content': 'Chronométrez-vous pour vous habituer à la pression temporelle des examens réels.',
            'icon': Icons.schedule,
          },
          {
            'title': 'Questions pièges',
            'content': 'Apprenez à identifier et éviter les questions pièges en lisant attentivement chaque énoncé.',
            'icon': Icons.warning,
          },
          {
            'title': 'Simulation d\'examen',
            'content': 'Faites des simulations complètes dans les conditions réelles d\'examen une fois par semaine.',
            'icon': Icons.school,
          },
        ],
        'bonus': 'Notre plateforme propose plus de 5000 QCM actualisés régulièrement par des experts ENA.',
      },
      'information': {
        'title': 'Rester informé',
        'icon': Icons.newspaper,
        'color': const Color(0xFFEC4899),
        'description': 'Maintenez-vous à jour sur l\'actualité nationale et internationale pour exceller en culture générale.',
        'tips': [
          {
            'title': 'Sources fiables',
            'content': 'Consultez quotidiennement des sources d\'information crédibles : journaux nationaux, sites officiels, médias internationaux.',
            'icon': Icons.verified,
          },
          {
            'title': 'Diversité thématique',
            'content': 'Couvrez tous les domaines : politique, économie, société, culture, sciences, sport, environnement.',
            'icon': Icons.category,
          },
          {
            'title': 'Prise de notes',
            'content': 'Tenez un carnet d\'actualités avec les événements marquants, dates importantes et personnalités clés.',
            'icon': Icons.note_add,
          },
          {
            'title': 'Analyse critique',
            'content': 'Ne vous contentez pas de lire, analysez les implications et les enjeux des événements d\'actualité.',
            'icon': Icons.psychology,
          },
          {
            'title': 'Révision régulière',
            'content': 'Révisez votre carnet d\'actualités chaque semaine pour mémoriser les informations importantes.',
            'icon': Icons.history,
          },
        ],
        'bonus': 'Abonnez-vous aux newsletters de qualité et suivez les comptes officiels des institutions.',
      },
    };

    final data = tipData[tipType];
    if (data == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête du dialogue
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: data['color'].withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        data['icon'],
                        color: data['color'],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'],
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Conseils de préparation ENA',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: data['color'],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Fermer',
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Description
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: data['color'].withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data['description'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Conseils
                Text(
                  'Conseils pratiques',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: (data['tips'] as List<Map<String, dynamic>>).map((tip) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: data['color'].withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: data['color'].withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    tip['icon'] as IconData,
                                    color: data['color'],
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tip['title'] as String,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tip['content'] as String,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Conseil bonus
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: data['color'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: data['color'].withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tips_and_updates, color: data['color'], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conseil bonus',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: data['color'],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data['bonus'],
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Bouton de fermeture
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: data['color'],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Merci pour les conseils !',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
