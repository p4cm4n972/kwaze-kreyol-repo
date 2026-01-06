import 'package:flutter/material.dart';
import '../models/domino_tile.dart';
import '../models/domino_game_state.dart';
import 'domino_tile_painter.dart';

/// Direction de la chaîne (pour le serpentin)
enum ChainDirection {
  right,
  down,
  left,
  up,
}

/// Position calculée d'un domino sur le plateau
class BoardTilePosition {
  final double x;
  final double y;
  final bool isVertical;
  final int displayValue1; // Valeur affichée en haut/gauche
  final int displayValue2; // Valeur affichée en bas/droite

  const BoardTilePosition({
    required this.x,
    required this.y,
    required this.isVertical,
    required this.displayValue1,
    required this.displayValue2,
  });
}

/// Widget qui affiche le plateau de dominos avec layout intelligent
class DominoBoardWidget extends StatefulWidget {
  final DominoGameState gameState;
  final bool isMyTurn;
  final Function(String side, DominoTile tile)? onTilePlaced;

  const DominoBoardWidget({
    super.key,
    required this.gameState,
    required this.isMyTurn,
    this.onTilePlaced,
  });

  @override
  State<DominoBoardWidget> createState() => _DominoBoardWidgetState();
}

class _DominoBoardWidgetState extends State<DominoBoardWidget> {
  final TransformationController _transformController = TransformationController();

  // Dimensions des tuiles - calculées dynamiquement selon la taille de l'écran
  double _tileWidth = 70.0;
  double _tileHeight = 35.0;
  double _spacing = 2.0;
  double _boardHeight = 400.0;

  /// Calcule les dimensions responsive selon la largeur de l'écran
  void _calculateResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (screenWidth < 400) {
      // Très petit mobile
      _tileWidth = 50.0;
      _tileHeight = 25.0;
      _spacing = 1.5;
      _boardHeight = 280.0;
    } else if (screenWidth < 600) {
      // Mobile standard
      _tileWidth = 60.0;
      _tileHeight = 30.0;
      _spacing = 2.0;
      _boardHeight = 320.0;
    } else if (screenWidth < 900) {
      // Tablette portrait ou grand mobile paysage
      _tileWidth = 70.0;
      _tileHeight = 35.0;
      _spacing = 2.0;
      _boardHeight = 380.0;
    } else if (screenWidth < 1200) {
      // Tablette paysage ou petit desktop
      _tileWidth = 80.0;
      _tileHeight = 40.0;
      _spacing = 2.5;
      _boardHeight = 420.0;
    } else {
      // Grand écran desktop
      _tileWidth = 90.0;
      _tileHeight = 45.0;
      _spacing = 3.0;
      _boardHeight = 480.0;
    }

    // Limiter la hauteur du plateau selon l'écran (max 50% de la hauteur)
    _boardHeight = _boardHeight.clamp(200.0, screenHeight * 0.45);
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculer les dimensions responsive
    _calculateResponsiveDimensions(context);

    final board = widget.gameState.board;

    if (board.isEmpty) {
      return _buildEmptyBoard();
    }

    // Calculer les positions de tous les dominos
    final positions = _calculateBoardPositions(board);

    // Calculer les bounds pour le centrage
    final bounds = _calculateBounds(positions);

    return Container(
      height: _boardHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade800,
            Colors.green.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.brown.shade700,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.5,
          maxScale: 3.0,
          boundaryMargin: const EdgeInsets.all(200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Centrer le contenu
              final centerX = (constraints.maxWidth - bounds.width) / 2 - bounds.left;
              final centerY = (constraints.maxHeight - bounds.height) / 2 - bounds.top;

              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    // Texture de table
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _TableTexturePainter(),
                      ),
                    ),

                    // Les dominos
                    ...positions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final pos = entry.value;

