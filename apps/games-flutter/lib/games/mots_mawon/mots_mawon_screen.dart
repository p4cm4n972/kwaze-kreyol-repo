import 'package:flutter/material.dart';
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
  Set<CellPosition> _selectedCells = {};
  Set<String> _foundWords = {};
  bool _isSelecting = false;
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
      _selectedCells = {};
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

    setState(() {
      _isSelecting = true;
      _selectedCells = {CellPosition(row, col)};
    });
  }

  void _handleCellHover(int row, int col) {
    if (!_isSelecting || _isGameComplete) return;

    setState(() {
      _selectedCells.add(CellPosition(row, col));
    });
  }

  void _handleSelectionEnd() {
    if (!_isSelecting || _gameData == null) return;

    // Vérifier si la sélection forme un mot
    final sortedCells = _selectedCells.toList()
      ..sort((a, b) => a.row != b.row ? a.row.compareTo(b.row) : a.col.compareTo(b.col));

    final selectedWord = sortedCells
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
      _selectedCells = {};
      _isSelecting = false;
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
        title: const Text('Mots Mawon'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
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
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildGameBoard(),
        ),
        Expanded(
          flex: 1,
          child: _buildWordList(),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: _buildGameBoard(),
        ),
        Expanded(
          flex: 1,
          child: _buildWordList(),
        ),
      ],
    );
  }

  Widget _buildGameBoard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildStats(),
          const SizedBox(height: 16),
          Expanded(
            child: GestureDetector(
              onPanEnd: (_) => _handleSelectionEnd(),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gameData!.size,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: _gameData!.size * _gameData!.size,
                  itemBuilder: (context, index) {
                    final row = index ~/ _gameData!.size;
                    final col = index % _gameData!.size;
                    return _buildCell(row, col);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAndStartGame,
            icon: const Icon(Icons.refresh),
            label: const Text('Nouvelle partie'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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

  Widget _buildCell(int row, int col) {
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

    return MouseRegion(
      onEnter: (_) => _handleCellHover(row, col),
      child: GestureDetector(
        onTapDown: (_) => _handleCellTap(row, col),
        child: Container(
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              _gameData!.grid[row][col],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isInFoundWord || isSelected ? Colors.white : Colors.black,
              ),
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
