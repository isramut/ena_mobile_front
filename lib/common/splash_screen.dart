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
  // Controllers pour les animations
  late AnimationController _initialGrowController;
  late AnimationController _moveUpController;
  late AnimationController _finalGrowController;
  late AnimationController _armoirieController;
  late AnimationController _checkerboardController;
  
  // Animations
  late Animation<double> _initialGrowAnimation;
  late Animation<double> _moveUpAnimation;
  late Animation<double> _finalGrowAnimation;
  late Animation<double> _armoirieAnimation;
  late Animation<double> _checkerboardAnimation;

  // Texte animé
  String fullText = "Servir l'État avec intégrité, compétence et patriotisme.";
  String displayedText = '';
  int charIndex = 0;
  Timer? _textTimer;
  Timer? _cursorTimer;

  bool showText = false;
  bool showArmoirie = false;
  bool showCursor = true;
  bool writingDone = false;

  // Pour la suite
  List<int> typingDelays = [];
  final List<String> motsGras = [
    "État",
    "intégrité", 
    "patriotisme",
  ];
  int nextBoldWordIndex = 0;
  int boldWordStart = -1;
  int boldWordEnd = -1;

  @override
  void initState() {
    super.initState();

    // 1. Animation de croissance initiale (20% → 40%)
    _initialGrowController = AnimationController(
      duration: const Duration(milliseconds: 2000), // +500ms
      vsync: this,
    );
    _initialGrowAnimation = Tween<double>(begin: 0.2, end: 0.4).animate(
      CurvedAnimation(parent: _initialGrowController, curve: Curves.easeInOut),
    );

    // 2. Animation de déplacement vers le haut
    _moveUpController = AnimationController(
      duration: const Duration(milliseconds: 1200), // +200ms
      vsync: this,
    );
    _moveUpAnimation = Tween<double>(begin: 0.0, end: -300.0).animate(
      CurvedAnimation(parent: _moveUpController, curve: Curves.easeInOut),
    );

    // 3. Animation de croissance finale (40% → 70%)
    _finalGrowController = AnimationController(
      duration: const Duration(milliseconds: 1500), // +300ms
      vsync: this,
    );
    _finalGrowAnimation = Tween<double>(begin: 0.4, end: 0.7).animate(
      CurvedAnimation(parent: _finalGrowController, curve: Curves.easeInOut),
    );

    // 4. Animation de l'armoirie (0% → 60%) - commence quand le logo atteint 70%
    _armoirieController = AnimationController(
      duration: const Duration(milliseconds: 2500), // +500ms pour le texte plus long
      vsync: this,
    );
    _armoirieAnimation = Tween<double>(begin: 0.0, end: 0.6).animate(
      CurvedAnimation(parent: _armoirieController, curve: Curves.easeInOut),
    );

    // 5. Animation de transition damier
    _checkerboardController = AnimationController(
      duration: const Duration(milliseconds: 1800), // Durée augmentée pour un effet plus visible
      vsync: this,
    );
    _checkerboardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkerboardController, curve: Curves.easeInOut),
    );

    _startAnimationSequence();
    _generateRandomDelays();
  }

  @override
  void dispose() {
    _initialGrowController.dispose();
    _moveUpController.dispose();
    _finalGrowController.dispose();
    _armoirieController.dispose();
    _checkerboardController.dispose();
    _textTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  void _generateRandomDelays() {
    final random = Random();
    for (int i = 0; i < fullText.length; i++) {
      typingDelays.add(random.nextInt(80) + 40);
    }
  }

  void _startAnimationSequence() async {
    // Étape 1 : Croissance initiale (20% → 40%)
    await _initialGrowController.forward();
    
    // Étape 2 : Déplacement vers le haut
    await _moveUpController.forward();
    
    // Étape 3 : Croissance finale (40% → 70%) + début de l'armoirie et du texte
    _finalGrowController.forward().then((_) {
      // Une fois la croissance terminée, commencer l'armoirie, le texte et le curseur en parallèle
      if (mounted) {
        setState(() {
          showText = true;
          showArmoirie = true;
        });
        
        // Démarrer l'animation de l'armoirie en parallèle
        _armoirieController.forward();
        
        // Démarrer le texte
        _startTextAnimation();
        _startCursorBlink();
      }
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
      writingDone = true;

      // Attendre 1.5 secondes puis commencer la transition damier
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {

          // Démarrer l'effet damier qui couvre progressivement l'écran
          _checkerboardController.forward().then((_) {

            // Attendre un petit délai pour que l'effet soit bien visible avant de naviguer
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _navigateToNextScreen();
              }
            });
          });
        }
      });
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;
    
    // Transition vers la page de login avec effet de fondu
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
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
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A365D),
      body: Stack(
        children: [
          // Logo principal avec toutes les animations
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _initialGrowController,
                _moveUpController,
                _finalGrowController,
              ]),
              builder: (context, child) {
                // Calculer la taille actuelle du logo selon l'étape
                double currentScale;
                if (_finalGrowController.isAnimating || _finalGrowController.isCompleted) {
                  currentScale = _finalGrowAnimation.value;
                } else {
                  currentScale = _initialGrowAnimation.value;
                }
                
                return Transform.translate(
                  offset: Offset(0, _moveUpAnimation.value),
                  child: SizedBox(
                    width: screenSize.width * currentScale,
                    height: screenSize.width * currentScale,
                    child: Image.asset(
                      'assets/images/ena_logo_blanc.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),

          // Armoirie au centre de l'écran (apparaît quand le logo atteint 70%)
          if (showArmoirie)
            Center(
              child: AnimatedBuilder(
                animation: _armoirieController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _armoirieAnimation.value > 0 ? 1.0 : 0.0,
                    child: SizedBox(
                      width: screenSize.width * _armoirieAnimation.value,
                      height: screenSize.width * _armoirieAnimation.value,
                      child: Image.asset(
                        'assets/images/armoirie.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Texte animé en bas
          if (showText)
            Positioned(
              bottom: screenSize.height * 0.15,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: screenSize.width * 0.9),
                  child: _buildAnimatedText(),
                ),
              ),
            ),

          // Effet damier de transition (toujours présent pour voir l'animation complète)
          AnimatedBuilder(
            animation: _checkerboardAnimation,
            builder: (context, child) {
              // Afficher l'effet damier dès que l'animation commence
              if (_checkerboardAnimation.value > 0.0) {
                return CustomPaint(
                  size: screenSize,
                  painter: CheckerboardPainter(
                    progress: _checkerboardAnimation.value,
                    screenSize: screenSize,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
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
              fontSize: 20,
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
              fontSize: 20,
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
              fontSize: 20,
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
              fontSize: 20,
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
                fontSize: 20,
              ),
            ),
            if (showCursor)
              TextSpan(
                text: " _",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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

// Classe pour l'effet damier de transition
class CheckerboardPainter extends CustomPainter {
  final double progress;
  final Size screenSize;

  CheckerboardPainter({
    required this.progress,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Utiliser un blanc semi-transparent pour un effet de fade-out visible
    final paint = Paint()
      ..style = PaintingStyle.fill;

    const int rows = 8;
    const int cols = 6;
    final double cellWidth = screenSize.width / cols;
    final double cellHeight = screenSize.height / rows;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        // Calculer le délai pour chaque cellule (effet domino diagonal)
        final double cellDelay = (row + col) / (rows + cols - 2) * 0.7; // Réduire le délai pour un effet plus visible
        final double cellProgress = ((progress - cellDelay) / (1 - cellDelay)).clamp(0.0, 1.0);
        
        if (cellProgress > 0) {
          // Créer un effet de transition blanc qui couvre progressivement l'écran
          final double cellOpacity = cellProgress * 0.95; // Opacité élevée pour être bien visible
          paint.color = Colors.white.withValues(alpha: cellOpacity);
          
          final Rect rect = Rect.fromLTWH(
            col * cellWidth,
            row * cellHeight,
            cellWidth,
            cellHeight,
          );
          
          canvas.drawRect(rect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CheckerboardPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
