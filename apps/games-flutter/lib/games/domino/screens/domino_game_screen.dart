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
import '../widgets/domino_tile_painter.dart';
import '../widgets/domino_board_widget.dart';

/// Extension pour les valeurs responsive
extension ResponsiveExtension on BuildContext {
  /// Largeur de l'écran
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Hauteur de l'écran
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Vérifie si c'est un très petit écran (< 400)
  bool get isVerySmallScreen => screenWidth < 400;

  /// Vérifie si c'est un mobile (< 600)
  bool get isMobile => screenWidth < 600;

  /// Vérifie si c'est une tablette (600-1200)
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;

  /// Vérifie si c'est un desktop (>= 1200)
  bool get isDesktop => screenWidth >= 1200;

  /// Retourne une valeur adaptée à la taille de l'écran
  /// [verySmall] pour < 400, [mobile] pour < 600, [tablet] pour 600-1200, [desktop] pour >= 1200
  T responsive<T>({
    required T mobile,
    T? verySmall,
    T? tablet,
    T? desktop,
  }) {
    if (isVerySmallScreen) return verySmall ?? mobile;
    if (isMobile) return mobile;
    if (isTablet) return tablet ?? mobile;
    return desktop ?? tablet ?? mobile;
  }

  /// Taille de texte responsive
  double responsiveFontSize(double base) {
    if (isVerySmallScreen) return base * 0.8;
    if (isMobile) return base;
    if (isTablet) return base * 1.1;
    return base * 1.2;
  }

