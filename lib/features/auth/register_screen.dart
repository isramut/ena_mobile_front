import 'package:ena_mobile_front/features/auth/email_verify.dart';
import 'package:ena_mobile_front/services/auth_api_service.dart';
import 'package:ena_mobile_front/widgets/error_popup.dart';
import 'package:ena_mobile_front/widgets/page_transitions.dart';
import 'package:ena_mobile_front/utils/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';

// Enum pour la force du mot de passe
enum PasswordStrength { weak, medium, strong }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String lastName = '';
  String middleName = '';
  String firstName = '';
  String email = '';
  String telephone = '';
  String password = '';
  String confirmPassword = '';
  bool loading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool showPasswordInfo = false; // Nouvelle variable pour afficher l'info
  bool acceptTerms = false; // Case à cocher pour les conditions d'utilisation
  String? error;
  PasswordStrength _passwordStrength = PasswordStrength.weak;

  // Validation stricte pour les noms (lettres accentuées et traits d'union uniquement)
  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName obligatoire";
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return "$fieldName doit contenir au moins 2 caractères";
    }

    // Regex stricte : lettres (avec accents) et traits d'union uniquement
    if (!RegExp(
      r'^[a-zA-ZàâäéèêëïîôöùûüÿçÀÂÄÉÈÊËÏÎÔÖÙÛÜŸÇ\-]+$',
    ).hasMatch(trimmedValue)) {
      return "$fieldName ne peut contenir que des lettres et des traits d'union";
    }

    return null;
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
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Mot de passe obligatoire";
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

    if (password.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              "Force du mot de passe : ",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            Text(
              getText(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: getColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: getProgress(),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(getColor()),
        ),
      ],
    );
  }

  // Widget pour afficher les règles du mot de passe
  Widget _buildPasswordRulesInfo() {
    if (!showPasswordInfo) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Règles du mot de passe :",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              InkWell(
                onTap: () => setState(() => showPasswordInfo = false),
                child: Icon(
                  Icons.close,
                  color: Colors.blue[600],
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPasswordRule("• Au moins 8 caractères (12+ recommandé)"),
          _buildPasswordRule("• Des lettres minuscules ET majuscules"),
          _buildPasswordRule("• Au moins un chiffre"),
          _buildPasswordRule("• Au moins un caractère spécial (!@#\$%^&*)"),
          _buildPasswordRule("• Pas de répétitions (ex: aaa, 111)"),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => showPasswordInfo = false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0),
              ),
              child: Text(
                "Compris",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRule(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        rule,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  InputDecoration _getInputDecoration(
    String labelText,
    IconData icon,
    bool isDark,
  ) {
    final mainBlue = const Color(0xFF013068);
    return InputDecoration(
      prefixIcon: Icon(
        icon,
        color: isDark ? Theme.of(context).colorScheme.primary : mainBlue,
      ),
      labelText: labelText,
      labelStyle: TextStyle(
        color: isDark ? Theme.of(context).colorScheme.onSurface : null,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? Theme.of(context).colorScheme.outline : Colors.grey,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? Theme.of(context).colorScheme.outline : Colors.grey,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? Theme.of(context).colorScheme.primary : mainBlue,
        ),
      ),
      filled: true,
      fillColor: isDark
          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.3)
          : Colors.grey[100],
    );
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérification des conditions d'utilisation
    if (!acceptTerms) {
      setState(() {
        error = "Vous devez accepter les conditions d'utilisation pour continuer.";
        loading = false;
      });
      await ErrorPopup.show(
        context,
        title: "Conditions d'utilisation",
        message: error!,
      );
      return;
    }

    // Vérification supplémentaire de la force du mot de passe
    if (_passwordStrength != PasswordStrength.strong) {
      setState(() {
        error = "Le mot de passe doit être fort pour procéder à l'inscription.";
        loading = false;
      });
      await ErrorPopup.show(
        context,
        title: "Mot de passe faible",
        message: error!,
      );
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    if (password != confirmPassword) {
      setState(() {
        error = "Les mots de passe ne correspondent pas.";
        loading = false;
      });
      await ErrorPopup.show(
        context,
        title: "Mots de passe différents",
        message: error!,
      );
      return;
    }

    // APPEL API INSCRIPTION
    try {
      final result = await AuthApiService.register(
        firstName: firstName.trim(),
        middleName: middleName.trim(),
        lastName: lastName.trim(),
        email: email.trim().toLowerCase(),
        password: password,
        telephone: telephone.trim(),
      );

      setState(() => loading = false);

      if (result['success'] == true) {
        // Succès - Redirection vers vérification email
        if (mounted) {
          AppNavigator.pushReplacement(
            context,
            PasswordRecuperationScreen(
              email: email.trim().toLowerCase(),
              isFromForgotPassword: false, // Flux inscription
            ),
          );
        }
      } else {
        // Erreur API - Gestion intelligente des erreurs de doublon
        if (mounted) {
          final errorInfo = _handleDuplicateError(result['error']);
          
          await ErrorPopup.show(
            context,
            title: errorInfo['title']!,
            message: errorInfo['message']!,
            details: result['details']?.toString(),
            onRetry: _register,
          );
        }
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        await ErrorPopup.show(
          context,
          title: "Erreur de connexion",
          message: 'Impossible de se connecter au serveur',
          details: e.toString(),
          onRetry: _register,
        );
      }
    }
  }

  void _goToLogin() {
    PageTransitions.pushReplacement(
      context,
      const LoginScreen(),
      type: PageTransitionType.slideAndFade,
      slideDirection: SlideDirection.leftToRight,
    );
  }

  // Méthode pour ouvrir les conditions d'utilisation
  void _openTermsOfService() {
    launchUrl(Uri.parse('https://ena.gouv.cd/terms'));
  }

  // Méthode pour gérer les erreurs de doublon avec des messages conviviaux
  Map<String, String> _handleDuplicateError(String? errorMessage) {
    if (errorMessage == null) {
      return {
        'title': 'Erreur d\'inscription',
        'message': 'Une erreur s\'est produite lors de l\'inscription.',
      };
    }

    final lowerError = errorMessage.toLowerCase();
    
    // Détection d'erreurs de doublon d'email
    if (lowerError.contains('email') && 
        (lowerError.contains('already') || 
         lowerError.contains('exists') || 
         lowerError.contains('duplicate') ||
         lowerError.contains('unique') ||
         lowerError.contains('déjà') ||
         lowerError.contains('utilisé'))) {
      return {
        'title': 'Email déjà utilisé',
        'message': 'Cette adresse email est déjà associée à un compte existant.\n\nVous avez peut-être déjà créé un compte avec cette adresse email.',
      };
    }
    
    // Détection d'erreurs de doublon de téléphone
    if ((lowerError.contains('phone') || 
         lowerError.contains('telephone') ||
         lowerError.contains('tel')) && 
        (lowerError.contains('already') || 
         lowerError.contains('exists') || 
         lowerError.contains('duplicate') ||
         lowerError.contains('unique') ||
         lowerError.contains('déjà') ||
         lowerError.contains('utilisé'))) {
      return {
        'title': 'Numéro de téléphone déjà utilisé',
        'message': 'Ce numéro de téléphone est déjà associé à un compte existant.\n\nVérifiez votre numéro ou utilisez un autre numéro.',
      };
    }
    
    // Détection d'erreurs générales d'utilisateur existant
    if ((lowerError.contains('user') ||
         lowerError.contains('utilisateur') ||
         lowerError.contains('account') ||
         lowerError.contains('compte')) && 
        (lowerError.contains('already') || 
         lowerError.contains('exists') || 
         lowerError.contains('duplicate') ||
         lowerError.contains('unique') ||
         lowerError.contains('déjà') ||
         lowerError.contains('exist'))) {
      return {
        'title': 'Compte déjà existant',
        'message': 'Un compte avec ces informations existe déjà.\n\nVérifiez vos informations ou connectez-vous si vous avez déjà un compte.',
      };
    }
    
    // Autres erreurs de contrainte unique/doublon
    if (lowerError.contains('duplicate') ||
        lowerError.contains('unique') ||
        lowerError.contains('constraint') ||
        lowerError.contains('violation')) {
      return {
        'title': 'Informations déjà utilisées',
        'message': 'Certaines de vos informations sont déjà utilisées par un autre compte.\n\nVérifiez votre email et votre numéro de téléphone.',
      };
    }
    
    // Message par défaut pour les autres erreurs
    return {
      'title': 'Erreur d\'inscription',
      'message': errorMessage.isNotEmpty ? errorMessage : 'Une erreur s\'est produite lors de l\'inscription.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mainBlue = const Color(0xFF013068);
    final accentBlue = const Color(0xFF3678FF);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131C25) : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ENA
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Theme.of(context).colorScheme.surface
                        : Colors.white,
                    borderRadius: BorderRadius.circular(80),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : mainBlue).withValues(
                          alpha: isDark ? 0.3 : 0.11,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(22),
                  child: Image.asset(
                    isDark
                        ? "assets/images/ena_logo_blanc.png"
                        : "assets/images/ena_logo.png",
                    height: 64,
                  ),
                ),
                // Card d'inscription
                Card(
                  color: isDark
                      ? Theme.of(context).colorScheme.surface
                      : Colors.white,
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  shadowColor: (isDark ? Colors.black : mainBlue).withValues(
                    alpha: isDark ? 0.3 : 0.13,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 38,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Créer un compte",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurface
                                : mainBlue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Nom
                              TextFormField(
                                style: GoogleFonts.poppins(
                                  color: isDark
                                      ? Theme.of(context).colorScheme.onSurface
                                      : null,
                                ),
                                decoration: _getInputDecoration(
                                  "Nom",
                                  Icons.person_outline_rounded,
                                  isDark,
                                ),
                                onChanged: (val) => lastName = val.trim(),
                                validator: (val) => _validateName(val, "Nom"),
                              ),
                              const SizedBox(height: 18),
                              // Postnom
                              TextFormField(
                                style: GoogleFonts.poppins(
                                  color: isDark
                                      ? Theme.of(context).colorScheme.onSurface
                                      : null,
                                ),
                                decoration: _getInputDecoration(
                                  "Postnom",
                                  Icons.person_outline_rounded,
                                  isDark,
                                ),
                                onChanged: (val) => middleName = val.trim(),
                                validator: (val) =>
                                    _validateName(val, "Postnom"),
                              ),
                              const SizedBox(height: 18),
                              // Prénom
                              TextFormField(
                                style: GoogleFonts.poppins(
                                  color: isDark
                                      ? Theme.of(context).colorScheme.onSurface
                                      : null,
                                ),
                                decoration: _getInputDecoration(
                                  "Prénom",
                                  Icons.person_outline_rounded,
                                  isDark,
                                ),
                                onChanged: (val) => firstName = val.trim(),
                                validator: (val) =>
                                    _validateName(val, "Prénom"),
                              ),
                              const SizedBox(height: 18),
                              // Email
                              TextFormField(
                                style: GoogleFonts.poppins(
                                  color: isDark
                                      ? Theme.of(context).colorScheme.onSurface
                                      : null,
                                ),
                                decoration: _getInputDecoration(
                                  "Email",
                                  Icons.email_outlined,
                                  isDark,
                                ),
                                onChanged: (val) => email = val.trim(),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return "Champ obligatoire";
                                  }
                                  if (!RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+',
                                  ).hasMatch(val)) {
                                    return "Format email invalide";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              // Téléphone
                              TextFormField(
                                style: GoogleFonts.poppins(
                                  color: isDark
                                      ? Theme.of(context).colorScheme.onSurface
                                      : null,
                                ),
                                decoration: _getInputDecoration(
                                  "Téléphone",
                                  Icons.phone_outlined,
                                  isDark,
                                ),
                                onChanged: (val) => telephone = val.trim(),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return "Champ obligatoire";
                                  }
                                  if (!RegExp(
                                    r'^\+?[0-9]{10,15}$',
                                  ).hasMatch(val)) {
                                    return "Numéro de téléphone invalide";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              // Mot de passe
                              TextFormField(
                                style: GoogleFonts.poppins(
                                  color: isDark
                                      ? Theme.of(context).colorScheme.onSurface
                                      : null,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: isDark
                                        ? Theme.of(context).colorScheme.primary
                                        : mainBlue,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      showPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: isDark
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : mainBlue,
                                    ),
                                    onPressed: () => setState(
                                      () => showPassword = !showPassword,
                                    ),
                                  ),
                                  labelText: "Mot de passe",
                                  labelStyle: TextStyle(
                                    color: isDark
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onSurface
                                        : null,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.outline
                                          : Colors.grey,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.outline
                                          : Colors.grey,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : mainBlue,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Theme.of(context).colorScheme.surface
                                            .withValues(alpha: 0.3)
                                      : Colors.grey[100],
                                ),
                                obscureText: !showPassword,
                                onTap: () {
                                  // Afficher les règles quand l'utilisateur clique sur le champ
                                  setState(() {
                                    showPasswordInfo = true;
                                  });
                                },
                                onChanged: (val) {
                                  password = val.trim();
                                  setState(() {
                                    _passwordStrength =
                                        _evaluatePasswordStrength(password);
                                  });
                                },
                                validator: (val) => _validatePassword(val),
                              ),
                              _buildPasswordRulesInfo(), // Afficher les règles
                              _buildPasswordStrengthIndicator(),
                              const SizedBox(height: 18),
                              // Confirmer mot de passe
                              TextFormField(
                                style: GoogleFonts.poppins(
                                  color: isDark
                                      ? Theme.of(context).colorScheme.onSurface
                                      : null,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: isDark
                                        ? Theme.of(context).colorScheme.primary
                                        : mainBlue,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      showConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: isDark
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : mainBlue,
                                    ),
                                    onPressed: () => setState(
                                      () => showConfirmPassword =
                                          !showConfirmPassword,
                                    ),
                                  ),
                                  labelText: "Confirmer mot de passe",
                                  labelStyle: TextStyle(
                                    color: isDark
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onSurface
                                        : null,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.outline
                                          : Colors.grey,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.outline
                                          : Colors.grey,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : mainBlue,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Theme.of(context).colorScheme.surface
                                            .withValues(alpha: 0.3)
                                      : Colors.grey[100],
                                ),
                                obscureText: !showConfirmPassword,
                                onChanged: (val) =>
                                    confirmPassword = val.trim(),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return "Champ obligatoire";
                                  }
                                  if (val != password) {
                                    return "Les mots de passe ne correspondent pas";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              // Case à cocher pour les conditions d'utilisation
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: acceptTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        acceptTerms = value ?? false;
                                      });
                                    },
                                    activeColor: isDark
                                        ? Theme.of(context).colorScheme.primary
                                        : accentBlue,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: isDark
                                                ? Theme.of(context).colorScheme.onSurface
                                                : Colors.grey[700],
                                          ),
                                          children: [
                                            const TextSpan(text: "J'ai lu et j'accepte les "),
                                            TextSpan(
                                              text: "conditions d'utilisation et la politique de confidentialité",
                                              style: GoogleFonts.poppins(
                                                color: isDark
                                                    ? Theme.of(context).colorScheme.primary
                                                    : accentBlue,
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.underline,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = _openTermsOfService,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              // Bouton d'inscription
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? Theme.of(context).colorScheme.primary
                                        : accentBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 3,
                                  ),
                                  onPressed: loading ? null : _register,
                                  child: loading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  isDark
                                                      ? Theme.of(
                                                          context,
                                                        ).colorScheme.onPrimary
                                                      : Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          "S'inscrire",
                                          style: GoogleFonts.poppins(
                                            color: isDark
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary
                                                : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                              if (error != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  error!,
                                  style: TextStyle(
                                    color: isDark
                                        ? Theme.of(context).colorScheme.error
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              Center(
                                child: TextButton(
                                  onPressed: _goToLogin,
                                  child: Text(
                                    "Déjà un compte ? Se connecter",
                                    style: GoogleFonts.poppins(
                                      color: isDark
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : accentBlue,
                                      fontWeight: FontWeight.bold,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
