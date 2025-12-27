import 'package:flutter/material.dart';
import 'dart:async';
import '../../../services/realtime_service.dart';
import '../services/met_double_service.dart';
import '../models/met_double_game.dart';
import 'met_double_results_screen.dart';

class MetDoubleGameScreen extends StatefulWidget {
  final MetDoubleSession session;

  const MetDoubleGameScreen({
    super.key,
    required this.session,
  });

  @override
  State<MetDoubleGameScreen> createState() => _MetDoubleGameScreenState();
}

class _MetDoubleGameScreenState extends State<MetDoubleGameScreen> {
  final MetDoubleService _metDoubleService = MetDoubleService();
  final RealtimeService _realtimeService = RealtimeService();

  late MetDoubleSession _currentSession;
  StreamSubscription<MetDoubleSession>? _sessionSubscription;
  bool _isRecording = false;
  bool _chireeDialogShown = false;
  bool _victoryDialogShown = false;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    _subscribeToSession();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _realtimeService.unsubscribeFromSession(_currentSession.id);
    super.dispose();
  }

  void _subscribeToSession() {
    _sessionSubscription = _realtimeService
        .subscribeToSession(_currentSession.id)
        .listen((session) {
      setState(() {
        _currentSession = session;
      });

      // Vérifier si tous les joueurs ont au moins 1 victoire (chirée)
      final allHaveAtLeastOne = _currentSession.participants.every((p) => p.victories >= 1);

      // Debug logs
      print('🔍 Vérification chirée:');
      print('   Tous >= 1 ? $allHaveAtLeastOne');
      print('   Dialog déjà affiché ? $_chireeDialogShown');
      _currentSession.participants.forEach((p) {
        print('   ${p.displayName}: ${p.victories} victoires');
      });

      // Réinitialiser le flag si quelqu'un est descendu en dessous de 1
      if (!allHaveAtLeastOne) {
        _chireeDialogShown = false;
      }

      // Afficher le dialog si c'est une nouvelle situation de chirée
      if (allHaveAtLeastOne && !_chireeDialogShown && mounted) {
        print('✅ Affichage du dialog de chirée');
        _chireeDialogShown = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showChireeDialog();
          }
        });
      }

      // Vérifier si un joueur a atteint 3 victoires
      final winner = _currentSession.participants.where((p) => p.victories >= 3).firstOrNull;

      // Réinitialiser le flag si personne n'a 3 victoires
      if (winner == null) {
        _victoryDialogShown = false;
      }

      // Afficher le dialog de victoire si quelqu'un a gagné
      if (winner != null && !_victoryDialogShown && mounted) {
        print('🏆 Victoire détectée: ${winner.displayName} avec ${winner.victories} victoires');
        _victoryDialogShown = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showVictoryDialog(winner);
          }
        });
      }

      // Si la session est terminée, naviguer vers l'écran de résultats
      if (_currentSession.status == 'completed' && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MetDoubleResultsScreen(session: _currentSession),
          ),
        );
      }
    });
  }

  Future<void> _showChireeDialog() async {
    final shouldRecord = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            const Text('Chirée détectée !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tous les joueurs ont au moins 1 point.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Voulez-vous enregistrer cette manche comme chirée ?',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text(
                'Dans une chirée, aucun joueur ne marque de point pour cette manche.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Enregistrer la chirée'),
          ),
        ],
      ),
    );

    if (shouldRecord == true) {
      await _recordRound(
        winner: _currentSession.participants.first,
        isChiree: true,
      );
      // Réinitialiser le flag après enregistrement
      _chireeDialogShown = false;
    }
  }

  Future<void> _showVictoryDialog(MetDoubleParticipant winner) async {
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            const SizedBox(width: 12),
            const Text('Manche terminée !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${winner.displayName} a gagné cette manche avec ${winner.victories} victoires !',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Que souhaitez-vous faire ?',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Text(
                'Valider enregistrera cette manche dans l\'historique.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Annuler (erreur)'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'validate'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
            child: const Text('Valider'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'restart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
            ),
            child: const Text('Valider et Nouvelle manche'),
          ),
        ],
      ),
    );

    if (action == 'validate' || action == 'restart') {
      // Enregistrer la manche gagnante dans l'historique
      await _recordVictoryRound(winner);

      // Si l'utilisateur a choisi de redémarrer, réinitialiser les scores
      if (action == 'restart') {
        await _resetScoresAfterVictory();
      }
    } else if (action == 'cancel') {
      // L'utilisateur a fait une erreur, décrémenter le score
      await _metDoubleService.decrementParticipantVictories(winner.id);
      _victoryDialogShown = false;
    }
  }

  Future<void> _recordVictoryRound(MetDoubleParticipant winner) async {
    try {
      // Trouver les cochons (ceux avec 0 victoires)
      final cochonParticipants = _currentSession.participants.where((p) => p.victories == 0).toList();
      final cochonIds = cochonParticipants.map((p) => p.id).toList();

      final nextRoundNumber = _currentSession.rounds.length + 1;
      await _metDoubleService.recordRound(
        sessionId: _currentSession.id,
        roundNumber: nextRoundNumber,
        winnerParticipantId: winner.id,
        cochonParticipantIds: cochonIds, // Enregistrer les IDs des cochons
        isChiree: false,
        skipIncrement: true, // Le score a déjà été incrémenté par le bouton +
      );

      // Marquer les cochons dans la table participants
      await _markCochons();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Manche enregistrée - ${winner.displayName} gagne !')),
        );
      }

      // Afficher les cochons si il y en a
      if (cochonParticipants.isNotEmpty && mounted) {
        await _showCochonsDialog(cochonParticipants);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<MetDoubleParticipant>> _markCochons() async {
    try {
      // Trouver tous les participants avec 0 victoires
      final cochons = _currentSession.participants.where((p) => p.victories == 0).toList();

      for (var cochon in cochons) {
        await _metDoubleService.markParticipantAsCochon(cochon.id);
      }

      return cochons;
    } catch (e) {
      print('Erreur lors du marquage des cochons: $e');
      return [];
    }
  }

  Future<void> _showCochonsDialog(List<MetDoubleParticipant> cochons) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('🐷', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Text(cochons.length > 1 ? 'Cochons !' : 'Cochon !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cochons.length > 1
                  ? 'Les joueurs suivants sont des cochons pour cette manche :'
                  : 'Le joueur suivant est un cochon pour cette manche :',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...cochons.map((cochon) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Text('🐷', style: TextStyle(fontSize: 20)),
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                cochons.length > 1
                    ? 'Ils avaient 0 point à la fin de cette manche !'
                    : 'Il avait 0 point à la fin de cette manche !',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetScoresAfterVictory() async {
    try {
      // Réinitialiser tous les scores à 0
      for (var participant in _currentSession.participants) {
        await _metDoubleService.resetParticipantScore(participant.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nouvelle manche démarrée !')),
        );
      }

      // Réinitialiser les flags
      _chireeDialogShown = false;
      _victoryDialogShown = false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _recordRound({
    required MetDoubleParticipant winner,
    bool isChiree = false,
  }) async {
    if (_isRecording) return;

    setState(() {
      _isRecording = true;
    });

    try {
      final nextRoundNumber = _currentSession.rounds.length + 1;

      await _metDoubleService.recordRound(
        sessionId: _currentSession.id,
        roundNumber: nextRoundNumber,
        winnerParticipantId: winner.id,
        isChiree: isChiree,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isChiree
                  ? 'Manche chirée enregistrée'
                  : 'Victoire de ${winner.displayName} enregistrée',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _showRecordDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _RecordRoundDialog(
        participants: _currentSession.participants,
      ),
    );

    if (result != null) {
      await _recordRound(
        winner: result['winner'],
        isChiree: result['isChiree'] ?? false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partie en cours'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: 'Retour au lobby',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Compteur de manches
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Column(
                children: [
                  const Text(
                    'Manches jouées',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '${_currentSession.rounds.length}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Scores des joueurs
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _currentSession.participants.length,
                itemBuilder: (context, index) {
                  final participant = _currentSession.participants[index];
                  return _buildPlayerScoreCard(participant);
                },
              ),
            ),

            // Historique des manches - Tableau
            if (_currentSession.rounds.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Historique des manches',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_currentSession.rounds.length} manche${_currentSession.rounds.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildRoundsTable(),
                    ),
                  ],
                ),
              ),
            ],

            // Boutons d'actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Utilisez les boutons +/- pour incrémenter les scores. La partie se termine automatiquement à 3 points.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Boutons d'action
                  Row(
                    children: [
                      // Bouton Nouvelle manche
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetScores,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Nouvelle manche'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.blue[700]!),
                            foregroundColor: Colors.blue[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Bouton Terminer la partie
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _endGame,
                          icon: const Icon(Icons.stop),
                          label: const Text('Terminer'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetScores() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle manche'),
        content: const Text(
          'Voulez-vous remettre tous les scores à 0 pour recommencer une nouvelle manche ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Réinitialiser tous les scores à 0
        for (var participant in _currentSession.participants) {
          await _metDoubleService.resetParticipantScore(participant.id);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scores réinitialisés')),
          );
        }

        // Réinitialiser les flags
        _chireeDialogShown = false;
        _victoryDialogShown = false;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _endGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer la partie'),
        content: const Text(
          'Voulez-vous vraiment terminer la partie ?\n\nLe joueur avec le plus de points sera déclaré vainqueur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Le gagnant sera calculé automatiquement par le service
        // en fonction du nombre de manches gagnées
        await _metDoubleService.forceEndSession(_currentSession.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Partie terminée !')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _incrementScore(String participantId) async {
    try {
      // Toujours juste incrémenter le score
      // L'enregistrement de la manche se fera dans la popup de validation
      await _metDoubleService.incrementParticipantVictories(participantId);

      // La mise à jour se fera automatiquement via Realtime
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _decrementScore(String participantId, int currentVictories) async {
    if (currentVictories <= 0) return;

    try {
      await _metDoubleService.decrementParticipantVictories(participantId);
      // La mise à jour se fera automatiquement via Realtime
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Widget _buildRoundsTable() {
    const cellWidth = 50.0;
    const cellHeight = 45.0;
    const headerHeight = 35.0;
    const nameColumnWidth = 120.0;

    // Construire columnWidths dynamiquement
    final columnWidths = <int, TableColumnWidth>{
      0: const FixedColumnWidth(nameColumnWidth), // Colonne joueur
    };
    for (int i = 0; i < _currentSession.rounds.length; i++) {
      columnWidths[i + 1] = const FixedColumnWidth(cellWidth);
    }

    return Table(
      columnWidths: columnWidths,
      border: TableBorder.all(color: Colors.grey[300]!),
      children: [
        // En-tête
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: [
            // Colonne joueur
            Container(
              height: headerHeight,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: const Text(
                'Joueur',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            // Colonnes manches
            ..._currentSession.rounds.map((round) => Container(
              height: headerHeight,
              alignment: Alignment.center,
              child: Text(
                'M${round.roundNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            )),
          ],
        ),
        // Lignes joueurs
        ..._currentSession.participants.map((participant) {
          return TableRow(
            children: [
              // Nom du joueur
              Container(
                height: cellHeight,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  participant.displayName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Résultats pour chaque manche
              ..._currentSession.rounds.map((round) {
                return Container(
                  height: cellHeight,
                  alignment: Alignment.center,
                  child: _buildCellContent(round, participant),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCellContent(MetDoubleRound round, MetDoubleParticipant participant) {
    // Si chirée
    if (round.isChiree) {
      return const Text(
        '⚠️',
        style: TextStyle(fontSize: 16),
      );
    }

    // Si c'est le gagnant (3 points)
    if (round.winnerParticipantId == participant.id) {
      return const Text(
        '🏆',
        style: TextStyle(fontSize: 18),
      );
    }

    // Si c'est un cochon (0 point)
    if (round.cochonParticipantIds.contains(participant.id)) {
      return const Text(
        '🐷',
        style: TextStyle(fontSize: 18),
      );
    }

    // Sinon, on ne connaît pas le score exact (1 ou 2 points)
    return Text(
      '-',
      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
    );
  }

  Widget _buildPlayerScoreCard(MetDoubleParticipant participant) {
    final isLeading = _currentSession.participants.every(
      (p) => participant.victories >= p.victories,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isLeading && participant.victories > 0
          ? Colors.amber.withOpacity(0.1)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: isLeading && participant.victories > 0
                  ? Colors.amber
                  : Colors.grey,
              child: Icon(
                participant.isGuest ? Icons.person_outline : Icons.person,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),

            // Nom
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        participant.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (participant.isCochon) ...[
                        const SizedBox(width: 8),
                        const Text(
                          '🐷',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ],
                  ),
                  if (participant.isHost)
                    Text(
                      'Hôte',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (participant.isCochon)
                    Text(
                      'Cochon',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

            // Boutons de contrôle du score
            Row(
              children: [
                // Bouton -
                IconButton(
                  onPressed: participant.victories > 0
                      ? () => _decrementScore(participant.id, participant.victories)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.red,
                  iconSize: 32,
                ),

                // Score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getVictoryColor(participant.victories).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${participant.victories}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _getVictoryColor(participant.victories),
                    ),
                  ),
                ),

                // Bouton +
                IconButton(
                  onPressed: participant.victories < 3
                      ? () => _incrementScore(participant.id)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.green,
                  iconSize: 32,
                ),
              ],
            ),

            // Indicateur de victoire
            if (participant.victories >= 3)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 32,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundChip(MetDoubleRound round) {
    final winner = _currentSession.participants.firstWhere(
      (p) => p.id == round.winnerParticipantId,
      orElse: () => _currentSession.participants.first,
    );

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: round.isChiree ? Colors.orange : Colors.green,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Manche ${round.roundNumber}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            round.isChiree ? 'Chirée' : winner.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
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

// Dialog pour enregistrer une manche
class _RecordRoundDialog extends StatefulWidget {
  final List<MetDoubleParticipant> participants;

  const _RecordRoundDialog({required this.participants});

  @override
  State<_RecordRoundDialog> createState() => _RecordRoundDialogState();
}

class _RecordRoundDialogState extends State<_RecordRoundDialog> {
  MetDoubleParticipant? _selectedWinner;
  bool _isChiree = false;

  @override
  void initState() {
    super.initState();
    // Vérifier si tous les joueurs ont au moins 1 victoire
    final allHaveAtLeastOne = widget.participants.every((p) => p.victories >= 1);
    if (allHaveAtLeastOne) {
      _isChiree = true;
    }
  }

  bool get _forcedChiree {
    return widget.participants.every((p) => p.victories >= 1);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enregistrer la manche'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message si chirée forcée
          if (_forcedChiree) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tous les joueurs ont au moins 1 point.\nCette manche doit être enregistrée comme chirée.',
                      style: TextStyle(color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Option chirée
          CheckboxListTile(
            title: const Text('Manche chirée'),
            subtitle: Text(
              _forcedChiree
                  ? 'Obligatoire - Tous ont au moins 1 point'
                  : 'Tous les joueurs avaient au moins 1 point',
            ),
            value: _isChiree,
            onChanged: _forcedChiree
                ? null
                : (value) {
                    setState(() {
                      _isChiree = value ?? false;
                      if (_isChiree) {
                        _selectedWinner = null;
                      }
                    });
                  },
          ),

          if (!_isChiree && !_forcedChiree) ...[
            const SizedBox(height: 16),
            const Text(
              'Qui a gagné cette manche ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Liste des joueurs
            ...widget.participants.map((participant) {
              return RadioListTile<MetDoubleParticipant>(
                title: Text(participant.displayName),
                subtitle: Text('${participant.victories} victoire${participant.victories > 1 ? 's' : ''}'),
                value: participant,
                groupValue: _selectedWinner,
                onChanged: (value) {
                  setState(() {
                    _selectedWinner = value;
                  });
                },
              );
            }),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: (_isChiree || _selectedWinner != null)
              ? () {
                  Navigator.pop(context, {
                    'winner': _selectedWinner ?? widget.participants.first,
                    'isChiree': _isChiree,
                  });
                }
              : null,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
