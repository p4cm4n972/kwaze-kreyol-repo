import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';
import '../../../services/realtime_service.dart';
import '../services/domino_service.dart';
import '../models/domino_session.dart';
import '../models/domino_tile.dart';
import '../models/domino_participant.dart';
import '../models/domino_round.dart';
import '../utils/domino_logic.dart';
import '../utils/responsive_utils.dart';
import '../widgets/domino_board_widget.dart';
import '../widgets/shared/game_header.dart';
import '../widgets/shared/opponent_card.dart';
import '../widgets/shared/player_hand.dart';
import '../widgets/dialogs/round_end_dialog.dart';

/// Écran principal du jeu de dominos
/// Gère le jeu en temps réel avec affichage du plateau et des mains
class DominoGameScreen extends StatefulWidget {
  final String sessionId;

  const DominoGameScreen({
    super.key,
    required this.sessionId,
  });

  @override
  State<DominoGameScreen> createState() => _DominoGameScreenState();
}

class _DominoGameScreenState extends State<DominoGameScreen>
    with TickerProviderStateMixin {
  final DominoService _dominoService = DominoService();
  final RealtimeService _realtimeService = RealtimeService();
  final AuthService _authService = AuthService();

  DominoSession? _session;
  DominoTile? _selectedTile;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isAnimatingPlacement = false;
  int? _lastSeenRoundNumber; // Pour détecter les changements de manche

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  String? get _currentUserId => _authService.getUserIdOrNull();

  DominoParticipant? get _currentParticipant {
    if (_session == null || _currentUserId == null) return null;
    try {
      return _session!.participants.firstWhere(
        (p) => p.userId == _currentUserId,
      );
    } catch (e) {
      return null;
    }
  }

  bool get _isMyTurn {
    if (_session?.currentGameState == null || _currentParticipant == null) {
      return false;
    }
    return _session!.currentGameState!.currentTurnParticipantId ==
        _currentParticipant!.id;
  }

  List<DominoTile> get _myHand {
    if (_session?.currentGameState == null || _currentParticipant == null) {
      return [];
    }
    return _session!.currentGameState!.playerHands[_currentParticipant!.id] ??
        [];
  }

  List<DominoTile> get _playableTiles {
    final gameState = _session?.currentGameState;
    if (gameState == null) return [];

    return DominoLogic.getPlayableTiles(
      _myHand,
      gameState.leftEnd,
      gameState.rightEnd,
    );
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
    _subscribeToSession();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _realtimeService.unsubscribeFromDominoSession(widget.sessionId);
    super.dispose();
  }

  void _subscribeToSession() {
    _realtimeService.subscribeToDominoSession(widget.sessionId).listen(
      (session) {
        final currentRound = session.currentGameState?.roundNumber;

        // Détecter si une nouvelle manche a commencé
        if (_lastSeenRoundNumber != null &&
            currentRound != null &&
            currentRound > _lastSeenRoundNumber! &&
            session.rounds.isNotEmpty) {
          // Une nouvelle manche a commencé - afficher le récap de la précédente
          final lastRound = session.rounds.last;
          _showRoundEndDialog(session, lastRound);
        }

        // Mettre à jour le numéro de manche vu
        _lastSeenRoundNumber = currentRound;

        setState(() {
          _session = session;
        });

        // Navigation automatique vers les résultats si la partie est terminée
        if ((session.status == 'completed' || session.status == 'chiree') && mounted) {
          context.go('/domino/results/${widget.sessionId}');
        }
      },
      onError: (error) {
        setState(() {
          _errorMessage = error.toString();
        });
      },
    );
  }

  /// Affiche le dialog de fin de manche
  void _showRoundEndDialog(DominoSession session, DominoRound round) {
    if (!mounted) return;
    RoundEndDialog.show(context, session, round);
  }

  Future<void> _placeTile(String side, DominoTile tile) async {
    if (_currentParticipant == null || _isAnimatingPlacement) return;

    setState(() {
      _isAnimatingPlacement = true;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Enregistrer le coup
      await _dominoService.placeTile(
        sessionId: widget.sessionId,
        participantId: _currentParticipant!.id,
        tile: tile,
        side: side,
      );

      if (mounted) {
        setState(() {
          _selectedTile = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAnimatingPlacement = false;
        });
      }
    }
  }

  Future<void> _passTurn() async {
    if (_currentParticipant == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _dominoService.passTurn(
        sessionId: widget.sessionId,
        participantId: _currentParticipant!.id,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A237E),
                const Color(0xFF283593),
                const Color(0xFF3949AB),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A237E),
              const Color(0xFF283593),
              const Color(0xFF3949AB),
              const Color(0xFF5C6BC0),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                DominoGameHeader(
                  session: _session!,
                  currentParticipant: _currentParticipant,
                ),
                if (_errorMessage != null) _buildErrorBanner(),
                Expanded(
                  child: Stack(
                    children: [
                      // Plateau de jeu (prend tout l'espace)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: _buildBoard(),
                        ),
                      ),
                      // Adversaires en overlay en haut
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: OpponentsRow(
                          opponents: _session!.participants
                              .where((p) => p.id != _currentParticipant?.id)
                              .toList(),
                          currentTurnParticipantId: _session!.currentGameState?.currentTurnParticipantId,
                          playerHands: _session!.currentGameState?.playerHands,
                          pulseAnimation: _pulseAnimation,
                        ),
                      ),
                    ],
                  ),
                ),
                PlayerHand(
                  tiles: _myHand,
                  playableTiles: _playableTiles,
                  selectedTile: _selectedTile,
                  isMyTurn: _isMyTurn,
                  isLoading: _isLoading,
                  gameState: _session?.currentGameState,
                  pulseAnimation: _pulseAnimation,
                  onTileSelected: (tile) => setState(() => _selectedTile = tile),
                  onTilePlaced: _placeTile,
                  onPassTurn: _passTurn,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.responsivePadding(16),
        vertical: context.responsivePadding(8),
      ),
      padding: EdgeInsets.all(context.responsivePadding(16)),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade900.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    final gameState = _session?.currentGameState;

    // Aucun état de jeu = afficher le chargement
    if (gameState == null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        height: 400,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Utiliser le nouveau widget de plateau modulaire
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: DominoBoardWidget(
        gameState: gameState,
        isMyTurn: _isMyTurn,
        onTilePlaced: (side, tile) => _placeTile(side, tile),
      ),
    );
  }
}
