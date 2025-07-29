import 'package:flutter/material.dart';

/// Widget utilitaire pour créer des transitions de page fluides, professionnelles et élégantes
class PageTransitions {
  /// Transition de type "slide and fade" - moderne et fluide
  static Route<T> slideAndFade<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    SlideDirection direction = SlideDirection.rightToLeft,
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.8).round()),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Animation de slide
        Offset begin;
        switch (direction) {
          case SlideDirection.rightToLeft:
            begin = const Offset(1.0, 0.0);
            break;
          case SlideDirection.leftToRight:
            begin = const Offset(-1.0, 0.0);
            break;
          case SlideDirection.topToBottom:
            begin = const Offset(0.0, -1.0);
            break;
          case SlideDirection.bottomToTop:
            begin = const Offset(0.0, 1.0);
            break;
        }

        final slideAnimation = Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        // Animation de fade
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(0.0, 0.7, curve: curve),
        ));

        // Animation de sortie de la page précédente
        final secondarySlideAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: direction == SlideDirection.rightToLeft
              ? const Offset(-0.3, 0.0)
              : const Offset(0.3, 0.0),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: curve,
        ));

        final secondaryFadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.7,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: curve,
        ));

        return SlideTransition(
          position: secondarySlideAnimation,
          child: FadeTransition(
            opacity: secondaryFadeAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Transition de type "fade and scale" - élégante et subtile
  static Route<T> fadeAndScale<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeOutCubic,
    double scaleBegin = 0.92,
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.8).round()),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Animation de fade principale
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        // Animation de scale subtile
        final scaleAnimation = Tween<double>(
          begin: scaleBegin,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ));

        // Animation de la page précédente
        final secondaryFadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.8,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: curve,
        ));

        final secondaryScaleAnimation = Tween<double>(
          begin: 1.0,
          end: 1.05,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: curve,
        ));

        return FadeTransition(
          opacity: secondaryFadeAnimation,
          child: ScaleTransition(
            scale: secondaryScaleAnimation,
            child: FadeTransition(
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

  /// Transition de type "shared axis" - moderne et Material Design 3
  static Route<T> sharedAxis<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    SharedAxisDirection direction = SharedAxisDirection.horizontal,
    Curve curve = Curves.easeInOutCubic,
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.8).round()),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const double slideDistance = 30.0;
        const double fadeDistance = 0.3;

        late Offset primarySlideBegin;
        late Offset primarySlideEnd;
        late Offset secondarySlideBegin;
        late Offset secondarySlideEnd;

        switch (direction) {
          case SharedAxisDirection.horizontal:
            primarySlideBegin = const Offset(slideDistance, 0.0);
            primarySlideEnd = Offset.zero;
            secondarySlideBegin = Offset.zero;
            secondarySlideEnd = const Offset(-slideDistance, 0.0);
            break;
          case SharedAxisDirection.vertical:
            primarySlideBegin = const Offset(0.0, slideDistance);
            primarySlideEnd = Offset.zero;
            secondarySlideBegin = Offset.zero;
            secondarySlideEnd = const Offset(0.0, -slideDistance);
            break;
        }

        // Animations pour la nouvelle page
        final primarySlideAnimation = Tween<Offset>(
          begin: primarySlideBegin,
          end: primarySlideEnd,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(fadeDistance, 1.0, curve: curve),
        ));

        final primaryFadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(fadeDistance, 1.0, curve: curve),
        ));

        // Animations pour l'ancienne page
        final secondarySlideAnimation = Tween<Offset>(
          begin: secondarySlideBegin,
          end: secondarySlideEnd,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: Interval(0.0, 1.0 - fadeDistance, curve: curve),
        ));

        final secondaryFadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: Interval(0.0, 1.0 - fadeDistance, curve: curve),
        ));

        return SlideTransition(
          position: secondarySlideAnimation,
          child: FadeTransition(
            opacity: secondaryFadeAnimation,
            child: SlideTransition(
              position: primarySlideAnimation,
              child: FadeTransition(
                opacity: primaryFadeAnimation,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Transition de type "fade through" - fluide et élégante
  static Route<T> fadeThrough<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOutCubic,
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.8).round()),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const double fadeOutInterval = 0.4;
        const double fadeInInterval = 0.6;

        // Animation de fade out pour l'ancienne page
        final fadeOutAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: Interval(0.0, fadeOutInterval, curve: curve),
        ));

        // Animation de fade in pour la nouvelle page
        final fadeInAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(fadeInInterval, 1.0, curve: curve),
        ));

        // Scale subtile pour la nouvelle page
        final scaleAnimation = Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(fadeInInterval, 1.0, curve: Curves.easeOutCubic),
        ));

        return FadeTransition(
          opacity: fadeOutAnimation,
          child: FadeTransition(
            opacity: fadeInAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Transition personnalisée pour les formulaires - avec parallax
  static Route<T> formTransition<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.7).round()),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Animation de slide avec effet parallax
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

        // Effet parallax sur la page précédente
        final parallaxAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.5, 0.0),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutCubic,
        ));

        return SlideTransition(
          position: parallaxAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Transition rapide et moderne pour les actions fréquentes
  static Route<T> quickSlide<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 250),
    SlideDirection direction = SlideDirection.rightToLeft,
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.9).round()),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin;
        switch (direction) {
          case SlideDirection.rightToLeft:
            begin = const Offset(1.0, 0.0);
            break;
          case SlideDirection.leftToRight:
            begin = const Offset(-1.0, 0.0);
            break;
          case SlideDirection.topToBottom:
            begin = const Offset(0.0, -1.0);
            break;
          case SlideDirection.bottomToTop:
            begin = const Offset(0.0, 1.0);
            break;
        }

        final slideAnimation = Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.fastEaseInToSlowEaseOut,
        ));

        return SlideTransition(
          position: slideAnimation,
          child: child,
        );
      },
    );
  }

  /// Méthode helper pour Navigator.push avec transition personnalisée
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget page, {
    PageTransitionType type = PageTransitionType.slideAndFade,
    Duration? duration,
    SlideDirection slideDirection = SlideDirection.rightToLeft,
    SharedAxisDirection sharedAxisDirection = SharedAxisDirection.horizontal,
    Curve? curve,
  }) {
    Route<T> route;

    switch (type) {
      case PageTransitionType.slideAndFade:
        route = slideAndFade<T>(
          page,
          duration: duration ?? const Duration(milliseconds: 300),
          direction: slideDirection,
          curve: curve ?? Curves.easeOutCubic,
        );
        break;
      case PageTransitionType.fadeAndScale:
        route = fadeAndScale<T>(
          page,
          duration: duration ?? const Duration(milliseconds: 350),
          curve: curve ?? Curves.easeOutCubic,
        );
        break;
      case PageTransitionType.sharedAxis:
        route = sharedAxis<T>(
          page,
          duration: duration ?? const Duration(milliseconds: 300),
          direction: sharedAxisDirection,
          curve: curve ?? Curves.easeInOutCubic,
        );
        break;
      case PageTransitionType.fadeThrough:
        route = fadeThrough<T>(
          page,
          duration: duration ?? const Duration(milliseconds: 400),
          curve: curve ?? Curves.easeInOutCubic,
        );
        break;
      case PageTransitionType.formTransition:
        route = formTransition<T>(
          page,
          duration: duration ?? const Duration(milliseconds: 350),
        );
        break;
      case PageTransitionType.quickSlide:
        route = quickSlide<T>(
          page,
          duration: duration ?? const Duration(milliseconds: 250),
          direction: slideDirection,
        );
        break;
    }

    return Navigator.of(context).push<T>(route);
  }

  /// Méthode helper pour Navigator.pushReplacement avec transition personnalisée
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page, {
    PageTransitionType type = PageTransitionType.fadeThrough,
    Duration? duration,
    SlideDirection slideDirection = SlideDirection.rightToLeft,
    SharedAxisDirection sharedAxisDirection = SharedAxisDirection.horizontal,
    Curve? curve,
    TO? result,
  }) {
    Route<T> route;

    switch (type) {
      case PageTransitionType.slideAndFade:
        route = slideAndFade<T>(
          page,
          duration: duration ?? const Duration(milliseconds: 300),
          direction: slideDirection,
          curve: curve ?? Curves.easeOutCubic,
        );
        break;
      case PageTransitionType.fadeAndScale:
        route = fadeAndScale<T>(
          page,
          duration: duration ?? const Duration(milliseconds: 350),
          curve: curve ?? Curves.easeOutCubic,
        );
        break;
      case PageTransitionType.sharedAxis:
        route = sharedAxis<T>(
          page,
          duration: duration ?? const Duration(milliseconds: 300),
          direction: sharedAxisDirection,
          curve: curve ?? Curves.easeInOutCubic,
        );
        break;
      case PageTransitionType.fadeThrough:
        route = fadeThrough<T>(
          page,
          duration: duration ?? const Duration(milliseconds: 400),
          curve: curve ?? Curves.easeInOutCubic,
        );
        break;
      case PageTransitionType.formTransition:
        route = formTransition<T>(
          page,
          duration: duration ?? const Duration(milliseconds: 350),
        );
        break;
      case PageTransitionType.quickSlide:
        route = quickSlide<T>(
          page,
          duration: duration ?? const Duration(milliseconds: 250),
          direction: slideDirection,
        );
        break;
    }

    return Navigator.of(context).pushReplacement<T, TO>(route, result: result);
  }
}

/// Types de transitions disponibles
enum PageTransitionType {
  /// Slide avec fade - moderne et fluide
  slideAndFade,
  
  /// Fade avec scale - élégant et subtil
  fadeAndScale,
  
  /// Shared axis - Material Design 3
  sharedAxis,
  
  /// Fade through - fluide et professionnel
  fadeThrough,
  
  /// Transition pour formulaires avec parallax
  formTransition,
  
  /// Slide rapide pour actions fréquentes
  quickSlide,
}

/// Directions de slide disponibles
enum SlideDirection {
  rightToLeft,
  leftToRight,
  topToBottom,
  bottomToTop,
}

/// Directions pour shared axis
enum SharedAxisDirection {
  horizontal,
  vertical,
}
