import 'package:flutter/material.dart';
import '../../models/domino_tile.dart';
import '../domino_tile_painter.dart';

/// Main compacte du joueur pour le mode solo
/// Layout horizontal avec contrôles à droite
class SoloPlayerHand extends StatelessWidget {
  final List<DominoTile> tiles;
  final List<DominoTile> playableTiles;
  final DominoTile? selectedTile;
  final bool isMyTurn;
  final int roundsWon;
  final ValueChanged<DominoTile?>? onTileSelected;
  final VoidCallback? onPassTurn;

  const SoloPlayerHand({
    super.key,
    required this.tiles,
    required this.playableTiles,
    this.selectedTile,
    this.isMyTurn = false,
    this.roundsWon = 0,
    this.onTileSelected,
    this.onPassTurn,
  });

  bool get _canPass => isMyTurn && playableTiles.isEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo.shade900.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildTilesList()),
          const SizedBox(width: 8),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildTilesList() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tiles.length,
        itemBuilder: (context, index) {
          final tile = tiles[index];
          final isPlayable = playableTiles.any((t) => t.id == tile.id);
          final isSelected = selectedTile?.id == tile.id;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Draggable<DominoTile>(
              data: tile,
              feedback: Material(
                color: Colors.transparent,
                child: Transform.scale(
                  scale: 1.2,
                  child: DominoTileWidget(
                    value1: tile.value1,
                    value2: tile.value2,
                    width: 35,
                    height: 70,
                    isVertical: true,
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: DominoTileWidget(
                  value1: tile.value1,
                  value2: tile.value2,
                  width: 35,
                  height: 70,
                  isVertical: true,
                ),
              ),
              child: GestureDetector(
                onTap: () {
                  if (isMyTurn && isPlayable) {
                    onTileSelected?.call(isSelected ? null : tile);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(
                    0,
                    isSelected ? -10 : 0,
                    0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isPlayable && isMyTurn
                          ? [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Opacity(
                      opacity: (!isMyTurn || !isPlayable) ? 0.5 : 1.0,
                      child: DominoTileWidget(
                        value1: tile.value1,
                        value2: tile.value2,
                        width: 35,
                        height: 70,
                        isVertical: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_canPass)
          _buildPassButton()
        else
          _buildTurnIndicator(),
        const SizedBox(height: 6),
        _buildRoundsWon(),
      ],
    );
  }

  Widget _buildPassButton() {
    return GestureDetector(
      onTap: onPassTurn,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.orange,
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.skip_next,
          color: Colors.orange,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildTurnIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMyTurn
            ? Colors.green.withValues(alpha: 0.3)
            : Colors.grey.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: isMyTurn ? Colors.green : Colors.grey,
          width: 2,
        ),
      ),
      child: Icon(
        isMyTurn ? Icons.play_arrow : Icons.hourglass_empty,
        color: isMyTurn ? Colors.green : Colors.grey,
        size: 20,
      ),
    );
  }

  Widget _buildRoundsWon() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 14),
        Text(
          '$roundsWon/3',
          style: const TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
