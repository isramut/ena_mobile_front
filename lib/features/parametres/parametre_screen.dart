import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../common/theme_provider.dart';
import '../auth/modifier_mot_de_passe_screen.dart';
import '../../services/biometric_service.dart';
import '../../widgets/error_popup.dart';
import '../../widgets/page_transitions.dart';
import 'transition_settings_screen.dart';
import '../../screens/account_deletion_screen.dart';

class ParametreScreen extends StatefulWidget {
  const ParametreScreen({super.key});

  @override
  State<ParametreScreen> createState() => _ParametreScreenState();
}

class _ParametreScreenState extends State<ParametreScreen> {
  bool notificationsEnabled = true;
  bool newsletter = true;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  String _biometricType = '';
  bool _loadingBiometric = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    setState(() => _loadingBiometric = true);
    
    // Diagnostic complet pour déboguer
    await BiometricAuthService.diagnoseBiometric();
    
    final isAvailable = await BiometricAuthService.isBiometricAvailableOnDevice();
    final isEnabled = await BiometricAuthService.isBiometricEnabled();
    final biometricType = await BiometricAuthService.getPrimaryBiometricType();
    
    if (mounted) {
      setState(() {
        _biometricAvailable = isAvailable;
        _biometricEnabled = isEnabled;
        _biometricType = biometricType;
        _loadingBiometric = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Activer la biométrie - tester d'abord
      final testResult = await BiometricAuthService.testBiometricAuth();
      
      if (!testResult['success']) {
        if (mounted) {
          await ErrorPopup.show(
            context,
            title: "Authentification échouée",
            message: testResult['error'] ?? "Impossible d'activer l'authentification biométrique",
          );
        }
        return;
      }

      // Si le test réussit, on active
      final success = await BiometricAuthService.setBiometricEnabled(true);
      if (success && mounted) {
        setState(() => _biometricEnabled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              testResult['message'] ?? 'Authentification biométrique activée !',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Désactiver la biométrie
      await BiometricAuthService.setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Authentification biométrique désactivée',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  IconData _getBiometricIcon() {
    if (_biometricType.contains('Face')) {
      return Icons.face_rounded;
    } else if (_biometricType.contains('Empreinte')) {
      return Icons.fingerprint_rounded;
    } else if (_biometricType.contains('iris')) {
      return Icons.visibility_rounded;
    } else {
      return Icons.security_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color mainBlue = theme.colorScheme.primary;
    final Color accentBlue = theme.colorScheme.secondary;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            // Bandeau titre
            Card(
              color: theme.colorScheme.primary,
              elevation: 7,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(19),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 19,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Paramètres",
                      style: GoogleFonts.poppins(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      "Personnalisez votre expérience utilisateur.",
                      style: GoogleFonts.poppins(
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.9,
                        ),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notifications
            Card(
              color: Theme.of(context).cardColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              child: SwitchListTile(
                activeColor: accentBlue,
                inactiveThumbColor: Colors.grey,
                title: Text(
                  "Recevoir les notifications",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                value: notificationsEnabled,
                onChanged: (val) => setState(() => notificationsEnabled = val),
                secondary: Icon(
                  Icons.notifications_active_rounded,
                  color: accentBlue,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Options de thème
            Card(
              color: Theme.of(context).cardColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.palette_outlined, color: accentBlue),
                    title: Text(
                      "Thème d'affichage",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Text(
                      _getThemeDescription(themeProvider.themeMode),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    trailing: Icon(
                      _getThemeIcon(themeProvider.themeMode),
                      color: mainBlue,
                    ),
                    onTap: () => _showThemeDialog(context, themeProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Newsletter
            Card(
              color: theme.colorScheme.surface,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              child: SwitchListTile(
                activeColor: accentBlue,
                inactiveThumbColor: Colors.grey,
                title: Text(
                  "Recevoir la newsletter",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                value: newsletter,
                onChanged: (val) => setState(() => newsletter = val),
                secondary: Icon(Icons.mail_outline_rounded, color: accentBlue),
              ),
            ),
            const SizedBox(height: 16),

            // Authentification biométrique
            if (_biometricAvailable)
              Card(
                color: theme.colorScheme.surface,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
                child: SwitchListTile(
                  activeColor: accentBlue,
                  inactiveThumbColor: Colors.grey,
                  title: Text(
                    "Authentification biométrique",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: _loadingBiometric
                      ? Text(
                          "Chargement...",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        )
                      : Text(
                          _biometricEnabled 
                              ? "Activé - Connexion avec $_biometricType"
                              : "Connectez-vous avec $_biometricType",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                  secondary: Icon(
                    _getBiometricIcon(),
                    color: accentBlue,
                  ),
                  value: _biometricEnabled,
                  onChanged: _loadingBiometric ? null : _toggleBiometric,
                ),
              ),
            if (_biometricAvailable) const SizedBox(height: 12),

            // Sécurité
            Card(
              color: theme.colorScheme.surface,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              child: ListTile(
                leading: Icon(Icons.lock_outline_rounded, color: accentBlue),
                title: Text(
                  "Changer le mot de passe",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                onTap: () {
                  PageTransitions.push(
                    context,
                    ModifierMotDePasseScreen(),
                    type: PageTransitionType.slideAndFade,
                  );
                },
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Personnaliser les transitions
            Card(
              color: theme.colorScheme.surface,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              child: ListTile(
                leading: Icon(Icons.tune, color: accentBlue),
                title: Text(
                  "Personnaliser les transitions",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Text(
                  "Configurez les animations selon vos préférences",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                onTap: () {
                  PageTransitions.push(
                    context,
                    const TransitionSettingsScreen(),
                    type: PageTransitionType.slideAndFade,
                  );
                },
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Mentions légales (exemple)
            Card(
              color: theme.colorScheme.surface,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              child: ListTile(
                leading: Icon(Icons.info_outline, color: accentBlue),
                title: Text(
                  "Mentions légales",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                onTap: () {
                  // Action vers page ou modal mentions légales
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Mentions légales"),
                      content: const Text(
                        "Site édité par l'École Nationale d’Administration - ENA RDC.\nPour toute information : contact@ena.cd",
                      ),
                      actions: [
                        TextButton(
                          child: const Text("OK"),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  );
                },
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Suppression de compte (maintenant en dernier)
            Card(
              color: theme.colorScheme.surface,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                title: Text(
                  "Supprimer mon compte",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.red,
                  ),
                ),
                subtitle: Text(
                  "Suppression définitive avec délai de 30 jours",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                onTap: () {
                  PageTransitions.push(
                    context,
                    const AccountDeletionScreen(),
                    type: PageTransitionType.slideAndFade,
                  );
                },
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 80), // Laisse la place pour le footer
          ],
        );
      },
    );
  }

  String _getThemeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return "Suit les paramètres système";
      case ThemeMode.light:
        return "Mode clair";
      case ThemeMode.dark:
        return "Mode sombre";
    }
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.auto_mode;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            "Thème d'affichage",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.headlineSmall?.color,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(
                context,
                themeProvider,
                ThemeMode.system,
                "Automatique",
                "Suit les paramètres système",
                Icons.auto_mode,
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context,
                themeProvider,
                ThemeMode.light,
                "Mode clair",
                "Toujours en mode clair",
                Icons.light_mode,
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context,
                themeProvider,
                ThemeMode.dark,
                "Mode sombre",
                "Toujours en mode sombre",
                Icons.dark_mode,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Fermer",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF3678FF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    ThemeMode mode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = themeProvider.themeMode == mode;

    return InkWell(
      onTap: () {
        themeProvider.setThemeMode(mode);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3678FF).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3678FF)
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF3678FF)
                  : Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 16,
                      color: isSelected
                          ? const Color(0xFF3678FF)
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF3678FF)),
          ],
        ),
      ),
    );
  }
}
