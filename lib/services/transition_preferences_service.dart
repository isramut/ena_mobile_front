import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/page_transitions.dart';

/// Service pour gérer les préférences de transitions de l'utilisateur
class TransitionPreferencesService {
  static const String _transitionTypeKey = 'user_preferred_transition_type';
  static const String _transitionDurationKey = 'user_preferred_transition_duration';
  static const String _transitionDirectionKey = 'user_preferred_transition_direction';

  // Valeurs par défaut
  static const PageTransitionType _defaultTransitionType = PageTransitionType.slideAndFade;
  static const int _defaultDuration = 300;
  static const SlideDirection _defaultDirection = SlideDirection.rightToLeft;

  /// Sauvegarder les préférences de transition de l'utilisateur
  static Future<void> saveTransitionPreferences({
    required PageTransitionType transitionType,
    required int durationMs,
    required SlideDirection direction,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_transitionTypeKey, transitionType.name);
    await prefs.setInt(_transitionDurationKey, durationMs);
    await prefs.setString(_transitionDirectionKey, direction.name);
  }

  /// Charger les préférences de transition de l'utilisateur
  static Future<TransitionPreferences> loadTransitionPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Charger le type de transition
    final transitionTypeString = prefs.getString(_transitionTypeKey);
    PageTransitionType transitionType = _defaultTransitionType;
    
    if (transitionTypeString != null) {
      transitionType = PageTransitionType.values.firstWhere(
        (type) => type.name == transitionTypeString,
        orElse: () => _defaultTransitionType,
      );
    }
    
    // Charger la durée
    final duration = prefs.getInt(_transitionDurationKey) ?? _defaultDuration;
    
    // Charger la direction
    final directionString = prefs.getString(_transitionDirectionKey);
    SlideDirection direction = _defaultDirection;
    
    if (directionString != null) {
      direction = SlideDirection.values.firstWhere(
        (dir) => dir.name == directionString,
        orElse: () => _defaultDirection,
      );
    }
    
    return TransitionPreferences(
      transitionType: transitionType,
      durationMs: duration,
      direction: direction,
    );
  }

  /// Réinitialiser aux valeurs par défaut
  static Future<void> resetToDefault() async {
    await saveTransitionPreferences(
      transitionType: _defaultTransitionType,
      durationMs: _defaultDuration,
      direction: _defaultDirection,
    );
  }
}

/// Classe pour stocker les préférences de transition
class TransitionPreferences {
  final PageTransitionType transitionType;
  final int durationMs;
  final SlideDirection direction;

  const TransitionPreferences({
    required this.transitionType,
    required this.durationMs,
    required this.direction,
  });

  Duration get duration => Duration(milliseconds: durationMs);

  @override
  String toString() {
    return 'TransitionPreferences(type: $transitionType, duration: ${durationMs}ms, direction: $direction)';
  }
}

/// Provider pour gérer l'état global des transitions
class TransitionProvider extends ChangeNotifier {
  TransitionPreferences _preferences = const TransitionPreferences(
    transitionType: PageTransitionType.slideAndFade,
    durationMs: 300,
    direction: SlideDirection.rightToLeft,
  );

  TransitionPreferences get preferences => _preferences;

  /// Initialiser les préférences au démarrage de l'app
  Future<void> initializePreferences() async {
    _preferences = await TransitionPreferencesService.loadTransitionPreferences();
    notifyListeners();
  }

  /// Mettre à jour les préférences de transition
  Future<void> updateTransitionPreferences({
    required PageTransitionType transitionType,
    required int durationMs,
    required SlideDirection direction,
  }) async {
    _preferences = TransitionPreferences(
      transitionType: transitionType,
      durationMs: durationMs,
      direction: direction,
    );
    
    // Sauvegarder les nouvelles préférences
    await TransitionPreferencesService.saveTransitionPreferences(
      transitionType: transitionType,
      durationMs: durationMs,
      direction: direction,
    );
    
    notifyListeners();
  }

  /// Réinitialiser aux valeurs par défaut
  Future<void> resetToDefault() async {
    await TransitionPreferencesService.resetToDefault();
    await initializePreferences();
  }
}

/// Extensions pour utiliser automatiquement les préférences utilisateur
extension ContextTransitionsWithPreferences on BuildContext {
  /// Navigue en utilisant les préférences de l'utilisateur
  Future<T?> pushPageWithUserPreferences<T extends Object?>(
    Widget page, {
    PageTransitionType? overrideType,
    Duration? overrideDuration,
    SlideDirection? overrideDirection,
  }) async {
    // Récupérer les préférences actuelles
    final preferences = await TransitionPreferencesService.loadTransitionPreferences();
    
    return PageTransitions.push<T>(
      this,
      page,
      type: overrideType ?? preferences.transitionType,
      duration: overrideDuration ?? preferences.duration,
      slideDirection: overrideDirection ?? preferences.direction,
    );
  }

  /// Remplace la page en utilisant les préférences de l'utilisateur
  Future<T?> replacePageWithUserPreferences<T extends Object?, TO extends Object?>(
    Widget page, {
    PageTransitionType? overrideType,
    Duration? overrideDuration,
    SlideDirection? overrideDirection,
    TO? result,
  }) async {
    final preferences = await TransitionPreferencesService.loadTransitionPreferences();
    
    return PageTransitions.pushReplacement<T, TO>(
      this,
      page,
      type: overrideType ?? preferences.transitionType,
      duration: overrideDuration ?? preferences.duration,
      slideDirection: overrideDirection ?? preferences.direction,
      result: result,
    );
  }
}

/// Widget helper pour naviguer automatiquement avec les préférences utilisateur
class SmartNavigationButton extends StatelessWidget {
  final Widget child;
  final Widget targetPage;
  final VoidCallback? onPressed;
  final PageTransitionType? overrideTransitionType;
  final Duration? overrideDuration;
  final SlideDirection? overrideDirection;

  const SmartNavigationButton({
    super.key,
    required this.child,
    required this.targetPage,
    this.onPressed,
    this.overrideTransitionType,
    this.overrideDuration,
    this.overrideDirection,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        onPressed?.call();
        
        // Utiliser les préférences de l'utilisateur pour la navigation
        await context.pushPageWithUserPreferences(
          targetPage,
          overrideType: overrideTransitionType,
          overrideDuration: overrideDuration,
          overrideDirection: overrideDirection,
        );
      },
      child: child,
    );
  }
}
