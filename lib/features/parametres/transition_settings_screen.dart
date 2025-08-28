import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/transition_preferences_service.dart';
import '../../widgets/page_transitions.dart';

/// Page de paramètres pour personnaliser les transitions
class TransitionSettingsScreen extends StatefulWidget {
  const TransitionSettingsScreen({super.key});

  @override
  State<TransitionSettingsScreen> createState() => _TransitionSettingsScreenState();
}

class _TransitionSettingsScreenState extends State<TransitionSettingsScreen> {
  PageTransitionType _selectedType = PageTransitionType.slideAndFade;
  SlideDirection _selectedDirection = SlideDirection.rightToLeft;
  double _selectedDuration = 300;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentPreferences();
  }

  Future<void> _loadCurrentPreferences() async {
    final preferences = await TransitionPreferencesService.loadTransitionPreferences();
    setState(() {
      _selectedType = preferences.transitionType;
      _selectedDirection = preferences.direction;
      _selectedDuration = preferences.durationMs.toDouble();
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);
    
    try {
      await TransitionPreferencesService.saveTransitionPreferences(
        transitionType: _selectedType,
        durationMs: _selectedDuration.round(),
        direction: _selectedDirection,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Paramètres de transition sauvegardés !',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Erreur lors de la sauvegarde: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _testCurrentTransition() {
    PageTransitions.push(
      context,
      _TransitionTestPage(
        transitionType: _selectedType,
        duration: Duration(milliseconds: _selectedDuration.round()),
        direction: _selectedDirection,
      ),
      type: _selectedType,
      duration: Duration(milliseconds: _selectedDuration.round()),
      slideDirection: _selectedDirection,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Personnaliser les transitions',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Personnaliser les transitions',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          // Bouton de réinitialisation
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Réinitialiser',
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await TransitionPreferencesService.resetToDefault();
              await _loadCurrentPreferences();
              if (!mounted) return;
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                    '🔄 Paramètres réinitialisés',
                    style: GoogleFonts.poppins(),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête d'explication
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Personnalisez les animations de navigation selon vos préférences. Ces paramètres s\'appliqueront à toute l\'application.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Section Type de transition
            _buildSectionTitle('Type de transition', Icons.animation),
            const SizedBox(height: 16),
            
            ..._buildTransitionTypeOptions(),
            
            const SizedBox(height: 24),

            // Section Direction (si applicable)
            if (_isDirectionApplicable()) ...[
              _buildSectionTitle('Direction de l\'animation', Icons.arrow_forward),
              const SizedBox(height: 16),
              ..._buildDirectionOptions(),
              const SizedBox(height: 24),
            ],

            // Section Vitesse
            _buildSectionTitle('Vitesse de l\'animation', Icons.speed),
            const SizedBox(height: 16),
            _buildSpeedSlider(),
            
            const SizedBox(height: 32),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testCurrentTransition,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      'Tester',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _savePreferences,
                    icon: const Icon(Icons.save),
                    label: Text(
                      'Sauvegarder',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.headlineSmall?.color,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTransitionTypeOptions() {
    final transitionOptions = [
      (PageTransitionType.slideAndFade, 'Slide & Fade', 'Animation moderne et fluide', Icons.arrow_forward),
      (PageTransitionType.fadeAndScale, 'Fade & Scale', 'Élégant avec zoom subtil', Icons.zoom_in),
      (PageTransitionType.sharedAxis, 'Shared Axis', 'Material Design 3', Icons.swap_horiz),
      (PageTransitionType.fadeThrough, 'Fade Through', 'Transition douce et seamless', Icons.blur_on),
      (PageTransitionType.formTransition, 'Form Transition', 'Spécialement pour les formulaires', Icons.edit_document),
      (PageTransitionType.quickSlide, 'Quick Slide', 'Rapide et direct', Icons.flash_on),
    ];

    return transitionOptions.map((option) {
      final (type, name, description, icon) = option;
      return _buildOptionCard(
        title: name,
        description: description,
        icon: icon,
        isSelected: _selectedType == type,
        onTap: () => setState(() => _selectedType = type),
      );
    }).toList();
  }

  List<Widget> _buildDirectionOptions() {
    final directionOptions = [
      (SlideDirection.rightToLeft, 'Droite vers Gauche', '→ ←'),
      (SlideDirection.leftToRight, 'Gauche vers Droite', '← →'),
      (SlideDirection.topToBottom, 'Haut vers Bas', '↓'),
      (SlideDirection.bottomToTop, 'Bas vers Haut', '↑'),
    ];

    return directionOptions.map((option) {
      final (direction, name, symbol) = option;
      return _buildOptionCard(
        title: name,
        description: symbol,
        icon: Icons.arrow_forward,
        isSelected: _selectedDirection == direction,
        onTap: () => setState(() => _selectedDirection = direction),
      );
    }).toList();
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                      : theme.colorScheme.outline.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedSlider() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lente',
              style: GoogleFonts.poppins(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_selectedDuration.round()}ms',
                style: GoogleFonts.poppins(
                  color: theme.colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              'Rapide',
              style: GoogleFonts.poppins(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.outline.withValues(alpha: 0.3),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: _selectedDuration,
            min: 200,
            max: 600,
            divisions: 8,
            onChanged: (value) => setState(() => _selectedDuration = value),
          ),
        ),
      ],
    );
  }

  bool _isDirectionApplicable() {
    return _selectedType == PageTransitionType.slideAndFade ||
           _selectedType == PageTransitionType.quickSlide;
  }
}

// Page de test pour visualiser la transition
class _TransitionTestPage extends StatelessWidget {
  final PageTransitionType transitionType;
  final Duration duration;
  final SlideDirection direction;

  const _TransitionTestPage({
    required this.transitionType,
    required this.duration,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Test de transition',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Transition testée !',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type: ${transitionType.name}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  Text(
                    'Durée: ${duration.inMilliseconds}ms',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  Text(
                    'Direction: ${direction.name}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: Text(
                'Retour aux paramètres',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
}
