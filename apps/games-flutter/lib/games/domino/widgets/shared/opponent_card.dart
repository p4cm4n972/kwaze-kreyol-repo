import 'package:flutter/material.dart';
import '../../models/domino_participant.dart';

/// Carte compacte d'un adversaire affichant son avatar, nom et nombre de tuiles
class OpponentCard extends StatelessWidget {
  final DominoParticipant player;
  final int tileCount;
  final bool isTheirTurn;
  final bool isLeft;
  final Animation<double>? pulseAnimation;

  const OpponentCard({
    super.key,
    required this.player,
    required this.tileCount,
    required this.isTheirTurn,
    this.isLeft = true,
    this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: EdgeInsets.only(
        left: isLeft ? 8 : 0,
        right: isLeft ? 0 : 8,
        top: 8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTheirTurn
              ? [const Color(0xFFFFD700), const Color(0xFFFF8C00)]
              : [Colors.black.withValues(alpha: 0.6), Colors.black.withValues(alpha: 0.4)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTheirTurn ? Colors.amber : Colors.white24,
          width: isTheirTurn ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isTheirTurn ? Colors.amber.withValues(alpha: 0.4) : Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatar(),
          const SizedBox(width: 8),
          _buildPlayerInfo(),
        ],
      ),
    );

    // Appliquer l'animation de pulsation si c'est le tour du joueur
    if (isTheirTurn && pulseAnimation != null) {
      return ScaleTransition(
        scale: pulseAnimation!,
        child: card,
      );
    }

    return card;
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isTheirTurn ? Colors.black26 : Colors.white24,
          child: Text(
            player.displayName[0].toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isTheirTurn ? Colors.black : Colors.white,
            ),
          ),
        ),
        // Badge nombre de tuiles
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isTheirTurn ? Colors.black : Colors.blue.shade700,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Center(
              child: Text(
                '$tileCount',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerInfo() {
    final displayName = player.displayName.length > 8
        ? '${player.displayName.substring(0, 8)}.'
        : player.displayName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayName,
          style: TextStyle(
            color: isTheirTurn ? Colors.black : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${player.roundsWon} ★',
          style: TextStyle(
            color: isTheirTurn ? Colors.black54 : Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Widget affichant tous les adversaires positionnés
class OpponentsRow extends StatelessWidget {
  final List<DominoParticipant> opponents;
  final String? currentTurnParticipantId;
  final Map<String, List<dynamic>>? playerHands;
  final Animation<double>? pulseAnimation;

  const OpponentsRow({
    super.key,
    required this.opponents,
    this.currentTurnParticipantId,
    this.playerHands,
    this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Adversaire gauche
        if (opponents.isNotEmpty)
          OpponentCard(
            player: opponents[0],
            tileCount: playerHands?[opponents[0].id]?.length ?? 0,
            isTheirTurn: currentTurnParticipantId == opponents[0].id,
            isLeft: true,
            pulseAnimation: pulseAnimation,
          ),
        // Adversaire droite
        if (opponents.length > 1)
          OpponentCard(
            player: opponents[1],
            tileCount: playerHands?[opponents[1].id]?.length ?? 0,
            isTheirTurn: currentTurnParticipantId == opponents[1].id,
            isLeft: false,
            pulseAnimation: pulseAnimation,
          ),
      ],
    );
  }
}
