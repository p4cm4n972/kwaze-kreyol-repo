import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/met_double_game.dart';
import '../services/met_double_service.dart';

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
  final MetDoubleService _metDoubleService = MetDoubleService();
  late MetDoubleSession _session;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      // Recharger la session complète avec toutes les données à jour
      final freshSession = await _metDoubleService.getSession(widget.session.id);
      setState(() {
        _session = freshSession;
        _isLoading = false;
      });

      // Lancer les confettis après chargement
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _confettiController.play();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Résultats'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final winner = _session.winner;
    final cochons = _session.participants
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
                    '${_session.rounds.length} manches jouées',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Gagnant
                  if (winner != null) ...[
                    (() {
                      // Calculer le nombre de manches gagnées par le vainqueur
                      final manchesGagnees = _session.rounds.where((r) => r.winnerParticipantId == winner.id).length;

                      return Container(
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
                              color: Colors.amber.withValues(alpha: 0.3),
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
                              '$manchesGagnees manche${manchesGagnees > 1 ? 's' : ''} gagnée${manchesGagnees > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }()),
                    const SizedBox(height: 16),
                  ],

                  // Met double (joueur qui a donné le plus de cochons)
                  (() {
                    // Calculer le nombre de cochons DONNÉS par chaque participant
                    final participantsMetDouble = _session.participants.map((p) {
                      int cochonsDonnes = 0;
                      for (var round in _session.rounds) {
                        if (round.winnerParticipantId == p.id) {
                          cochonsDonnes += round.cochonParticipantIds.length;
                        }
                      }
                      return {'participant': p, 'cochonsDonnes': cochonsDonnes};
                    }).toList();

                    // Trier par nombre de cochons donnés (décroissant)
                    participantsMetDouble.sort((a, b) => (b['cochonsDonnes'] as int).compareTo(a['cochonsDonnes'] as int));

                    // Obtenir celui qui a donné le plus de cochons
                    final metDouble = participantsMetDouble.first;
                    final metDoubleParticipant = metDouble['participant'] as MetDoubleParticipant;
                    final cochonsDonnes = metDouble['cochonsDonnes'] as int;

                    // N'afficher que si au moins 1 cochon donné
                    if (cochonsDonnes > 0) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade300,
                              Colors.green.shade100,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '💪',
                              style: TextStyle(fontSize: 64),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'MET DOUBLE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              metDoubleParticipant.displayName,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$cochonsDonnes cochon${cochonsDonnes > 1 ? 's' : ''} donné${cochonsDonnes > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  }()),
                  const SizedBox(height: 16),

                  // Met cochon (joueur qui a reçu le plus de cochons)
                  (() {
                    // Calculer le nombre de cochons REÇUS par chaque participant
                    final participantsAvecCochons = _session.participants.map((p) {
                      final nombreCochons = _session.rounds.where((r) => r.cochonParticipantIds.contains(p.id)).length;
                      return {'participant': p, 'nombreCochons': nombreCochons};
                    }).toList();

                    // Trier par nombre de cochons reçus (décroissant)
                    participantsAvecCochons.sort((a, b) => (b['nombreCochons'] as int).compareTo(a['nombreCochons'] as int));

                    // Obtenir celui qui a reçu le plus de cochons
                    final metCochon = participantsAvecCochons.first;
                    final metCochonParticipant = metCochon['participant'] as MetDoubleParticipant;
                    final nombreCochons = metCochon['nombreCochons'] as int;

                    // N'afficher que si au moins 1 cochon reçu
                    if (nombreCochons > 0) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.pink.shade300,
                              Colors.pink.shade100,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '🐷',
                              style: TextStyle(fontSize: 64),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'MET COCHON',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              metCochonParticipant.displayName,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$nombreCochons cochon${nombreCochons > 1 ? 's' : ''} reçu${nombreCochons > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  }()),
                  const SizedBox(height: 32),

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

                  // Trier les participants par nombre de manches gagnées (décroissant)
                  ...(() {
                    final sortedParticipants = _session.participants.toList()
                      ..sort((a, b) {
                        // Compter les manches gagnées pour chaque participant
                        final manchesA = _session.rounds.where((r) => r.winnerParticipantId == a.id).length;
                        final manchesB = _session.rounds.where((r) => r.winnerParticipantId == b.id).length;
                        return manchesB.compareTo(manchesA);
                      });
                    return sortedParticipants.asMap().entries.map((entry) {
                      final index = entry.key;
                      final participant = entry.value;
                      return _buildRankingCard(
                        participant,
                        index + 1,
                      );
                    });
                  }()),

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
    // Calculer le nombre de manches gagnées depuis l'historique
    final manchesGagnees = _session.rounds.where((r) => r.winnerParticipantId == participant.id).length;

    // Calculer le nombre de cochons (combien de fois le joueur apparaît dans cochonParticipantIds)
    final nombreCochons = _session.rounds.where((r) => r.cochonParticipantIds.contains(participant.id)).length;

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
          '$manchesGagnees manche${manchesGagnees > 1 ? 's' : ''} gagnée${manchesGagnees > 1 ? 's' : ''} • $nombreCochons cochon${nombreCochons > 1 ? 's' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Victoires
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getVictoryColor(manchesGagnees).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$manchesGagnees',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getVictoryColor(manchesGagnees),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '🏆',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Cochons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.pink.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$nombreCochons',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '🐷',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
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
