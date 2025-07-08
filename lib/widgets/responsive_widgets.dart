import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../common/responsive_helper.dart';

/// Widget de carte responsive qui s'adapte automatiquement
class EnaResponsiveCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool fullWidth;

  const EnaResponsiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.elevation,
    this.margin,
    this.padding,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      builder: (context, screenType, dimensions) {
        Widget cardContent = Container(
          width: fullWidth ? double.infinity : null,
          constraints: fullWidth
              ? BoxConstraints(maxWidth: dimensions.maxWidth)
              : null,
          child: child,
        );

        if (padding != null) {
          cardContent = Padding(padding: padding!, child: cardContent);
        }

        return Center(
          child: Card(
            color: backgroundColor ?? Theme.of(context).cardColor,
            elevation: elevation ?? (screenType == ScreenType.desktop ? 8 : 4),
            margin: margin ?? EdgeInsets.all(dimensions.padding / 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                screenType == ScreenType.foldClosed ? 12 : 16,
              ),
            ),
            child: onTap != null
                ? InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(
                      screenType == ScreenType.foldClosed ? 12 : 16,
                    ),
                    child: cardContent,
                  )
                : cardContent,
          ),
        );
      },
    );
  }
}

/// Widget de grille responsive pour organiser le contenu
class EnaResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? forceColumns;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const EnaResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.forceColumns,
    this.shrinkWrap = true,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      builder: (context, screenType, dimensions) {
        final columns = forceColumns ?? dimensions.columns;

        if (columns == 1) {
          // Pour mobile et fold fermé : disposition en colonne
          return Column(
            children: children
                .map(
                  (child) => Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: runSpacing),
                    child: child,
                  ),
                )
                .toList(),
          );
        } else {
          // Pour tablette et desktop : disposition en grille
          return GridView.builder(
            shrinkWrap: shrinkWrap,
            physics: physics ?? const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: runSpacing,
              crossAxisSpacing: spacing,
              childAspectRatio: dimensions.aspectRatio,
            ),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
          );
        }
      },
    );
  }
}

/// Widget de texte responsive qui s'adapte aux tailles d'écran
class EnaResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isTitle;
  final bool isSubtitle;

  const EnaResponsiveText(
    this.text, {
    super.key,
    this.baseStyle,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isTitle = false,
    this.isSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      builder: (context, screenType, dimensions) {
        double fontSize = dimensions.fontSize;

        if (isTitle) {
          fontSize = screenType == ScreenType.foldClosed
              ? dimensions.fontSize + 4
              : dimensions.fontSize + 8;
        } else if (isSubtitle) {
          fontSize = screenType == ScreenType.foldClosed
              ? dimensions.fontSize + 1
              : dimensions.fontSize + 2;
        }

        final effectiveStyle =
            baseStyle?.copyWith(fontSize: fontSize) ??
            GoogleFonts.poppins(fontSize: fontSize);

        return Text(
          text,
          style: effectiveStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

/// Conteneur responsive avec padding adaptatif
class EnaResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool centerContent;
  final double? maxWidth;

  const EnaResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.centerContent = false,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      builder: (context, screenType, dimensions) {
        final effectivePadding = padding ?? EdgeInsets.all(dimensions.padding);
        final effectiveMaxWidth = maxWidth ?? dimensions.maxWidth;

        Widget content = Container(
          width: double.infinity,
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          padding: effectivePadding,
          color: backgroundColor,
          child: child,
        );

        return centerContent ? Center(child: content) : content;
      },
    );
  }
}

/// Widget pour les boutons responsives
class EnaResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const EnaResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isFullWidth = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      builder: (context, screenType, dimensions) {
        final buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: textColor ?? Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: dimensions.cardPadding,
            horizontal: dimensions.cardPadding * 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: dimensions.fontSize,
            fontWeight: FontWeight.w600,
          ),
        );

        Widget button = icon != null
            ? ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: dimensions.iconSize),
                label: Text(text),
                style: buttonStyle,
              )
            : ElevatedButton(
                onPressed: onPressed,
                style: buttonStyle,
                child: Text(text),
              );

        return isFullWidth
            ? SizedBox(width: double.infinity, child: button)
            : button;
      },
    );
  }
}
