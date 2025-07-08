import 'package:ena_mobile_front/services/auth_api_service.dart';
import 'package:ena_mobile_front/widgets/error_popup.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

enum PasswordStrength { weak, medium, strong }

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String? otp; // Code OTP validé depuis email_verify

  const NewPasswordScreen({super.key, required this.email, this.otp});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _loading = false;
  bool _showPasswordInfo = false;
  
  String _newPassword = '';
  PasswordStrength _passwordStrength = PasswordStrength.weak;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Évaluation de la force du mot de passe (copié de register_screen)
  PasswordStrength _evaluatePasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;

    int score = 0;

    // Longueur
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Minuscules
    if (password.contains(RegExp(r'[a-z]'))) score++;

    // Majuscules
    if (password.contains(RegExp(r'[A-Z]'))) score++;

    // Chiffres
    if (password.contains(RegExp(r'[0-9]'))) score++;

    // Caractères spéciaux
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    // Pas de répétitions
    if (!password.contains(RegExp(r'(.)\1{2,}'))) score++;

    if (score <= 3) return PasswordStrength.weak;
    if (score <= 5) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  // Validation stricte du mot de passe
  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Nouveau mot de passe obligatoire";
    }

    if (value.length < 8) {
      return "Le mot de passe doit contenir au moins 8 caractères";
    }

    final strength = _evaluatePasswordStrength(value);

    if (strength != PasswordStrength.strong) {
      return "Mot de passe trop faible. Il doit contenir :\n"
          "• Au moins 8 caractères (12+ recommandé)\n"
          "• Des lettres minuscules et majuscules\n"
          "• Des chiffres et caractères spéciaux\n"
          "• Pas de répétitions (ex: aaa)";
    }

    return null;
  }

  // Validation de la confirmation du mot de passe
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Confirmation obligatoire";
    }

    if (value != _newPassword) {
      return "Les mots de passe ne correspondent pas";
    }

    return null;
  }

  // Widget pour afficher la force du mot de passe
  Widget _buildPasswordStrengthIndicator() {
    Color getColor() {
      switch (_passwordStrength) {
        case PasswordStrength.weak:
          return Colors.red;
        case PasswordStrength.medium:
          return Colors.orange;
        case PasswordStrength.strong:
          return Colors.green;
      }
    }

    String getText() {
      switch (_passwordStrength) {
        case PasswordStrength.weak:
          return "Faible";
        case PasswordStrength.medium:
          return "Moyen";
        case PasswordStrength.strong:
          return "Fort ✓";
      }
    }

    double getProgress() {
      switch (_passwordStrength) {
        case PasswordStrength.weak:
          return 0.33;
        case PasswordStrength.medium:
          return 0.66;
        case PasswordStrength.strong:
          return 1.0;
      }
    }

    if (_newPassword.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: getProgress(),
                backgroundColor: getColor().withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(getColor()),
                minHeight: 4,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              getText(),
              style: GoogleFonts.poppins(
                color: getColor(),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // Widget d'information sur les exigences du mot de passe
  Widget _buildPasswordInfoWidget() {
    if (!_showPasswordInfo) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3678FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF3678FF).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF3678FF),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                "Exigences pour un mot de passe fort :",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF3678FF),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPasswordRequirement(
            "Au moins 8 caractères (12+ recommandé)",
            _newPassword.length >= 8,
          ),
          _buildPasswordRequirement(
            "Lettres minuscules (a-z)",
            _newPassword.contains(RegExp(r'[a-z]')),
          ),
          _buildPasswordRequirement(
            "Lettres majuscules (A-Z)",
            _newPassword.contains(RegExp(r'[A-Z]')),
          ),
          _buildPasswordRequirement(
            "Chiffres (0-9)",
            _newPassword.contains(RegExp(r'[0-9]')),
          ),
          _buildPasswordRequirement(
            "Caractères spéciaux (!@#\$%^&*)",
            _newPassword.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
          ),
          _buildPasswordRequirement(
            "Pas de répétitions (ex: aaa)",
            !_newPassword.contains(RegExp(r'(.)\1{2,}')),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: isMet ? Colors.green : Colors.grey[600],
                fontSize: 11,
                fontWeight: isMet ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitNewPassword() async {
    if (!_formKey.currentState!.validate()) return;

    PasswordStrength passwordStrength = _evaluatePasswordStrength(_newPassword);
    if (passwordStrength != PasswordStrength.strong) {
      await ErrorPopup.show(
        context,
        title: "Mot de passe faible",
        message: "Veuillez choisir un mot de passe fort.",
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await AuthApiService.resetPassword(
        email: widget.email,
        newPassword: _newPassword,
        otp: widget.otp ?? "", // Utilise le code OTP validé
      );

      setState(() => _loading = false);

      if (result['success'] == true) {
        if (mounted) {
          await ErrorPopup.showSuccess(
            context,
            title: "Mot de passe mis à jour",
            message: "Votre mot de passe a été mis à jour avec succès. Vous pouvez maintenant vous connecter.",
            onContinue: () {
              Navigator.of(context).pop(); // Ferme la pop-up new_password
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          );
        }
      } else {
        if (mounted) {
          await ErrorPopup.show(
            context,
            title: "Erreur de réinitialisation",
            message: result['error'] ?? "Erreur lors de la réinitialisation.",
            details: result['details']?.toString(),
            onRetry: _submitNewPassword,
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        await ErrorPopup.show(
          context,
          title: "Erreur de connexion",
          message: "Impossible de se connecter au serveur.",
          details: e.toString(),
          onRetry: _submitNewPassword,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
        child: Card(
          elevation: 12,
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.surface
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête
                    Icon(
                      Icons.lock_reset_rounded,
                      color: const Color(0xFF3678FF),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Nouveau mot de passe",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: const Color(0xFF013068),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Choisissez un nouveau mot de passe sécurisé pour votre compte.",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: theme.brightness == Brightness.dark
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                            : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Champ Nouveau mot de passe
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: !_showNewPassword,
                      decoration: InputDecoration(
                        labelText: "Nouveau mot de passe",
                        prefixIcon: Icon(
                          Icons.lock,
                          color: theme.colorScheme.primary,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.info_outline,
                                color: theme.iconTheme.color,
                              ),
                              onPressed: () => setState(() => _showPasswordInfo = !_showPasswordInfo),
                              tooltip: "Voir les exigences",
                            ),
                            IconButton(
                              icon: Icon(
                                _showNewPassword ? Icons.visibility_off : Icons.visibility,
                                color: theme.iconTheme.color,
                              ),
                              onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                            ),
                          ],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      ),
                      validator: _validateNewPassword,
                      onChanged: (value) {
                        setState(() {
                          _newPassword = value;
                          _passwordStrength = _evaluatePasswordStrength(value);
                        });
                      },
                    ),
                    _buildPasswordStrengthIndicator(),
                    _buildPasswordInfoWidget(),
                    const SizedBox(height: 20),

                    // Champ Confirmation du mot de passe
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      decoration: InputDecoration(
                        labelText: "Confirmer le nouveau mot de passe",
                        prefixIcon: Icon(
                          Icons.lock_reset,
                          color: theme.colorScheme.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: theme.iconTheme.color,
                          ),
                          onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      ),
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 24),

                    // Boutons d'action
                    if (_loading)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF3678FF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Réinitialisation en cours...",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitNewPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3678FF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                "Réinitialiser le mot de passe",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              "Annuler",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF3678FF),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
