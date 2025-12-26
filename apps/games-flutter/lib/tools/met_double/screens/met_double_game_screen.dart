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
        automaticallyImplyLeading: false,
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

            // Historique des manches récentes
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
                    const Text(
                      'Dernières manches',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _currentSession.rounds.length > 5
                            ? 5
                            : _currentSession.rounds.length,
                        itemBuilder: (context, index) {
                          final roundIndex =
                              _currentSession.rounds.length - 1 - index;
                          final round = _currentSession.rounds[roundIndex];
                          return _buildRoundChip(round);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Bouton d'enregistrement
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isRecording ? null : _showRecordDialog,
                  icon: _isRecording
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_circle),
                  label: Text(
                    _isRecording
                        ? 'Enregistrement...'
                        : 'Enregistrer une manche',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
                  Text(
                    participant.displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (participant.isHost)
                    Text(
                      'Hôte',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),

            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

            // Indicateur de victoire proche
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enregistrer la manche'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Option chirée
          CheckboxListTile(
            title: const Text('Manche chirée'),
            subtitle: const Text('Tous les joueurs avaient au moins 1 point'),
            value: _isChiree,
            onChanged: (value) {
              setState(() {
                _isChiree = value ?? false;
                if (_isChiree) {
                  _selectedWinner = null;
                }
              });
            },
          ),

          if (!_isChiree) ...[
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
