import 'package:flutter/material.dart';

/// Système de responsive design pour l'application ENA Mobile
class ResponsiveHelper {
  // Breakpoints pour différents types d'écrans
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;
  static const double desktopMaxWidth = 1440;

  // Breakpoints spéciaux pour les écrans pliables
  static const double foldClosedWidth = 374; // Samsung Fold fermé
  static const double foldOpenWidth = 717; // Samsung Fold ouvert

  /// Détermine le type d'écran basé sur la largeur
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width <= foldClosedWidth) {
      return ScreenType.foldClosed;
    } else if (width <= mobileMaxWidth) {
      return ScreenType.mobile;
    } else if (width <= foldOpenWidth) {
      return ScreenType.foldOpen;
    } else if (width <= tabletMaxWidth) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }

  /// Obtient les dimensions responsive basées sur le type d'écran
  static ResponsiveDimensions getDimensions(BuildContext context) {
    final screenType = getScreenType(context);
    final size = MediaQuery.of(context).size;

    switch (screenType) {
      case ScreenType.foldClosed:
        return ResponsiveDimensions(
          padding: 8.0,
          cardPadding: 12.0,
          fontSize: 12.0,
          iconSize: 20.0,
          maxWidth: size.width * 0.95,
          columns: 1,
          aspectRatio: 1.2,
        );
      case ScreenType.mobile:
        return ResponsiveDimensions(
          padding: 16.0,
          cardPadding: 16.0,
          fontSize: 14.0,
          iconSize: 24.0,
          maxWidth: size.width * 0.9,
          columns: 1,
          aspectRatio: 1.1,
        );
      case ScreenType.foldOpen:
        return ResponsiveDimensions(
          padding: 20.0,
          cardPadding: 18.0,
          fontSize: 15.0,
          iconSize: 26.0,
          maxWidth: size.width * 0.85,
          columns: 2,
          aspectRatio: 1.0,
        );
      case ScreenType.tablet:
        return ResponsiveDimensions(
          padding: 24.0,
          cardPadding: 20.0,
          fontSize: 16.0,
          iconSize: 28.0,
          maxWidth: size.width * 0.8,
          columns: 2,
          aspectRatio: 0.9,
        );
      case ScreenType.desktop:
        return ResponsiveDimensions(
          padding: 32.0,
          cardPadding: 24.0,
          fontSize: 18.0,
          iconSize: 32.0,
          maxWidth: 1200,
          columns: 3,
          aspectRatio: 0.8,
        );
    }
  }

  /// Calcule la largeur responsive d'une carte
  static double getCardWidth(BuildContext context, {int? forcedColumns}) {
    final dimensions = getDimensions(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final columns = forcedColumns ?? dimensions.columns;

    if (columns == 1) {
      return dimensions.maxWidth;
    }

    final totalPadding = dimensions.padding * 2;
    final spacingBetweenCards = 16.0 * (columns - 1);
    final availableWidth = screenWidth - totalPadding - spacingBetweenCards;

    return availableWidth / columns;
  }

  /// Vérifie si l'écran est en mode paysage
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Vérifie si c'est un écran pliable
  static bool isFoldableScreen(BuildContext context) {
    final screenType = getScreenType(context);
    return screenType == ScreenType.foldClosed ||
        screenType == ScreenType.foldOpen;
  }
}

/// Énumération des types d'écran
enum ScreenType {
  foldClosed, // Samsung Fold fermé ou écrans très étroits
  mobile, // Téléphones standard
  foldOpen, // Samsung Fold ouvert
  tablet, // Tablettes
  desktop, // Ordinateurs de bureau
}

/// Classe contenant les dimensions responsive
class ResponsiveDimensions {
  final double padding;
  final double cardPadding;
  final double fontSize;
  final double iconSize;
  final double maxWidth;
  final int columns;
  final double aspectRatio;

  const ResponsiveDimensions({
    required this.padding,
    required this.cardPadding,
    required this.fontSize,
    required this.iconSize,
    required this.maxWidth,
    required this.columns,
    required this.aspectRatio,
  });
}

/// Widget responsive qui s'adapte automatiquement à la taille d'écran
class ResponsiveWidget extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    ScreenType screenType,
    ResponsiveDimensions dimensions,
  )
  builder;

  const ResponsiveWidget({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveHelper.getScreenType(context);
    final dimensions = ResponsiveHelper.getDimensions(context);

    return builder(context, screenType, dimensions);
  }
}

/// Conteneur responsive avec contraintes automatiques
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool centerContent;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final dimensions = ResponsiveHelper.getDimensions(context);
    final effectiveMaxWidth = maxWidth ?? dimensions.maxWidth;
    final effectivePadding = padding ?? EdgeInsets.all(dimensions.padding);

    Widget content = Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
      padding: effectivePadding,
      child: child,
    );

    if (centerContent) {
      content = Center(child: content);
    }

    return content;
  }
}

/// Grid responsive qui s'adapte au nombre de colonnes
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? forceColumns;
  final double spacing;
  final double runSpacing;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.forceColumns,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final dimensions = ResponsiveHelper.getDimensions(context);
    final columns = forceColumns ?? dimensions.columns;

    if (columns == 1) {
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        children: children
            .map(
              (child) => Padding(
                padding: EdgeInsets.only(bottom: runSpacing),
                child: child,
              ),
            )
            .toList(),
      );
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children
          .map(
            (child) => SizedBox(
              width: ResponsiveHelper.getCardWidth(
                context,
                forcedColumns: columns,
              ),
              child: child,
            ),
          )
          .toList(),
    );
  }
}

/// Card responsive avec dimensions automatiques
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final bool adaptivePadding;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.elevation,
    this.margin,
    this.adaptivePadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimensions = ResponsiveHelper.getDimensions(context);

    Widget cardContent = child;

    if (adaptivePadding) {
      cardContent = Padding(
        padding: EdgeInsets.all(dimensions.cardPadding),
        child: child,
      );
    }

    return Card(
      color: color ?? theme.cardTheme.color,
      elevation: elevation ?? theme.cardTheme.elevation,
      margin: margin ?? EdgeInsets.all(dimensions.padding / 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: cardContent,
            )
          : cardContent,
    );
  }
}
