import 'package:flutter/material.dart';
import 'page_transitions.dart';

/// Extension sur Navigator pour simplifier l'utilisation des transitions
extension NavigatorTransitions on NavigatorState {
  /// Push avec transitions personnalisées
  Future<T?> pushWithTransition<T extends Object?>(
    Widget page, {
    PageTransitionType type = PageTransitionType.slideAndFade,
    Duration? duration,
    SlideDirection slideDirection = SlideDirection.rightToLeft,
    SharedAxisDirection sharedAxisDirection = SharedAxisDirection.horizontal,
    Curve? curve,
  }) {
    return PageTransitions.push<T>(
      context,
      page,
      type: type,
      duration: duration,
      slideDirection: slideDirection,
      sharedAxisDirection: sharedAxisDirection,
      curve: curve,
    );
  }

  /// Push replacement avec transitions personnalisées
  Future<T?> pushReplacementWithTransition<T extends Object?, TO extends Object?>(
    Widget page, {
    PageTransitionType type = PageTransitionType.fadeThrough,
    Duration? duration,
    SlideDirection slideDirection = SlideDirection.rightToLeft,
    SharedAxisDirection sharedAxisDirection = SharedAxisDirection.horizontal,
    Curve? curve,
    TO? result,
  }) {
    return PageTransitions.pushReplacement<T, TO>(
      context,
      page,
      type: type,
      duration: duration,
      slideDirection: slideDirection,
      sharedAxisDirection: sharedAxisDirection,
      curve: curve,
      result: result,
    );
  }
}

/// Extension sur BuildContext pour un accès encore plus simple
extension ContextTransitions on BuildContext {
  /// Navigue vers une nouvelle page avec une transition fluide
  Future<T?> pushPage<T extends Object?>(
    Widget page, {
    PageTransitionType type = PageTransitionType.slideAndFade,
    Duration? duration,
    SlideDirection slideDirection = SlideDirection.rightToLeft,
    SharedAxisDirection sharedAxisDirection = SharedAxisDirection.horizontal,
    Curve? curve,
  }) {
    return PageTransitions.push<T>(
      this,
      page,
      type: type,
      duration: duration,
      slideDirection: slideDirection,
      sharedAxisDirection: sharedAxisDirection,
      curve: curve,
    );
  }

  /// Remplace la page actuelle avec une transition fluide
  Future<T?> replacePage<T extends Object?, TO extends Object?>(
    Widget page, {
    PageTransitionType type = PageTransitionType.fadeThrough,
    Duration? duration,
    SlideDirection slideDirection = SlideDirection.rightToLeft,
    SharedAxisDirection sharedAxisDirection = SharedAxisDirection.horizontal,
    Curve? curve,
    TO? result,
  }) {
    return PageTransitions.pushReplacement<T, TO>(
      this,
      page,
      type: type,
      duration: duration,
      slideDirection: slideDirection,
      sharedAxisDirection: sharedAxisDirection,
      curve: curve,
      result: result,
    );
  }
}
