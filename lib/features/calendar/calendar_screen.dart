import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/program_event.dart';
import '../../services/program_events_api_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<ProgramEvent> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final result = await ProgramEventsApiService.getUpcomingEvents(token: token);
      
      if (mounted) {
        if (result['success'] == true) {
          final events = result['data'] as List<ProgramEvent>?;
          setState(() {
            _events = events ?? [];
            _isLoading = false;
          });
        } else {
          // Distinguer les vraies erreurs des réponses vides
          final errorMessage = result['error']?.toString() ?? '';
          
          // Si l'erreur indique qu'il n'y a pas d'événements, traiter comme un cas normal
          if (errorMessage.toLowerCase().contains('aucun événement') ||
              errorMessage.toLowerCase().contains('no events') ||
              errorMessage.toLowerCase().contains('pas d\'événement') ||
              result['data'] is List && (result['data'] as List).isEmpty) {
            setState(() {
              _events = [];
              _isLoading = false;
            });
          } else {
            setState(() {
              _error = errorMessage.isNotEmpty ? errorMessage : 'Erreur lors du chargement des événements';
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur de connexion au serveur';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          "Calendrier des programmes",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: _loadEvents,
            tooltip: "Actualiser",
          ),
        ],
      ),
      body: _buildBody(theme, isNarrowScreen),
    );
  }

  Widget _buildBody(ThemeData theme, bool isNarrowScreen) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorState(theme);
    }

    if (_events.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _buildEventsList(theme, isNarrowScreen);
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              "Erreur de chargement",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? "Une erreur s'est produite",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadEvents,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                "Réessayer",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              "Aucun événement en cours",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Il n'y a actuellement aucun événement programmé. Les nouveaux événements du calendrier apparaîtront ici dès qu'ils seront disponibles.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadEvents,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                "Actualiser",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(ThemeData theme, bool isNarrowScreen) {
    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: EdgeInsets.all(isNarrowScreen ? 12 : 16),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return _buildEventCard(event, theme, isNarrowScreen);
        },
      ),
    );
  }

  Widget _buildEventCard(ProgramEvent event, ThemeData theme, bool isNarrowScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.only(bottom: isNarrowScreen ? 12 : 16),
      child: Padding(
        padding: EdgeInsets.all(isNarrowScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec titre et statut
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.name,
                    style: GoogleFonts.poppins(
                      fontSize: isNarrowScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(event, theme),
              ],
            ),
            const SizedBox(height: 12),
            
            // Description
            if (event.description.isNotEmpty) ...[
              Text(
                event.description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Informations détaillées
            _buildInfoRow(Icons.calendar_today_rounded, "Période", event.formattedPeriod, theme),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_rounded, "Lieu", event.location, theme),
            if (event.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.notes_rounded, "Notes", event.notes, theme),
            ],
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        event.status,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '-',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}
