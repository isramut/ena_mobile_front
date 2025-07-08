import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController logoMainController;
  late Animation<double> logoScaleAnimation;
  late Animation<double> logoPositionAnimation;
  late AnimationController logoFinalGrowController;
  late Animation<double> logoFinalScaleAnimation;

  // Texte animé (partie 2)
  String fullText = 'Servir l Etat avec Integrite, Competence et Patriotisme.';
  String displayedText = '';
  int charIndex = 0;
  Timer? _textTimer;
  Timer? _cursorTimer;

  bool showText = false;
  bool showLogoFinal = false;
  bool showCursor = true;
  bool writingDone = false;

  // Pour la suite
  List<int> typingDelays = [];
  final List<String> motsGras = [
    "Etat",
    "Integrite",
    "Competence",
    "Patriotisme",
  ];
  int nextBoldWordIndex = 0;
  int boldWordStart = -1;
  int boldWordEnd = -1;

  @override
  void initState() {
    super.initState();

    // Controller principal du logo
    logoMainController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: logoMainController, curve: Curves.bounceOut),
    );
    logoPositionAnimation = Tween<double>(begin: 0.0, end: -50.0).animate(
      CurvedAnimation(parent: logoMainController, curve: Curves.easeInOut),
    );

    // Controller pour la dernière croissance du logo
    logoFinalGrowController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    logoFinalScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: logoFinalGrowController, curve: Curves.easeOut),
    );

    _startAnimations();
    _generateRandomDelays();
  }

  @override
  void dispose() {
    logoMainController.dispose();
    logoFinalGrowController.dispose();
    _textTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  void _generateRandomDelays() {
    final random = Random();
    for (int i = 0; i < fullText.length; i++) {
      typingDelays.add(random.nextInt(100) + 50);
    }
  }

  void _startAnimations() {
    logoMainController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            showText = true;
          });
          _startTextAnimation();
          _startCursorBlink();
        }
      });
    });
  }

  void _startTextAnimation() {
    _findNextBoldWord();
    _typeNextCharacter();
  }

  void _findNextBoldWord() {
    if (nextBoldWordIndex < motsGras.length) {
      String motCherche = motsGras[nextBoldWordIndex];
      int startIndex = fullText.indexOf(motCherche, charIndex);
      if (startIndex != -1) {
        boldWordStart = startIndex;
        boldWordEnd = startIndex + motCherche.length - 1;
      }
    }
  }

  void _typeNextCharacter() {
    if (charIndex < fullText.length) {
      int delay = typingDelays[charIndex];
      _textTimer = Timer(Duration(milliseconds: delay), () {
        if (mounted) {
          setState(() {
            displayedText += fullText[charIndex];
            charIndex++;
          });

          if (charIndex - 1 == boldWordEnd) {
            nextBoldWordIndex++;
            _findNextBoldWord();
          }

          _typeNextCharacter();
        }
      });
    } else {
      _finishTextAnimation();
    }
  }

  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted && !writingDone) {
        setState(() {
          showCursor = !showCursor;
        });
      }
    });
  }

  void _finishTextAnimation() {
    if (mounted) {
      setState(() {
        showLogoFinal = true;
      });
      logoFinalGrowController.forward();
      writingDone = true;
      Future.delayed(const Duration(milliseconds: 1500), _goToLogin);
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(seconds: 2),
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(
          onLoginSuccess: () {
            // This will be handled by the LoginScreen itself
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A365D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo avec animations
            AnimatedBuilder(
              animation: logoMainController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, logoPositionAnimation.value),
                  child: showLogoFinal
                      ? AnimatedBuilder(
                          animation: logoFinalGrowController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: logoFinalScaleAnimation.value,
                              child: Image.asset(
                                'assets/images/ena_logo_blanc.png',
                                width: 120,
                                height: 120,
                              ),
                            );
                          },
                        )
                      : Transform.scale(
                          scale: logoScaleAnimation.value,
                          child: Image.asset(
                            'assets/images/ena_logo_blanc.png',
                            width: 120,
                            height: 120,
                          ),
                        ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Texte animé
            if (showText)
              Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: _buildAnimatedText(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedText() {
    // Logique pour afficher le texte avec des mots en gras
    if (_hasCurrentBoldWord()) {
      List<TextSpan> spans = [];

      // Texte avant le mot en gras
      if (boldWordStart > 0) {
        spans.add(
          TextSpan(
            text: displayedText.substring(0, boldWordStart),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
        );
      }

      // Le mot en gras (partiellement tapé)
      int endIndex = min(displayedText.length, boldWordEnd + 1);
      if (endIndex > boldWordStart) {
        spans.add(
          TextSpan(
            text: displayedText.substring(boldWordStart, endIndex),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        );
      }

      // Texte après le mot en gras
      if (displayedText.length > boldWordEnd + 1) {
        spans.add(
          TextSpan(
            text: displayedText.substring(boldWordEnd + 1),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
        );
      }

      // Curseur
      if (showCursor) {
        spans.add(
          TextSpan(
            text: " _",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        );
      }

      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: spans),
      );
    } else {
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: displayedText,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 22,
              ),
            ),
            if (showCursor)
              TextSpan(
                text: " _",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
          ],
        ),
      );
    }
  }

  bool _hasCurrentBoldWord() {
    return boldWordStart != -1 &&
        displayedText.length > boldWordStart &&
        charIndex <= boldWordEnd + 1;
  }
}
