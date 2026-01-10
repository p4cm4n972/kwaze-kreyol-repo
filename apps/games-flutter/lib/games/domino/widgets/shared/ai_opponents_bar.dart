import 'package:flutter/material.dart';
import '../../models/domino_participant.dart';

/// Barre d'affichage des adversaires IA
class AIOpponentsBar extends StatelessWidget {
  final List<DominoParticipant> aiPlayers;
  final String? currentTurnParticipantId;
  final Map<String, List<dynamic>>? playerHands;
  final Animation<double>? pulseAnimation;

  const AIOpponentsBar({
    super.key,
    required this.aiPlayers,
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
        children: aiPlayers.map((ai) {
          final isCurrentTurn = currentTurnParticipantId == ai.id;
          final tileCount = playerHands?[ai.id]?.length ?? 0;

          return _AIOpponentCard(
            player: ai,
            tileCount: tileCount,
            isCurrentTurn: isCurrentTurn,
            pulseAnimation: pulseAnimation,
          );
        }).toList(),
      ),
    );
  }
}

class _AIOpponentCard extends StatelessWidget {
  final DominoParticipant player;
  final int tileCount;
  final bool isCurrentTurn;
  final Animation<double>? pulseAnimation;

  const _AIOpponentCard({
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
            ? Colors.purple.withValues(alpha: 0.4)
            : Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentTurn
              ? Colors.purple
              : Colors.white.withValues(alpha: 0.2),
          width: isCurrentTurn ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.purple.shade700,
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
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
                  Text(
                    '$tileCount tuiles',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
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
}
