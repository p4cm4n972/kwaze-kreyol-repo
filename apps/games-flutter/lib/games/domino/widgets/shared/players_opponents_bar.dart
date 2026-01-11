import 'package:flutter/material.dart';
import '../../models/domino_participant.dart';

/// Barre d'affichage des adversaires humains (mode multijoueur)
class PlayersOpponentsBar extends StatelessWidget {
  final List<DominoParticipant> opponents;
  final String? currentTurnParticipantId;
  final Map<String, List<dynamic>>? playerHands;
  final Animation<double>? pulseAnimation;

  const PlayersOpponentsBar({
    super.key,
    required this.opponents,
    this.currentTurnParticipantId,
    this.playerHands,
    this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: opponents.map((opponent) {
          final isCurrentTurn = currentTurnParticipantId == opponent.id;
          final tileCount = playerHands?[opponent.id]?.length ?? 0;

          return _PlayerOpponentCard(
            player: opponent,
            tileCount: tileCount,
            isCurrentTurn: isCurrentTurn,
            pulseAnimation: pulseAnimation,
          );
        }).toList(),
      ),
    );
  }
}

class _PlayerOpponentCard extends StatelessWidget {
  final DominoParticipant player;
  final int tileCount;
  final bool isCurrentTurn;
  final Animation<double>? pulseAnimation;

  const _PlayerOpponentCard({
    required this.player,
    required this.tileCount,
    required this.isCurrentTurn,
    this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentTurn
            ? Colors.orange.withValues(alpha: 0.4)
            : Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentTurn
              ? Colors.orange
              : Colors.white.withValues(alpha: 0.2),
          width: isCurrentTurn ? 2 : 1,
        ),
        boxShadow: isCurrentTurn
            ? [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatar(),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                player.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.style,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$tileCount',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  Text(
                    ' ${player.roundsWon}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isCurrentTurn) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.orange,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );

    if (isCurrentTurn && pulseAnimation != null) {
      return AnimatedBuilder(
        animation: pulseAnimation!,
        builder: (context, child) {
          return Transform.scale(
            scale: pulseAnimation!.value,
            child: card,
          );
        },
      );
    }

    return card;
  }

  Widget _buildAvatar() {
    final initial = player.displayName.isNotEmpty
        ? player.displayName[0].toUpperCase()
        : '?';

    // Couleur basee sur le nom
    final colorSeed = player.displayName.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
    ];
    final avatarColor = colors[colorSeed.abs() % colors.length];

    return CircleAvatar(
      radius: 16,
      backgroundColor: avatarColor.shade700,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
