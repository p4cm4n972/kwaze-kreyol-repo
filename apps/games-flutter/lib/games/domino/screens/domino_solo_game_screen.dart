import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';
import '../services/domino_ai_service.dart';
import '../services/domino_solo_service.dart';
import '../services/domino_sound_service.dart';
import '../models/domino_session.dart';
import '../models/domino_tile.dart';
import '../models/domino_participant.dart';
import '../models/domino_game_state.dart';
import '../utils/domino_logic.dart';
import '../widgets/domino_board_widget.dart';
import '../widgets/shared/solo_game_header.dart';
import '../widgets/shared/ai_opponents_bar.dart';
import '../widgets/shared/solo_player_hand.dart';

/// Écran de jeu solo contre 2 IA
class DominoSoloGameScreen extends StatefulWidget {
  final AIDifficulty difficulty;

  const DominoSoloGameScreen({
    super.key,
    required this.difficulty,
  });

  @override
  State<DominoSoloGameScreen> createState() => _DominoSoloGameScreenState();
}

class _DominoSoloGameScreenState extends State<DominoSoloGameScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final DominoSoundService _soundService = DominoSoundService();

  DominoSession? _session;
  DominoGameState? _gameState;
  DominoTile? _selectedTile;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isAIPlaying = false;
  Timer? _aiTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String? get _currentUserId => _authService.getUserIdOrNull();
  String _playerName = 'Joueur';

  DominoParticipant? get _humanParticipant {
    if (_session == null) return null;
    return _session!.participants.firstWhere((p) => !p.isAI);
  }

  bool get _isMyTurn {
    if (_gameState == null || _humanParticipant == null) return false;
    return _gameState!.currentTurnParticipantId == _humanParticipant!.id;
  }

  List<DominoTile> get _myHand {
    if (_gameState == null || _humanParticipant == null) return [];
    return _gameState!.playerHands[_humanParticipant!.id] ?? [];
  }

  List<DominoTile> get _playableTiles {
    if (_gameState == null) return [];
    return DominoLogic.getPlayableTiles(
      _myHand,
      _gameState!.leftEnd,
      _gameState!.rightEnd,
    );
  }

  DominoParticipant? get _currentTurnParticipant {
    if (_session == null || _gameState == null) return null;
    return _session!.participants.firstWhere(
      (p) => p.id == _gameState!.currentTurnParticipantId,
      orElse: () => _session!.participants.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _soundService.initialize();
    _loadPlayerName();
    _initializeGame();
  }

  Future<void> _loadPlayerName() async {
    final user = await _authService.getCurrentUser();
    final guestName = await _authService.getGuestName();
    if (mounted) {
      setState(() {
        _playerName = user?.username ?? guestName ?? 'Joueur';
      });
    }
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeGame({bool forceNew = false}) async {
    // Essayer de charger une session existante POUR LA MÊME DIFFICULTÉ (sauf si forceNew)
    if (!forceNew) {
      final savedSession = await DominoSoloService.loadSession(
        forDifficulty: widget.difficulty,
      );
      if (savedSession != null && savedSession.status == 'in_progress') {
        setState(() {
          _session = savedSession;
          _gameState = savedSession.currentGameState;
        });

        // Vérifier si c'est le tour d'une IA
        _checkAndExecuteAITurn();
        return;
      }
    }

    // Supprimer l'ancienne session si forceNew ou si difficulté différente
    await DominoSoloService.clearSession();

    // Réinitialiser complètement l'état avant de créer une nouvelle session
    _session = null;
    _gameState = null;

    // Créer la session solo (nouveaux participants avec roundsWon = 0)
    final session = DominoSoloService.createSoloSession(
      humanPlayerId: _currentUserId ?? 'guest',
      humanPlayerName: _playerName,
      difficulty: widget.difficulty,
    );

    // Démarrer la première manche
    final gameState = DominoSoloService.startNewRound(session);

    final newSession = session.copyWith(currentGameState: gameState);

    setState(() {
      _session = newSession;
      _gameState = gameState;
    });

    // Sauvegarder la nouvelle session AVEC la difficulté
    await DominoSoloService.saveSession(newSession, difficulty: widget.difficulty);

    // Afficher qui commence et avec quel double
    _showStartingPlayerInfo(gameState, newSession.participants);

    // Vérifier si c'est le tour d'une IA
    _checkAndExecuteAITurn();
  }

  /// Sauvegarde la session actuelle
  Future<void> _saveSession() async {
    if (_session != null) {
      await DominoSoloService.saveSession(_session!, difficulty: widget.difficulty);
    }
  }

  /// Affiche un message indiquant qui commence et avec quel double
  void _showStartingPlayerInfo(
    DominoGameState gameState,
    List<DominoParticipant> participants,
  ) {
    if (!mounted) return;

    final startingPlayerId = gameState.currentTurnParticipantId;
    final startingPlayer = participants.firstWhere(
      (p) => p.id == startingPlayerId,
      orElse: () => participants.first,
    );

    // Trouver le plus grand double
    final highestDouble = DominoLogic.findHighestDouble(gameState.playerHands);

    String message;
    if (highestDouble != null) {
      final (playerId, doubleValue) = highestDouble;
      if (playerId == startingPlayerId) {
        message = '${startingPlayer.displayName} commence avec le double $doubleValue';
      } else {
        message = '${startingPlayer.displayName} commence';
      }
    } else {
      message = '${startingPlayer.displayName} commence';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _checkAndExecuteAITurn() {
    if (_session == null || _gameState == null) return;

    final currentPlayer = _currentTurnParticipant;
    if (currentPlayer == null || !currentPlayer.isAI) return;

    // L'IA joue
    setState(() {
      _isAIPlaying = true;
    });

    final delay = DominoAIService.getThinkingDelay(widget.difficulty);

    _aiTimer = Timer(Duration(milliseconds: delay), () {
      _executeAITurn(currentPlayer);
    });
  }

  void _executeAITurn(DominoParticipant aiPlayer) {
    if (_gameState == null || _session == null) return;

    final hand = _gameState!.playerHands[aiPlayer.id] ?? [];

    // Vérifier si l'IA peut jouer
    final shouldPass = DominoAIService.shouldPass(
      hand: hand,
      leftEnd: _gameState!.leftEnd,
      rightEnd: _gameState!.rightEnd,
      boardEmpty: _gameState!.board.isEmpty,
    );

    if (shouldPass) {
      _aiPassTurn(aiPlayer);
    } else {
      _aiPlaceTile(aiPlayer, hand);
    }
  }

  void _aiPlaceTile(DominoParticipant aiPlayer, List<DominoTile> hand) {
    final move = DominoAIService.selectMove(
      hand: hand,
      leftEnd: _gameState!.leftEnd,
      rightEnd: _gameState!.rightEnd,
      board: _gameState!.board,
      difficulty: widget.difficulty,
    );

    if (move == null) {
      _aiPassTurn(aiPlayer);
      return;
    }

    try {
      final result = DominoSoloService.placeTile(
        state: _gameState!,
        participantId: aiPlayer.id,
        tile: move.tile,
        side: move.side,
        participants: _session!.participants,
      );

      final newSession = _session!.copyWith(currentGameState: result.newState);
      setState(() {
        _gameState = result.newState;
        _session = newSession;
        _isAIPlaying = false;
      });

      // Sauvegarder après le coup de l'IA
      _saveSession();

      // Son de placement
      _soundService.playPlace();

      if (result.roundEnded) {
        _handleRoundEnd(result.roundWinnerId!, isCapot: result.isCapot);
      } else {
        _checkAndExecuteAITurn();
      }
    } catch (e) {
      debugPrint('AI place tile error: $e');
      _aiPassTurn(aiPlayer);
    }
  }

  void _aiPassTurn(DominoParticipant aiPlayer) {
    try {
      final result = DominoSoloService.passTurn(
        state: _gameState!,
        participantId: aiPlayer.id,
        participants: _session!.participants,
      );

      final newSession = _session!.copyWith(currentGameState: result.newState);
      setState(() {
        _gameState = result.newState;
        _session = newSession;
        _isAIPlaying = false;
      });

      // Sauvegarder après le passe de l'IA
      _saveSession();

      // Son de passe
      _soundService.playPass();

      if (result.roundEnded) {
        _handleRoundEnd(result.roundWinnerId!);
      } else {
        _checkAndExecuteAITurn();
      }
    } catch (e) {
      debugPrint('AI pass turn error: $e');
      setState(() {
        _isAIPlaying = false;
      });
    }
  }

  void _handleRoundEnd(String winnerId, {bool isCapot = false}) {
    if (_session == null || _gameState == null) return;

    // Calculer les scores finaux (points restants dans chaque main)
    final Map<String, int> finalScores = {};
    for (final entry in _gameState!.playerHands.entries) {
      int totalPoints = 0;
      for (final tile in entry.value) {
        totalPoints += tile.value1 + tile.value2;
      }
      finalScores[entry.key] = totalPoints;
    }

    // Mettre à jour la session avec les rounds
    final updatedSession = DominoSoloService.updateSessionAfterRound(
      _session!,
      winnerId,
      isCapot: isCapot,
      finalScores: finalScores,
    );

    setState(() {
      _session = updatedSession;
    });

    // Sauvegarder après la fin de manche
    _saveSession();

    // Jouer le son de victoire uniquement pour fin de partie
    if (updatedSession.status == 'completed') {
      _soundService.playVictory();
    } else if (updatedSession.status == 'chiree') {
      _soundService.playChiree();
    }
    // Pas de son pour simple victoire de manche

    // Afficher le dialog de fin de manche
    _showRoundEndDialog(winnerId);
  }

  void _showRoundEndDialog(String winnerId) {
    if (!mounted || _session == null) return;

    final winner = _session!.participants.firstWhere(
      (p) => p.id == winnerId,
      orElse: () => _session!.participants.first,
    );

    final isCapot = _gameState!.playerHands[winnerId]?.isEmpty ?? false;

    final accentColor = isCapot ? Colors.amber : Colors.orange;
    final gradientColors = isCapot
        ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
        : [const Color(0xFFE65100), const Color(0xFFFF8F00)];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
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
                    isCapot ? Icons.emoji_events : Icons.block,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                // Titre
                Text(
                  'Manche ${_gameState?.roundNumber ?? 1} terminée !',
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
                    isCapot ? 'CAPOT !' : 'Partie bloquée',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Gagnant
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      winner.displayName,
                      style: TextStyle(
                        color: winner.isAI ? Colors.orange : Colors.lightGreenAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (winner.isAI) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.smart_toy, color: Colors.grey, size: 20),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                // Score des manches
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Score des manches',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._session!.participants.map((p) {
                        final isWinner = p.id == winnerId;
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
                              Icon(
                                p.isAI ? Icons.smart_toy : Icons.person,
                                color: Colors.grey.shade600,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  p.displayName,
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
                                  '${p.roundsWon}',
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
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Bouton
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _checkGameOverOrContinue();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      DominoSoloService.isGameOver(_session!) ? 'Voir résultats' : 'Manche suivante',
                      style: const TextStyle(
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
      ),
    );
  }

  void _checkGameOverOrContinue() async {
    if (_session == null) return;

    if (DominoSoloService.isGameOver(_session!)) {
      // Partie terminée - supprimer la session sauvegardée
      await DominoSoloService.clearSession();
      _showFinalResultsDialog();
    } else {
      // Démarrer une nouvelle manche - le gagnant de la dernière manche commence
      final previousWinnerId = _session!.rounds.isNotEmpty
          ? _session!.rounds.last.winnerParticipantId
          : null;

      final newGameState = DominoSoloService.startNewRound(
        _session!,
        previousWinnerId: previousWinnerId,
      );

      setState(() {
        _gameState = newGameState;
        _session = _session!.copyWith(currentGameState: newGameState);
      });

      // Sauvegarder après le début de la nouvelle manche
      await _saveSession();

      _checkAndExecuteAITurn();
    }
  }

  void _showFinalResultsDialog() {
    if (!mounted || _session == null) return;

    final isChiree = _session!.isChiree;
    final winner = isChiree
        ? null
        : _session!.participants.reduce((a, b) => a.roundsWon > b.roundsWon ? a : b);
    final humanWon = winner != null && !winner.isAI;

    final accentColor = isChiree
        ? Colors.blue
        : (humanWon ? Colors.amber : Colors.red);
    final gradientColors = isChiree
        ? [const Color(0xFF1565C0), const Color(0xFF42A5F5)]
        : (humanWon
            ? [const Color(0xFFFF8F00), const Color(0xFFFFCA28)]
            : [const Color(0xFFC62828), const Color(0xFFEF5350)]);
    final icon = isChiree
        ? Icons.handshake
        : (humanWon ? Icons.emoji_events : Icons.sentiment_dissatisfied);
    final title = isChiree
        ? 'CHIRÉE !'
        : (humanWon ? 'VICTOIRE !' : 'DÉFAITE');
    final subtitle = isChiree
        ? 'Match nul ! Tous les joueurs ont gagné au moins une manche.'
        : (humanWon
            ? 'Félicitations, vous avez gagné la partie !'
            : '${winner!.displayName} a gagné la partie.');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1a1a2e), const Color(0xFF16213e)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône principale avec animation
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.6),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 20),
                // Titre
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                // Sous-titre
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                // Scores finaux
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Résultats finaux',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._session!.participants.map((p) {
                        final isCochon = p.roundsWon == 0;
                        final isWinner = !isChiree && p.id == winner?.id;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              // Indicateur
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isWinner
                                      ? accentColor.withValues(alpha: 0.3)
                                      : (isCochon
                                          ? Colors.red.withValues(alpha: 0.3)
                                          : Colors.white.withValues(alpha: 0.1)),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isWinner
                                      ? const Icon(Icons.star, color: Colors.amber, size: 18)
                                      : (isCochon
                                          ? const Text('🐷', style: TextStyle(fontSize: 14))
                                          : (p.isAI
                                              ? Icon(Icons.smart_toy, color: Colors.grey.shade500, size: 16)
                                              : Icon(Icons.person, color: Colors.grey.shade500, size: 16))),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Nom
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.displayName,
                                      style: TextStyle(
                                        color: isWinner
                                            ? accentColor
                                            : (isCochon ? Colors.red.shade300 : Colors.white),
                                        fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (isCochon)
                                      Text(
                                        'Cochon !',
                                        style: TextStyle(
                                          color: Colors.red.shade300,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Score
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: isWinner
                                      ? LinearGradient(colors: gradientColors)
                                      : null,
                                  color: isWinner ? null : Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${p.roundsWon}',
                                  style: TextStyle(
                                    color: isWinner ? Colors.white : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await DominoSoloService.clearSession();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            context.go('/domino');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Menu'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _initializeGame(forceNew: true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Rejouer',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _placeTile(String side, DominoTile tile) async {
    if (_humanParticipant == null || _isAIPlaying) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = DominoSoloService.placeTile(
        state: _gameState!,
        participantId: _humanParticipant!.id,
        tile: tile,
        side: side,
        participants: _session!.participants,
      );

      final newSession = _session!.copyWith(currentGameState: result.newState);
      setState(() {
        _gameState = result.newState;
        _session = newSession;
        _selectedTile = null;
        _isLoading = false;
      });

      // Sauvegarder après le coup du joueur
      _saveSession();

      // Son de placement
      _soundService.playPlace();

      if (result.roundEnded) {
        _handleRoundEnd(result.roundWinnerId!, isCapot: result.isCapot);
      } else {
        _checkAndExecuteAITurn();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _passTurn() async {
    if (_humanParticipant == null || !_isMyTurn || _isAIPlaying) return;

    // Vérifier qu'on ne peut vraiment pas jouer
    if (_playableTiles.isNotEmpty) {
      setState(() {
        _errorMessage = 'Vous pouvez encore jouer une tuile !';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = DominoSoloService.passTurn(
        state: _gameState!,
        participantId: _humanParticipant!.id,
        participants: _session!.participants,
      );

      final newSession = _session!.copyWith(currentGameState: result.newState);
      setState(() {
        _gameState = result.newState;
        _session = newSession;
        _isLoading = false;
      });

      // Sauvegarder après le passe du joueur
      _saveSession();

      // Son de passe
      _soundService.playPass();

      if (result.roundEnded) {
        _handleRoundEnd(result.roundWinnerId!);
      } else {
        _checkAndExecuteAITurn();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null || _gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final aiPlayers = _session!.participants.where((p) => p.isAI).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
              const Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SoloGameHeader(
                roundNumber: _gameState!.roundNumber,
                difficulty: widget.difficulty,
                isAIPlaying: _isAIPlaying,
                onBack: _showExitConfirmation,
              ),
              AIOpponentsBar(
                aiPlayers: aiPlayers,
                currentTurnParticipantId: _gameState!.currentTurnParticipantId,
                playerHands: _gameState!.playerHands,
                pulseAnimation: _pulseAnimation,
              ),
              Expanded(
                child: DominoBoardWidget(
                  gameState: _gameState!,
                  isMyTurn: _isMyTurn && !_isAIPlaying,
                  onTilePlaced: _placeTile,
                  selectedTile: _selectedTile,
                ),
              ),
              SoloPlayerHand(
                tiles: _myHand,
                playableTiles: _playableTiles,
                selectedTile: _selectedTile,
                isMyTurn: _isMyTurn && !_isAIPlaying,
                roundsWon: _humanParticipant?.roundsWon ?? 0,
                onTileSelected: (tile) => setState(() => _selectedTile = tile),
                onPassTurn: _passTurn,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1a1a2e), const Color(0xFF16213e)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.2),
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
                // Icône
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.exit_to_app,
                    color: Colors.orange,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                // Titre
                const Text(
                  'Quitter la partie ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Message
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.save,
                      color: Colors.lightGreenAccent.withValues(alpha: 0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Votre progression sera sauvegardée',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/domino');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Quitter',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