  /// Padding responsive
  double responsivePadding(double base) {
    if (isVerySmallScreen) return base * 0.6;
    if (isMobile) return base;
    if (isTablet) return base * 1.2;
    return base * 1.5;
  }
}

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

    // Trouver le gagnant
    final winner = round.winnerParticipantId != null
        ? session.participants.firstWhere(
            (p) => p.id == round.winnerParticipantId,
            orElse: () => session.participants.first,
          )
        : null;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
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
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type de fin
            Container(
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
            ),
            const SizedBox(height: 16),

            // Gagnant
            if (winner != null) ...[
              Text(
                'Gagnant: ${winner.displayName}',
                style: const TextStyle(
                  color: Colors.lightGreenAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Scores de chaque joueur
            const Text(
              'Points restants:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...session.participants.map((p) {
              final score = round.finalScores[p.id] ?? 0;
              final isWinner = p.id == round.winnerParticipantId;
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
                        p.displayName,
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
            }),
          ],
        ),
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
      ),
    );
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
                _buildHeader(),
                if (_errorMessage != null) _buildErrorBanner(),
                Expanded(
                  child: Stack(
                    children: [
                      // Plateau de jeu (prend tout l'espace)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60), // Espace pour les adversaires
                          child: _buildBoard(),
                        ),
                      ),
                      // Adversaires en overlay en haut
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _buildOpponents(),
                      ),
                    ],
                  ),
                ),
                _buildMyHand(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final gameState = _session!.currentGameState;
    final roundNumber = gameState?.roundNumber ?? 1;

    return Container(
      margin: EdgeInsets.all(context.responsivePadding(12)),
      padding: EdgeInsets.symmetric(
        horizontal: context.responsivePadding(20),
        vertical: context.responsivePadding(16),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: context.responsive(mobile: 20.0, tablet: 24.0, desktop: 28.0),
              ),
              onPressed: () => context.go('/domino'),
            ),
          ),
          SizedBox(width: context.responsivePadding(16)),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsivePadding(16),
                    vertical: context.responsivePadding(8),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD700),
                        const Color(0xFFFF8C00),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8C00).withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '🎲 Manche $roundNumber',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(18),
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: context.responsivePadding(8)),
                // Badges joueurs compacts
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _session!.participants.map((p) {
                    final isCurrentPlayer = p.id == _currentParticipant?.id;
                    // Nom court: max 6 caractères sur mobile, 10 sinon
                    final maxLen = context.isMobile ? 6 : 10;
                    final shortName = p.displayName.length > maxLen
                        ? p.displayName.substring(0, maxLen)
                        : p.displayName;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCurrentPlayer
                            ? Colors.amber.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCurrentPlayer
                              ? Colors.amber
                              : Colors.white.withOpacity(0.2),
                          width: isCurrentPlayer ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            shortName,
                            style: TextStyle(
                              fontSize: context.isMobile ? 11 : 13,
                              color: isCurrentPlayer ? Colors.amber : Colors.white,
                              fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: p.roundsWon > 0
                                  ? Colors.green.shade600
                                  : Colors.grey.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${p.roundsWon}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
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
            color: Colors.red.shade900.withOpacity(0.4),
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

  /// Construit les cartes adversaires positionnées dans les coins
  Widget _buildOpponents() {
    final otherPlayers = _session!.participants
        .where((p) => p.id != _currentParticipant?.id)
        .toList();

    final gameState = _session!.currentGameState;

    // Positionner les adversaires: un à gauche, un à droite
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Adversaire gauche
        if (otherPlayers.isNotEmpty)
          _buildOpponentCard(otherPlayers[0], gameState, Alignment.topLeft),
        // Adversaire droite
        if (otherPlayers.length > 1)
          _buildOpponentCard(otherPlayers[1], gameState, Alignment.topRight),
      ],
    );
  }

  /// Carte compacte d'un adversaire
  Widget _buildOpponentCard(DominoParticipant player, dynamic gameState, Alignment alignment) {
    final tileCount = gameState?.playerHands[player.id]?.length ?? 0;
    final isTheirTurn = gameState?.currentTurnParticipantId == player.id;
    final isLeft = alignment == Alignment.topLeft;

    return ScaleTransition(
      scale: isTheirTurn ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        margin: EdgeInsets.only(
          left: isLeft ? 8 : 0,
          right: isLeft ? 0 : 8,
          top: 8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isTheirTurn
                ? [const Color(0xFFFFD700), const Color(0xFFFF8C00)]
                : [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.4)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTheirTurn ? Colors.amber : Colors.white24,
            width: isTheirTurn ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isTheirTurn ? Colors.amber.withOpacity(0.4) : Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar avec badge nombre de tuiles
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isTheirTurn ? Colors.black26 : Colors.white24,
                  child: Text(
                    player.displayName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isTheirTurn ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                // Badge nombre de tuiles
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isTheirTurn ? Colors.black : Colors.blue.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '$tileCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Nom et score
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.displayName.length > 8
                      ? '${player.displayName.substring(0, 8)}.'
                      : player.displayName,
                  style: TextStyle(
                    color: isTheirTurn ? Colors.black : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${player.roundsWon} ★',
                  style: TextStyle(
                    color: isTheirTurn ? Colors.black54 : Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
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
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.1),
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

  Widget _buildMyHand() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.6),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: _isMyTurn ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.3),
            width: _isMyTurn ? 4 : 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicateur de tour
          if (_isMyTurn)
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700),
                      const Color(0xFFFF8C00),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8C00).withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.touch_app,
                      color: Colors.black,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'C\'est votre tour!',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'En attente...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Boutons de placement (apparaissent quand une tuile est sélectionnée)
          if (_isMyTurn && _selectedTile != null && _playableTiles.any((t) => t.id == _selectedTile!.id))
            _buildPlacementButtons(),

          const SizedBox(height: 8),

          // Main du joueur
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _myHand.map((tile) {
                final isSelected = _selectedTile?.id == tile.id;
                final isPlayable = _playableTiles.any((t) => t.id == tile.id);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      if (_isMyTurn && isPlayable) {
                        setState(() {
                          _selectedTile = isSelected ? null : tile;
                        });
                      }
                    },
                    child: _isMyTurn && isPlayable
                        ? Draggable<DominoTile>(
                            data: tile,
                            feedback: Transform.scale(
                              scale: 1.2,
                              child: Opacity(
                                opacity: 0.8,
                                child: _buildTileWidget(tile, false, isPlayable: true),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _buildTileWidget(tile, false, isPlayable: true),
                            ),
                            child: _buildTileWidget(tile, isSelected, isPlayable: isPlayable),
                          )
                        : _buildTileWidget(tile, isSelected, isPlayable: isPlayable),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Bouton Passer
          if (_isMyTurn && _playableTiles.isEmpty)
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _passTurn,
              icon: const Icon(Icons.skip_next, size: 24),
              label: const Text(
                'Passer le tour',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                shadowColor: const Color(0xFFFF6B6B).withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }

  /// Boutons de placement pour le tap-to-place
  Widget _buildPlacementButtons() {
    final gameState = _session?.currentGameState;
    if (gameState == null || _selectedTile == null) return const SizedBox.shrink();

    final tile = _selectedTile!;
    final canPlaceLeft = DominoLogic.canPlaceAt(tile, gameState.leftEnd, 'left', gameState.board.isEmpty);
    final canPlaceRight = DominoLogic.canPlaceAt(tile, gameState.rightEnd, 'right', gameState.board.isEmpty);

    // Si le plateau est vide, un seul bouton suffit
    if (gameState.board.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _placeTile('left', tile),
          icon: const Icon(Icons.add_circle_outline, size: 20),
          label: const Text('Placer au centre'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bouton Gauche
          if (canPlaceLeft)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _placeTile('left', tile),
                icon: const Icon(Icons.arrow_back, size: 20),
                label: Text('Gauche (${gameState.leftEnd})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          // Bouton Droite
          if (canPlaceRight)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _placeTile('right', tile),
                icon: const Icon(Icons.arrow_forward, size: 20),
                label: Text('Droite (${gameState.rightEnd})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTileWidget(
    DominoTile tile,
    bool isSelected, {
    bool isPlayable = true,
    bool isOnBoard = false, // Sur le plateau = horizontal, dans la main = vertical
  }) {
    // Calculer la taille selon l'écran (responsive pour tous les appareils)
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Breakpoints: très petit < 400, mobile < 600, tablette < 900, grand < 1200, desktop >= 1200
    double width, height;
    if (isOnBoard) {
      // Sur le plateau: dominos horizontaux
      if (screenWidth < 400) {
        width = 50;
        height = 25;
      } else if (screenWidth < 600) {
        width = 60;
        height = 30;
      } else if (screenWidth < 900) {
        width = 70;
        height = 35;
      } else if (screenWidth < 1200) {
        width = 80;
        height = 40;
      } else {
        width = 96;
        height = 48;
      }
    } else {
      // Dans la main: dominos verticaux (hauteur > largeur)
      // Adapter aussi à la hauteur de l'écran pour les écrans larges mais courts
      final maxTileHeight = screenHeight * 0.15; // Max 15% de la hauteur de l'écran

      if (screenWidth < 400) {
        width = 40;
        height = 80;
      } else if (screenWidth < 600) {
        width = 50;
        height = 100;
      } else if (screenWidth < 900) {
        width = 60;
        height = 120;
      } else if (screenWidth < 1200) {
        width = 70;
        height = 140;
      } else {
        width = 80;
        height = 160;
      }

      // Limiter la hauteur si l'écran est trop petit en hauteur
      if (height > maxTileHeight) {
        final scale = maxTileHeight / height;
        width = width * scale;
        height = maxTileHeight;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: isSelected
            ? Border.all(
                color: const Color(0xFFFFD700),
                width: 4,
              )
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: DominoTileWidget(
        value1: tile.value1,
        value2: tile.value2,
        width: width,
        height: height,
        isVertical: !isOnBoard, // Horizontal sur le plateau
        baseColor: isPlayable
            ? Colors.white
            : Colors.grey.shade400,
        dotColor: isPlayable
            ? Colors.black87
            : Colors.grey.shade700,
        showShadow: !isSelected,
      ),
    );
  }
}
