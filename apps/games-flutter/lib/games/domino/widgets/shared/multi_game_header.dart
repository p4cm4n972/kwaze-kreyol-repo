import 'package:flutter/material.dart';
import '../../models/domino_session.dart';
import '../../models/domino_participant.dart';

/// Header pour le mode multijoueur avec scores des joueurs
class MultiGameHeader extends StatelessWidget {
  final DominoSession session;
  final DominoParticipant? currentParticipant;
  final VoidCallback? onBack;

  const MultiGameHeader({
    super.key,
    required this.session,
    this.currentParticipant,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final roundNumber = session.currentGameState?.roundNumber ?? 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          _buildRoundBadge(roundNumber),
          const SizedBox(width: 12),
          _buildMultiplayerBadge(),
          const Spacer(),
          _buildScoresSummary(),
        ],
      ),
    );
  }

  Widget _buildRoundBadge(int roundNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
          const SizedBox(width: 6),
          Text(
            'Manche $roundNumber',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplayerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people, color: Colors.blue.shade300, size: 16),
          const SizedBox(width: 4),
          Text(
            '${session.participants.length} joueurs',
            style: TextStyle(
              color: Colors.blue.shade300,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoresSummary() {
    // Afficher les scores de tous les joueurs de maniere compacte
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: session.participants.map((p) {
        final isCurrentPlayer = p.id == currentParticipant?.id;
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrentPlayer
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: isCurrentPlayer
                  ? Border.all(color: Colors.green.withValues(alpha: 0.5))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getInitials(p.displayName),
                  style: TextStyle(
                    color: isCurrentPlayer ? Colors.green : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, color: Colors.amber, size: 12),
                Text(
                  '${p.roundsWon}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}
