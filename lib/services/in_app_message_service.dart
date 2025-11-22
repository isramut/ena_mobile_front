import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animated_popup.dart';

/// Service pour afficher des messages in-app sous forme de dialog centré
class InAppMessageService {
  /// Afficher un dialog de notification push (quand app est ouverte)
  static Future<void> showPushNotificationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String type,  // info, success, error, warning, urgent
    String? link,
  }) async {
    await AnimatedPopup.showAnimatedDialog(
      context: context,
      animationType: AnimationType.fadeScale,
      duration: const Duration(milliseconds: 350),
      barrierDismissible: true,
      child: _buildNotificationDialog(context, title, message, type, link),
    );
  }

  /// Builder du dialog avec design cohérent à l'app
  static Widget _buildNotificationDialog(
    BuildContext context,
    String title,
    String message,
    String type,
    String? link,
  ) {
    final iconData = _getIconForType(type);
    final typeColor = _getColorForType(type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Theme.of(context).cardColor,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône selon type
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: typeColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            
            // Badge type
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                type.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: typeColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Titre
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineSmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Message
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Boutons
            Row(
              children: [
                // Bouton Fermer
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Fermer',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                // Bouton "Voir" si link fourni
                if (link != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Le callback de navigation sera géré par PushNotificationService
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark 
                            ? const Color(0xFF3B82F6) 
                            : const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Voir',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Obtenir l'icône Material selon le type
  static IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'success':
      case 'succès':
        return Icons.check_circle;
      case 'error':
      case 'erreur':
        return Icons.error;
      case 'warning':
      case 'avertissement':
        return Icons.warning;
      case 'urgent':
      case 'alerte':
        return Icons.priority_high;
      case 'info':
      default:
        return Icons.info;
    }
  }

  /// Obtenir la couleur selon le type
  static Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'success':
      case 'succès':
        return const Color(0xFF10B981); // Vert
      case 'error':
      case 'erreur':
        return const Color(0xFFEF4444); // Rouge
      case 'warning':
      case 'avertissement':
        return const Color(0xFFF59E0B); // Orange
      case 'urgent':
      case 'alerte':
        return const Color(0xFFEF4444); // Rouge urgent
      case 'info':
      default:
        return const Color(0xFF3678FF); // Bleu
    }
  }
}
