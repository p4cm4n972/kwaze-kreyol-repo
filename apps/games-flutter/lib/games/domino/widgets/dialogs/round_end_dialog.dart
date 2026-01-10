import 'package:flutter/material.dart';
import '../../models/domino_session.dart';
import '../../models/domino_round.dart';
import '../../models/domino_participant.dart';

/// Dialog affichant les résultats d'une manche terminée
class RoundEndDialog extends StatelessWidget {
  final DominoSession session;
  final DominoRound round;

  const RoundEndDialog({
    super.key,
    required this.session,
    required this.round,
  });

  /// Affiche le dialog de fin de manche
  static void show(BuildContext context, DominoSession session, DominoRound round) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => RoundEndDialog(
        session: session,
        round: round,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final winner = _findWinner();

    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: _buildTitle(),
      content: _buildContent(winner),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Continuer',
            style: TextStyle(
              color: Colors.lightGreenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  DominoParticipant? _findWinner() {
    if (round.winnerParticipantId == null) return null;

    try {
      return session.participants.firstWhere(
        (p) => p.id == round.winnerParticipantId,
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Icon(
          round.isCapot ? Icons.emoji_events : Icons.block,
          color: round.isCapot ? Colors.amber : Colors.orange,
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Manche ${round.roundNumber} terminée !',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(DominoParticipant? winner) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEndTypeBadge(),
        const SizedBox(height: 16),
        if (winner != null) ...[
          _buildWinnerText(winner),
          const SizedBox(height: 16),
        ],
        _buildScoresSection(),
      ],
    );
  }

  Widget _buildEndTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: round.isCapot ? Colors.green.shade800 : Colors.orange.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        round.isCapot ? 'CAPOT !' : 'Partie bloquée',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWinnerText(DominoParticipant winner) {
    return Text(
      'Gagnant: ${winner.displayName}',
      style: const TextStyle(
        color: Colors.lightGreenAccent,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildScoresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Points restants:',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...session.participants.map((p) => _buildPlayerScore(p)),
      ],
    );
  }

  Widget _buildPlayerScore(DominoParticipant player) {
    final score = round.finalScores[player.id] ?? 0;
    final isWinner = player.id == round.winnerParticipantId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (isWinner)
            const Icon(Icons.star, color: Colors.amber, size: 20)
          else
            const SizedBox(width: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player.displayName,
              style: TextStyle(
                color: isWinner ? Colors.lightGreenAccent : Colors.white,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '$score pts',
            style: TextStyle(
              color: isWinner ? Colors.lightGreenAccent : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
