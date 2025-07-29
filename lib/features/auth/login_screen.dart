import 'package:ena_mobile_front/features/auth/forgot_password_screen.dart';
import 'package:ena_mobile_front/main.dart';
import 'package:ena_mobile_front/services/auth_api_service.dart';
import 'package:ena_mobile_front/services/biometric_service.dart';
import 'package:ena_mobile_front/widgets/error_popup.dart';
import 'package:ena_mobile_front/widgets/biometric_setup_popup.dart';
import 'package:ena_mobile_front/widgets/page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool loading = false;
  bool showPassword = false;
  String? error;
  bool _biometricAvailable = false;
  bool _biometricLoading = false;
  String _biometricType = '';

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Rechecker l'état biométrique quand on revient sur cette page
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final isEnabled = await BiometricAuthService.isBiometricEnabled();
    final hasCredentials = await BiometricAuthService.hasStoredCredentials();
    final isAvailable = await BiometricAuthService.isBiometricAvailableOnDevice();
    final biometricType = await BiometricAuthService.getPrimaryBiometricType();
    
    if (mounted) {
      setState(() {
        // Afficher le bouton biométrique si activé et disponible
        // Maintenant on vérifie aussi les credentials car ils sont préservés après logout
        _biometricAvailable = isEnabled && hasCredentials && isAvailable;
        _biometricType = biometricType;
      });
    }
  }

  Future<void> _biometricLogin() async {
    setState(() => _biometricLoading = true);

    try {
      final result = await BiometricAuthService.authenticateForLogin();
      
      if (result['success'] == true) {
        // VALIDATION DU TOKEN avant navigation
        if (result['token'] != null) {
          // Test de validation du token avec un appel API simple
          final validationResult = await AuthApiService.getUserInfo(token: result['token']);
          
          if (validationResult['success'] == true) {
            // Token valide - procéder avec la connexion
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('auth_token', result['token']);
            
            if (result['email'] != null) {
              await prefs.setString('user_email', result['email']);
            }

            setState(() => _biometricLoading = false);

            if (mounted) {
              PageTransitions.pushReplacement(
                context,
                const MainRouter(),
                type: PageTransitionType.fadeThrough,
                duration: const Duration(milliseconds: 500),
              );
            }
          } else {
            // Token invalide - forcer une nouvelle authentification
            setState(() => _biometricLoading = false);
            
            // Nettoyer les credentials biométriques invalides
            await BiometricAuthService.clearAllBiometricData();
            
            if (mounted) {
              await ErrorPopup.show(
                context,
                title: "Session expirée",
                message: "Votre session a expiré. Veuillez vous reconnecter avec votre email et mot de passe.",
              );
            }
          }
        } else {
          setState(() => _biometricLoading = false);
          if (mounted) {
            await ErrorPopup.show(
              context,
              title: "Erreur de session",
              message: "Aucun token d'authentification trouvé. Veuillez vous reconnecter.",
            );
          }
        }
      } else {
        setState(() => _biometricLoading = false);
        if (mounted) {
          await ErrorPopup.show(
            context,
            title: "Authentification échouée",
            message: result['error'] ?? "Impossible de vous authentifier",
          );
        }
      }
    } catch (e) {
      setState(() => _biometricLoading = false);
      if (mounted) {
        await ErrorPopup.show(
          context,
          title: "Erreur",
          message: "Erreur lors de l'authentification biométrique",
          details: e.toString(),
        );
      }
    }
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await AuthApiService.login(
        email: email.trim().toLowerCase(),
        password: password,
      );

      setState(() => loading = false);

      if (result['success'] == true) {
        // Vérifier si l'utilisateur a changé et désactiver la biométrie si nécessaire
        await BiometricAuthService.checkUserChanged();
        
        // Sauvegarde d'état de connexion et du token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('user_email', email.trim().toLowerCase()); // Sauvegarder l'email
        if (result['token'] != null) {
          await prefs.setString('auth_token', result['token']);
        }

        // Navigation directe vers MainRouter
        if (mounted) {
          // Proposer la configuration biométrique si disponible et pas encore configurée
          final isDeviceSupported = await BiometricAuthService.isBiometricAvailableOnDevice();
          final hasStoredCredentials = await BiometricAuthService.hasStoredCredentials();
          
          if (isDeviceSupported && !hasStoredCredentials && result['token'] != null) {
            await BiometricSetupPopup.show(
              context,
              token: result['token'],
              email: email.trim().toLowerCase(),
              onSetupComplete: () {
                // Recharger l'état biométrique après activation
                _checkBiometricStatus();
              },
            );
          }
          
          PageTransitions.pushReplacement(
            context,
            const MainRouter(),
            type: PageTransitionType.fadeThrough,
            duration: const Duration(milliseconds: 500),
          );
        }
      } else {
        if (mounted) {
          await ErrorPopup.show(
            context,
            title: "Échec de connexion",
            message: result['error'] ?? "Email ou mot de passe incorrect",
            details: result['details']?.toString(),
            onRetry: _login,
          );
        }
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        await ErrorPopup.show(
          context,
          title: "Erreur de connexion",
          message: "Impossible de se connecter au serveur",
          details: e.toString(),
          onRetry: _login,
        );
      }
    }
  }

  void _goToRegister() {
    PageTransitions.push(
      context,
      const RegisterScreen(),
      type: PageTransitionType.slideAndFade,
      slideDirection: SlideDirection.rightToLeft,
    );
  }

  IconData _getBiometricIcon() {
    switch (_biometricType.toLowerCase()) {
      case 'face':
        return Icons.face;
      case 'fingerprint':
        return Icons.fingerprint;
      case 'iris':
        return Icons.visibility;
      default:
        return Icons.security;
    }
  }

  String _getBiometricLabel() {
    switch (_biometricType.toLowerCase()) {
      case 'face':
        return 'Reconnaissance faciale';
      case 'fingerprint':
        return 'Empreinte digitale';
      case 'iris':
        return 'Reconnaissance de l\'iris';
      default:
        return 'Authentification biométrique';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131C25)
          : const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo ENA
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(80),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isDark
                                        ? Colors.black
                                        : const Color(0xFF013068))
                                    .withValues(alpha: 0.12),
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
                    // Card de connexion
                    Card(
                      color: isDark ? const Color(0xFF1A2530) : Colors.white,
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      shadowColor:
                          (isDark ? Colors.black : const Color(0xFF013068))
                              .withValues(alpha: 0.13),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 38,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Connexion",
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF013068),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    style: GoogleFonts.poppins(),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.email_rounded,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF013068),
                                      ),
                                      labelText: "Adresse e-mail",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? const Color(0xFF232D38)
                                          : Colors.grey[100],
                                    ),
                                    onChanged: (val) => email = val.trim(),
                                    validator: (val) =>
                                        val == null || val.isEmpty
                                        ? "Champ obligatoire"
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    obscureText: !showPassword,
                                    style: GoogleFonts.poppins(),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.lock_outline_rounded,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF013068),
                                      ),
                                      labelText: "Mot de passe",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? const Color(0xFF232D38)
                                          : Colors.grey[100],
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          showPassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(
                                            () => showPassword = !showPassword,
                                          );
                                        },
                                      ),
                                    ),
                                    onChanged: (val) => password = val,
                                    validator: (val) =>
                                        val == null || val.isEmpty
                                        ? "Champ obligatoire"
                                        : null,
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF3678FF,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        textStyle: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      onPressed: loading ? null : _login,
                                      child: loading
                                          ? const SizedBox(
                                              width: 26,
                                              height: 26,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Color(0xFFFFFFFF)),
                                              ),
                                            )
                                          : const Text("Se connecter"),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // --- Bouton Biométrique (si disponible) ---
                                  if (_biometricAvailable)
                                    Column(
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            icon: _biometricLoading
                                                ? SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                        isDark ? Colors.white : Colors.black87,
                                                      ),
                                                    ),
                                                  )
                                                : Icon(
                                                    _getBiometricIcon(),
                                                    size: 22,
                                                  ),
                                            label: Text(
                                              _biometricLoading
                                                  ? "Authentification en cours..."
                                                  : _getBiometricLabel(),
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w500,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: isDark
                                                  ? const Color(0xFF232D38)
                                                  : Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              side: BorderSide(
                                                color: const Color(0xFF3678FF),
                                                width: 1.5,
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                            ),
                                            onPressed: (loading || _biometricLoading)
                                                ? null
                                                : _biometricLogin,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                      ],
                                    ),
                                  // Lien vers la page Register
                                  TextButton(
                                    onPressed: _goToRegister,
                                    child: Text(
                                      "Créer un compte",
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFFF8B400),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (error != null) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      error!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        PageTransitions.push(
                                          context,
                                          const ForgotPasswordScreen(),
                                          type: PageTransitionType.fadeAndScale,
                                        );
                                      },
                                      child: Text(
                                        "Mot de passe oublié ?",
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF3678FF),
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
                    ),
                  ],
                ),
              ),
            ),

            // Copyright sticky en bas
          ],
        ),
      ),
    );
  }
}
