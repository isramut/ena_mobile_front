import 'dart:async';
import 'package:ena_mobile_front/features/auth/new_password.dart';
import 'package:ena_mobile_front/features/auth/login_screen.dart';
import 'package:ena_mobile_front/services/auth_api_service.dart';
import 'package:ena_mobile_front/widgets/error_popup.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PasswordRecuperationScreen extends StatefulWidget {
  final String? email;
  final bool isFromForgotPassword; // Nouveau paramètre pour distinguer les flux

  const PasswordRecuperationScreen({
    super.key,
    this.email,
    this.isFromForgotPassword = false, // Par défaut false (flux inscription)
  });

  @override
  State<PasswordRecuperationScreen> createState() =>
      _PasswordRecuperationScreenState();
}

class _PasswordRecuperationScreenState
    extends State<PasswordRecuperationScreen> {
  final int _codeLength = 6;
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  bool _success = false;
  bool _error = false;
  int _secondsLeft = 300; // 5 minutes
  Timer? _timer;
  bool _loading = false;
  bool _resendingCode = false; // Pour l'état du bouton de renvoi
  Timer? _debounceTimer; // Pour éviter les appels multiples

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _codeLength; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onCodeChanged() async {
    String code = _controllers.map((c) => c.text).join();
    
    // Annuler le timer précédent s'il existe
    _debounceTimer?.cancel();
    
    if (code.length == _codeLength && !_loading) {
      // Ajouter un délai pour éviter les appels multiples
      _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        if (!mounted || _loading) return;
        
        setState(() {
          _loading = true;
          _error = false;
          _success = false;
        });

        try {
          if (widget.isFromForgotPassword) {
            // Flux mot de passe oublié : validation locale uniquement
            // On considère le code valide s'il fait 6 caractères numériques
            if (code.length == _codeLength && RegExp(r'^\d{6}$').hasMatch(code)) {
              setState(() {
                _success = true;
                _error = false;
                _loading = false;
              });
            } else {
              setState(() {
                _error = true;
                _loading = false;
              });
              
              _resetOtpFields();
              
              if (mounted) {
                await ErrorPopup.show(
                  context,
                  title: "Code OTP invalide",
                  message: "Le code OTP doit contenir 6 chiffres.",
                );
              }
            }
          } else {
            // Flux inscription : appel API pour vérification
            final result = await AuthApiService.verifyOtp(
              email: widget.email ?? "",
              otp: code,
            );

            if (!mounted) return;

            if (result['success'] == true) {
              setState(() {
                _success = true;
                _error = false;
                _loading = false;
              });
            } else {
              setState(() {
                _error = true;
                _loading = false;
              });
              
              // Reset des champs et affichage de l'erreur
              _resetOtpFields();
              
              if (mounted) {
                await ErrorPopup.show(
                  context,
                  title: "Code OTP incorrect",
                  message: result['error'] ?? "Code OTP incorrect.",
                );
              }
            }
          }
        } catch (e) {
          if (!mounted) return;
          
          setState(() {
            _error = true;
            _loading = false;
          });
          
          // Reset des champs et affichage de l'erreur
          _resetOtpFields();
          
          if (mounted) {
            await ErrorPopup.show(
              context,
              title: "Erreur de connexion",
              message: "Impossible de se connecter au serveur.",
              details: e.toString(),
            );
          }
        }
      });
    } else if (code.length < _codeLength) {
      setState(() {
        _success = false;
        _error = false;
      });
    }
  }

  void _resetOtpFields() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          for (final controller in _controllers) {
            controller.clear();
          }
          _error = false;
        });
        // Focus sur le premier champ après le reset
        if (_focusNodes.isNotEmpty) {
          _focusNodes[0].requestFocus();
        }
      }
    });
  }

  String _formatTimer(int totalSeconds) {
    int min = totalSeconds ~/ 60;
    int sec = totalSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // Méthode pour renvoyer le code OTP
  Future<void> _resendCode() async {
    if (_resendingCode || widget.email == null) return;

    setState(() => _resendingCode = true);

    try {
      late Map<String, dynamic> result;
      
      if (widget.isFromForgotPassword) {
        // Flux mot de passe oublié : utiliser forgotPassword
        result = await AuthApiService.forgotPassword(
          email: widget.email!,
        );
      } else {
        // Flux inscription : utiliser resendOtp
        result = await AuthApiService.resendOtp(
          email: widget.email!,
          action: 'registration',
        );
      }

      if (mounted) {
        if (result['success'] == true) {
          // Réinitialiser le timer
          _timer?.cancel();
          setState(() {
            _secondsLeft = 300; // 5 minutes
            _resendingCode = false;
            _error = false;
            _success = false;
          });
          
          // Redémarrer le timer
          _timer = Timer.periodic(const Duration(seconds: 1), (t) {
            if (_secondsLeft > 0) {
              setState(() => _secondsLeft--);
            } else {
              t.cancel();
            }
          });
          
          // Réinitialiser les champs
          for (final controller in _controllers) {
            controller.clear();
          }
          
          // Focus sur le premier champ
          if (_focusNodes.isNotEmpty) {
            _focusNodes[0].requestFocus();
          }
          
          // Afficher un message de succès spécifique au contexte
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isFromForgotPassword
                    ? "Un nouveau code de réinitialisation a été envoyé à ${widget.email}"
                    : "Un nouveau code de vérification a été envoyé à ${widget.email}",
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          setState(() => _resendingCode = false);
          
          // Afficher l'erreur
          if (mounted) {
            await ErrorPopup.show(
              context,
              title: "Erreur",
              message: result['error'] ?? "Impossible de renvoyer le code",
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _resendingCode = false);
        
        await ErrorPopup.show(
          context,
          title: "Erreur de connexion",
          message: "Impossible de renvoyer le code",
          details: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentBlue = theme.colorScheme.secondary;
    final mainBlue = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? theme.colorScheme.surface
          : theme.colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  double cardWidth = constraints.maxWidth < 370
                      ? constraints.maxWidth
                      : 370;
                  return Center(
                    child: Card(
                      elevation: 8,
                      color: theme.brightness == Brightness.dark
                          ? theme.colorScheme.surface
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Container(
                        width: cardWidth,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 32,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mark_email_read_rounded,
                              color: accentBlue,
                              size: 42,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.isFromForgotPassword
                                  ? "Réinitialisation du mot de passe"
                                  : "Vérification du compte",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 21,
                                color: mainBlue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.email != null
                                  ? widget.isFromForgotPassword
                                      ? "Un code de réinitialisation à 6 chiffres a été envoyé à\n${widget.email}.\nSaisissez-le pour continuer."
                                      : "Un code de vérification à 6 chiffres a été envoyé à\n${widget.email}.\nSaisissez-le pour activer votre compte."
                                  : "Un code à 6 chiffres a été envoyé par email.",
                              style: GoogleFonts.poppins(
                                fontSize: 14.2,
                                color: theme.brightness == Brightness.dark
                                    ? theme.colorScheme.onSurface.withValues(
                                        alpha: 0.8,
                                      )
                                    : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 13),
                            _secondsLeft > 0
                                ? Text(
                                    "Le code expire dans ${_formatTimer(_secondsLeft)}",
                                    style: GoogleFonts.poppins(
                                      color: accentBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.8,
                                    ),
                                  )
                                : Text(
                                    widget.isFromForgotPassword
                                        ? "Code expiré, demandez un nouveau code de réinitialisation."
                                        : "Code expiré, demandez un nouveau code de vérification.",
                                    style: GoogleFonts.poppins(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                            const SizedBox(height: 17),

                            // Bouton "Renvoyer le code" - n'apparaît que quand le timer est épuisé
                            if (_secondsLeft == 0 && !_success && !_loading)
                              Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: _resendingCode
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Icon(
                                              Icons.refresh_rounded,
                                              size: 18,
                                            ),
                                      label: Text(
                                        _resendingCode
                                            ? "Envoi en cours..."
                                            : widget.isFromForgotPassword
                                                ? "Renvoyer le code de réinitialisation"
                                                : "Renvoyer le code de vérification",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accentBlue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                      ),
                                      onPressed: _resendingCode ? null : _resendCode,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),

                            // Code Input
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_codeLength, (i) {
                                  // Calcul plus robuste de la largeur pour éviter les overflows
                                  double fieldWidth = (cardWidth - 80) / _codeLength;
                                  if (fieldWidth < 40) fieldWidth = 40;
                                  if (fieldWidth > 60) fieldWidth = 60;
                                  
                                  return Container(
                                    width: fieldWidth,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    child: TextField(
                                      controller: _controllers[i],
                                      focusNode: _focusNodes[i],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      maxLength: 1,
                                      enabled:
                                          _secondsLeft > 0 &&
                                          !_success &&
                                          !_loading,
                                      style: GoogleFonts.poppins(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                        color: _error
                                            ? Colors.red
                                            : _success
                                            ? Colors.green
                                            : mainBlue,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: "",
                                        filled: true,
                                        fillColor: _error
                                            ? (theme.brightness ==
                                                      Brightness.dark
                                                  ? Colors.red.withValues(
                                                      alpha: 0.2,
                                                    )
                                                  : Colors.red.withValues(
                                                      alpha: 0.13,
                                                    ))
                                            : _success
                                            ? (theme.brightness ==
                                                      Brightness.dark
                                                  ? Colors.green.withValues(
                                                      alpha: 0.2,
                                                    )
                                                  : Colors.green.withValues(
                                                      alpha: 0.13,
                                                    ))
                                            : (theme.brightness ==
                                                      Brightness.dark
                                                  ? theme.colorScheme.surface
                                                        .withValues(alpha: 0.5)
                                                  : Colors.grey[100]),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                          borderSide: BorderSide(
                                            color: _error
                                                ? Colors.red
                                                : _success
                                                ? Colors.green
                                                : accentBlue,
                                            width: 2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                          borderSide: BorderSide(
                                            color: _error
                                                ? Colors.red
                                                : _success
                                                ? Colors.green
                                                : accentBlue,
                                            width: 2.1,
                                          ),
                                        ),
                                      ),
                                      onChanged: (val) {
                                        if (val.length == 1 &&
                                            i < _codeLength - 1) {
                                          _focusNodes[i + 1].requestFocus();
                                        }
                                        if (val.isEmpty && i > 0) {
                                          _focusNodes[i - 1].requestFocus();
                                        }
                                        _onCodeChanged();
                                      },
                                      onTap: () => _controllers[i].selection =
                                          TextSelection(
                                            baseOffset: 0,
                                            extentOffset:
                                                _controllers[i].text.length,
                                          ),
                                    ),
                                  );
                                }),
                              ),
                            ),

                            const SizedBox(height: 19),
                            if (_loading)
                              const CircularProgressIndicator(strokeWidth: 2),
                            if (_success)
                              Column(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    widget.isFromForgotPassword
                                        ? "Code correct ! Vous pouvez maintenant choisir un nouveau mot de passe."
                                        : "Code correct ! Votre compte a été vérifié avec succès.",
                                    style: GoogleFonts.poppins(
                                      color: Colors.green,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    icon: Icon(
                                      widget.isFromForgotPassword
                                          ? Icons.arrow_forward_rounded
                                          : Icons.login_rounded,
                                      size: 19,
                                    ),
                                    label: Text(
                                      widget.isFromForgotPassword
                                          ? "Continuer"
                                          : "Se connecter",
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentBlue,
                                      foregroundColor: Colors.white,
                                      textStyle: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                        horizontal: 16,
                                      ),
                                    ),
                                    onPressed: () {
                                      if (widget.isFromForgotPassword) {
                                        // Flux mot de passe oublié : ouvrir la pop-up new_password
                                        // Récupérer le code OTP validé
                                        String validatedOtp = _controllers.map((c) => c.text).join();
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) =>
                                              NewPasswordScreen(
                                                email: widget.email ?? "",
                                                otp: validatedOtp,
                                              ),
                                        );
                                      } else {
                                        // Flux inscription : retourner à la page de connexion
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const LoginScreen(),
                                          ),
                                          (route) => false,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            if (_error)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    "Code invalide !",
                                    style: GoogleFonts.poppins(
                                      color: Colors.red,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 9),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                widget.isFromForgotPassword
                                    ? "Retour à la connexion"
                                    : "Retour à l'inscription",
                                style: GoogleFonts.poppins(
                                  color: accentBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
