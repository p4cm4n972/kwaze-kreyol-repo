import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../models/word.dart';
import '../../models/dictionary_entry.dart';
import '../../services/dictionary_service.dart';
import '../../services/auth_service.dart';
import '../../utils/word_search_generator.dart';
import '../../widgets/game_header.dart';
import 'models/mots_mawon_game.dart';
import 'services/mots_mawon_service.dart';
import 'services/mots_mawon_sound_service.dart';
import 'dart:async';
import 'dart:math';

class MotsMawonScreen extends StatefulWidget {
  const MotsMawonScreen({super.key});

  @override
  State<MotsMawonScreen> createState() => _MotsMawonScreenState();
}

class _MotsMawonScreenState extends State<MotsMawonScreen>
    with TickerProviderStateMixin {
  final DictionaryService _dictService = DictionaryService();
  final AuthService _authService = AuthService();
  final MotsMawonService _motsMawonService = MotsMawonService();
  final MotsMawonSoundService _soundService = MotsMawonSoundService();

  WordSearchGrid? _gameData;
  List<CellPosition> _selectedCells = []; // Changed to List to maintain order
  Set<String> _foundWords = {};
  int _score = 0;
  int _timeElapsed = 0;
  Timer? _timer;
  Timer? _autoSaveTimer;
  bool _isLoading = true;
  bool _isGameComplete = false;
  bool _isSaving = false;
  MotsMawonGame? _currentGame;

  // Couleurs madras pour les mots trouvés
  final List<Color> _madrasColors = [
    const Color(0xFFE74C3C), // Rouge
    const Color(0xFFF39C12), // Jaune/orange
    const Color(0xFF27AE60), // Vert
    const Color(0xFF3498DB), // Bleu
    const Color(0xFF9B59B6), // Violet
    const Color(0xFFE67E22), // Orange foncé
    const Color(0xFF1ABC9C), // Turquoise
  ];

  // Map pour associer chaque mot trouvé à une couleur
  final Map<String, Color> _wordColors = {};

  // Mot sélectionné pour afficher sa définition
  Word? _selectedWordForDefinition;

  // Animation pour mot trouvé
  AnimationController? _wordFoundAnimController;
  Animation<double>? _wordFoundAnimation;
  String? _lastFoundWord;

  // Animation pour la progression
  AnimationController? _progressAnimController;

  // Confetti pour la victoire
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _initSound();
    _initAnimations();
    _checkAuthAndLoadGame();
  }

  Future<void> _initSound() async {
    await _soundService.initialize();
  }

  void _initAnimations() {
    _wordFoundAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _wordFoundAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _wordFoundAnimController!,
        curve: Curves.elasticOut,
      ),
    );

    _progressAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    _wordFoundAnimController?.dispose();
    _progressAnimController?.dispose();
    _soundService.dispose();
    // Save final state before disposing (without setState since widget is being destroyed)
    if (_currentGame != null && !_isGameComplete && !_isSaving) {
      _saveProgressSync();
    }
    super.dispose();
  }

  /// Sauvegarde synchrone sans mise à jour UI (pour dispose)
  void _saveProgressSync() {
    if (_currentGame == null) return;

    // Fire and forget - pas de setState car le widget est détruit
    _motsMawonService
        .saveGameProgress(
          gameId: _currentGame!.id,
          foundWords: _foundWords,
          score: _score,
          timeElapsed: _timeElapsed,
        )
        .catchError((e) {
          debugPrint('Erreur de sauvegarde finale: $e');
        });
  }

  /// Vérifie l'authentification et charge la partie en cours ou démarre une nouvelle
  Future<void> _checkAuthAndLoadGame() async {
    setState(() {
      _isLoading = true;
    });

    // Vérifier si l'utilisateur est connecté
    final userId = _authService.getUserIdOrNull();
    if (userId == null) {
      // Rediriger vers l'écran d'authentification après la construction
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/auth');
        }
      });
      return;
    }

    try {
      // Essayer de charger une partie en cours
      final inProgressGame = await _motsMawonService.loadInProgressGame();

      if (inProgressGame != null && mounted) {
        // Proposer de reprendre la partie
        final shouldResume = await showDialog<bool?>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Partie en cours'),
            content: const Text(
              'Vous avez une partie en cours. Voulez-vous la reprendre ?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/home');
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Retour', style: TextStyle(fontSize: 13)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Nouvelle', style: TextStyle(fontSize: 13)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Reprendre', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        );

        // Si l'utilisateur a cliqué sur "Retour", on sort
        if (shouldResume == null) return;

        if (shouldResume == true) {
          await _resumeGame(inProgressGame);
        } else {
          // Abandonner l'ancienne partie et en créer une nouvelle
          await _motsMawonService.abandonGame(inProgressGame.id);
          await _loadAndStartGame();
        }
      } else {
        // Pas de partie en cours, démarrer une nouvelle
        await _loadAndStartGame();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
      await _loadAndStartGame();
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Reprendre une partie sauvegardée
  Future<void> _resumeGame(MotsMawonGame game) async {
    setState(() {
      _currentGame = game;
      _gameData = game.gridData;
      _foundWords = game.foundWords;
      _score = game.score;
      _timeElapsed = game.timeElapsed;
      _isGameComplete = false;
      _selectedCells = [];
    });

    // Marquer les mots déjà trouvés dans la grille
    for (final word in _gameData!.words) {
      if (_foundWords.contains(word.text)) {
        word.found = true;
      }
    }

    _startTimers();
  }

  /// Démarrer les timers (jeu et auto-save)
  void _startTimers() {
    // Timer du jeu
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isGameComplete) {
        setState(() {
          _timeElapsed++;
        });
      }
    });

    // Timer d'auto-save (toutes les 30 secondes)
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isGameComplete && _currentGame != null) {
        _saveProgress();
      }
    });
  }

  /// Sauvegarder la progression
  Future<void> _saveProgress() async {
    if (_currentGame == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _motsMawonService.saveGameProgress(
        gameId: _currentGame!.id,
        foundWords: _foundWords,
        score: _score,
        timeElapsed: _timeElapsed,
      );
    } catch (e) {
      // Erreur silencieuse pour ne pas interrompre le jeu
      debugPrint('Erreur de sauvegarde: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// Terminer la partie
  Future<void> _completeGame() async {
    if (_currentGame == null) return;

    // Son de victoire
    _soundService.playVictory();

    setState(() {
      _isGameComplete = true;
      _showConfetti = true;
    });

    _timer?.cancel();
    _autoSaveTimer?.cancel();

    try {
      await _motsMawonService.completeGame(
        gameId: _currentGame!.id,
        foundWords: _foundWords,
        score: _score,
        timeElapsed: _timeElapsed,
      );

      if (mounted) {
        // Attendre un peu pour que le son et confetti jouent
        await Future.delayed(const Duration(milliseconds: 500));

        // Afficher un dialog de félicitations amélioré
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE74C3C),
                    Color(0xFFF39C12),
                    Color(0xFF27AE60),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🎉',
                    style: TextStyle(fontSize: 60),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'BRAVO !',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tous les mots trouvés !',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              '$_score pts',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer, color: Colors.white70, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(_timeElapsed),
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Boutons d'action
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go('/home');
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.home, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Accueil',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go('/mots-mawon/leaderboard');
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.leaderboard, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Classement',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _showConfetti = false;
                          });
                          _loadAndStartGame();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFE74C3C),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Rejouer',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    }
  }

  Future<void> _loadAndStartGame() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer les mots aléatoires depuis la base de données
      final wordsFromDB = await _motsMawonService.getRandomWordsFromDB(
        count: 10,
        minLength: 3,
        maxLength: 10,
      );

      if (wordsFromDB.isNotEmpty) {
        // Convertir en DictionaryEntry pour compatibilité avec le générateur
        final entries = wordsFromDB.map((w) => DictionaryEntry(
          mot: w['word'] as String,
          definitions: [
            Definition(
              sensNum: 1,
              traduction: w['translation'] as String? ?? '',
              nature: w['nature'] as String? ?? '',
            ),
          ],
        )).toList();

        await _startNewGame(entries);
      } else {
        // Fallback: charger depuis les fichiers JSON locaux si pas de données en BDD
        final fallbackEntries = await _dictService.loadDictionary('A');
        if (fallbackEntries.isNotEmpty) {
          final randomEntries = _dictService.getRandomEntries(fallbackEntries, 10);
          await _startNewGame(randomEntries);
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des mots: $e');
      // Fallback en cas d'erreur
      final fallbackEntries = await _dictService.loadDictionary('A');
      if (fallbackEntries.isNotEmpty) {
        final randomEntries = _dictService.getRandomEntries(fallbackEntries, 10);
        await _startNewGame(randomEntries);
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _startNewGame(List<DictionaryEntry> entries) async {
    final grid = WordSearchGenerator.generateWithDefinitions(entries);

    try {
      // Créer la partie dans Supabase
      final game = await _motsMawonService.createGame(grid);

      setState(() {
        _currentGame = game;
        _gameData = grid;
        _selectedCells = [];
        _foundWords = {};
        _score = 0;
        _timeElapsed = 0;
        _isGameComplete = false;
      });

      _startTimers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création de la partie: $e'),
          ),
        );
      }
    }
  }

  void _handleCellTap(int row, int col) {
    if (_isGameComplete) return;

    final cellPos = CellPosition(row, col);

    setState(() {
      // Si la cellule est déjà sélectionnée, on la retire
      if (_selectedCells.contains(cellPos)) {
        _selectedCells.remove(cellPos);
      } else {
        // Sinon, on vérifie qu'elle est adjacente à la dernière cellule sélectionnée
        if (_selectedCells.isEmpty || _isAdjacentToLast(cellPos)) {
          _selectedCells.add(cellPos);
          _soundService.playSelect(); // Son de sélection
        }
      }
    });
  }

  bool _isAdjacentToLast(CellPosition newCell) {
    if (_selectedCells.isEmpty) return true;

    final lastCell = _selectedCells.last;
    final rowDiff = (newCell.row - lastCell.row).abs();
    final colDiff = (newCell.col - lastCell.col).abs();

    // Adjacent = même ligne/colonne/diagonale et à distance 1
    return (rowDiff <= 1 && colDiff <= 1) && !(rowDiff == 0 && colDiff == 0);
  }

  void _validateSelection() {
    if (_selectedCells.isEmpty || _gameData == null) return;

    // Construire le mot à partir des cellules sélectionnées
    final selectedWord = _selectedCells
        .map((cell) => _gameData!.grid[cell.row][cell.col])
        .join('');

    // Chercher le mot dans la liste
    final foundWord = _gameData!.words.firstWhere(
      (w) => w.text == selectedWord && !_foundWords.contains(w.text),
      orElse: () => Word(text: '', cells: []),
    );

    if (foundWord.text.isNotEmpty) {
      // Son et animation de mot trouvé
      _soundService.playWordFound();
      _lastFoundWord = foundWord.text;
      _wordFoundAnimController?.forward(from: 0);

      setState(() {
        _foundWords.add(foundWord.text);
        _score += foundWord.text.length * 10;
        foundWord.found = true;

        // Assigner une couleur madras au mot trouvé
        _wordColors[foundWord.text] =
            _madrasColors[_foundWords.length % _madrasColors.length];
      });

      // Sauvegarder la progression après chaque mot trouvé
      _saveProgress();

      // Vérifier si tous les mots sont trouvés
      if (_foundWords.length == _gameData!.words.length) {
        _completeGame();
      }
    } else {
      // Son d'erreur si mot invalide
      _soundService.playError();
    }

    setState(() {
      _selectedCells = [];
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedCells = [];
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_gameData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Erreur de chargement du dictionnaire'),
              ElevatedButton(
                onPressed: _loadAndStartGame,
                child: const Text('Réessayer'),
              ),
            ],
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
              const Color(0xFFE74C3C).withValues(alpha: 0.3), // Rouge madras
              const Color(0xFFF39C12).withValues(alpha: 0.3), // Jaune
              const Color(0xFF27AE60).withValues(alpha: 0.3), // Vert
              const Color(0xFF3498DB).withValues(alpha: 0.3), // Bleu
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header unifié
              GameHeader(
                title: 'Mo Mawon',
                iconPath: 'assets/icons/mo-mawon.png',
                onBack: () => context.go('/home'),
                gradientColors: const [Color(0xFFE74C3C), Color(0xFFF39C12)],
                actions: [
                  if (_isSaving)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  GameHeaderAction(
                    icon: Icons.leaderboard,
                    onPressed: () => context.go('/mots-mawon/leaderboard'),
                    tooltip: 'Classement',
                    iconColor: Colors.amber,
                  ),
                ],
              ),
              // Contenu du jeu
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;

                    if (isWide) {
                      return _buildWideLayout();
                    } else {
                      return _buildNarrowLayout();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(flex: 2, child: _buildGameBoard(constraints.maxWidth)),
            Expanded(flex: 1, child: _buildWordList()),
          ],
        );
      },
    );
  }

  Widget _buildNarrowLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(flex: 4, child: _buildGameBoard(constraints.maxWidth)),
            SizedBox(height: 12),
            Expanded(flex: 2, child: _buildWordList()),
          ],
        );
      },
    );
  }

  Widget _buildGameBoard([double? screenWidth]) {
    final isMobile = screenWidth != null && screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 16.0),
      child: Column(
        children: [
          // Stats compacts en mode mobile
          if (isMobile)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMobileStatItem(
                    'assets/icons/clock.svg',
                    _formatTime(_timeElapsed),
                  ),
                  _buildMobileStatItem('assets/icons/trophy.svg', '$_score'),
                  _buildMobileStatItem(
                    'assets/icons/check_circle.svg',
                    '${_foundWords.length}/${_gameData!.words.length}',
                  ),
                ],
              ),
            )
          else
            _buildStats(),

          SizedBox(height: isMobile ? 4 : 16),

          // Grille - prend tout l'espace disponible
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gameData!.size,
                  crossAxisSpacing: isMobile ? 4 : 2,
                  mainAxisSpacing: isMobile ? 4 : 2,
                ),
                itemCount: _gameData!.size * _gameData!.size,
                itemBuilder: (context, index) {
                  final row = index ~/ _gameData!.size;
                  final col = index % _gameData!.size;
                  return _buildCell(row, col, isMobile);
                },
              ),
            ),
          ),
          SizedBox(height: isMobile ? 4 : 16),

          // Boutons de contrôle compacts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 2.0 : 8.0,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _selectedCells.isEmpty ? null : _clearSelection,
                    icon: Icon(Icons.clear, size: isMobile ? 14 : 20),
                    label: Text(
                      'Annuler',
                      style: TextStyle(fontSize: isMobile ? 12 : 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 8 : 16,
                      ),
                      minimumSize: Size(0, isMobile ? 32 : 50),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 2.0 : 8.0,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _selectedCells.isEmpty
                        ? null
                        : _validateSelection,
                    icon: Icon(Icons.check, size: isMobile ? 14 : 20),
                    label: Text(
                      'Valider',
                      style: TextStyle(fontSize: isMobile ? 12 : 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 8 : 16,
                      ),
                      minimumSize: Size(0, isMobile ? 32 : 50),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 2.0 : 8.0,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _loadAndStartGame,
                    icon: Icon(Icons.refresh, size: isMobile ? 14 : 20),
                    label: Text(
                      'Nouveau',
                      style: TextStyle(fontSize: isMobile ? 12 : 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 8 : 16,
                      ),
                      minimumSize: Size(0, isMobile ? 32 : 50),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final progress = _gameData != null
        ? _foundWords.length / _gameData!.words.length
        : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItemWithSvg(
              'assets/icons/clock.svg',
              _formatTime(_timeElapsed),
            ),
            _buildStatItemWithSvg('assets/icons/trophy.svg', '$_score pts'),
            _buildStatItemWithSvg(
              'assets/icons/check_circle.svg',
              '${_foundWords.length}/${_gameData!.words.length}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Barre de progression
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.white.withValues(alpha: 0.3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _madrasColors[0],
                          _madrasColors[1],
                          _madrasColors[2],
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: _madrasColors[1].withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItemWithSvg(String svgPath, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(svgPath, width: 20, height: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatItem(String svgPath, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(svgPath, width: 14, height: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCell(int row, int col, [bool isMobile = false]) {
    final cellPos = CellPosition(row, col);
    final isSelected = _selectedCells.contains(cellPos);

    // Trouver le mot qui contient cette cellule (s'il existe)
    String? foundWordText;
    for (final w in _gameData!.words) {
      if (_foundWords.contains(w.text) && w.cells.contains(cellPos)) {
        foundWordText = w.text;
        break;
      }
    }
    final isInFoundWord = foundWordText != null;

    Color cellColor;
    if (isInFoundWord) {
      // Utiliser la couleur madras assignée au mot
      cellColor = _wordColors[foundWordText!] ?? Colors.green;
    } else if (isSelected) {
      cellColor = const Color(
        0xFFE74C3C,
      ).withValues(alpha: 0.7); // Rouge madras pour sélection
    } else {
      cellColor = Colors.white.withValues(alpha: 0.3); // Transparence pour glassmorphisme
    }

    return GestureDetector(
      onTap: () => _handleCellTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          // Effet glassmorphisme
          color: isInFoundWord || isSelected ? cellColor : cellColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFFE74C3C), width: 2)
              : Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
          // Ombre pour effet de profondeur
          boxShadow: isInFoundWord || isSelected
              ? [
                  BoxShadow(
                    color: cellColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  _gameData!.grid[row][col],
                  style: GoogleFonts.openSans(
                    fontSize: isMobile ? 14 : 20,
                    fontWeight: FontWeight.bold,
                    color: isInFoundWord || isSelected
                        ? Colors.white
                        : Colors.black87,
                    shadows: isInFoundWord || isSelected
                        ? [
                            const Shadow(
                              color: Colors.black26,
                              blurRadius: 2,
                              offset: Offset(1, 1),
                            ),
                          ]
                        : [],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mots à trouver',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (_isGameComplete)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF39C12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatTime(_timeElapsed)} - $_score pts',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                // Liste des mots
                Expanded(
                  flex: _selectedWordForDefinition != null ? 2 : 3,
                  child: ListView.separated(
                    itemCount: _gameData!.words.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final word = _gameData!.words[index];
                      final isFound = _foundWords.contains(word.text);
                      final wordColor =
                          _wordColors[word.text] ?? const Color(0xFF27AE60);
                      final isSelected = _selectedWordForDefinition == word;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? wordColor.withValues(alpha: 0.2)
                              : (isFound
                                    ? wordColor.withValues(alpha: 0.1)
                                    : Colors.grey[50]),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? wordColor
                                : (isFound ? wordColor : Colors.grey[300]!),
                            width: isSelected ? 2 : (isFound ? 2 : 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (isFound)
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: wordColor,
                              ),
                            if (isFound) const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                word.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isFound ? wordColor : Colors.black87,
                                  decoration: isFound
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            // Bouton "?" pour afficher la définition
                            InkWell(
                              onTap: () {
                                // Détecter si on est en mode mobile
                                final isMobile =
                                    MediaQuery.of(context).size.width < 600;

                                if (isMobile) {
                                  // Sur mobile, afficher une popup
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Row(
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            color: Color(0xFF3498DB),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              word.text,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF3498DB),
                                              ),
                                            ),
                                          ),
                                          if (word.nature != null &&
                                              word.nature!.isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF3498DB),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                word.nature!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      content: SingleChildScrollView(
                                        child: Text(
                                          word.definition ??
                                              'Aucune définition disponible',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Fermer'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  // Sur desktop, comportement actuel (inline)
                                  setState(() {
                                    _selectedWordForDefinition = isSelected
                                        ? null
                                        : word;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? wordColor
                                      : const Color(0xFF3498DB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.question_mark,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Section de définition
                if (_selectedWordForDefinition != null) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF3498DB),
                          width: 2,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: Color(0xFF3498DB),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _selectedWordForDefinition!.text,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3498DB),
                                    ),
                                  ),
                                ),
                                if (_selectedWordForDefinition!.nature !=
                                        null &&
                                    _selectedWordForDefinition!
                                        .nature!
                                        .isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3498DB),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _selectedWordForDefinition!.nature!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_selectedWordForDefinition!.definition !=
                                    null &&
                                _selectedWordForDefinition!
                                    .definition!
                                    .isNotEmpty)
                              Text(
                                _selectedWordForDefinition!.definition!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            else
                              const Text(
                                'Aucune définition disponible',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
