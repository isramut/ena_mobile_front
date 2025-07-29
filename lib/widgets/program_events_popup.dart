import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/program_event.dart';
import '../features/calendar/calendar_screen.dart';
import '../utils/app_navigator.dart';
import 'animated_popup.dart';

class ProgramEventsPopup extends StatelessWidget {
  final List<ProgramEvent> events;

  const ProgramEventsPopup({
    super.key,
    required this.events,
  });

  static void show(BuildContext context, List<ProgramEvent> events) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // BackdropFilter pour flouter l'arrière-plan
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: animation.value * 5.0,
                    sigmaY: animation.value * 5.0,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: animation.value * 0.1),
                  ),
                ),
              ),
              // Popup content avec animations
              Center(
                child: FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.9,
                      end: 1.0,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    )),
                    child: ProgramEventsPopup(events: events),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          maxHeight: screenHeight * 0.8,
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
              // En-tête du popup
              _buildHeader(theme, context, isNarrowScreen),
              
              // Contenu scrollable
              Flexible(
                child: events.isEmpty 
                    ? _buildEmptyState(theme)
                    : _buildEventsList(theme, isNarrowScreen),
              ),
              
              // Bouton "Consulter tout le calendrier"
              _buildFooterButton(theme, context, isNarrowScreen),
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
          vertical: isNarrowScreen ? 16 : 20,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: isNarrowScreen ? 24 : 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Programme & calendrier",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isNarrowScreen ? 16 : 18,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 48,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "Aucun programme disponible",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Il n'y a actuellement aucun événement programmé.",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(ThemeData theme, bool isNarrowScreen) {
    return AnimatedPopupChild(
      delay: const Duration(milliseconds: 200),
      child: ListView.separated(
        padding: EdgeInsets.all(isNarrowScreen ? 16 : 20),
        shrinkWrap: true,
        itemCount: events.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final event = events[index];
          return AnimatedPopupChild(
            delay: Duration(milliseconds: 250 + (index * 50)),
            child: _buildEventCard(event, theme, isNarrowScreen),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(ProgramEvent event, ThemeData theme, bool isNarrowScreen) {
    return Container(
      padding: EdgeInsets.all(isNarrowScreen ? 14 : 16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface.withValues(alpha: 0.5)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre et statut
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.name,
                  style: GoogleFonts.poppins(
                    fontSize: isNarrowScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusChip(event, theme),
            ],
          ),
          const SizedBox(height: 8),
          
          // Description
          if (event.description.isNotEmpty) ...[
            Text(
              event.description,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          
          // Informations compactes
          _buildCompactInfo(Icons.calendar_today_rounded, event.formattedPeriod, theme),
          const SizedBox(height: 4),
          _buildCompactInfo(Icons.location_on_rounded, event.location, theme),
          if (event.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildCompactInfo(Icons.notes_rounded, event.notes, theme, maxLines: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(ProgramEvent event, ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    
    switch (event.status) {
      case 'En cours':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        break;
      case 'À venir':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        event.status,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildCompactInfo(IconData icon, String text, ThemeData theme, {int? maxLines}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text.isNotEmpty ? text : '-',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterButton(ThemeData theme, BuildContext context, bool isNarrowScreen) {
    return AnimatedPopupChild(
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: EdgeInsets.all(isNarrowScreen ? 16 : 20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer le popup
              AppNavigator.push(
                context,
                const CalendarScreen(),
              );
            },
            icon: const Icon(Icons.calendar_view_month_rounded, size: 20),
            label: Text(
              "Consulter tout le calendrier",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: isNarrowScreen ? 14 : 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                vertical: isNarrowScreen ? 12 : 14,
              ),
              elevation: 2,
            ),
          ),
        ),
      ),
    );
  }
}
