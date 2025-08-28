import 'package:flutter/material.dart';
import '../services/transition_preferences_service.dart';
import '../widgets/page_transitions.dart';

/// Utilitaire pour la navigation avec transitions automatiques
/// 
/// Ce helper applique automatiquement les préférences de l'utilisateur
/// à toutes les navigations de l'application.
class AppNavigator {
  
  /// Navigation avec préférences utilisateur
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget page, {
    PageTransitionType? forceType,
    Duration? forceDuration,
    SlideDirection? forceDirection,
  }) async {
    // Si un type est forcé, l'utiliser directement
    if (forceType != null) {
      return PageTransitions.push<T>(
        context,
        page,
        type: forceType,
        duration: forceDuration ?? const Duration(milliseconds: 300),
        slideDirection: forceDirection ?? SlideDirection.rightToLeft,
      );
    }
    
    // Sinon, charger les préférences utilisateur
    try {
      final prefs = await TransitionPreferencesService.loadTransitionPreferences();
      if (!context.mounted) return null;
      return PageTransitions.push<T>(
        context,
        page,
        type: prefs.transitionType,
        duration: Duration(milliseconds: prefs.durationMs),
        slideDirection: prefs.direction,
      );
    } catch (e) {
      // En cas d'erreur, utiliser une transition par défaut
      if (!context.mounted) return null;
      return PageTransitions.push<T>(
        context,
        page,
        type: PageTransitionType.slideAndFade,
        duration: const Duration(milliseconds: 300),
        slideDirection: SlideDirection.rightToLeft,
      );
    }
  }
  
  /// Navigation de remplacement avec préférences utilisateur
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page, {
    TO? result,
    PageTransitionType? forceType,
    Duration? forceDuration,
    SlideDirection? forceDirection,
  }) async {
    // Si un type est forcé, l'utiliser directement
    if (forceType != null) {
      return PageTransitions.pushReplacement<T, TO>(
        context,
        page,
        result: result,
        type: forceType,
        duration: forceDuration ?? const Duration(milliseconds: 300),
        slideDirection: forceDirection ?? SlideDirection.rightToLeft,
      );
    }
    
    // Sinon, charger les préférences utilisateur
    try {
      final prefs = await TransitionPreferencesService.loadTransitionPreferences();
      if (!context.mounted) return null;
      return PageTransitions.pushReplacement<T, TO>(
        context,
        page,
        result: result,
        type: prefs.transitionType,
        duration: Duration(milliseconds: prefs.durationMs),
        slideDirection: prefs.direction,
      );
    } catch (e) {
      // En cas d'erreur, utiliser une transition par défaut
      if (!context.mounted) return null;
      return PageTransitions.pushReplacement<T, TO>(
        context,
        page,
        result: result,
        type: PageTransitionType.fadeThrough,
        duration: const Duration(milliseconds: 500),
        slideDirection: SlideDirection.rightToLeft,
      );
    }
  }
  
  /// Navigation spécialisée pour les formulaires
  static Future<T?> pushForm<T extends Object?>(
    BuildContext context,
    Widget formPage,
  ) {
    return push<T>(
      context,
      formPage,
      forceType: PageTransitionType.formTransition,
      forceDuration: const Duration(milliseconds: 350),
    );
  }
  
  /// Navigation spécialisée pour les pages de détail
  static Future<T?> pushDetail<T extends Object?>(
    BuildContext context,
    Widget detailPage,
  ) {
    return push<T>(
      context,
      detailPage,
      forceType: PageTransitionType.fadeAndScale,
      forceDuration: const Duration(milliseconds: 350),
    );
  }
  
  /// Navigation rapide pour les actions fréquentes
  static Future<T?> pushQuick<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return push<T>(
      context,
      page,
      forceType: PageTransitionType.quickSlide,
      forceDuration: const Duration(milliseconds: 250),
    );
  }
  
  /// Navigation depuis le bas (pour chat, modales, etc.)
  static Future<T?> pushFromBottom<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return push<T>(
      context,
      page,
      forceDirection: SlideDirection.bottomToTop,
    );
  }
}
