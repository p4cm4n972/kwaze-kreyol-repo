import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import 'models/skrabb_game.dart';
import 'models/board.dart';
import 'models/tile.dart';
import 'models/move.dart';
import 'services/skrabb_service.dart';
import 'services/word_validator.dart';
import 'utils/scrabble_scoring.dart';
import 'utils/move_validator.dart';
import 'utils/tile_bag_manager.dart';

class SkrabbScreen extends StatefulWidget {
  const SkrabbScreen({super.key});

  @override
  State<SkrabbScreen> createState() => _SkrabbScreenState();
}

class _SkrabbScreenState extends State<SkrabbScreen> {
  final AuthService _authService = AuthService();
  final SkrabbService _skrabbService = SkrabbService();
  final WordValidator _wordValidator = WordValidator();
  final TileBagManager _tileBagManager = TileBagManager();

  // État du jeu
  SkrabbGame? _currentGame;
  Board? _board;
  List<Tile> _rack = [];
  List<Tile> _tileBag = [];
  List<Move> _moveHistory = [];
  int _score = 0;
  int _timeElapsed = 0;

  // État de l'UI
  List<PlacedTile> _pendingPlacements = []; // Tuiles placées mais non validées
  Tile? _selectedRackTile;
  int? _selectedRackIndex;
  bool _isLoading = true;
  bool _isValidating = false;
  bool _isSaving = false;
  bool _isGameComplete = false;
  String? _errorMessage;

  // Timers
  Timer? _timer;
  Timer? _autoSaveTimer;

  // Couleurs madras
  final List<Color> _madrasColors = [
    const Color(0xFFE74C3C), // Rouge
    const Color(0xFFF39C12), // Jaune
    const Color(0xFF27AE60), // Vert
    const Color(0xFF3498DB), // Bleu
    const Color(0xFF9B59B6), // Violet
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    // Sauvegarde finale avant destruction
    if (_currentGame != null && !_isGameComplete && !_isSaving) {
      _saveProgressSync();
    }
    super.dispose();
  }

  /// Sauvegarde synchrone sans mise à jour UI (pour dispose)
  void _saveProgressSync() {
    if (_currentGame == null || _board == null) return;

    _skrabbService
        .saveGameProgress(
          gameId: _currentGame!.id,
          boardData: _board!.toJson(),
          rack: _rack.map((t) => t.toJson()).toList(),
          tileBag: _tileBag.map((t) => t.toJson()).toList(),
          moveHistory: _moveHistory.map((m) => m.toJson()).toList(),
          score: _score,
          timeElapsed: _timeElapsed,
        )
        .catchError((e) {
      debugPrint('Erreur de sauvegarde finale: $e');
    });
  }

