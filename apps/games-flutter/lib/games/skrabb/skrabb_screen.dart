import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math';
import '../../services/auth_service.dart';
import 'models/skrabb_game.dart';
import 'models/board.dart';
import 'models/tile.dart';
import 'models/move.dart';
import 'models/letter_distribution.dart';
import 'services/skrabb_service.dart';
import 'services/word_validator.dart';
import 'services/sound_service.dart';
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
  final SoundService _soundService = SoundService();

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

  // Animations
  final Map<String, bool> _animatingTiles = {}; // "row,col" -> isAnimating
  final Map<String, bool> _validatedTiles = {}; // "row,col" -> isValidated (pour pulse)
  bool _shakeError = false; // Pour animation shake en cas d'erreur

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
    _setLandscapeOrientation();
    _initializeSound();
    _checkAuthAndLoadGame();
  }

  /// Initialise le service audio
  Future<void> _initializeSound() async {
    await _soundService.initialize();
  }

  /// Force l'orientation paysage (compatible mobile, web, desktop)
  Future<void> _setLandscapeOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (e) {
      // Ignoré si la plateforme ne supporte pas (certains navigateurs)
      debugPrint('Orientation lock not supported: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    // Sauvegarde finale avant destruction
    if (_currentGame != null && !_isGameComplete && !_isSaving) {
      _saveProgressSync();
    }
    // Note: L'orientation est restaurée dans _onBackPressed() avant navigation
    // Ne pas restaurer ici car dispose() est synchrone et trop tardif
    super.dispose();
  }

  /// Restaure toutes les orientations (retour à l'état par défaut)
  Future<void> _restoreAllOrientations() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (e) {
      // Ignoré si la plateforme ne supporte pas
      debugPrint('Orientation unlock not supported: $e');
    }
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

  /// Déclenche l'animation de placement d'une tuile
  void _animateTilePlacement(int row, int col) {
    final key = '$row,$col';
    setState(() {
      _animatingTiles[key] = true;
    });

    // Arrêter l'animation après 300ms
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _animatingTiles[key] = false;
        });
      }
    });
  }

  /// Gère le placement d'une tuile sur le plateau
  Future<void> _onBoardSquareTapped(int row, int col) async {
    if (_board == null) return;

    final square = _board!.getSquare(row, col);

    // Si la case contient une tuile non verrouillée, la retirer
    if (square.placedTile != null && !square.isLocked) {
      setState(() {
        final tile = square.placedTile!;

        // Retirer la tuile du plateau
        _board!.removeTile(row, col);

        // Remettre la tuile dans le chevalet
        _rack.add(tile);

        // Retirer de la liste des placements en attente
        _pendingPlacements.removeWhere(
          (p) => p.row == row && p.col == col,
        );

        // Retirer de la liste d'animation
        _animatingTiles.remove('$row,$col');

        _errorMessage = null;
      });
      return;
    }

    // Si aucune tuile sélectionnée, ne rien faire
    if (_selectedRackTile == null) return;

    // Vérifier que la case est vide
    if (square.placedTile != null) {
      _showError('Case déjà occupée');
      return;
    }

    // Si c'est un joker, demander la lettre
    Tile tileToPlace = _selectedRackTile!;
    if (tileToPlace.isBlank && tileToPlace.assignedLetter == null) {
      final selectedLetter = await _showBlankTileDialog();
      if (selectedLetter == null) {
        // L'utilisateur a annulé
        return;
      }
      tileToPlace = tileToPlace.copyWith(assignedLetter: selectedLetter);
    }

    // Placer la tuile
    setState(() {
      _board!.placeTile(row, col, tileToPlace);
      _pendingPlacements.add(
        PlacedTile(row: row, col: col, tile: tileToPlace),
      );

      // Retirer du chevalet
      _rack.removeAt(_selectedRackIndex!);

      // Désélectionner
      _selectedRackTile = null;
      _selectedRackIndex = null;
      _errorMessage = null;
    });

    // Animer le placement
    _animateTilePlacement(row, col);

    // Jouer le son de placement
    _soundService.playTilePlacement();
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

    // Jouer le son d'annulation
    _soundService.playUndo();
  }

  /// Mélange les tuiles du chevalet
  void _onShuffleRack() {
    setState(() {
      _rack.shuffle(Random());
      // Désélectionner si une tuile était sélectionnée
      _selectedRackTile = null;
      _selectedRackIndex = null;
    });

    // Jouer le son de mélange
    _soundService.playShuffle();
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
        // Jouer le son d'erreur
        _soundService.playError();
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

      // Jouer le son de validation
      _soundService.playValidation();

      // Animer les tuiles validées
      for (final placement in _pendingPlacements) {
        final key = '${placement.row},${placement.col}';
        setState(() {
          _validatedTiles[key] = true;
        });
      }

      // Attendre l'animation
      await Future.delayed(const Duration(milliseconds: 500));

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

        // Réinitialiser les placements en attente et animations
        _pendingPlacements.clear();
        _validatedTiles.clear();

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

      // Jouer le son de victoire
      _soundService.playVictory();

      // Afficher dialogue de félicitations
      if (mounted) {
        _showGameCompletedDialog();
      }
    } catch (e) {
      debugPrint('Erreur lors de la finalisation: $e');
    }
  }

  /// Affiche le dialogue de fin de partie
  void _showGameCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.amber, size: 32),
            const SizedBox(width: 12),
            const Text('Partie terminée!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Félicitations! Vous avez terminé la partie.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildStatRow('Score final', '$_score pts', Icons.stars),
            const SizedBox(height: 12),
            _buildStatRow(
              'Temps total',
              _formatTime(_timeElapsed),
              Icons.timer,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Mots formés',
              '${_moveHistory.length}',
              Icons.spellcheck,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('Accueil'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/skrabb/leaderboard');
            },
            icon: const Icon(Icons.emoji_events),
            label: const Text('Voir Classement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFE74C3C)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Affiche un dialogue pour choisir la lettre d'un joker
  Future<String?> _showBlankTileDialog() async {
    final distribution = LetterDistribution.creole();
    final allLetters = distribution.allLetters;

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6D3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Choisir une lettre',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: allLetters.length,
            itemBuilder: (context, index) {
              final letter = allLetters[index];
              return InkWell(
                onTap: () => Navigator.of(context).pop(letter),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E6D3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  /// Affiche un message d'erreur
  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _shakeError = true;
    });

    // Jouer le son d'erreur
    _soundService.playError();

    // Arrêter l'animation shake après 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _shakeError = false;
        });
      }
    });
  }

  /// Formate le temps écoulé (MM:SS)
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Gère le bouton retour (restaure orientation avant navigation)
  Future<void> _onBackPressed() async {
    // Restaurer l'orientation avant de naviguer
    await _restoreAllOrientations();
    // Naviguer vers l'écran d'accueil
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _onBackPressed();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFF6B6B), // Coral rose
                const Color(0xFFFFB347), // Orange pastel
                const Color(0xFFFFD93D), // Jaune doré
                const Color(0xFFFF8C94), // Rose saumon
              ],
            ),
          ),
          child: Stack(
            children: [
              // Pattern madras en arrière-plan
              Positioned.fill(
                child: CustomPaint(
                  painter: MadrasPatternPainter(
                    colors: _madrasColors,
                    opacity: 0.08,
                  ),
                ),
              ),
              // Contenu du jeu
              SafeArea(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildGameContent(),
              ),
            ],
          ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          margin: EdgeInsets.all(isMobile ? 8 : 12),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 20,
            vertical: isMobile ? 12 : 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.black.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Bouton retour dans un cercle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: isMobile ? 20 : 24),
                  onPressed: _onBackPressed,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              // Icône ronde du jeu
              Container(
                width: isMobile ? 65 : 80,
                height: isMobile ? 65 : 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Transform.scale(
                    scale: 1.1,
                    child: Image.asset(
                      'assets/icons/skrabb.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        'S',
                        style: TextStyle(
                          fontSize: isMobile ? 28 : 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(width: isMobile ? 8 : 12),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6 : 12,
                  vertical: isMobile ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars, color: Colors.amber, size: isMobile ? 16 : 20),
                    SizedBox(width: isMobile ? 4 : 6),
                    Text(
                      '$_score',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isMobile ? 6 : 12),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6 : 12,
                  vertical: isMobile ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, color: Colors.blue, size: isMobile ? 16 : 20),
                    SizedBox(width: isMobile ? 4 : 6),
                    Text(
                      _formatTime(_timeElapsed),
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isMobile ? 4 : 8),
              IconButton(
                icon: Icon(Icons.emoji_events, color: Colors.amber, size: isMobile ? 20 : 28),
                tooltip: 'Classement',
                onPressed: () => context.go('/skrabb/leaderboard'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(width: isMobile ? 4 : 0),
              IconButton(
                icon: Icon(Icons.help_outline, color: Colors.white70, size: isMobile ? 20 : 28),
                tooltip: 'Aide',
                onPressed: () => context.go('/skrabb/help'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            width: 3,
          ),
          boxShadow: [
            // Ombre principale
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            // Ombre intérieure (effet 3D)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            // Lueur dorée subtile
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.1),
              blurRadius: 15,
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2c3e50),
                  const Color(0xFF34495e),
                ],
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Board.size,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 1,
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
        ),
      ),
    );
  }

  Widget _buildBoardSquare(int row, int col) {
    final square = _board!.getSquare(row, col);

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        // Accepter uniquement si la case est vide
        return square.placedTile == null;
      },
      onAcceptWithDetails: (details) async {
        final data = details.data;
        Tile tile = data['tile'] as Tile;
        final rackIndex = data['rackIndex'] as int;

        // Si c'est un joker, demander la lettre
        if (tile.isBlank && tile.assignedLetter == null) {
          final selectedLetter = await _showBlankTileDialog();
          if (selectedLetter == null) {
            // L'utilisateur a annulé
            return;
          }
          tile = tile.copyWith(assignedLetter: selectedLetter);
        }

        // Placer la tuile via drag & drop
        setState(() {
          _board!.placeTile(row, col, tile);
          _pendingPlacements.add(
            PlacedTile(row: row, col: col, tile: tile),
          );

          // Retirer du chevalet
          _rack.removeAt(rackIndex);

          // Désélectionner
          _selectedRackTile = null;
          _selectedRackIndex = null;
          _errorMessage = null;
        });

        // Animer le placement
        _animateTilePlacement(row, col);

        // Jouer le son de placement
        _soundService.playTilePlacement();
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () => _onBoardSquareTapped(row, col),
          child: Container(
            decoration: BoxDecoration(
              gradient: isHovering
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getSquareColor(square),
                        _getSquareColor(square).withValues(alpha: 0.7),
                      ],
                    )
                  : null,
              color: isHovering ? null : _getSquareColor(square),
              border: Border.all(
                color: isHovering
                    ? const Color(0xFFFFD700).withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.15),
                width: isHovering ? 2 : 0.5,
              ),
              boxShadow: isHovering
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: square.placedTile != null
                ? _buildAnimatedTile(row, col, square.placedTile!, square.isLocked)
                : Stack(
                    children: [
                      // Effet de profondeur subtil pour les cases bonus
                      if (square.bonusType != BonusType.none)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 0.8,
                                colors: [
                                  Colors.white.withValues(alpha: 0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Label du bonus
                      Center(
                        child: Text(
                          square.bonusType.shortName,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.8),
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
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

  /// Widget de tuile avec animation
  Widget _buildAnimatedTile(int row, int col, Tile tile, bool isLocked) {
    final key = '$row,$col';
    final isAnimating = _animatingTiles[key] ?? false;
    final isValidated = _validatedTiles[key] ?? false;

    return AnimatedScale(
      scale: isAnimating ? 1.2 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isValidated
              ? const Color(0xFFFFD700).withValues(alpha: 0.3)
              : const Color(0xFFF5E6D3),
          borderRadius: BorderRadius.circular(4),
          border: isValidated
              ? Border.all(color: const Color(0xFFFFD700), width: 2)
              : tile.isBlank
                  ? Border.all(color: Colors.amber, width: 2)
                  : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: isAnimating ? 6 : 2,
              offset: Offset(0, isAnimating ? 3 : 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Lettre au centre
            Center(
              child: Text(
                tile.displayLetter,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            // Indicateur joker en haut à gauche
            if (tile.isBlank)
              Positioned(
                top: 1,
                left: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            // Points dans le coin inférieur droit
            Positioned(
              bottom: 2,
              right: 3,
              child: Text(
                '${tile.value}',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTileWidget(Tile tile, {required bool isOnBoard}) {
    // Pour les jokers sans lettre assignée, afficher un "?"
    final displayText = tile.isBlank && tile.assignedLetter == null
        ? '?'
        : tile.displayLetter;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3),
        borderRadius: BorderRadius.circular(4),
        border: tile.isBlank
            ? Border.all(color: Colors.amber, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Lettre au centre
          Center(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: tile.isBlank ? Colors.amber.shade700 : Colors.black87,
              ),
            ),
          ),
          // Indicateur joker en haut à gauche (seulement si assigné)
          if (tile.isBlank && tile.assignedLetter != null)
            Positioned(
              top: 1,
              left: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          // Points dans le coin inférieur droit
          Positioned(
            bottom: 2,
            right: 3,
            child: Text(
              '${tile.value}',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.elasticOut,
              transform: Matrix4.translationValues(
                _shakeError ? 10.0 : 0.0,
                0.0,
                0.0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculer la taille optimale des tuiles selon la largeur disponible
          final availableWidth = constraints.maxWidth;
          final tileSize = ((availableWidth - 56) / 7).clamp(40.0, 60.0);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              if (index < _rack.length) {
                return _buildRackTile(index, tileSize);
              } else {
                return _buildEmptyRackSlot(tileSize);
              }
            }),
          );
        },
      ),
    );
  }

  Widget _buildRackTile(int index, double tileSize) {
    final isSelected = _selectedRackIndex == index;
    final tile = _rack[index];

    // Pour les jokers sans lettre assignée, afficher un "?"
    final displayText = tile.isBlank && tile.assignedLetter == null
        ? '?'
        : tile.displayLetter;

    final tileWidget = Container(
      width: tileSize,
      height: tileSize,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected
            ? _madrasColors[1]
            : const Color(0xFFF5E6D3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? Colors.black
              : tile.isBlank
                  ? Colors.amber
                  : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Lettre au centre
          Center(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: tileSize * 0.4,
                fontWeight: FontWeight.bold,
                color: tile.isBlank ? Colors.amber.shade700 : Colors.black87,
              ),
            ),
          ),
          // Indicateur joker en haut à gauche (seulement si assigné)
          if (tile.isBlank && tile.assignedLetter != null)
            Positioned(
              top: 2,
              left: 4,
              child: Container(
                width: tileSize * 0.2,
                height: tileSize * 0.2,
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontSize: tileSize * 0.12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          // Points dans le coin inférieur droit
          Positioned(
            bottom: 4,
            right: 6,
            child: Text(
              '${tile.value}',
              style: TextStyle(
                fontSize: tileSize * 0.15,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );

    return Draggable<Map<String, dynamic>>(
      data: {'tile': tile, 'rackIndex': index},
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.7,
          child: Container(
            width: tileSize,
            height: tileSize,
            decoration: BoxDecoration(
              color: _madrasColors[1],
              borderRadius: BorderRadius.circular(8),
              border: tile.isBlank
                  ? Border.all(color: Colors.amber, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Lettre au centre
                Center(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: tileSize * 0.4,
                      fontWeight: FontWeight.bold,
                      color: tile.isBlank ? Colors.amber.shade700 : Colors.black87,
                    ),
                  ),
                ),
                // Indicateur joker en haut à gauche (seulement si assigné)
                if (tile.isBlank && tile.assignedLetter != null)
                  Positioned(
                    top: 2,
                    left: 4,
                    child: Container(
                      width: tileSize * 0.2,
                      height: tileSize * 0.2,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontSize: tileSize * 0.12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Points dans le coin inférieur droit
                Positioned(
                  bottom: 4,
                  right: 6,
                  child: Text(
                    '${tile.value}',
                    style: TextStyle(
                      fontSize: tileSize * 0.15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: tileWidget,
      ),
      child: GestureDetector(
        onTap: () => _onRackTileSelected(index),
        child: tileWidget,
      ),
    );
  }

  Widget _buildEmptyRackSlot(double tileSize) {
    return Container(
      width: tileSize,
      height: tileSize,
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
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton.icon(
                onPressed: _pendingPlacements.isEmpty ? null : _onUndoPlacements,
                icon: const Icon(Icons.undo, size: 18),
                label: const Text(
                  'Annuler',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE74C3C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 14,
                  ),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.grey.shade700,
                  disabledForegroundColor: Colors.grey.shade500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton.icon(
                onPressed: _rack.isEmpty ? null : _onShuffleRack,
                icon: const Icon(Icons.shuffle, size: 18),
                label: const Text(
                  'Mélanger',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B59B6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 14,
                  ),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.grey.shade700,
                  disabledForegroundColor: Colors.grey.shade500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton.icon(
                onPressed:
                    _pendingPlacements.isEmpty || _isValidating
                        ? null
                        : _onValidateMove,
                icon: _isValidating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check, size: 18),
                label: const Text(
                  'Valider',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 14,
                  ),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.grey.shade700,
                  disabledForegroundColor: Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter pour créer un pattern madras en arrière-plan
class MadrasPatternPainter extends CustomPainter {
  final List<Color> colors;
  final double opacity;

  MadrasPatternPainter({
    required this.colors,
    this.opacity = 0.05,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Dessiner des rayures diagonales colorées
    final stripWidth = size.width / 20;

    for (int i = 0; i < 40; i++) {
      paint.color = colors[i % colors.length].withValues(alpha: opacity);

      final path = Path();
      final startX = i * stripWidth - size.height;

      path.moveTo(startX, 0);
      path.lineTo(startX + stripWidth, 0);
      path.lineTo(startX + stripWidth + size.height, size.height);
      path.lineTo(startX + size.height, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }

    // Ajouter des rayures horizontales subtiles
    for (int i = 0; i < 15; i++) {
      paint.color = colors[i % colors.length].withValues(alpha: opacity * 0.5);

      final y = i * (size.height / 15);
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, stripWidth / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
