import 'package:ena_mobile_front/features/auth/email_verify.dart';
import 'package:ena_mobile_front/services/auth_api_service.dart';
import 'package:ena_mobile_front/widgets/error_popup.dart';
import 'package:ena_mobile_front/utils/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  bool loading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    try {
      final result = await AuthApiService.forgotPassword(
        email: email.trim().toLowerCase(),
      );

      setState(() => loading = false);

      if (result['success'] == true) {
        // Succès - Redirection vers vérification OTP (nouveau flux)
        if (mounted) {
          AppNavigator.pushForm(
            context,
            PasswordRecuperationScreen(
              email: email.trim().toLowerCase(),
              isFromForgotPassword: true, // Flux mot de passe oublié
            ),
          );
        }
      } else {
        if (mounted) {
          await ErrorPopup.show(
            context,
            title: "Erreur",
            message: result['error'] ?? "Erreur lors de l'envoi du code de réinitialisation",
            details: result['details']?.toString(),
            onRetry: _submit,
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
          onRetry: _submit,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentBlue = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 7,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 34,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_reset_rounded,
                        color: accentBlue,
                        size: 46,
                      ),
                      const SizedBox(height: 9),
                      Text(
                        "Mot de passe oublié",
                        style: GoogleFonts.poppins(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 21,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Saisis ton adresse e-mail pour recevoir un code de réinitialisation.",
                        style: GoogleFonts.poppins(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                          fontWeight: FontWeight.w400,
                          fontSize: 14.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Adresse e-mail",
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.onSurface.withValues(
                              alpha: 0.1,
                            ),
                          ),
                          onChanged: (val) => email = val.trim(),
                          validator: (val) => val == null || val.isEmpty
                              ? "Champ obligatoire"
                              : (!val.contains('@') ? "Email invalide" : null),
                        ),
                      ),
                      const SizedBox(height: 19),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: loading
                              ? const SizedBox.shrink()
                              : const Text("Envoyer le code"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentBlue,
                            foregroundColor: Colors.white,
                            textStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: loading ? null : _submit,
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
    );
  }
}
