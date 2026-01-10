import 'package:flutter/material.dart';
import '../../models/domino_tile.dart';
import '../../models/domino_game_state.dart';
import '../../utils/domino_logic.dart';
import '../domino_tile_painter.dart';

/// Widget affichant la main du joueur avec drag & drop et sélection
class PlayerHand extends StatelessWidget {
  final List<DominoTile> tiles;
  final List<DominoTile> playableTiles;
  final DominoTile? selectedTile;
  final bool isMyTurn;
  final bool isLoading;
  final DominoGameState? gameState;
  final Animation<double>? pulseAnimation;
  final ValueChanged<DominoTile?>? onTileSelected;
  final Function(String side, DominoTile tile)? onTilePlaced;
  final VoidCallback? onPassTurn;

  const PlayerHand({
    super.key,
    required this.tiles,
    required this.playableTiles,
    this.selectedTile,
    this.isMyTurn = false,
    this.isLoading = false,
    this.gameState,
    this.pulseAnimation,
    this.onTileSelected,
    this.onTilePlaced,
    this.onPassTurn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.4),
            Colors.black.withValues(alpha: 0.6),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: isMyTurn ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.3),
            width: isMyTurn ? 4 : 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTurnIndicator(),
          const SizedBox(height: 12),
          if (isMyTurn && selectedTile != null && _isSelectedTilePlayable())
            _buildPlacementButtons(context),
          const SizedBox(height: 8),
          _buildTilesList(context),
          const SizedBox(height: 12),
          if (isMyTurn && playableTiles.isEmpty) _buildPassButton(),
        ],
      ),
    );
  }

  bool _isSelectedTilePlayable() {
    return playableTiles.any((t) => t.id == selectedTile!.id);
  }

  Widget _buildTurnIndicator() {
    if (isMyTurn) {
      Widget indicator = Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8C00).withValues(alpha: 0.5),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, color: Colors.black, size: 24),
            SizedBox(width: 12),
            Text(
              'C\'est votre tour!',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );

      if (pulseAnimation != null) {
        return ScaleTransition(scale: pulseAnimation!, child: indicator);
      }
      return indicator;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_empty,
            color: Colors.white.withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'En attente...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementButtons(BuildContext context) {
    if (gameState == null || selectedTile == null) return const SizedBox.shrink();

    final tile = selectedTile!;
    final canPlaceLeft = DominoLogic.canPlaceAt(tile, gameState!.leftEnd, 'left', gameState!.board.isEmpty);
    final canPlaceRight = DominoLogic.canPlaceAt(tile, gameState!.rightEnd, 'right', gameState!.board.isEmpty);

    // Si le plateau est vide, un seul bouton suffit
    if (gameState!.board.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : () => onTilePlaced?.call('left', tile),
          icon: const Icon(Icons.add_circle_outline, size: 20),
          label: const Text('Placer au centre'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (canPlaceLeft)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => onTilePlaced?.call('left', tile),
                icon: const Icon(Icons.arrow_back, size: 20),
                label: Text('Gauche (${gameState!.leftEnd})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          if (canPlaceRight)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => onTilePlaced?.call('right', tile),
                icon: const Icon(Icons.arrow_forward, size: 20),
                label: Text('Droite (${gameState!.rightEnd})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTilesList(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: tiles.map((tile) {
          final isSelected = selectedTile?.id == tile.id;
          final isPlayable = playableTiles.any((t) => t.id == tile.id);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                if (isMyTurn && isPlayable) {
                  onTileSelected?.call(isSelected ? null : tile);
                }
              },
              child: isMyTurn && isPlayable
                  ? Draggable<DominoTile>(
                      data: tile,
                      feedback: Transform.scale(
                        scale: 1.2,
                        child: Opacity(
                          opacity: 0.8,
                          child: _TileWidget(
                            tile: tile,
                            isSelected: false,
                            isPlayable: true,
                            context: context,
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _TileWidget(
                          tile: tile,
                          isSelected: false,
                          isPlayable: true,
                          context: context,
                        ),
                      ),
                      child: _TileWidget(
                        tile: tile,
                        isSelected: isSelected,
                        isPlayable: isPlayable,
                        context: context,
                      ),
                    )
                  : _TileWidget(
                      tile: tile,
                      isSelected: isSelected,
                      isPlayable: isPlayable,
                      context: context,
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPassButton() {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPassTurn,
      icon: const Icon(Icons.skip_next, size: 24),
      label: const Text(
        'Passer le tour',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        shadowColor: const Color(0xFFFF6B6B).withValues(alpha: 0.5),
      ),
    );
  }
}

/// Widget interne pour afficher une tuile dans la main
class _TileWidget extends StatelessWidget {
  final DominoTile tile;
  final bool isSelected;
  final bool isPlayable;
  final BuildContext context;

  const _TileWidget({
    required this.tile,
    required this.isSelected,
    required this.isPlayable,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Dans la main: dominos verticaux (hauteur > largeur)
    final maxTileHeight = screenHeight * 0.15;
    double width, height;

    if (screenWidth < 400) {
      width = 40;
      height = 80;
    } else if (screenWidth < 600) {
      width = 50;
      height = 100;
    } else if (screenWidth < 900) {
      width = 60;
      height = 120;
    } else if (screenWidth < 1200) {
      width = 70;
      height = 140;
    } else {
      width = 80;
      height = 160;
    }

    // Limiter la hauteur si l'écran est trop petit
    if (height > maxTileHeight) {
      final scale = maxTileHeight / height;
      width = width * scale;
      height = maxTileHeight;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: isSelected
            ? Border.all(color: const Color(0xFFFFD700), width: 4)
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: DominoTileWidget(
        value1: tile.value1,
        value2: tile.value2,
        width: width,
        height: height,
        isVertical: true,
        baseColor: isPlayable ? Colors.white : Colors.grey.shade400,
        dotColor: isPlayable ? Colors.black : Colors.grey.shade600,
      ),
    );
  }
}
