import '../models/board.dart';
import '../models/move.dart';
import 'word_extractor.dart';

/// Utilitaire pour calculer les scores selon les règles du Scrabble
class ScrabbleScoring {
  /// Calcule le score total d'un coup
  ///
  /// Prend en compte:
  /// - Les valeurs des lettres
  /// - Les multiplicateurs de lettres (DL, TL) pour les nouvelles tuiles
  /// - Les multiplicateurs de mots (DW, TW, Centre) pour les nouvelles tuiles
  /// - Le bonus bingo (+50) si 7 tuiles sont placées
  static int calculateMoveScore(
    Board board,
    List<PlacedTile> newTiles,
  ) {
    if (newTiles.isEmpty) return 0;

    int totalScore = 0;

    // Extraire tous les mots formés (principal + croisés)
    final words = WordExtractor.extractFormedWords(board, newTiles);

    // Calculer le score de chaque mot
    for (final word in words) {
      totalScore += _calculateWordScore(board, word, newTiles);
    }

    // Bonus bingo: 7 tuiles = +50 points
    if (newTiles.length == 7) {
      totalScore += 50;
    }

    return totalScore;
  }

  /// Calcule le score d'un mot spécifique formé sur le plateau
  static int _calculateWordScore(
    Board board,
    String word,
    List<PlacedTile> newTiles,
  ) {
    if (word.isEmpty) return 0;

    // Trouver les positions des lettres du mot
    final wordPositions = _findWordPositions(board, word);
    if (wordPositions.isEmpty) return 0;

    int wordScore = 0;
    int wordMultiplier = 1;

    // Calculer le score pour chaque lettre
    for (final position in wordPositions) {
      final square = board.getSquare(position.row, position.col);
      final tile = square.placedTile;

      if (tile == null) continue;

      int letterScore = tile.value;

      // Les bonus ne s'appliquent qu'aux lettres nouvellement placées
      final isNewTile = _isNewTile(position.row, position.col, newTiles);

      if (isNewTile) {
        switch (square.bonusType) {
          case BonusType.doubleLetter:
            letterScore *= 2;
            break;
          case BonusType.tripleLetter:
            letterScore *= 3;
            break;
          case BonusType.doubleWord:
          case BonusType.center:
            wordMultiplier *= 2;
            break;
          case BonusType.tripleWord:
            wordMultiplier *= 3;
            break;
          case BonusType.none:
            break;
        }
      }

      wordScore += letterScore;
    }

    return wordScore * wordMultiplier;
  }

  /// Trouve les positions de toutes les lettres d'un mot sur le plateau
  static List<_Position> _findWordPositions(Board board, String word) {
    final normalizedWord = word.toUpperCase();

    // Chercher horizontalement
    for (int row = 0; row < Board.size; row++) {
      for (int col = 0; col <= Board.size - normalizedWord.length; col++) {
        final positions = _extractHorizontalWordPositions(board, row, col, normalizedWord.length);
        if (positions.isNotEmpty) {
          final foundWord = positions
              .map((pos) => board.getSquare(pos.row, pos.col).placedTile?.displayLetter ?? '')
              .join()
              .toUpperCase();

          if (foundWord == normalizedWord) {
            return positions;
          }
        }
      }
    }

    // Chercher verticalement
    for (int col = 0; col < Board.size; col++) {
      for (int row = 0; row <= Board.size - normalizedWord.length; row++) {
        final positions = _extractVerticalWordPositions(board, col, row, normalizedWord.length);
        if (positions.isNotEmpty) {
          final foundWord = positions
              .map((pos) => board.getSquare(pos.row, pos.col).placedTile?.displayLetter ?? '')
              .join()
              .toUpperCase();

          if (foundWord == normalizedWord) {
            return positions;
          }
        }
      }
    }

    return [];
  }

  /// Extrait les positions d'un mot horizontal
  static List<_Position> _extractHorizontalWordPositions(
    Board board,
    int row,
    int startCol,
    int length,
  ) {
    final positions = <_Position>[];

    for (int col = startCol; col < startCol + length && col < Board.size; col++) {
      final tile = board.getSquare(row, col).placedTile;
      if (tile == null) {
        return []; // Trou trouvé, pas un mot valide
      }
      positions.add(_Position(row, col));
    }

    return positions;
  }

