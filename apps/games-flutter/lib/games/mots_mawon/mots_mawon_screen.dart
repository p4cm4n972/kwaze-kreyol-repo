import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/word.dart';
import '../../models/dictionary_entry.dart';
import '../../services/dictionary_service.dart';
import '../../utils/word_search_generator.dart';
import 'dart:async';

class MotsMawonScreen extends StatefulWidget {
  const MotsMawonScreen({super.key});

  @override
  State<MotsMawonScreen> createState() => _MotsMawonScreenState();
}

class _MotsMawonScreenState extends State<MotsMawonScreen> {
  final DictionaryService _dictService = DictionaryService();

  WordSearchGrid? _gameData;
  List<CellPosition> _selectedCells = []; // Changed to List to maintain order
  Set<String> _foundWords = {};
  int _score = 0;
  int _timeElapsed = 0;
  Timer? _timer;
  bool _isLoading = true;
  bool _isGameComplete = false;

  @override
  void initState() {
    super.initState();
    _loadAndStartGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAndStartGame() async {
    setState(() {
      _isLoading = true;
    });

    // Charger le dictionnaire
    final entries = await _dictService.loadDictionary('A');

    if (entries.isNotEmpty) {
      _startNewGame(entries);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _startNewGame(List<DictionaryEntry> entries) {
    final words = _dictService.getRandomWords(entries, 10);
    final grid = WordSearchGenerator.generate(words);

    setState(() {
      _gameData = grid;
      _selectedCells = [];
      _foundWords = {};
      _score = 0;
      _timeElapsed = 0;
      _isGameComplete = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isGameComplete) {
        setState(() {
          _timeElapsed++;
        });
      }
    });
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
      setState(() {
        _foundWords.add(foundWord.text);
        _score += foundWord.text.length * 10;
        foundWord.found = true;

        // Vérifier si tous les mots sont trouvés
        if (_foundWords.length == _gameData!.words.length) {
          _isGameComplete = true;
          _timer?.cancel();
        }
      });
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Mots Mawon'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final size = MediaQuery.of(context).size;
            final isPortrait = orientation == Orientation.portrait;
            final isMobile = size.shortestSide < 600;

            // Sur mobile en portrait, afficher un message pour tourner l'appareil
            if (isMobile && isPortrait) {
              return _buildRotateDeviceMessage();
            }

            // En mode paysage, utiliser le layout large
            if (orientation == Orientation.landscape) {
              return _buildWideLayout();
            } else {
              return _buildNarrowLayout();
            }
          },
        ),
      ),
    );
  }

  Widget _buildRotateDeviceMessage() {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.screen_rotation,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'Tournez votre appareil',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Ce jeu est optimisé pour le mode paysage',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
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
            Expanded(
              flex: 2,
              child: _buildGameBoard(constraints.maxWidth),
            ),
            Expanded(
              flex: 1,
              child: _buildWordList(),
            ),
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
            Expanded(
              flex: 4,
              child: _buildGameBoard(constraints.maxWidth),
            ),
            Expanded(
              flex: 1,
              child: _buildWordList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGameBoard([double? screenWidth]) {
    final isMobile = screenWidth != null && screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
      child: Column(
        children: [
          _buildStats(),
          SizedBox(height: isMobile ? 8 : 16),

          // Mot en cours de construction - espace réservé fixe
          SizedBox(
            height: isMobile ? 40 : 56,
            child: _selectedCells.isNotEmpty
                ? Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        _selectedCells
                            .map((cell) => _gameData!.grid[cell.row][cell.col])
                            .join(''),
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  )
                : Container(),
          ),
          SizedBox(height: isMobile ? 8 : 16),

          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gameData!.size,
                  crossAxisSpacing: isMobile ? 3 : 2,
                  mainAxisSpacing: isMobile ? 3 : 2,
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
          SizedBox(height: isMobile ? 8 : 16),

          // Boutons de contrôle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 4.0 : 8.0),
                  child: ElevatedButton.icon(
                    onPressed: _selectedCells.isEmpty ? null : _clearSelection,
                    icon: Icon(Icons.clear, size: isMobile ? 16 : 20),
                    label: Text(
                      'Annuler',
                      style: TextStyle(fontSize: isMobile ? 14 : 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                      minimumSize: Size(0, isMobile ? 40 : 50),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 4.0 : 8.0),
                  child: ElevatedButton.icon(
                    onPressed: _selectedCells.isEmpty ? null : _validateSelection,
                    icon: Icon(Icons.check, size: isMobile ? 16 : 20),
                    label: Text(
                      'Valider',
                      style: TextStyle(fontSize: isMobile ? 14 : 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                      minimumSize: Size(0, isMobile ? 40 : 50),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 16),
          ElevatedButton.icon(
            onPressed: _loadAndStartGame,
            icon: Icon(Icons.refresh, size: isMobile ? 16 : 20),
            label: Text(
              'Nouvelle partie',
              style: TextStyle(fontSize: isMobile ? 14 : 16),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 32,
                vertical: isMobile ? 12 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('⏱️', _formatTime(_timeElapsed)),
        _buildStatItem('🎯', 'Score: $_score'),
        _buildStatItem('✅', '${_foundWords.length}/${_gameData!.words.length}'),
      ],
    );
  }

  Widget _buildStatItem(String icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$icon $text',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCell(int row, int col, [bool isMobile = false]) {
    final cellPos = CellPosition(row, col);
    final isSelected = _selectedCells.contains(cellPos);
    final isInFoundWord = _gameData!.words.any(
      (w) => _foundWords.contains(w.text) && w.cells.contains(cellPos),
    );

    Color cellColor;
    if (isInFoundWord) {
      cellColor = Colors.green;
    } else if (isSelected) {
      cellColor = Colors.amber;
    } else {
      cellColor = Colors.grey[300]!;
    }

    return GestureDetector(
      onTap: () => _handleCellTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(4),
          border: isSelected
              ? Border.all(color: Colors.orange, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            _gameData!.grid[row][col],
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: isInFoundWord || isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordList() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mots à trouver',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _gameData!.words.length,
              itemBuilder: (context, index) {
                final word = _gameData!.words[index];
                final isFound = _foundWords.contains(word.text);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isFound ? Colors.green : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFound ? Colors.green : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    word.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isFound ? Colors.white : Colors.black,
                      decoration: isFound ? TextDecoration.lineThrough : null,
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isGameComplete) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    '🎉 Bravo !',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Temps: ${_formatTime(_timeElapsed)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Score: $_score points',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
