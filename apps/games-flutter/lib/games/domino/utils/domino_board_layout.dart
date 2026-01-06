import 'dart:ui';

/// Direction du placement d'un domino
enum PlacementDirection {
  right,  // Vers la droite →
  down,   // Vers le bas ↓
  left,   // Vers la gauche ←
  up,     // Vers le haut ↑
}

/// Position et orientation d'un domino sur le plateau 2D
class DominoPosition {
  final double x;
  final double y;
  final PlacementDirection direction;
  final bool isVertical; // true si le domino est vertical (haut/bas), false si horizontal (gauche/droite)

  DominoPosition({
    required this.x,
    required this.y,
    required this.direction,
    required this.isVertical,
  });
}

/// Calcule le layout 2D intelligent des dominos sur le plateau
/// Les dominos se placent en serpentin pour ne pas sortir de l'écran
class DominoBoardLayout {
  /// Largeur d'un domino horizontal
  final double tileWidth;

  /// Hauteur d'un domino horizontal
  final double tileHeight;

  /// Nombre maximum de dominos avant de tourner (par défaut 6)
  final int maxTilesBeforeTurn;

  /// Largeur disponible sur l'écran
  final double availableWidth;

  /// Hauteur disponible sur l'écran
  final double availableHeight;

  DominoBoardLayout({
    required this.tileWidth,
    required this.tileHeight,
    this.maxTilesBeforeTurn = 6,
    required this.availableWidth,
    required this.availableHeight,
  });

  /// Calcule les positions de tous les dominos sur le plateau
  /// Retourne une liste de positions pour chaque domino
  List<DominoPosition> calculatePositions(int dominoCount) {
    if (dominoCount == 0) return [];

    final positions = <DominoPosition>[];

    // Position de départ (origine 0,0 - on centrera après)
    double currentX = 0;
    double currentY = 0;

    // Direction initiale: vers la droite
    PlacementDirection currentDirection = PlacementDirection.right;
    int tilesInCurrentDirection = 0;

    for (int i = 0; i < dominoCount; i++) {
      // Déterminer si le domino est vertical ou horizontal
      final isVertical = currentDirection == PlacementDirection.up ||
                        currentDirection == PlacementDirection.down;

      // Ajouter la position actuelle
      positions.add(DominoPosition(
        x: currentX,
        y: currentY,
        direction: currentDirection,
        isVertical: isVertical,
      ));

      // Si ce n'est pas le dernier domino, calculer la position suivante
      if (i < dominoCount - 1) {
        tilesInCurrentDirection++;

        // Vérifier s'il faut tourner
        final shouldTurn = tilesInCurrentDirection >= maxTilesBeforeTurn;

        if (shouldTurn) {
          // Tourner dans le sens horaire
          currentDirection = _getNextDirection(currentDirection);
          tilesInCurrentDirection = 0;
        }

        // Calculer la prochaine position
        final offset = _getOffset(currentDirection);
        currentX += offset.dx;
        currentY += offset.dy;
      }
    }

    // Centrer toutes les positions
    if (positions.isNotEmpty) {
      final bounds = calculateBounds(positions);
      final centerOffsetX = (availableWidth - bounds.width) / 2 - bounds.left;
      final centerOffsetY = (availableHeight - bounds.height) / 2 - bounds.top;

      // Appliquer l'offset de centrage à toutes les positions
      for (int i = 0; i < positions.length; i++) {
        positions[i] = DominoPosition(
          x: positions[i].x + centerOffsetX,
          y: positions[i].y + centerOffsetY,
          direction: positions[i].direction,
          isVertical: positions[i].isVertical,
        );
      }
    }

    return positions;
  }

  /// Retourne le décalage (dx, dy) pour une direction donnée
  Offset _getOffset(PlacementDirection direction) {
    switch (direction) {
      case PlacementDirection.right:
        return Offset(tileWidth, 0);
      case PlacementDirection.down:
        return Offset(0, tileHeight);
      case PlacementDirection.left:
        return Offset(-tileWidth, 0);
      case PlacementDirection.up:
        return Offset(0, -tileHeight);
    }
  }

  /// Retourne la prochaine direction (rotation horaire)
  PlacementDirection _getNextDirection(PlacementDirection current) {
    switch (current) {
      case PlacementDirection.right:
        return PlacementDirection.down;
      case PlacementDirection.down:
        return PlacementDirection.left;
      case PlacementDirection.left:
        return PlacementDirection.up;
      case PlacementDirection.up:
        return PlacementDirection.right;
    }
  }

  /// Calcule les limites (bounding box) de tous les dominos
  /// Utile pour centrer le plateau ou calculer le zoom initial
  Rect calculateBounds(List<DominoPosition> positions) {
    if (positions.isEmpty) {
      return Rect.zero;
    }

    double minX = positions.first.x;
    double maxX = positions.first.x;
    double minY = positions.first.y;
    double maxY = positions.first.y;

    for (final pos in positions) {
      final width = pos.isVertical ? tileHeight : tileWidth;
      final height = pos.isVertical ? tileWidth : tileHeight;

      minX = minX < pos.x ? minX : pos.x;
      maxX = maxX > (pos.x + width) ? maxX : (pos.x + width);
      minY = minY < pos.y ? minY : pos.y;
      maxY = maxY > (pos.y + height) ? maxY : (pos.y + height);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Calcule le zoom initial pour que tous les dominos soient visibles
  double calculateInitialScale(List<DominoPosition> positions) {
    if (positions.isEmpty) return 1.0;

    final bounds = calculateBounds(positions);
    final contentWidth = bounds.width;
    final contentHeight = bounds.height;

    // Ajouter un padding de 20%
    final scaleX = availableWidth / (contentWidth * 1.2);
    final scaleY = availableHeight / (contentHeight * 1.2);

    // Utiliser le plus petit scale pour que tout rentre
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Limiter entre 0.3 et 1.0
    if (scale > 1.0) return 1.0;
    if (scale < 0.3) return 0.3;
    return scale;
  }

  /// Calcule l'offset pour centrer le contenu
  Offset calculateCenterOffset(List<DominoPosition> positions, double scale) {
    if (positions.isEmpty) return Offset.zero;

    final bounds = calculateBounds(positions);
    final contentWidth = bounds.width * scale;
    final contentHeight = bounds.height * scale;

    final offsetX = (availableWidth - contentWidth) / 2 - bounds.left * scale;
    final offsetY = (availableHeight - contentHeight) / 2 - bounds.top * scale;

    return Offset(offsetX, offsetY);
  }
}
