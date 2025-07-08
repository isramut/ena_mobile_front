import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Configuration spécifique pour les plateformes mobiles (Android/iOS)
class MobilePlatformConfig {
  /// Configure les optimisations spécifiques à la plateforme
  static void configurePlatform() {
    if (kIsWeb) return; // Pas de configuration web puisque supprimé

    // Configuration Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      _configureAndroid();
    }

    // Configuration iOS
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _configureiOS();
    }
  }

  /// Configuration spécifique Android
  static void _configureAndroid() {
    // Navigation bar transparente
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );

    // Couleurs de la status bar pour Android
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Configuration spécifique iOS
  static void _configureiOS() {
    // Configuration iOS pour status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Obtient la configuration responsive optimisée pour mobile
  static ResponsiveMobileConfig getMobileConfig(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final platform = Theme.of(context).platform;

    // Configuration pour téléphones pliables (Galaxy Fold, etc.)
    if (size.width <= 374) {
      return ResponsiveMobileConfig.foldClosed(platform);
    }

    // Configuration pour petits téléphones
    if (size.width <= 390) {
      return ResponsiveMobileConfig.smallPhone(platform);
    }

    // Configuration pour téléphones standards
    if (size.width <= 430) {
      return ResponsiveMobileConfig.standardPhone(platform);
    }

    // Configuration pour téléphones pliables ouverts et tablettes
    if (size.width <= 717) {
      return ResponsiveMobileConfig.foldOpen(platform);
    }

    // Configuration pour tablettes
    return ResponsiveMobileConfig.tablet(platform);
  }

  /// Vérifie si l'appareil est un téléphone pliable
  static bool isFoldableDevice(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width <= 374 || (size.width >= 717 && size.width <= 800);
  }

  /// Vérifie si l'appareil est en mode paysage
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Obtient le safe area padding pour Android/iOS
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
}

/// Configuration responsive spécifique pour les appareils mobiles
class ResponsiveMobileConfig {
  final double padding;
  final double cardPadding;
  final double fontSize;
  final double iconSize;
  final double maxWidth;
  final int columns;
  final double aspectRatio;
  final double appBarHeight;
  final double bottomNavHeight;
  final TargetPlatform platform;

  const ResponsiveMobileConfig({
    required this.padding,
    required this.cardPadding,
    required this.fontSize,
    required this.iconSize,
    required this.maxWidth,
    required this.columns,
    required this.aspectRatio,
    required this.appBarHeight,
    required this.bottomNavHeight,
    required this.platform,
  });

  /// Configuration pour téléphones pliables fermés (Galaxy Fold fermé)
  factory ResponsiveMobileConfig.foldClosed(TargetPlatform platform) {
    return ResponsiveMobileConfig(
      padding: 8.0,
      cardPadding: 12.0,
      fontSize: 13.0,
      iconSize: 20.0,
      maxWidth: 360,
      columns: 1,
      aspectRatio: 1.1,
      appBarHeight: platform == TargetPlatform.iOS ? 44.0 : 56.0,
      bottomNavHeight: platform == TargetPlatform.iOS ? 83.0 : 80.0,
      platform: platform,
    );
  }

  /// Configuration pour petits téléphones (iPhone SE, petits Android)
  factory ResponsiveMobileConfig.smallPhone(TargetPlatform platform) {
    return ResponsiveMobileConfig(
      padding: 12.0,
      cardPadding: 14.0,
      fontSize: 14.0,
      iconSize: 22.0,
      maxWidth: 380,
      columns: 1,
      aspectRatio: 1.0,
      appBarHeight: platform == TargetPlatform.iOS ? 44.0 : 56.0,
      bottomNavHeight: platform == TargetPlatform.iOS ? 83.0 : 80.0,
      platform: platform,
    );
  }

  /// Configuration pour téléphones standards (iPhone 14, Galaxy S23)
  factory ResponsiveMobileConfig.standardPhone(TargetPlatform platform) {
    return ResponsiveMobileConfig(
      padding: 16.0,
      cardPadding: 16.0,
      fontSize: 15.0,
      iconSize: 24.0,
      maxWidth: 420,
      columns: platform == TargetPlatform.iOS
          ? 1
          : 2, // Android peut afficher 2 colonnes
      aspectRatio: 0.95,
      appBarHeight: platform == TargetPlatform.iOS ? 44.0 : 56.0,
      bottomNavHeight: platform == TargetPlatform.iOS ? 83.0 : 80.0,
      platform: platform,
    );
  }

  /// Configuration pour téléphones pliables ouverts (Galaxy Fold ouvert)
  factory ResponsiveMobileConfig.foldOpen(TargetPlatform platform) {
    return ResponsiveMobileConfig(
      padding: 20.0,
      cardPadding: 18.0,
      fontSize: 16.0,
      iconSize: 26.0,
      maxWidth: 700,
      columns: 2,
      aspectRatio: 0.9,
      appBarHeight: platform == TargetPlatform.iOS ? 44.0 : 56.0,
      bottomNavHeight: platform == TargetPlatform.iOS ? 83.0 : 80.0,
      platform: platform,
    );
  }

  /// Configuration pour tablettes (iPad, tablettes Android)
  factory ResponsiveMobileConfig.tablet(TargetPlatform platform) {
    return ResponsiveMobileConfig(
      padding: 24.0,
      cardPadding: 20.0,
      fontSize: 17.0,
      iconSize: 28.0,
      maxWidth: 1000,
      columns: 3,
      aspectRatio: 0.85,
      appBarHeight: platform == TargetPlatform.iOS ? 50.0 : 64.0,
      bottomNavHeight: platform == TargetPlatform.iOS ? 90.0 : 88.0,
      platform: platform,
    );
  }

  /// Retourne la taille de texte optimisée selon la plateforme
  double getOptimizedFontSize() {
    if (platform == TargetPlatform.iOS) {
      return fontSize * 1.05; // iOS préfère des polices légèrement plus grandes
    }
    return fontSize;
  }

  /// Retourne l'espacement optimisé selon la plateforme
  double getOptimizedPadding() {
    if (platform == TargetPlatform.iOS) {
      return padding * 1.1; // iOS préfère plus d'espacement
    }
    return padding;
  }
}
