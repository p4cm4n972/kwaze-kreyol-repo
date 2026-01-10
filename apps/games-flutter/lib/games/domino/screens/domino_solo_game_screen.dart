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
import '../widgets/domino_tile_painter.dart';
import '../widgets/domino_board_widget.dart';

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

  void _initializeGame() {
    // Réinitialiser complètement l'état avant de créer une nouvelle session
    _session = null;
    _gameState = null;

    // Créer la session solo (nouveaux participants avec roundsWon = 0)
    final session = DominoSoloService.createSoloSession(
      humanPlayerId: _currentUserId ?? 'guest',
      humanPlayerName: _playerName,
      difficulty: widget.difficulty,
    );

    // Log de debug pour vérifier la réinitialisation
    print('[SOLO] Nouvelle session créée: ${session.id}');
    for (final p in session.participants) {
      print('[SOLO] Participant ${p.displayName}: roundsWon=${p.roundsWon}');
    }

    // Démarrer la première manche
    final gameState = DominoSoloService.startNewRound(session);

    setState(() {
      _session = session.copyWith(currentGameState: gameState);
      _gameState = gameState;
    });

    // Vérifier si c'est le tour d'une IA
    _checkAndExecuteAITurn();
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

      setState(() {
        _gameState = result.newState;
        _session = _session!.copyWith(currentGameState: result.newState);
        _isAIPlaying = false;
      });

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

      setState(() {
        _gameState = result.newState;
        _session = _session!.copyWith(currentGameState: result.newState);
        _isAIPlaying = false;
      });

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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isCapot ? Icons.emoji_events : Icons.block,
              color: isCapot ? Colors.amber : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Manche ${_gameState?.roundNumber ?? 1} terminée !',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCapot ? Colors.green.shade800 : Colors.orange.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isCapot ? 'CAPOT !' : 'Partie bloquée',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Gagnant: ${winner.displayName}',
              style: TextStyle(
                color: winner.isAI ? Colors.orange : Colors.lightGreenAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Score des manches:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ..._session!.participants.map((p) {
              final isWinner = p.id == winnerId;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    if (isWinner)
                      const Icon(Icons.star, color: Colors.amber, size: 20)
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    if (p.isAI)
                      const Icon(Icons.smart_toy, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        p.displayName,
                        style: TextStyle(
                          color: isWinner ? Colors.lightGreenAccent : Colors.white,
                          fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      '${p.roundsWon} manches',
                      style: TextStyle(
                        color: isWinner ? Colors.lightGreenAccent : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkGameOverOrContinue();
            },
            child: Text(
              DominoSoloService.isGameOver(_session!) ? 'Voir résultats' : 'Manche suivante',
              style: const TextStyle(
                color: Colors.lightGreenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkGameOverOrContinue() {
    if (_session == null) return;

    if (DominoSoloService.isGameOver(_session!)) {
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isChiree
                  ? Icons.handshake
                  : (humanWon ? Icons.emoji_events : Icons.sentiment_dissatisfied),
              color: isChiree
                  ? Colors.blue
                  : (humanWon ? Colors.amber : Colors.red),
              size: 48,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isChiree
                  ? 'CHIRÉE !'
                  : (humanWon ? 'VICTOIRE !' : 'DÉFAITE'),
              style: TextStyle(
                color: isChiree
                    ? Colors.blue
                    : (humanWon ? Colors.amber : Colors.red),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isChiree)
              const Text(
                'Match nul ! Tous les joueurs ont gagné au moins une manche.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              )
            else if (!humanWon)
              Text(
                '${winner!.displayName} a gagné la partie.',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            ..._session!.participants.map((p) {
              final isCochon = p.roundsWon == 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (p.isAI)
                      const Icon(Icons.smart_toy, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${p.displayName}: ${p.roundsWon} manches',
                      style: TextStyle(
                        color: isCochon ? Colors.red : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (isCochon) ...[
                      const SizedBox(width: 8),
                      const Text('🐷', style: TextStyle(fontSize: 20)),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/domino');
            },
            child: const Text(
              'Retour au menu',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Rejouer'),
          ),
        ],
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

      setState(() {
        _gameState = result.newState;
        _session = _session!.copyWith(currentGameState: result.newState);
        _selectedTile = null;
        _isLoading = false;
      });

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

      setState(() {
        _gameState = result.newState;
        _session = _session!.copyWith(currentGameState: result.newState);
        _isLoading = false;
      });

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
              _buildHeader(),
              _buildOpponentsBar(),
              Expanded(child: _buildBoard()),
              _buildPlayerHand(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final difficultyText = {
      AIDifficulty.easy: 'Facile',
      AIDifficulty.normal: 'Normal',
      AIDifficulty.hard: 'Difficile',
    }[widget.difficulty]!;

    final difficultyColor = {
      AIDifficulty.easy: Colors.green,
      AIDifficulty.normal: Colors.orange,
      AIDifficulty.hard: Colors.red,
    }[widget.difficulty]!;

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
            onPressed: () => _showExitConfirmation(),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Text(
              'Manche ${_gameState!.roundNumber}',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: difficultyColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.smart_toy, color: difficultyColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  difficultyText,
                  style: TextStyle(
                    color: difficultyColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_isAIPlaying)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.purple.shade200,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'IA réfléchit...',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOpponentsBar() {
    final aiPlayers = _session!.participants.where((p) => p.isAI).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: aiPlayers.map((ai) {
          final isCurrentTurn = _gameState!.currentTurnParticipantId == ai.id;
          final tileCount = _gameState!.playerHands[ai.id]?.length ?? 0;

          return AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isCurrentTurn ? _pulseAnimation.value : 1.0,
                child: Container(
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
                            ai.displayName,
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
                              Icon(Icons.star, color: Colors.amber, size: 14),
                              Text(
                                ' ${ai.roundsWon}',
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
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBoard() {
    return DominoBoardWidget(
      gameState: _gameState!,
      isMyTurn: _isMyTurn && !_isAIPlaying,
      onTilePlaced: _placeTile,
      selectedTile: _selectedTile, // Pour tap-to-place
    );
  }

  Widget _buildPlayerHand() {
    final isCurrentTurn = _isMyTurn && !_isAIPlaying;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo.shade900.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Main du joueur (dominos)
          Expanded(
            child: SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _myHand.length,
                itemBuilder: (context, index) {
                  final tile = _myHand[index];
                  final isPlayable = _playableTiles.contains(tile);
                  final isSelected = _selectedTile == tile;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Draggable<DominoTile>(
                      data: tile,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Transform.scale(
                          scale: 1.2,
                          child: DominoTileWidget(
                            value1: tile.value1,
                            value2: tile.value2,
                            width: 35,
                            height: 70,
                            isVertical: true,
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: DominoTileWidget(
                          value1: tile.value1,
                          value2: tile.value2,
                          width: 35,
                          height: 70,
                          isVertical: true,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTile = isSelected ? null : tile;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          transform: Matrix4.translationValues(
                            0,
                            isSelected ? -10 : 0,
                            0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isPlayable && isCurrentTurn
                                  ? [
                                      BoxShadow(
                                        color: Colors.green.withValues(alpha: 0.6),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Opacity(
                              opacity: (!isCurrentTurn || !isPlayable) ? 0.5 : 1.0,
                              child: DominoTileWidget(
                                value1: tile.value1,
                                value2: tile.value2,
                                width: 35,
                                height: 70,
                                isVertical: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Infos joueur à droite
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Indicateur de tour
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrentTurn
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrentTurn ? Colors.green : Colors.grey,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCurrentTurn ? Icons.play_arrow : Icons.hourglass_empty,
                      color: isCurrentTurn ? Colors.green : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCurrentTurn ? 'À vous' : 'Attente',
                      style: TextStyle(
                        color: isCurrentTurn ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Nombre de manches
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_humanParticipant?.roundsWon ?? 0}/3',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // Bouton passer si nécessaire
              if (isCurrentTurn && _playableTiles.isEmpty) ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _passTurn,
                  icon: const Icon(Icons.skip_next, size: 16),
                  label: const Text('Passer', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
              // Message d'erreur
              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 10),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Quitter la partie ?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'La progression sera perdue.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/domino');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
}