                      return Positioned(
                        left: pos.x + centerX,
                        top: pos.y + centerY,
                        child: _buildDominoTile(pos, index),
                      );
                    }),

                    // Zones de drop
                    if (widget.isMyTurn && positions.isNotEmpty) ...[
                      _buildDropZone('left', positions, centerX, centerY, bounds),
                      _buildDropZone('right', positions, centerX, centerY, bounds),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Plateau vide avec zone de drop centrale
  Widget _buildEmptyBoard() {
    return Container(
      height: _boardHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade800,
            Colors.green.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.brown.shade700,
          width: 4,
        ),
      ),
      child: DragTarget<DominoTile>(
        onWillAcceptWithDetails: (details) => widget.isMyTurn,
        onAcceptWithDetails: (details) {
          widget.onTilePlaced?.call('right', details.data);
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;

          return Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isHovering
                    ? Colors.green.shade600.withOpacity(0.5)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isHovering
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isHovering ? Icons.add_circle : Icons.casino,
                    size: 64,
                    color: isHovering ? Colors.white : Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isMyTurn
                        ? (isHovering ? 'Déposez ici !' : 'Glissez un domino')
                        : 'En attente...',
                    style: TextStyle(
                      color: isHovering ? Colors.white : Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Nombre max de dominos avant de tourner (serpentin)
  static const int _maxTilesBeforeTurn = 7;

  // Direction actuelle aux extrémités (pour les zones de drop)
  ChainDirection _leftEndDirection = ChainDirection.left;
  ChainDirection _rightEndDirection = ChainDirection.right;

  /// Calcule les positions de tous les dominos sur le plateau
  ///
  /// RÈGLES IMPORTANTES:
  /// - La chaîne forme un SERPENTIN quand elle devient trop longue
  /// - Les doubles sont affichés VERTICALEMENT (comme un "pont")
  /// - Un domino connecté à un double est CENTRÉ verticalement sur le double
  /// - La chaîne tourne après _maxTilesBeforeTurn dominos
  List<BoardTilePosition> _calculateBoardPositions(List<PlacedTile> board) {
    if (board.isEmpty) return [];

    final positions = <BoardTilePosition>[];
    double currentX = 0;
    double currentY = 0;
    ChainDirection direction = ChainDirection.right;
    int tilesInCurrentDirection = 0;

    for (int i = 0; i < board.length; i++) {
      final placedTile = board[i];
      final tile = placedTile.tile;
      final isDouble = tile.isDouble;

      // Les doubles sont verticaux, les autres horizontaux (sauf si direction verticale)
      final isVertical = isDouble || direction == ChainDirection.down || direction == ChainDirection.up;

      // Déterminer les valeurs à afficher
      final displayValues = _getDisplayValues(placedTile, i == 0);

      // Dimensions de cette tuile
      final tileW = isVertical ? _tileHeight : _tileWidth;
      final tileH = isVertical ? _tileWidth : _tileHeight;

      // Calculer la position Y ajustée pour les doubles
      double posX = currentX;
      double posY = currentY;

      if (isDouble && (direction == ChainDirection.right || direction == ChainDirection.left)) {
        // Double sur une ligne horizontale: centrer verticalement
        posY = currentY - (_tileWidth - _tileHeight) / 2;
      } else if (isDouble && (direction == ChainDirection.down || direction == ChainDirection.up)) {
        // Double sur une ligne verticale: centrer horizontalement
        posX = currentX - (_tileWidth - _tileHeight) / 2;
      }

      // Si le précédent était un double, centrer ce domino sur le double
      if (i > 0 && board[i - 1].tile.isDouble) {
        final prevPos = positions[i - 1];
        if (direction == ChainDirection.right || direction == ChainDirection.left) {
          // Centrer verticalement
          posY = prevPos.y + (_tileWidth - _tileHeight) / 2;
        } else {
          // Centrer horizontalement
          posX = prevPos.x + (_tileWidth - _tileHeight) / 2;
        }
      }

      positions.add(BoardTilePosition(
        x: posX,
        y: posY,
        isVertical: isVertical,
        displayValue1: displayValues.$1,
        displayValue2: displayValues.$2,
      ));

      // Mémoriser la direction du premier domino
      if (i == 0) {
        _leftEndDirection = _oppositeDirection(direction);
      }

      tilesInCurrentDirection++;

      // Calculer la position du prochain domino
      if (i < board.length - 1) {
        // Vérifier si on doit tourner (serpentin)
        bool shouldTurn = tilesInCurrentDirection >= _maxTilesBeforeTurn;

        if (shouldTurn) {
          // Tourner (sens horaire)
          direction = _rotateDirection(direction);
          tilesInCurrentDirection = 0;
        }

        // Avancer dans la direction actuelle
        switch (direction) {
          case ChainDirection.right:
            currentX += tileW + _spacing;
            break;
          case ChainDirection.down:
            currentY += tileH + _spacing;
            break;
          case ChainDirection.left:
            currentX -= tileW + _spacing;
            break;
          case ChainDirection.up:
            currentY -= tileH + _spacing;
            break;
        }
      }

      // Mémoriser la direction du dernier domino
      _rightEndDirection = direction;
    }

    return positions;
  }

  /// Direction opposée
  ChainDirection _oppositeDirection(ChainDirection dir) {
    switch (dir) {
      case ChainDirection.right: return ChainDirection.left;
      case ChainDirection.left: return ChainDirection.right;
      case ChainDirection.down: return ChainDirection.up;
      case ChainDirection.up: return ChainDirection.down;
    }
  }

  /// Rotation horaire de la direction
  ChainDirection _rotateDirection(ChainDirection dir) {
    switch (dir) {
      case ChainDirection.right: return ChainDirection.down;
      case ChainDirection.down: return ChainDirection.left;
      case ChainDirection.left: return ChainDirection.up;
      case ChainDirection.up: return ChainDirection.right;
    }
  }

  /// Détermine les valeurs à afficher (avec flip si nécessaire)
  ///
  /// Pour un domino horizontal: value1 à gauche, value2 à droite
  /// Pour un double vertical: value1 en haut, value2 en bas (identiques)
  ///
  /// LOGIQUE:
  /// - Side 'right' ou null: connexion par la gauche → value1 = connectedValue
  /// - Side 'left': connexion par la droite → value2 = connectedValue
  (int, int) _getDisplayValues(PlacedTile placedTile, bool isFirst) {
    final tile = placedTile.tile;
    final connectedValue = placedTile.connectedValue;

    // Pour un double, pas besoin de flip (les deux valeurs sont identiques)
    if (tile.isDouble) {
      return (tile.value1, tile.value2);
    }

    // Déterminer le côté de connexion
    // Le premier domino original a side='right', connexion par la gauche
    // Les dominos insérés à gauche ont side='left', connexion par la droite
    final side = placedTile.side;

    if (side == 'right') {
      // Connexion par la gauche: displayValue1 (gauche) doit être connectedValue
      if (tile.value1 == connectedValue) {
        return (tile.value1, tile.value2);
      } else {
        return (tile.value2, tile.value1);
      }
    } else {
      // Connexion par la droite: displayValue2 (droite) doit être connectedValue
      if (tile.value2 == connectedValue) {
        return (tile.value1, tile.value2);
      } else {
        return (tile.value2, tile.value1);
      }
    }
  }

  /// Calcule les bounds de tous les dominos
  Rect _calculateBounds(List<BoardTilePosition> positions) {
    if (positions.isEmpty) return Rect.zero;

    double minX = positions.first.x;
    double maxX = positions.first.x;
    double minY = positions.first.y;
    double maxY = positions.first.y;

    for (final pos in positions) {
      final w = pos.isVertical ? _tileHeight : _tileWidth;
      final h = pos.isVertical ? _tileWidth : _tileHeight;

      if (pos.x < minX) minX = pos.x;
      if (pos.x + w > maxX) maxX = pos.x + w;
      if (pos.y < minY) minY = pos.y;
      if (pos.y + h > maxY) maxY = pos.y + h;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Construit un domino visuel
  Widget _buildDominoTile(BoardTilePosition pos, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: DominoTileWidget(
        value1: pos.displayValue1,
        value2: pos.displayValue2,
        width: pos.isVertical ? _tileHeight : _tileWidth,
        height: pos.isVertical ? _tileWidth : _tileHeight,
        isVertical: pos.isVertical,
        baseColor: const Color(0xFFFFFFF0), // Ivory
        dotColor: Colors.black87,
        showShadow: true,
      ),
    );
  }

  /// Zone de drop pour placer des dominos
  /// Suit la direction du serpentin
  Widget _buildDropZone(
    String side,
    List<BoardTilePosition> positions,
    double centerX,
    double centerY,
    Rect bounds,
  ) {
    final isLeft = side == 'left';
    final pos = isLeft ? positions.first : positions.last;
    final direction = isLeft ? _leftEndDirection : _rightEndDirection;

    // Dimensions de la tuile de référence
    final refTileW = pos.isVertical ? _tileHeight : _tileWidth;
    final refTileH = pos.isVertical ? _tileWidth : _tileHeight;

    // Position de la zone de drop selon la direction
    double dropX, dropY;
    double dropW, dropH;

    switch (direction) {
      case ChainDirection.right:
        dropX = pos.x + centerX + refTileW + 8;
        dropY = pos.y + centerY + (refTileH - _tileHeight) / 2;
        dropW = _tileWidth * 0.6;
        dropH = _tileHeight;
        break;
      case ChainDirection.left:
        dropX = pos.x + centerX - _tileWidth * 0.6 - 8;
        dropY = pos.y + centerY + (refTileH - _tileHeight) / 2;
        dropW = _tileWidth * 0.6;
        dropH = _tileHeight;
        break;
      case ChainDirection.down:
        dropX = pos.x + centerX + (refTileW - _tileHeight) / 2;
        dropY = pos.y + centerY + refTileH + 8;
        dropW = _tileHeight;
        dropH = _tileWidth * 0.6;
        break;
      case ChainDirection.up:
        dropX = pos.x + centerX + (refTileW - _tileHeight) / 2;
        dropY = pos.y + centerY - _tileWidth * 0.6 - 8;
        dropW = _tileHeight;
        dropH = _tileWidth * 0.6;
        break;
    }

    final targetEnd = isLeft
        ? widget.gameState.leftEnd
        : widget.gameState.rightEnd;

    return Positioned(
      left: dropX,
      top: dropY,
      child: DragTarget<DominoTile>(
        onWillAcceptWithDetails: (details) {
          if (targetEnd == null) return false;
          return details.data.canConnect(targetEnd);
        },
        onAcceptWithDetails: (details) {
          widget.onTilePlaced?.call(side, details.data);
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          final isRejected = rejectedData.isNotEmpty;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: dropW,
            height: dropH,
            decoration: BoxDecoration(
              color: isHovering
                  ? Colors.lightGreenAccent.withOpacity(0.4)
                  : isRejected
                      ? Colors.red.withOpacity(0.3)
                      : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHovering
                    ? Colors.lightGreenAccent
                    : isRejected
                        ? Colors.red
                        : Colors.white.withOpacity(0.2),
                width: isHovering ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                targetEnd != null ? '$targetEnd' : '+',
                style: TextStyle(
                  color: isHovering
                      ? Colors.lightGreenAccent
                      : Colors.white.withOpacity(0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


/// Peint la texture de la table de jeu
class _TableTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner des lignes subtiles pour simuler le bois/feutre
    final paint = Paint()
      ..color = Colors.green.shade700.withOpacity(0.1)
      ..strokeWidth = 1;

    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
