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

/// Numéro de version pour debug (s'incrémente à chaque modification)
const String kBoardVersion = 'v40';

/// Widget qui affiche le plateau de dominos avec layout intelligent
class DominoBoardWidget extends StatefulWidget {
  final DominoGameState gameState;
  final bool isMyTurn;
  final Function(String side, DominoTile tile)? onTilePlaced;
  final DominoTile? selectedTile; // Tuile sélectionnée pour tap-to-place

  const DominoBoardWidget({
    super.key,
    required this.gameState,
    required this.isMyTurn,
    this.onTilePlaced,
    this.selectedTile,
  });

  @override
  State<DominoBoardWidget> createState() => _DominoBoardWidgetState();
}

class _DominoBoardWidgetState extends State<DominoBoardWidget> {
  final TransformationController _transformController = TransformationController();

  // Pour détecter une nouvelle manche et réinitialiser la vue
  int _lastBoardLength = 0;

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

    // Détecter nouvelle manche (board repart à zéro ou diminue fortement)
    if (board.length < _lastBoardLength - 2 || (board.length <= 2 && _lastBoardLength > 5)) {
      // Nouvelle manche détectée - réinitialiser la vue
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _transformController.value = Matrix4.identity();
        }
      });
      print('[$kBoardVersion] Nouvelle manche détectée: reset transform');
    }
    _lastBoardLength = board.length;

    if (board.isEmpty) {
      return _buildEmptyBoard();
    }

    // Calculer les positions de tous les dominos
    final positions = _calculateBoardPositions(board);

    // Calculer les bounds pour le centrage
    final bounds = _calculateBounds(positions);

    // Auto-zoom: dézoomer si le contenu est trop grand
    // Calculer le scale nécessaire pour que tout tienne dans la vue
    final viewportWidth = MediaQuery.of(context).size.width - 48; // Marges
    final viewportHeight = _boardHeight - 24; // Marges
    final contentWidth = bounds.width + 100; // Marges pour les zones de drop
    final contentHeight = bounds.height + 100;

    final scaleX = viewportWidth / contentWidth;
    final scaleY = viewportHeight / contentHeight;
    final autoScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.3, 1.0);

    // Le autoScale sera appliqué directement au contenu via Transform.scale
    print('[$kBoardVersion] bounds: ${bounds.width}x${bounds.height}, viewport: ${viewportWidth}x$viewportHeight, autoScale: $autoScale');

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
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12), // Marge interne pour les zones de drop
          child: InteractiveViewer(
            transformationController: _transformController,
            minScale: 0.3,
            maxScale: 3.0,
            boundaryMargin: const EdgeInsets.all(300), // Plus d'espace pour scroller
            child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculer la taille du contenu avec marge pour les zones de drop
              // Zones de drop = _tileWidth * 0.6 + 8 ≈ 50px de chaque côté
              final dropZoneMargin = _tileWidth * 0.7 + 16;
              final contentWidth = bounds.width + dropZoneMargin * 2;
              final contentHeight = bounds.height + dropZoneMargin * 2;

              // Offset pour centrer les dominos dans le contenu
              final offsetX = dropZoneMargin - bounds.left;
              final offsetY = dropZoneMargin - bounds.top;

              return Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: contentWidth,
                    height: contentHeight,
                    child: Stack(
                  children: [
                    // Texture de table
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _TableTexturePainter(),
                      ),
                    ),

                    // Numéro de version (debug)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Text(
                        kBoardVersion,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                    ),

                    // Les dominos
                    ...positions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final pos = entry.value;

                      return Positioned(
                        left: pos.x + offsetX,
                        top: pos.y + offsetY,
                        child: _buildDominoTile(pos, index),
                      );
                    }),

                    // Zones de drop
                    if (widget.isMyTurn && positions.isNotEmpty) ...[
                      _buildDropZone('left', positions, offsetX, offsetY, bounds, 1.0),
                      _buildDropZone('right', positions, offsetX, offsetY, bounds, 1.0),
                    ],
                  ],
                ),
                ),
                ),
              );
            },
          ),
        ),
      ),
      ),
    );
  }

  /// Plateau vide avec zone de drop centrale
  Widget _buildEmptyBoard() {
    // Tap-to-place: si une tuile est sélectionnée sur plateau vide
    final hasSelectedTile = widget.selectedTile != null && widget.isMyTurn;

    return GestureDetector(
      onTap: () {
        // Tap-to-place pour le premier domino
        if (hasSelectedTile) {
          widget.onTilePlaced?.call('right', widget.selectedTile!);
        }
      },
      child: Container(
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
            final isHighlighted = hasSelectedTile;

            return Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isHovering
                      ? Colors.green.shade600.withValues(alpha: 0.5)
                      : isHighlighted
                          ? Colors.amber.withValues(alpha: 0.3)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isHovering
                        ? Colors.white
                        : isHighlighted
                            ? Colors.amber
                            : Colors.white.withValues(alpha: 0.3),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHovering || isHighlighted ? Icons.add_circle : Icons.casino,
                      size: 64,
                      color: isHovering
                          ? Colors.white
                          : isHighlighted
                              ? Colors.amber
                              : Colors.white54,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.isMyTurn
                          ? (isHovering
                              ? 'Déposez ici !'
                              : isHighlighted
                                  ? 'Tapez pour placer'
                                  : 'Glissez ou sélectionnez')
                          : 'En attente...',
                      style: TextStyle(
                        color: isHovering
                            ? Colors.white
                            : isHighlighted
                                ? Colors.amber
                                : Colors.white70,
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
      ),
    );
  }

  // Nombre max de dominos par direction avant de tourner
  // 5 dominos pour éviter que le serpent ne se chevauche
  static const int _maxTilesBeforeTurn = 5;

  // Direction actuelle aux extrémités (pour les zones de drop)
  ChainDirection _leftEndDirection = ChainDirection.left;
  ChainDirection _rightEndDirection = ChainDirection.right;

  // Index dans board des dominos aux extrémités (pour les zones de drop)
  int _leftEndIndex = 0;
  int _rightEndIndex = 0;

  /// Calcule les positions de tous les dominos sur le plateau
  ///
  /// RÈGLES IMPORTANTES:
  /// - La chaîne a DEUX côtés: gauche et droite
  /// - Chaque côté forme son propre SERPENTIN quand il devient trop long
  /// - Les doubles sont affichés PERPENDICULAIRES à la direction (comme un "pont")
  /// - La chaîne tourne après _maxTilesBeforeTurn dominos
  ///
  /// IMPORTANT: Le service de jeu stocke les dominos côté gauche avec INSERT(0, ...)
  /// Donc board = [gauche_récent, gauche_ancien, départ, droite1, droite2, ...]
  /// Le domino de départ N'EST PAS à board[0] s'il y a des dominos côté gauche!
  List<BoardTilePosition> _calculateBoardPositions(List<PlacedTile> board) {
    if (board.isEmpty) return [];

    // Réinitialiser les variables d'état pour chaque calcul
    // (important pour les nouvelles manches)
    _leftEndDirection = ChainDirection.left;
    _rightEndDirection = ChainDirection.right;
    _leftEndIndex = 0;
    _rightEndIndex = 0;
    _lastCalculatedDirection = ChainDirection.right;

    // Séparer les dominos par côté
    // ATTENTION: board[0] n'est PAS forcément le départ!
    // Le service fait insert(0, ...) pour les dominos gauche
    // Donc: board = [gauche_N, gauche_N-1, ..., gauche_1, départ, droite_1, droite_2, ...]
    final leftTiles = <int>[]; // Indices des dominos côté gauche
    final rightTiles = <int>[]; // Indices des dominos côté droit (inclut le départ)
    int startIndex = -1;

    for (int i = 0; i < board.length; i++) {
      if (board[i].side == 'left') {
        leftTiles.add(i);
      } else {
        if (startIndex == -1) {
          startIndex = i; // Premier domino côté droit = le départ
        }
        rightTiles.add(i);
      }
    }

    // Si pas de départ trouvé, le premier domino est le départ
    if (startIndex == -1) {
      startIndex = 0;
      rightTiles.add(0);
    }

    print('[$kBoardVersion] startIndex=$startIndex, leftTiles=$leftTiles, rightTiles=$rightTiles');
    print('[$kBoardVersion] board order: ${board.map((p) => '${p.tile.value1}-${p.tile.value2}(${p.side})').join(', ')}');

    // Créer la liste des positions (même taille que board)
    final positions = List<BoardTilePosition?>.filled(board.length, null);

    // Calculer les positions de la chaîne DROITE (le départ est à startIndex)
    _calculateChainPositions(
      board: board,
      indices: rightTiles,
      positions: positions,
      startDirection: ChainDirection.right,
      rotateClockwise: true,
    );

    // Mémoriser la direction et l'index de fin du côté droit
    _rightEndDirection = _lastCalculatedDirection;
    _rightEndIndex = rightTiles.isNotEmpty ? rightTiles.last : startIndex;

    // Calculer les positions de la chaîne GAUCHE (part du domino de départ vers la gauche)
    if (leftTiles.isNotEmpty) {
      // Récupérer la position du domino de départ (à startIndex, pas à 0!)
      final startPos = positions[startIndex]!;
      final startTile = board[startIndex].tile;
      final startIsDouble = startTile.isDouble;

      // Largeur du domino de départ (pour calculer son bord gauche)
      final startTileW = startIsDouble ? _tileHeight : _tileWidth;

      // IMPORTANT: Le service stocke les dominos gauche dans l'ordre INVERSE
      // board = [gauche_récent, gauche_ancien, départ, ...]
      // leftTiles = [0, 1] où board[0]=récent, board[1]=ancien
      //
      // Pour l'affichage, on veut:
      // - L'ANCIEN (premier ajouté) proche du départ (position -93)
      // - Le RÉCENT (dernier ajouté) loin du départ (position -186)
      //
      // Donc on doit REVERSER leftTiles pour que:
      // - leftTiles.reversed[0] = ancien → position -93
      // - leftTiles.reversed[1] = récent → position -186
      final leftTilesReversed = leftTiles.reversed.toList();

      // Le curseur pour direction LEFT représente le BORD DROIT du prochain domino
      // startX = bord gauche du domino de départ - spacing
      double startX = startPos.x - _spacing;
      // startY = baseline Y = 0 pour direction horizontale
      double startY = 0.0;

      print('[$kBoardVersion] Chaîne GAUCHE: startX=$startX, startY=$startY (baseline), count=${leftTiles.length}');
      print('[$kBoardVersion] leftTiles ORIGINAL: ${leftTiles.map((i) => 'board[$i]=${board[i].tile.value1}-${board[i].tile.value2}').join(', ')}');
      print('[$kBoardVersion] leftTiles REVERSED: ${leftTilesReversed.map((i) => 'board[$i]=${board[i].tile.value1}-${board[i].tile.value2}').join(', ')}');

      _calculateChainPositions(
        board: board,
        indices: leftTilesReversed,  // REVERSED: ancien d'abord (proche du départ)
        positions: positions,
        startDirection: ChainDirection.left,
        rotateClockwise: true,
        startX: startX,
        startY: startY,
        previousIsDouble: startIsDouble,
      );

      _leftEndDirection = _lastCalculatedDirection;
      // L'extrémité gauche est le dernier de leftTilesReversed = leftTiles.first (le plus récent)
      _leftEndIndex = leftTiles.first;
    } else {
      _leftEndDirection = ChainDirection.left;
      _leftEndIndex = startIndex;
    }

    // Convertir en liste non-nullable
    return positions.map((p) => p!).toList();
  }

  ChainDirection _lastCalculatedDirection = ChainDirection.right;

  /// Calcule les positions d'une chaîne de dominos (gauche ou droite)
  ///
  /// LOGIQUE CLÉ pour le positionnement:
  /// - RIGHT: le domino est placé à droite du point courant (posX = currentX)
  /// - DOWN: le domino est placé en-dessous du point courant (posY = currentY)
  /// - LEFT: le domino est placé à GAUCHE du point courant (posX = currentX - tileW)
  /// - UP: le domino est placé AU-DESSUS du point courant (posY = currentY - tileH)
  void _calculateChainPositions({
    required List<PlacedTile> board,
    required List<int> indices,
    required List<BoardTilePosition?> positions,
    required ChainDirection startDirection,
    required bool rotateClockwise,
    double startX = 0,
    double startY = 0,
    bool previousIsDouble = false,
  }) {
    if (indices.isEmpty) return;

    double currentX = startX;
    double currentY = startY;
    ChainDirection direction = startDirection;
    int lineCount = 0;

    for (int idx = 0; idx < indices.length; idx++) {
      final boardIndex = indices[idx];
      final placedTile = board[boardIndex];
      final tile = placedTile.tile;
      final isDouble = tile.isDouble;

      // Déterminer l'orientation: doubles perpendiculaires à la direction
      bool isVertical;
      if (isDouble) {
        // Un double est PERPENDICULAIRE à la direction de la chaîne
        isVertical = direction == ChainDirection.right || direction == ChainDirection.left;
      } else {
        // Un domino normal est PARALLÈLE à la direction de la chaîne
        isVertical = direction == ChainDirection.down || direction == ChainDirection.up;
      }

      // Dimensions de cette tuile
      final tileW = isVertical ? _tileHeight : _tileWidth;
      final tileH = isVertical ? _tileWidth : _tileHeight;

      // Valeurs à afficher (prend en compte la direction actuelle)
      // isFirst = vrai seulement pour le domino de départ (premier de la chaîne droite)
      final isStartTile = idx == 0 && startDirection == ChainDirection.right;
      final displayValues = _getDisplayValues(placedTile, direction, isStartTile);

      // === CALCUL DE LA POSITION ===
      // Le point courant (currentX, currentY) représente le point de CONNEXION
      // Pour RIGHT/DOWN: le domino s'étend VERS la direction positive
      // Pour LEFT/UP: le domino s'étend VERS la direction négative
      double posX = currentX;
      double posY = currentY;

      // Pour LEFT, le domino doit être placé à gauche du point de connexion
      if (direction == ChainDirection.left) {
        posX = currentX - tileW;
      }
      // Pour UP, le domino doit être placé au-dessus du point de connexion
      if (direction == ChainDirection.up) {
        posY = currentY - tileH;
      }

      // Centrage des doubles (perpendiculaire à la direction)
      if (isDouble) {
        if (direction == ChainDirection.right || direction == ChainDirection.left) {
          // Double vertical sur axe horizontal: centrer verticalement
          posY = posY - (_tileWidth - _tileHeight) / 2;
        } else {
          // Double horizontal sur axe vertical: centrer horizontalement
          posX = posX - (_tileWidth - _tileHeight) / 2;
        }
      }

      positions[boardIndex] = BoardTilePosition(
        x: posX,
        y: posY,
        isVertical: isVertical,
        displayValue1: displayValues.$1,
        displayValue2: displayValues.$2,
      );

      lineCount++;
      print('[$kBoardVersion] idx=$idx tile=${tile.value1}-${tile.value2} lineCount=$lineCount dir=$direction pos=($posX,$posY) tileW=$tileW');

      // Préparer la position du prochain domino
      if (idx < indices.length - 1) {
        final nextTile = board[indices[idx + 1]].tile;
        final nextIsDouble = nextTile.isDouble;

        // Vérifier si on doit tourner
        // Règle: tourner après _maxTilesBeforeTurn, sauf si le prochain est un double
        bool shouldTurn = lineCount >= _maxTilesBeforeTurn && !nextIsDouble;
        if (lineCount > _maxTilesBeforeTurn) {
          shouldTurn = true; // Forcer après avoir attendu un double
        }

        bool justTurned = false;
        ChainDirection directionBeforeTurn = direction; // Mémoriser la direction AVANT virage
        if (shouldTurn) {
          print('[$kBoardVersion] >>> VIRAGE après idx=$idx, ancienne dir=$direction, nouvelle direction: ${rotateClockwise ? _rotateDirection(direction) : _rotateDirectionCounterClockwise(direction)}');
          direction = rotateClockwise
              ? _rotateDirection(direction)
              : _rotateDirectionCounterClockwise(direction);
          lineCount = 0;
          justTurned = true;
        }

        // === AVANCER LE CURSEUR pour le prochain domino ===
        // On avance selon la NOUVELLE direction (après virage éventuel)
        switch (direction) {
          case ChainDirection.right:
            currentX = posX + tileW + _spacing;
            currentY = posY;
            break;
          case ChainDirection.down:
            currentX = posX;
            currentY = posY + tileH + _spacing;
            break;
          case ChainDirection.left:
            currentX = posX - _spacing;
            currentY = posY;
            break;
          case ChainDirection.up:
            currentX = posX;
            currentY = posY - _spacing;
            break;
        }

        // === CORRECTION VIRAGE: Positionner sur le point de connexion ===
        // Après un virage, le prochain domino doit être aligné sur le POINT DE CONNEXION
        // - Pour un DOUBLE: la connexion est au CENTRE (le double est perpendiculaire)
        // - Pour un NON-DOUBLE: la connexion est au BORD selon la direction AVANT virage
        if (justTurned) {
          if (isDouble) {
            // DOUBLE: centrer sur le centre du double (qui est perpendiculaire)
            if (direction == ChainDirection.left || direction == ChainDirection.right) {
              currentY = posY + tileH / 2 - _tileHeight / 2;
            } else {
              currentX = posX + tileW / 2 - _tileHeight / 2;
            }
          } else {
            // NON-DOUBLE: connecter au BORD du domino selon la direction AVANT virage
            // Le point de connexion dépend de où allait la chaîne AVANT le virage
            switch (directionBeforeTurn) {
              case ChainDirection.right:
                // RIGHT → DOWN: connexion au bord DROIT du domino horizontal
                // Prochain domino vertical aligné sur le bord droit
                currentX = posX + tileW - _tileHeight;
                break;
              case ChainDirection.down:
                // DOWN → LEFT: connexion au bord BAS du domino vertical
                // Prochain domino horizontal aligné sur le bord bas
                currentY = posY + tileH - _tileHeight;
                break;
              case ChainDirection.left:
                // LEFT → UP: connexion au bord GAUCHE du domino horizontal
                // Prochain domino vertical aligné sur le bord gauche
                currentX = posX;
                break;
              case ChainDirection.up:
                // UP → RIGHT: connexion au bord HAUT du domino vertical
                // Prochain domino horizontal aligné sur le bord haut
                currentY = posY;
                break;
            }
          }
          print('[$kBoardVersion] justTurned: isDouble=$isDouble, dirBefore=$directionBeforeTurn, newCursor=($currentX,$currentY)');
        }

        // === CORRECTION APRÈS UN DOUBLE (sans virage) ===
        // Le prochain domino doit être CENTRÉ sur le double
        // Le double est perpendiculaire à la direction, donc:
        // - Direction horizontale (RIGHT/LEFT): double est vertical → centrer Y
        // - Direction verticale (UP/DOWN): double est horizontal → centrer X
        if (!justTurned && isDouble) {
          if (direction == ChainDirection.right || direction == ChainDirection.left) {
            // Double vertical sur axe horizontal: centrer Y sur le centre du double
            // Centre du double = posY + tileH/2, prochain domino hauteur = _tileHeight
            currentY = posY + tileH / 2 - _tileHeight / 2;
            print('[$kBoardVersion] après double (horiz): centrage Y = $currentY');
          } else {
            // Double horizontal sur axe vertical: centrer X sur le centre du double
            // Centre du double = posX + tileW/2, prochain domino largeur = _tileHeight (car vertical)
            currentX = posX + tileW / 2 - _tileHeight / 2;
            print('[$kBoardVersion] après double (vert): centrage X = $currentX');
          }
        }

        print('[$kBoardVersion] nextCursor=($currentX,$currentY) nextDir=$direction');
      }
    }

    _lastCalculatedDirection = direction;
  }

  /// Rotation anti-horaire
  ChainDirection _rotateDirectionCounterClockwise(ChainDirection dir) {
    switch (dir) {
      case ChainDirection.right: return ChainDirection.up;
      case ChainDirection.up: return ChainDirection.left;
      case ChainDirection.left: return ChainDirection.down;
      case ChainDirection.down: return ChainDirection.right;
    }
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
  /// Pour un domino vertical: value1 en haut, value2 en bas
  ///
  /// LOGIQUE basée sur la DIRECTION (pas le side):
  /// - RIGHT: connexion par la GAUCHE → displayValue1 = connectedValue
  /// - LEFT: connexion par la DROITE → displayValue2 = connectedValue
  /// - DOWN: connexion par le HAUT → displayValue1 = connectedValue
  /// - UP: connexion par le BAS → displayValue2 = connectedValue
  (int, int) _getDisplayValues(PlacedTile placedTile, ChainDirection direction, bool isFirst) {
    final tile = placedTile.tile;
    final connectedValue = placedTile.connectedValue;

    // Pour un double, pas besoin de flip (les deux valeurs sont identiques)
    if (tile.isDouble) {
      return (tile.value1, tile.value2);
    }

    // Pour le premier domino (départ), pas de connexion donc pas de flip
    if (isFirst) {
      return (tile.value1, tile.value2);
    }

    // Déterminer si la valeur connectée doit être en position 1 (gauche/haut)
    // ou en position 2 (droite/bas)
    bool connectedIsFirst;
    switch (direction) {
      case ChainDirection.right:
        // Connexion par la gauche → connectedValue doit être displayValue1
        connectedIsFirst = true;
        break;
      case ChainDirection.down:
        // Connexion par le haut → connectedValue doit être displayValue1
        connectedIsFirst = true;
        break;
      case ChainDirection.left:
        // Connexion par la droite → connectedValue doit être displayValue2
        connectedIsFirst = false;
        break;
      case ChainDirection.up:
        // Connexion par le bas → connectedValue doit être displayValue2
        connectedIsFirst = false;
        break;
    }

    if (connectedIsFirst) {
      // connectedValue doit être en position 1
      if (tile.value1 == connectedValue) {
        return (tile.value1, tile.value2);
      } else {
        return (tile.value2, tile.value1);
      }
    } else {
      // connectedValue doit être en position 2
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
    double scale,
  ) {
    final isLeft = side == 'left';
    // Utiliser les indices d'extrémité calculés, pas positions.first/last
    final endIndex = isLeft ? _leftEndIndex : _rightEndIndex;
    final pos = positions[endIndex];
    final direction = isLeft ? _leftEndDirection : _rightEndDirection;

    // Dimensions de la tuile de référence
    final refTileW = pos.isVertical ? _tileHeight : _tileWidth;
    final refTileH = pos.isVertical ? _tileWidth : _tileHeight;

    // Position de la zone de drop selon la direction
    double dropX, dropY;
    double dropW, dropH;

    // La zone de drop doit être à côté de l'extrémité de la chaîne
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

    // Vérifier si la tuile sélectionnée peut être placée ici (tap-to-place)
    final canPlaceSelected = widget.selectedTile != null &&
        targetEnd != null &&
        widget.selectedTile!.canConnect(targetEnd);

    return Positioned(
      left: dropX,
      top: dropY,
      child: GestureDetector(
        onTap: () {
          // Tap-to-place : si une tuile est sélectionnée et peut être placée
          if (canPlaceSelected && widget.isMyTurn) {
            widget.onTilePlaced?.call(side, widget.selectedTile!);
          }
        },
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
            final isHighlighted = canPlaceSelected && widget.isMyTurn;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: dropW,
              height: dropH,
              decoration: BoxDecoration(
                color: isHovering
                    ? Colors.lightGreenAccent.withValues(alpha: 0.4)
                    : isRejected
                        ? Colors.red.withValues(alpha: 0.3)
                        : isHighlighted
                            ? Colors.amber.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isHovering
                      ? Colors.lightGreenAccent
                      : isRejected
                          ? Colors.red
                          : isHighlighted
                              ? Colors.amber
                              : Colors.white.withValues(alpha: 0.2),
                  width: (isHovering || isHighlighted) ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  targetEnd != null ? '$targetEnd' : '+',
                  style: TextStyle(
                    color: isHovering
                        ? Colors.lightGreenAccent
                        : isHighlighted
                            ? Colors.amber
                            : Colors.white.withValues(alpha: 0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
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
      ..color = Colors.green.shade700.withValues(alpha: 0.1)
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
