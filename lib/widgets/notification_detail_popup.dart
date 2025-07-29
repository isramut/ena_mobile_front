import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import '../services/auth_api_service.dart';
import 'animated_popup.dart';

class NotificationDetailPopup extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onMarkAsRead;

  const NotificationDetailPopup({
    super.key,
    required this.notification,
    this.onMarkAsRead,
  });

  static Future<void> show(
    BuildContext context,
    NotificationModel notification, {
    VoidCallback? onMarkAsRead,
  }) async {
    await AnimatedPopup.showAnimatedDialog<void>(
      context: context,
      animationType: AnimationType.blurBackdrop,
      duration: const Duration(milliseconds: 400),
      child: NotificationDetailPopup(
        notification: notification,
        onMarkAsRead: onMarkAsRead,
      ),
    );
    
    // Marquer comme lue automatiquement après fermeture du popup
    if (!notification.isRead) {
      await _markNotificationAsRead(notification.id);
      onMarkAsRead?.call();
    }
  }

  static Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        await AuthApiService.markNotificationAsRead(
          token: token,
          notificationId: notificationId,
        );
      }
    } catch (e) {
      // Gérer silencieusement l'erreur
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isNarrowScreen = screenWidth < 400;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isNarrowScreen ? screenWidth * 0.95 : 500,
          maxHeight: screenHeight * 0.7,
        ),
        child: Card(
          elevation: 16,
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête avec icône de type et bouton fermer
              _buildHeader(theme, context, isNarrowScreen),
              
              // Contenu de la notification
              Flexible(
                child: _buildContent(theme, isNarrowScreen),
              ),
              
              // Pied avec date et statut
              _buildFooter(theme, isNarrowScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, BuildContext context, bool isNarrowScreen) {
    return AnimatedPopupChild(
      delay: const Duration(milliseconds: 100),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isNarrowScreen ? 16 : 20,
          vertical: isNarrowScreen ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: notification.typeColor.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: notification.typeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notification.typeIcon,
                color: notification.typeColor,
                size: isNarrowScreen ? 20 : 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.poppins(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: isNarrowScreen ? 16 : 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: notification.typeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      notification.type.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: notification.typeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              onPressed: () => Navigator.of(context).pop(),
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isNarrowScreen) {
    return AnimatedPopupChild(
      delay: const Duration(milliseconds: 200),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isNarrowScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message principal
            Text(
              notification.message,
              style: GoogleFonts.poppins(
                fontSize: isNarrowScreen ? 14 : 16,
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
            
            // Lien si disponible
            if (notification.link != null && notification.link!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? theme.colorScheme.surface.withValues(alpha: 0.5)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notification.link!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildFooter(ThemeData theme, bool isNarrowScreen) {
    return AnimatedPopupChild(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: EdgeInsets.all(isNarrowScreen ? 16 : 20),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.surface.withValues(alpha: 0.3)
              : Colors.grey.shade50,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Date de création
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  notification.formattedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            
            // Statut de lecture
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: notification.isRead 
                        ? Colors.grey 
                        : notification.typeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  notification.isRead ? "Lue" : "Non lue",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: notification.isRead 
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                        : notification.typeColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
