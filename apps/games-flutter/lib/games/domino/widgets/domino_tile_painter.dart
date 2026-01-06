import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Painter pour dessiner une tuile de domino de manière vectorielle
/// S'adapte automatiquement à toutes les tailles d'écran
class DominoTilePainter extends CustomPainter {
  final int value1;
  final int value2;
  final bool isVertical;
  final Color baseColor;
  final Color dotColor;
  final bool showShadow;

  DominoTilePainter({
    required this.value1,
    required this.value2,
    this.isVertical = true,
    this.baseColor = Colors.white,
    this.dotColor = Colors.black,
    this.showShadow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final cornerRadius = math.min(width, height) * 0.12;

    // Dessiner l'ombre si activée
    if (showShadow) {
      _drawShadow(canvas, size, cornerRadius);
    }

    // Dessiner le fond avec dégradé 3D
    _drawBackground(canvas, size, cornerRadius);

    // Dessiner la bordure
    _drawBorder(canvas, size, cornerRadius);

    // Dessiner la ligne de séparation
    _drawDivider(canvas, size);

    // Dessiner les points
    if (isVertical) {
      _drawDots(canvas, value1, size.width / 2, height * 0.25, math.min(width, height * 0.4), true);
      _drawDots(canvas, value2, size.width / 2, height * 0.75, math.min(width, height * 0.4), true);
    } else {
      _drawDots(canvas, value1, width * 0.25, size.height / 2, math.min(height, width * 0.4), false);
      _drawDots(canvas, value2, width * 0.75, size.height / 2, math.min(height, width * 0.4), false);
    }
  }

  /// Dessine l'ombre portée
  void _drawShadow(Canvas canvas, Size size, double cornerRadius) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 3, size.width, size.height),
      Radius.circular(cornerRadius),
    );

    canvas.drawRRect(shadowRect, shadowPaint);
  }

  /// Dessine le fond avec dégradé 3D
  void _drawBackground(Canvas canvas, Size size, double cornerRadius) {
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(cornerRadius),
    );

    // Dégradé pour effet 3D
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor,
        baseColor.withValues(alpha: 0.85),
        baseColor.withValues(alpha: 0.95),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final bgPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(bgRect, bgPaint);

    // Surbrillance en haut à gauche pour effet brillant
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.15),
      size.width * 0.3,
      highlightPaint,
    );
  }

  /// Dessine la bordure
  void _drawBorder(Canvas canvas, Size size, double cornerRadius) {
    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(cornerRadius),
    );

    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(borderRect, borderPaint);

    // Bordure intérieure pour effet de profondeur
    final innerBorderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3),
      Radius.circular(cornerRadius - 1.5),
    );

    final innerBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(innerBorderRect, innerBorderPaint);
  }

  /// Dessine la ligne de séparation
  void _drawDivider(Canvas canvas, Size size) {
    final dividerPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    if (isVertical) {
      // Ligne horizontale au milieu
      final y = size.height / 2;
      final margin = size.width * 0.1;
      canvas.drawLine(
        Offset(margin, y),
        Offset(size.width - margin, y),
        dividerPaint,
      );
    } else {
      // Ligne verticale au milieu
      final x = size.width / 2;
      final margin = size.height * 0.1;
      canvas.drawLine(
        Offset(x, margin),
        Offset(x, size.height - margin),
        dividerPaint,
      );
    }
  }

  /// Dessine les points selon la valeur (0-6)
  void _drawDots(Canvas canvas, int value, double centerX, double centerY, double maxSize, bool isVerticalOrientation) {
    if (value == 0) return;

    final dotRadius = maxSize * 0.08;
    final spacing = maxSize * 0.25;

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    // Ombre pour les points
    final dotShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final positions = _getDotPositions(value, centerX, centerY, spacing, isVerticalOrientation);

    for (final pos in positions) {
      // Dessiner l'ombre du point
      canvas.drawCircle(
        Offset(pos.dx + 1, pos.dy + 1),
        dotRadius,
        dotShadowPaint,
      );
      // Dessiner le point
      canvas.drawCircle(pos, dotRadius, dotPaint);

      // Reflet sur le point pour effet brillant
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4);
      canvas.drawCircle(
        Offset(pos.dx - dotRadius * 0.3, pos.dy - dotRadius * 0.3),
        dotRadius * 0.35,
        highlightPaint,
      );
    }
  }

  /// Retourne les positions des points selon la valeur
  /// Quand horizontal, les positions sont tournées de 90° pour correspondre à la rotation du domino
  List<Offset> _getDotPositions(int value, double cx, double cy, double spacing, bool isVerticalOrientation) {
    // Positions de base pour orientation verticale (offsets relatifs au centre)
    final List<List<double>> relativeOffsets;

    switch (value) {
      case 1:
        relativeOffsets = [[0, 0]];
        break;
      case 2:
        relativeOffsets = [[-1, -1], [1, 1]];
        break;
      case 3:
        relativeOffsets = [[-1, -1], [0, 0], [1, 1]];
        break;
      case 4:
        relativeOffsets = [[-1, -1], [1, -1], [-1, 1], [1, 1]];
        break;
      case 5:
        relativeOffsets = [[-1, -1], [1, -1], [0, 0], [-1, 1], [1, 1]];
        break;
      case 6:
        relativeOffsets = [[-1, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [1, 1]];
        break;
      default:
        relativeOffsets = [];
    }

    final positions = <Offset>[];
    for (final offset in relativeOffsets) {
      double dx = offset[0] * spacing;
      double dy = offset[1] * spacing;

      // Si horizontal, rotation de 90° horaire: (x, y) → (y, -x)
      if (!isVerticalOrientation) {
        final temp = dx;
        dx = dy;
        dy = -temp;
      }

      positions.add(Offset(cx + dx, cy + dy));
    }

    return positions;
  }

  @override
  bool shouldRepaint(covariant DominoTilePainter oldDelegate) {
    return oldDelegate.value1 != value1 ||
        oldDelegate.value2 != value2 ||
        oldDelegate.isVertical != isVertical ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.dotColor != dotColor;
  }
}

