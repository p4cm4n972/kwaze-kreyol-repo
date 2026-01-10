import 'package:flutter/material.dart';

/// Extension pour les valeurs responsive dans les écrans Domino
/// Fournit des helpers pour adapter l'UI à différentes tailles d'écran
extension ResponsiveExtension on BuildContext {
  /// Largeur de l'écran
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Hauteur de l'écran
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Vérifie si c'est un très petit écran (< 400)
  bool get isVerySmallScreen => screenWidth < 400;

  /// Vérifie si c'est un mobile (< 600)
  bool get isMobile => screenWidth < 600;

  /// Vérifie si c'est une tablette (600-1200)
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;

  /// Vérifie si c'est un desktop (>= 1200)
  bool get isDesktop => screenWidth >= 1200;

  /// Retourne une valeur adaptée à la taille de l'écran
  /// [verySmall] pour < 400, [mobile] pour < 600, [tablet] pour 600-1200, [desktop] pour >= 1200
  T responsive<T>({
    required T mobile,
    T? verySmall,
    T? tablet,
    T? desktop,
  }) {
    if (isVerySmallScreen) return verySmall ?? mobile;
    if (isMobile) return mobile;
    if (isTablet) return tablet ?? mobile;
    return desktop ?? tablet ?? mobile;
  }

  /// Taille de texte responsive
  double responsiveFontSize(double base) {
    if (isVerySmallScreen) return base * 0.8;
    if (isMobile) return base;
    if (isTablet) return base * 1.1;
    return base * 1.2;
  }

  /// Padding responsive
  double responsivePadding(double base) {
    if (isVerySmallScreen) return base * 0.6;
    if (isMobile) return base;
    if (isTablet) return base * 1.2;
    return base * 1.5;
  }

  /// Taille d'icône responsive
  double responsiveIconSize(double base) {
    if (isVerySmallScreen) return base * 0.75;
    if (isMobile) return base;
    if (isTablet) return base * 1.15;
    return base * 1.3;
  }

  /// Espacement responsive
  double responsiveSpacing(double base) {
    if (isVerySmallScreen) return base * 0.5;
    if (isMobile) return base;
    if (isTablet) return base * 1.25;
    return base * 1.5;
  }
}
