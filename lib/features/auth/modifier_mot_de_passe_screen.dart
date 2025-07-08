import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_api_service.dart';
import 'login_screen.dart';

enum PasswordStrength { weak, medium, strong }

class ModifierMotDePasseScreen extends StatefulWidget {
  const ModifierMotDePasseScreen({super.key});

  @override
  State<ModifierMotDePasseScreen> createState() =>
      _ModifierMotDePasseScreenState();
}

class _ModifierMotDePasseScreenState extends State<ModifierMotDePasseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _showPasswordInfo = false;

  String _newPassword = '';
  PasswordStrength _passwordStrength = PasswordStrength.weak;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Évaluation de la force du mot de passe
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

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorSnackBar("Session expirée. Veuillez vous reconnecter.");
        setState(() => _isLoading = false);
        return;
      }

      final result = await AuthApiService.selfResetPassword(
        token: token,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar(result['error'] ?? "Erreur lors du changement de mot de passe");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar("Erreur de connexion");
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                "Mot de passe modifié !",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            "Votre mot de passe a été changé avec succès. Vous allez être déconnecté pour des raisons de sécurité.",
            style: GoogleFonts.poppins(
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3678FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Continuer",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Sauvegarder les paramètres biométriques avant d'effacer
      final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      
      await prefs.clear();
      
      // Restaurer les paramètres biométriques
      if (biometricEnabled) {
        await prefs.setBool('biometric_enabled', true);
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // En cas d'erreur, on redirige quand même vers login
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : const Color(0xFF013068),
        foregroundColor: Colors.white,
        title: Text(
          "Modifier le mot de passe",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Information de sécurité
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                      : const Color(0xFFEDF2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3678FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: const Color(0xFF3678FF),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Pour votre sécurité, vous serez déconnecté après le changement de mot de passe.",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Mot de passe actuel
              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_showCurrentPassword,
                decoration: InputDecoration(
                  labelText: "Mot de passe actuel",
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: theme.colorScheme.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showCurrentPassword ? Icons.visibility_off : Icons.visibility,
                      color: theme.iconTheme.color,
                    ),
                    onPressed: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Mot de passe actuel obligatoire";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Nouveau mot de passe
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

              // Confirmation du nouveau mot de passe
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
              const SizedBox(height: 32),

              // Bouton de validation
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3678FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Changement en cours...",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        "Changer le mot de passe",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
