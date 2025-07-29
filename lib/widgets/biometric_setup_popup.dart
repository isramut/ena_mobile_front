import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ena_mobile_front/services/biometric_service.dart';
import 'package:ena_mobile_front/widgets/error_popup.dart';
import 'animated_popup.dart';

class BiometricSetupPopup extends StatefulWidget {
  final String token;
  final String email;
  final VoidCallback? onSetupComplete;

  const BiometricSetupPopup({
    super.key,
    required this.token,
    required this.email,
    this.onSetupComplete,
  });

  @override
  State<BiometricSetupPopup> createState() => _BiometricSetupPopupState();

  static Future<void> show(
    BuildContext context, {
    required String token,
    required String email,
    VoidCallback? onSetupComplete,
  }) async {
    await AnimatedPopup.showAnimatedDialog<void>(
      context: context,
      animationType: AnimationType.blurBackdrop,
      duration: const Duration(milliseconds: 500),
      child: BiometricSetupPopup(
        token: token,
        email: email,
        onSetupComplete: onSetupComplete,
      ),
    );
  }
}

class _BiometricSetupPopupState extends State<BiometricSetupPopup> {
  bool _isLoading = false;
  String _biometricDescription = '';

  @override
  void initState() {
    super.initState();
    _loadBiometricInfo();
  }

  Future<void> _loadBiometricInfo() async {
    final type = await BiometricAuthService.getPrimaryBiometricType();
    final description = _getBiometricDescription(type);
    if (mounted) {
      setState(() {
        _biometricDescription = description;
      });
    }
  }

  String _getBiometricDescription(String type) {
    switch (type.toLowerCase()) {
      case 'face':
        return 'la reconnaissance faciale';
      case 'fingerprint':
        return 'votre empreinte digitale';
      case 'iris':
        return 'la reconnaissance de l\'iris';
      default:
        return 'l\'authentification biométrique';
    }
  }

  Future<void> _setupBiometric() async {
    setState(() => _isLoading = true);

    try {
      // Tester d'abord l'authentification biométrique
      final testResult = await BiometricAuthService.testBiometricAuth();
      
      if (testResult['success'] != true) {
        if (mounted) {
          await ErrorPopup.show(
            context,
            title: "Test d'authentification échoué",
            message: testResult['error'] ?? "Impossible de tester l'authentification biométrique",
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Sauvegarder les credentials de manière sécurisée
      final storeResult = await BiometricAuthService.storeAuthCredentials(
        token: widget.token,
        email: widget.email,
      );

      if (!storeResult) {
        if (mounted) {
          await ErrorPopup.show(
            context,
            title: "Erreur de sauvegarde",
            message: "Impossible de sauvegarder les informations d'authentification",
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Activer la biométrie dans les paramètres
      final enableResult = await BiometricAuthService.setBiometricEnabled(true);

      if (enableResult) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Authentification biométrique activée !',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.of(context).pop();
          widget.onSetupComplete?.call();
        }
      } else {
        if (mounted) {
          await ErrorPopup.show(
            context,
            title: "Erreur d'activation",
            message: "Impossible d'activer l'authentification biométrique",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await ErrorPopup.show(
          context,
          title: "Erreur de configuration",
          message: "Une erreur est survenue lors de la configuration",
          details: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentBlue = theme.colorScheme.secondary;
    final mainBlue = theme.colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedPopupChild(
              delay: const Duration(milliseconds: 100),
              child: Icon(
                Icons.fingerprint,
                color: accentBlue,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedPopupChild(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'Activer l\'authentification biométrique ?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainBlue,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedPopupChild(
              delay: const Duration(milliseconds: 300),
              child: Text(
                'Connectez-vous plus rapidement avec $_biometricDescription',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: theme.brightness == Brightness.dark
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                      : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedPopupChild(
              delay: const Duration(milliseconds: 350),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: accentBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vos données restent sécurisées et chiffrées',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: accentBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedPopupChild(
              delay: const Duration(milliseconds: 400),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Plus tard',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _setupBiometric,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Activer',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
}
