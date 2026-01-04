import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';
import '../../../services/realtime_service.dart';
import '../services/domino_service.dart';
import '../models/domino_session.dart';
import '../models/domino_tile.dart';
import '../models/domino_participant.dart';
import '../models/domino_game_state.dart';
import '../utils/domino_logic.dart';
import '../utils/domino_scoring.dart';

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

class _DominoGameScreenState extends State<DominoGameScreen> {
  final DominoService _dominoService = DominoService();
  final RealtimeService _realtimeService = RealtimeService();
  final AuthService _authService = AuthService();

  DominoSession? _session;
  DominoTile? _selectedTile;
  String? _errorMessage;
  bool _isLoading = false;

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
    _subscribeToSession();
  }

  @override
  void dispose() {
    _realtimeService.unsubscribeFromDominoSession(widget.sessionId);
    super.dispose();
  }

  void _subscribeToSession() {
    _realtimeService.subscribeToDominoSession(widget.sessionId).listen(
      (session) {
        setState(() {
          _session = session;
        });

        // Navigation automatique vers les résultats si la partie est terminée
        if (session.status == 'completed' && mounted) {
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

  Future<void> _placeTile(String side) async {
    if (_selectedTile == null || _currentParticipant == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _dominoService.placeTile(
        sessionId: widget.sessionId,
        participantId: _currentParticipant!.id,
        tile: _selectedTile!,
        side: side,
      );

      setState(() {
        _selectedTile = null;
      });
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C3E50),
              const Color(0xFF34495E),
              const Color(0xFF2C3E50),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_errorMessage != null) _buildErrorBanner(),
              Expanded(
                child: Column(
                  children: [
                    _buildOpponents(),
                    Expanded(child: _buildBoard()),
                    _buildMyHand(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final gameState = _session!.currentGameState;
    final roundNumber = gameState?.roundNumber ?? 1;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/domino'),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Manche $roundNumber',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _session!.participants.map((p) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${p.displayName}: ${p.roundsWon}',
                        style: TextStyle(
                          fontSize: 14,
                          color: p.id == _currentParticipant?.id
                              ? Colors.amber
                              : Colors.white70,
                          fontWeight: p.id == _currentParticipant?.id
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponents() {
    final otherPlayers = _session!.participants
        .where((p) => p.id != _currentParticipant?.id)
        .toList();

    final gameState = _session!.currentGameState;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: otherPlayers.map((player) {
          final tileCount =
              gameState?.playerHands[player.id]?.length ?? 0;
          final isTheirTurn =
              gameState?.currentTurnParticipantId == player.id;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isTheirTurn
                    ? [
                        Colors.amber.withOpacity(0.3),
                        Colors.amber.withOpacity(0.1),
                      ]
                    : [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.1),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTheirTurn
                    ? Colors.amber
                    : Colors.white.withOpacity(0.2),
                width: isTheirTurn ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: player.isHost
                      ? Colors.amber
                      : Colors.grey.withOpacity(0.5),
                  child: Text(
                    player.displayName[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  player.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.casino, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$tileCount',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (isTheirTurn) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Son tour',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBoard() {
    final gameState = _session?.currentGameState;
    if (gameState == null) {
      return const Center(
        child: Text(
          'Chargement...',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (gameState.board.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: const Text(
            'Le plateau est vide.\nPlacez la première tuile!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Bouton gauche (si tuile sélectionnée et c'est mon tour)
          if (_selectedTile != null && _isMyTurn) ...[
            _buildPlacementButton('left', gameState.leftEnd),
            const SizedBox(width: 8),
          ],

          // Chaîne de dominos
          ...gameState.board.map((placedTile) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _buildTileWidget(placedTile.tile, false),
            );
          }),

          // Bouton droit (si tuile sélectionnée et c'est mon tour)
          if (_selectedTile != null && _isMyTurn) ...[
            const SizedBox(width: 8),
            _buildPlacementButton('right', gameState.rightEnd),
          ],
        ],
      ),
    );
  }

  Widget _buildPlacementButton(String side, int? endValue) {
    final canPlace = _selectedTile != null &&
        endValue != null &&
        _selectedTile!.canConnect(endValue);

    return GestureDetector(
      onTap: canPlace ? () => _placeTile(side) : null,
      child: Container(
        width: 60,
        height: 120,
        decoration: BoxDecoration(
          color: canPlace
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: canPlace ? Colors.green : Colors.grey,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              side == 'left' ? Icons.arrow_back : Icons.arrow_forward,
              color: canPlace ? Colors.green : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            if (endValue != null)
              Text(
                '$endValue',
                style: TextStyle(
                  color: canPlace ? Colors.white : Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyHand() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.5),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: _isMyTurn ? Colors.amber : Colors.white.withOpacity(0.2),
            width: _isMyTurn ? 3 : 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicateur de tour
          if (_isMyTurn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'C\'est votre tour!',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(
              'En attente...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),

          const SizedBox(height: 12),

          // Main du joueur
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _myHand.map((tile) {
                final isSelected = _selectedTile?.id == tile.id;
                final isPlayable = _playableTiles.any((t) => t.id == tile.id);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: _isMyTurn && isPlayable
                        ? () {
                            setState(() {
                              _selectedTile =
                                  isSelected ? null : tile;
                            });
                          }
                        : null,
                    child: _buildTileWidget(
                      tile,
                      isSelected,
                      isPlayable: isPlayable,
                    ),
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
              icon: const Icon(Icons.skip_next),
              label: const Text('Passer le tour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
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
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 50,
      height: 100,
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.amber
            : (isPlayable ? Colors.white : Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? Colors.amber.shade700
              : (isPlayable ? Colors.black : Colors.grey.shade600),
          width: isSelected ? 3 : 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDots(tile.value1, isPlayable),
          Container(
            height: 2,
            color: isPlayable ? Colors.black : Colors.grey.shade600,
          ),
          _buildDots(tile.value2, isPlayable),
        ],
      ),
    );
  }

  Widget _buildDots(int value, bool isPlayable) {
    final color = isPlayable ? Colors.black : Colors.grey.shade600;

    // Patterns de points pour chaque valeur (0-6)
    final patterns = {
      0: [],
      1: [4],
      2: [0, 8],
      3: [0, 4, 8],
      4: [0, 2, 6, 8],
      5: [0, 2, 4, 6, 8],
      6: [0, 2, 3, 5, 6, 8],
    };

    final dots = patterns[value] ?? [];

    return SizedBox(
      height: 40,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(9, (index) {
          return dots.contains(index)
              ? Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : const SizedBox();
        }),
      ),
    );
  }
}