  /// Vérifie l'authentification et charge la partie
  Future<void> _checkAuthAndLoadGame() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final userId = _authService.getUserIdOrNull();
    if (userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login');
        }
      });
      return;
    }

    try {
      // Vérifier s'il existe une partie en cours
      final existingGame = await _skrabbService.loadInProgressGame();

      if (existingGame != null) {
        // Reprendre la partie existante
        await _loadExistingGame(existingGame);
      } else {
        // Créer une nouvelle partie
        await _startNewGame();
      }

      // Démarrer les timers
      _startTimers();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  /// Charge une partie existante
  Future<void> _loadExistingGame(SkrabbGame game) async {
    setState(() {
      _currentGame = game;
      _board = game.board;
      _rack = List.from(game.rack);
      _tileBag = List.from(game.tileBag);
      _moveHistory = List.from(game.moveHistory);
      _score = game.score;
      _timeElapsed = game.timeElapsed;
      _isLoading = false;
    });
  }

  /// Démarre une nouvelle partie
  Future<void> _startNewGame() async {
    final userId = _authService.getUserIdOrNull();
    if (userId == null) return;

    // Créer un nouveau jeu (ID temporaire, sera remplacé par Supabase)
    final newGame = SkrabbGame.create(id: '', userId: userId);

    // Sauvegarder dans Supabase (l'ID sera généré par Supabase)
    final savedGame = await _skrabbService.createGame(newGame);

    setState(() {
      _currentGame = savedGame;
      _board = savedGame.board;
      _rack = List.from(savedGame.rack);
      _tileBag = List.from(savedGame.tileBag);
      _moveHistory = [];
      _score = 0;
      _timeElapsed = 0;
      _isLoading = false;
    });
  }

  /// Démarre les timers (temps et auto-save)
  void _startTimers() {
    // Timer du jeu (1 seconde)
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isGameComplete) {
        setState(() {
          _timeElapsed++;
        });
      }
    });

    // Auto-save (30 secondes)
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isGameComplete && !_isSaving) {
        _saveProgress();
      }
    });
  }

  /// Sauvegarde la progression (avec setState)
  Future<void> _saveProgress() async {
    if (_currentGame == null || _board == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _skrabbService.saveGameProgress(
        gameId: _currentGame!.id,
        boardData: _board!.toJson(),
        rack: _rack.map((t) => t.toJson()).toList(),
        tileBag: _tileBag.map((t) => t.toJson()).toList(),
        moveHistory: _moveHistory.map((m) => m.toJson()).toList(),
        score: _score,
        timeElapsed: _timeElapsed,
      );
    } catch (e) {
      debugPrint('Erreur de sauvegarde: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Gère la sélection d'une tuile du chevalet
  void _onRackTileSelected(int index) {
    setState(() {
      if (_selectedRackIndex == index) {
        // Déselectionner
        _selectedRackIndex = null;
        _selectedRackTile = null;
      } else {
        // Sélectionner
        _selectedRackIndex = index;
        _selectedRackTile = _rack[index];
      }
    });
  }

  /// Gère le placement d'une tuile sur le plateau
  void _onBoardSquareTapped(int row, int col) {
    if (_selectedRackTile == null || _board == null) return;

    final square = _board!.getSquare(row, col);

    // Vérifier que la case est vide
    if (square.placedTile != null) {
      _showError('Case déjà occupée');
      return;
    }

    // Placer la tuile
    setState(() {
      _board!.placeTile(row, col, _selectedRackTile!);
      _pendingPlacements.add(
        PlacedTile(row: row, col: col, tile: _selectedRackTile!),
      );

      // Retirer du chevalet
      _rack.removeAt(_selectedRackIndex!);

      // Désélectionner
      _selectedRackTile = null;
      _selectedRackIndex = null;
      _errorMessage = null;
    });
  }

  /// Annule les placements en attente
  void _onUndoPlacements() {
    if (_pendingPlacements.isEmpty || _board == null) return;

    setState(() {
      // Retirer les tuiles du plateau
      for (final placement in _pendingPlacements) {
        _board!.removeTile(placement.row, placement.col);
        _rack.add(placement.tile);
      }

      _pendingPlacements.clear();
      _errorMessage = null;
    });
  }

  /// Valide le coup
  Future<void> _onValidateMove() async {
    if (_pendingPlacements.isEmpty || _board == null) {
      _showError('Aucune tuile placée');
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      // Valider le coup
      final isFirstMove = _moveHistory.isEmpty;
      final validator = MoveValidator(_wordValidator);
      final validationResult = await validator.validateMove(
        _board!,
        _pendingPlacements,
        isFirstMove,
      );

      if (!validationResult.isValid) {
        setState(() {
          _errorMessage = validationResult.errorMessage;
          _isValidating = false;
        });
        return;
      }

      // Calculer le score
      final moveScore = ScrabbleScoring.calculateMoveScore(
        _board!,
        _pendingPlacements,
      );

      // Créer le mouvement
      final move = Move(
        placedTiles: List.from(_pendingPlacements),
        formedWords: validationResult.formedWords,
        score: moveScore,
        isBingo: _pendingPlacements.length == 7,
        timestamp: DateTime.now(),
      );

      // Appliquer le coup
      setState(() {
        // Verrouiller les tuiles sur le plateau
        _board!.lockAllTiles();

        // Ajouter le mouvement à l'historique
        _moveHistory.add(move);

        // Mettre à jour le score
        _score += moveScore;

        // Piocher de nouvelles tuiles
        final newTiles = _tileBagManager.refillRack(_tileBag, _rack);
        _rack.addAll(newTiles);

        // Réinitialiser les placements en attente
        _pendingPlacements.clear();

        // Vérifier fin de partie
        if (_tileBag.isEmpty && _rack.isEmpty) {
          _isGameComplete = true;
          _completeGame();
        }

        _isValidating = false;
      });

      // Sauvegarder
      await _saveProgress();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de validation: $e';
        _isValidating = false;
      });
    }
  }

  /// Termine la partie
  Future<void> _completeGame() async {
    if (_currentGame == null || _board == null) return;

    try {
      await _skrabbService.completeGame(
        gameId: _currentGame!.id,
        boardData: _board!.toJson(),
        rack: _rack.map((t) => t.toJson()).toList(),
        tileBag: _tileBag.map((t) => t.toJson()).toList(),
        moveHistory: _moveHistory.map((m) => m.toJson()).toList(),
        score: _score,
        timeElapsed: _timeElapsed,
      );

      // Arrêter les timers
      _timer?.cancel();
      _autoSaveTimer?.cancel();
    } catch (e) {
      debugPrint('Erreur lors de la finalisation: $e');
    }
  }

  /// Affiche un message d'erreur
  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  /// Formate le temps écoulé (MM:SS)
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _madrasColors[0].withOpacity(0.1),
              _madrasColors[2].withOpacity(0.1),
              _madrasColors[4].withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildGameContent(),
        ),
      ),
    );
  }

  Widget _buildGameContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800;

        return Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: isWideScreen
                  ? _buildWideLayout()
                  : _buildNarrowLayout(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/games'),
          ),
          const Text(
            'Skrabb',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            'Score: $_score',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _formatTime(_timeElapsed),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Center(
            child: _buildBoard(),
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildInfoPanel(),
              const SizedBox(height: 16),
              _buildRack(),
              const SizedBox(height: 16),
              _buildControls(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildBoard(),
                const SizedBox(height: 16),
                _buildInfoPanel(),
              ],
            ),
          ),
        ),
        _buildRack(),
        _buildControls(),
      ],
    );
  }

  Widget _buildBoard() {
    if (_board == null) {
      return const Center(child: Text('Chargement du plateau...'));
    }

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Board.size,
            ),
            itemCount: Board.size * Board.size,
            itemBuilder: (context, index) {
              final row = index ~/ Board.size;
              final col = index % Board.size;
              return _buildBoardSquare(row, col);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBoardSquare(int row, int col) {
    final square = _board!.getSquare(row, col);

    return GestureDetector(
      onTap: () => _onBoardSquareTapped(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: _getSquareColor(square),
          border: Border.all(
            color: Colors.black.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: square.placedTile != null
            ? _buildTileWidget(square.placedTile!, isOnBoard: true)
            : Center(
                child: Text(
                  square.bonusType.shortName,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
      ),
    );
  }

  Color _getSquareColor(BoardSquare square) {
    switch (square.bonusType) {
      case BonusType.tripleWord:
        return Colors.red.shade700;
      case BonusType.doubleWord:
        return Colors.pink.shade300;
      case BonusType.tripleLetter:
        return Colors.blue.shade700;
      case BonusType.doubleLetter:
        return Colors.blue.shade300;
      case BonusType.center:
        return Colors.pink.shade400;
      case BonusType.none:
        return Colors.green.shade50;
    }
  }

  Widget _buildTileWidget(Tile tile, {required bool isOnBoard}) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          tile.displayLetter,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tuiles restantes: ${_tileBag.length}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (_isGameComplete)
            const Text(
              'Partie terminée!',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRack() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(7, (index) {
          if (index < _rack.length) {
            return _buildRackTile(index);
          } else {
            return _buildEmptyRackSlot();
          }
        }),
      ),
    );
  }

  Widget _buildRackTile(int index) {
    final isSelected = _selectedRackIndex == index;

    return GestureDetector(
      onTap: () => _onRackTileSelected(index),
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? _madrasColors[1]
              : const Color(0xFFF5E6D3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _rack[index].displayLetter,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRackSlot() {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _pendingPlacements.isEmpty ? null : _onUndoPlacements,
            icon: const Icon(Icons.undo),
            label: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed:
                _pendingPlacements.isEmpty || _isValidating
                    ? null
                    : _onValidateMove,
            icon: _isValidating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Valider'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
