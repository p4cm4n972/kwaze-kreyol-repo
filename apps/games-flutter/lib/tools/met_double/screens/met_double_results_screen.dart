import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/met_double_game.dart';

class MetDoubleResultsScreen extends StatefulWidget {
  final MetDoubleSession session;

  const MetDoubleResultsScreen({
    super.key,
    required this.session,
  });

  @override
  State<MetDoubleResultsScreen> createState() => _MetDoubleResultsScreenState();
}

class _MetDoubleResultsScreenState extends State<MetDoubleResultsScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    // Lancer les confettis après un court délai
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.session.winner;
    final cochons = widget.session.participants
        .where((p) => p.isCochon)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Titre
                  const Text(
                    'Partie terminée',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.session.rounds.length} manches jouées',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Gagnant
                  if (winner != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade300,
                            Colors.amber.shade100,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            size: 64,
                            color: Colors.amber,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'VAINQUEUR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            winner.displayName,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${winner.victories} victoires',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Cochons
                  if (cochons.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.pink.shade200,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '🐷 COCHONS 🐷',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            cochons.length == 1
                                ? '${cochons.length} joueur n\'a marqué aucun point'
                                : '${cochons.length} joueurs n\'ont marqué aucun point',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...cochons.map((cochon) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.sentiment_dissatisfied,
                                      color: Colors.pink,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      cochon.displayName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Classement
                  const Text(
                    'Classement final',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...widget.session.participants.asMap().entries.map((entry) {
                    final index = entry.key;
                    final participant = entry.value;
                    return _buildRankingCard(
                      participant,
                      index + 1,
                    );
                  }),

                  const SizedBox(height: 32),

                  // Boutons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Retour à l\'accueil'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confettis
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2, // vers le bas
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.amber,
                Colors.orange,
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.blue,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard(MetDoubleParticipant participant, int rank) {
    Color? cardColor;
    IconData? medalIcon;

    switch (rank) {
      case 1:
        cardColor = Colors.amber.shade100;
        medalIcon = Icons.emoji_events;
        break;
      case 2:
        cardColor = Colors.grey.shade300;
        medalIcon = Icons.military_tech;
        break;
      case 3:
        cardColor = Colors.orange.shade100;
        medalIcon = Icons.stars;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$rank',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (medalIcon != null) ...[
              const SizedBox(width: 8),
              Icon(
                medalIcon,
                color: rank == 1 ? Colors.amber : Colors.grey[700],
              ),
            ],
          ],
        ),
        title: Text(
          participant.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          participant.isCochon
              ? '0 victoire - Cochon 🐷'
              : '${participant.victories} victoire${participant.victories > 1 ? 's' : ''}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getVictoryColor(participant.victories).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${participant.victories}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _getVictoryColor(participant.victories),
            ),
          ),
        ),
      ),
    );
  }

  Color _getVictoryColor(int victories) {
    if (victories == 0) return Colors.grey;
    if (victories == 1) return Colors.blue;
    if (victories == 2) return Colors.orange;
    return Colors.green;
  }
}
