import 'dart:math';
import '../models/word.dart';

class WordSearchGenerator {
  static const List<Direction> _directions = [
    Direction(0, 1), // horizontal →
    Direction(1, 0), // vertical ↓
    Direction(1, 1), // diagonal ↘
    Direction(1, -1), // diagonal ↙
  ];

  static WordSearchGrid generate(List<String> words, {int size = 12}) {
    final grid = List.generate(size, (_) => List<String>.filled(size, ''));
    final placedWords = <Word>[];

    // Normaliser et filtrer les mots
    final normalizedWords = words
        .map((w) => _normalizeWord(w.toUpperCase()))
        .where((w) => w.length >= 3 && w.length <= size)
        .take(10)
        .toList();

    // Placer les mots
    for (final word in normalizedWords) {
      final placed = _placeWord(grid, word, size);
      if (placed != null) {
        placedWords.add(placed);
      }
    }

    // Remplir les cases vides
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (grid[row][col].isEmpty) {
          grid[row][col] = _getRandomLetter();
        }
      }
    }

    return WordSearchGrid(
      grid: grid,
      words: placedWords,
      size: size,
    );
  }

  static Word? _placeWord(List<List<String>> grid, String word, int size) {
    final random = Random();
    const maxAttempts = 100;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final direction = _directions[random.nextInt(_directions.length)];
      final startRow = random.nextInt(size);
      final startCol = random.nextInt(size);

      if (_canPlaceWord(grid, word, startRow, startCol, direction, size)) {
        final cells = <CellPosition>[];

        for (int i = 0; i < word.length; i++) {
          final row = startRow + i * direction.dx;
          final col = startCol + i * direction.dy;
          grid[row][col] = word[i];
          cells.add(CellPosition(row, col));
        }

        return Word(text: word, cells: cells);
      }
    }

    return null;
  }

  static bool _canPlaceWord(
    List<List<String>> grid,
    String word,
    int startRow,
    int startCol,
    Direction direction,
    int size,
  ) {
    for (int i = 0; i < word.length; i++) {
      final row = startRow + i * direction.dx;
      final col = startCol + i * direction.dy;

      // Vérifier les limites
      if (row < 0 || row >= size || col < 0 || col >= size) {
        return false;
      }

      // Vérifier si la case est vide ou contient la même lettre
      if (grid[row][col].isNotEmpty && grid[row][col] != word[i]) {
        return false;
      }
    }

    return true;
  }

  static String _normalizeWord(String word) {
    return word.replaceAll(RegExp(r'[^A-ZÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇÑòóôõöùúûüèéêëàáâãäåìíîïçñ]'), '').toUpperCase();
  }

  static String _getRandomLetter() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZÉÈÊÀÔÙ';
    return letters[Random().nextInt(letters.length)];
  }
}

class Direction {
  final int dx;
  final int dy;

  const Direction(this.dx, this.dy);
}
