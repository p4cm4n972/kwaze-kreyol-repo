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
    final accentColor = round.isCapot ? Colors.amber : Colors.orange;
    final gradientColors = round.isCapot
        ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
        : [const Color(0xFFE65100), const Color(0xFFFF8F00)];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1a1a2e), const Color(0xFF16213e)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône principale
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.5),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Icon(
                  round.isCapot ? Icons.emoji_events : Icons.block,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              // Titre
              Text(
                'Manche ${round.roundNumber} terminée !',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Badge type de fin
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  round.isCapot ? 'CAPOT !' : 'Partie bloquée',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Gagnant
              if (winner != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      winner.displayName,
                      style: const TextStyle(
                        color: Colors.lightGreenAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              // Points restants
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Points restants',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...session.participants.map((p) => _buildPlayerScore(p)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Bouton
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continuer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildPlayerScore(DominoParticipant player) {
    final score = round.finalScores[player.id] ?? 0;
    final isWinner = player.id == round.winnerParticipantId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (isWinner)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 14),
            )
          else
            const SizedBox(width: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              player.displayName,
              style: TextStyle(
                color: isWinner ? Colors.lightGreenAccent : Colors.white,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isWinner
                  ? Colors.lightGreenAccent.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$score pts',
              style: TextStyle(
                color: isWinner ? Colors.lightGreenAccent : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