  /// Extrait les positions d'un mot vertical
  static List<_Position> _extractVerticalWordPositions(
    Board board,
    int col,
    int startRow,
    int length,
  ) {
    final positions = <_Position>[];

    for (int row = startRow; row < startRow + length && row < Board.size; row++) {
      final tile = board.getSquare(row, col).placedTile;
      if (tile == null) {
        return []; // Trou trouvé, pas un mot valide
      }
      positions.add(_Position(row, col));
    }

    return positions;
  }

  /// Vérifie si une position correspond à une tuile nouvellement placée
  static bool _isNewTile(int row, int col, List<PlacedTile> newTiles) {
    return newTiles.any((tile) => tile.row == row && tile.col == col);
  }

  /// Calcule le score d'un mot formé avec détails
  /// Retourne un objet détaillé pour l'affichage
  static WordScoreDetail calculateWordScoreDetail(
    Board board,
    String word,
    List<PlacedTile> newTiles,
  ) {
    final positions = _findWordPositions(board, word);
    if (positions.isEmpty) {
      return WordScoreDetail(
        word: word,
        baseScore: 0,
        wordMultiplier: 1,
        finalScore: 0,
        letterScores: [],
      );
    }

    int baseScore = 0;
    int wordMultiplier = 1;
    final letterScores = <LetterScoreDetail>[];

    for (final position in positions) {
      final square = board.getSquare(position.row, position.col);
      final tile = square.placedTile;

      if (tile == null) continue;

      int letterScore = tile.value;
      int letterMultiplier = 1;
      String bonusApplied = '';

      final isNewTile = _isNewTile(position.row, position.col, newTiles);

      if (isNewTile) {
        switch (square.bonusType) {
          case BonusType.doubleLetter:
            letterMultiplier = 2;
            bonusApplied = 'DL';
            break;
          case BonusType.tripleLetter:
            letterMultiplier = 3;
            bonusApplied = 'TL';
            break;
          case BonusType.doubleWord:
          case BonusType.center:
            wordMultiplier *= 2;
            bonusApplied = 'DW';
            break;
          case BonusType.tripleWord:
            wordMultiplier *= 3;
            bonusApplied = 'TW';
            break;
          case BonusType.none:
            break;
        }
      }

      letterScore *= letterMultiplier;
      baseScore += letterScore;

      letterScores.add(LetterScoreDetail(
        letter: tile.displayLetter,
        baseValue: tile.value,
        multiplier: letterMultiplier,
        score: letterScore,
        bonusApplied: bonusApplied,
        isNewTile: isNewTile,
      ));
    }

    return WordScoreDetail(
      word: word,
      baseScore: baseScore,
      wordMultiplier: wordMultiplier,
      finalScore: baseScore * wordMultiplier,
      letterScores: letterScores,
    );
  }
}

/// Position interne pour le calcul
class _Position {
  final int row;
  final int col;

  _Position(this.row, this.col);
}

/// Détails du score d'un mot (pour affichage)
class WordScoreDetail {
  final String word;
  final int baseScore;
  final int wordMultiplier;
  final int finalScore;
  final List<LetterScoreDetail> letterScores;

  WordScoreDetail({
    required this.word,
    required this.baseScore,
    required this.wordMultiplier,
    required this.finalScore,
    required this.letterScores,
  });

  @override
  String toString() {
    return '$word: $baseScore × $wordMultiplier = $finalScore pts';
  }
}

/// Détails du score d'une lettre (pour affichage)
class LetterScoreDetail {
  final String letter;
  final int baseValue;
  final int multiplier;
  final int score;
  final String bonusApplied;
  final bool isNewTile;

  LetterScoreDetail({
    required this.letter,
    required this.baseValue,
    required this.multiplier,
    required this.score,
    required this.bonusApplied,
    required this.isNewTile,
  });

  @override
  String toString() {
    final bonus = bonusApplied.isNotEmpty ? ' ($bonusApplied)' : '';
    return '$letter: ${baseValue}${bonus} = $score pts';
  }
}
