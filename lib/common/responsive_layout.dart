import 'package:flutter/material.dart';
import 'responsive_helper.dart';

/// Layout principal responsive qui wrap toute l'application
class EnaResponsiveLayout extends StatelessWidget {
  final Widget child;
  final bool enablePadding;
  final bool centerContent;

  const EnaResponsiveLayout({
    super.key,
    required this.child,
    this.enablePadding = true,
    this.centerContent = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      builder: (context, screenType, dimensions) {
        Widget content = child;

        // Ajouter du padding responsive si activé
        if (enablePadding) {
          content = Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dimensions.padding,
              vertical: dimensions.padding / 2,
            ),
            child: content,
          );
        }

        // Centrer le contenu si demandé et si c'est un grand écran
        if (centerContent &&
            (screenType == ScreenType.tablet ||
                screenType == ScreenType.desktop)) {
          content = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dimensions.maxWidth),
              child: content,
            ),
          );
        }

        return content;
      },
    );
  }
}

/// Mixin pour ajouter facilement des fonctionnalités responsive aux widgets existants
mixin ResponsiveMixin {
  /// Obtient les dimensions responsive pour le contexte actuel
  ResponsiveDimensions getResponsiveDimensions(BuildContext context) {
    return ResponsiveHelper.getDimensions(context);
  }

  /// Obtient le type d'écran actuel
  ScreenType getScreenType(BuildContext context) {
    return ResponsiveHelper.getScreenType(context);
  }

  /// Adapte une taille de police selon l'écran
  double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.foldClosed:
        return baseFontSize * 0.85;
      case ScreenType.mobile:
        return baseFontSize;
      case ScreenType.foldOpen:
        return baseFontSize * 1.1;
      case ScreenType.tablet:
        return baseFontSize * 1.2;
      case ScreenType.desktop:
        return baseFontSize * 1.3;
    }
  }

  /// Adapte un padding selon l'écran
  EdgeInsets getResponsivePadding(
    BuildContext context, {
    double multiplier = 1.0,
  }) {
    final dimensions = getResponsiveDimensions(context);
    return EdgeInsets.all(dimensions.padding * multiplier);
  }

  /// Adapte la taille d'une icône selon l'écran
  double getResponsiveIconSize(BuildContext context, double baseIconSize) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.foldClosed:
        return baseIconSize * 0.8;
      case ScreenType.mobile:
        return baseIconSize;
      case ScreenType.foldOpen:
        return baseIconSize * 1.1;
      case ScreenType.tablet:
        return baseIconSize * 1.2;
      case ScreenType.desktop:
        return baseIconSize * 1.4;
    }
  }

  /// Détermine le nombre de colonnes optimal pour une grille
  int getOptimalColumns(
    BuildContext context, {
    int? minColumns,
    int? maxColumns,
  }) {
    final dimensions = getResponsiveDimensions(context);
    int columns = dimensions.columns;

    if (minColumns != null && columns < minColumns) {
      columns = minColumns;
    }
    if (maxColumns != null && columns > maxColumns) {
      columns = maxColumns;
    }

    return columns;
  }
}

/// Extension pour faciliter l'utilisation des fonctionnalités responsive
extension ResponsiveContext on BuildContext {
  ResponsiveDimensions get responsiveDimensions =>
      ResponsiveHelper.getDimensions(this);
  ScreenType get screenType => ResponsiveHelper.getScreenType(this);
  bool get isMobile =>
      screenType == ScreenType.mobile || screenType == ScreenType.foldClosed;
  bool get isTablet =>
      screenType == ScreenType.tablet || screenType == ScreenType.foldOpen;
  bool get isDesktop => screenType == ScreenType.desktop;
  bool get isFoldable => ResponsiveHelper.isFoldableScreen(this);

  /// Obtient une taille de police responsive
  double responsiveFontSize(double baseFontSize) {
    switch (screenType) {
      case ScreenType.foldClosed:
        return baseFontSize * 0.85;
      case ScreenType.mobile:
        return baseFontSize;
      case ScreenType.foldOpen:
        return baseFontSize * 1.1;
      case ScreenType.tablet:
        return baseFontSize * 1.2;
      case ScreenType.desktop:
        return baseFontSize * 1.3;
    }
  }
}
