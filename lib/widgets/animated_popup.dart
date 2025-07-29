import 'dart:ui';
import 'package:flutter/material.dart';

/// Widget utilitaire pour créer des animations de popup professionnelles et élégantes
class AnimatedPopup {
  /// Animation de type "fade + scale" avec effet de rebond élégant
  static Route<T> createFadeScaleRoute<T extends Object?>(
    Widget child, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeOutBack,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.7).round()),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Animation de fade
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(0.0, 0.8, curve: Curves.easeOut),
        ));

        // Animation de scale avec rebond élégant
        final scaleAnimation = Tween<double>(
          begin: 0.7,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        // Animation de slide subtile vers le haut
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Animation de type "slide from bottom" avec effet élastique
  static Route<T> createSlideFromBottomRoute<T extends Object?>(
    Widget child, {
    Duration duration = const Duration(milliseconds: 400),
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.6).round()),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Animation de slide depuis le bas
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        ));

        // Animation de fade
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(0.0, 0.7, curve: Curves.easeOut),
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Animation de type "slide from right" pour les panneaux latéraux
  static Route<T> createSlideFromRightRoute<T extends Object?>(
    Widget child, {
    Duration duration = const Duration(milliseconds: 300),
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.7).round()),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Animation de slide depuis la droite
        final slideAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        // Animation de fade
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(0.0, 0.6, curve: Curves.easeOut),
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Animation de type "zoom in" avec effet de rotation subtile
  static Route<T> createZoomRotateRoute<T extends Object?>(
    Widget child, {
    Duration duration = const Duration(milliseconds: 450),
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.6).round()),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Animation de scale
        final scaleAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        ));

        // Animation de rotation subtile
        final rotationAnimation = Tween<double>(
          begin: 0.1,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        // Animation de fade
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(0.0, 0.8, curve: Curves.easeOut),
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: Transform.rotate(
            angle: rotationAnimation.value,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Animation de type "blur fade" avec effet de flou progressif
  static Route<T> createBlurFadeRoute<T extends Object?>(
    Widget child, {
    Duration duration = const Duration(milliseconds: 300),
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.8).round()),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Animation de fade
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        // Animation de scale subtile
        final scaleAnimation = Tween<double>(
          begin: 1.1,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Animation avec effet de flou au lieu d'un fond sombre
  static Route<T> createBlurBackdropRoute<T extends Object?>(
    Widget child, {
    Duration duration = const Duration(milliseconds: 350),
    bool barrierDismissible = true,
  }) {
    return PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.8).round()),
      pageBuilder: (context, animation, secondaryAnimation) {
        // Animation de fade
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        // Animation de scale subtile
        final scaleAnimation = Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ));

        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: animation.value * 5.0,
            sigmaY: animation.value * 5.0,
          ),
          child: Scaffold(
            backgroundColor: Colors.black.withValues(alpha: animation.value * 0.1),
            body: FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Méthode utilitaire pour afficher un dialog avec une animation personnalisée
  static Future<T?> showAnimatedDialog<T extends Object?>({
    required BuildContext context,
    required Widget child,
    AnimationType animationType = AnimationType.fadeScale,
    Duration duration = const Duration(milliseconds: 350),
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    Route<T> route;

    switch (animationType) {
      case AnimationType.fadeScale:
        route = createFadeScaleRoute<T>(
          child,
          duration: duration,
          barrierDismissible: barrierDismissible,
          barrierColor: barrierColor,
        );
        break;
      case AnimationType.slideFromBottom:
        route = createSlideFromBottomRoute<T>(
          child,
          duration: duration,
          barrierDismissible: barrierDismissible,
          barrierColor: barrierColor,
        );
        break;
      case AnimationType.slideFromRight:
        route = createSlideFromRightRoute<T>(
          child,
          duration: duration,
          barrierDismissible: barrierDismissible,
          barrierColor: barrierColor,
        );
        break;
      case AnimationType.zoomRotate:
        route = createZoomRotateRoute<T>(
          child,
          duration: duration,
          barrierDismissible: barrierDismissible,
          barrierColor: barrierColor,
        );
        break;
      case AnimationType.blurFade:
        route = createBlurFadeRoute<T>(
          child,
          duration: duration,
          barrierDismissible: barrierDismissible,
          barrierColor: barrierColor,
        );
        break;
      case AnimationType.blurBackdrop:
        route = createBlurBackdropRoute<T>(
          child,
          duration: duration,
          barrierDismissible: barrierDismissible,
        );
        break;
    }

    return Navigator.of(context).push<T>(route);
  }
}

/// Types d'animations disponibles pour les popups
enum AnimationType {
  /// Animation de fade avec scale et rebond élégant
  fadeScale,
  
  /// Animation de slide depuis le bas avec effet élastique
  slideFromBottom,
  
  /// Animation de slide depuis la droite
  slideFromRight,
  
  /// Animation de zoom avec rotation subtile
  zoomRotate,
  
  /// Animation de fade avec blur progressif
  blurFade,
  
  /// Animation avec effet de flou en arrière-plan au lieu d'un fond sombre
  blurBackdrop,
}

/// Widget wrapper pour ajouter des micro-animations aux éléments de popup
class AnimatedPopupChild extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;

  const AnimatedPopupChild({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedPopupChild> createState() => _AnimatedPopupChildState();
}

class _AnimatedPopupChildState extends State<AnimatedPopupChild>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Démarrer l'animation après le délai spécifié
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