/// Widget réutilisable pour afficher une tuile de domino
class DominoTileWidget extends StatelessWidget {
  final int value1;
  final int value2;
  final double width;
  final double height;
  final bool isVertical;
  final Color? baseColor;
  final Color? dotColor;
  final bool showShadow;

  const DominoTileWidget({
    Key? key,
    required this.value1,
    required this.value2,
    this.width = 60,
    this.height = 120,
    this.isVertical = true,
    this.baseColor,
    this.dotColor,
    this.showShadow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: DominoTilePainter(
          value1: value1,
          value2: value2,
          isVertical: isVertical,
          baseColor: baseColor ?? Colors.white,
          dotColor: dotColor ?? Colors.black87,
          showShadow: showShadow,
        ),
      ),
    );
  }
}

/// Widget responsive qui ajuste automatiquement la taille
class ResponsiveDominoTile extends StatelessWidget {
  final int value1;
  final int value2;
  final bool isVertical;
  final Color? baseColor;
  final Color? dotColor;

  const ResponsiveDominoTile({
    Key? key,
    required this.value1,
    required this.value2,
    this.isVertical = true,
    this.baseColor,
    this.dotColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculer la taille optimale selon l'écran
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;

        double width, height;

        if (isMobile) {
          // Mobile: tuiles plus petites
          width = isVertical ? 50 : 100;
          height = isVertical ? 100 : 50;
        } else if (isTablet) {
          // Tablette: taille moyenne
          width = isVertical ? 65 : 130;
          height = isVertical ? 130 : 65;
        } else {
          // Desktop: tuiles plus grandes
          width = isVertical ? 80 : 160;
          height = isVertical ? 160 : 80;
        }

        return DominoTileWidget(
          value1: value1,
          value2: value2,
          width: width,
          height: height,
          isVertical: isVertical,
          baseColor: baseColor,
          dotColor: dotColor,
        );
      },
    );
  }
}
