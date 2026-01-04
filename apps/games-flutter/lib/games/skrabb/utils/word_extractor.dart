import '../models/board.dart';
import '../models/move.dart';

/// Direction d'un mot sur le plateau
enum Direction { horizontal, vertical, both }

/// Utilitaire pour extraire les mots formés sur le plateau Skrabb
class WordExtractor {
  /// Extrait tous les mots formés par un coup (mot principal + mots croisés)
  static List<String> extractFormedWords(
    Board board,
    List<PlacedTile> newTiles,
  ) {
    if (newTiles.isEmpty) return [];

    final words = <String>[];

    // Déterminer la direction du coup
    final direction = _determineDirection(newTiles);

    // Extraire le mot principal
    final mainWord = _extractMainWord(board, newTiles, direction);
    if (mainWord.length > 1) {
      words.add(mainWord);
    }

    // Extraire les mots croisés (perpendiculaires)
    for (final placedTile in newTiles) {
      final crossDirection = direction == Direction.horizontal
          ? Direction.vertical
          : Direction.horizontal;

      final crossWord = _extractWordAt(
        board,
        placedTile.row,
        placedTile.col,
        crossDirection,
      );

      if (crossWord.length > 1) {
        words.add(crossWord);
      }
    }

    return words;
  }

  /// Détermine la direction d'un coup (horizontal, vertical, ou both si 1 tuile)
  static Direction _determineDirection(List<PlacedTile> tiles) {
    if (tiles.length == 1) return Direction.both;

    final rows = tiles.map((t) => t.row).toSet();
    final cols = tiles.map((t) => t.col).toSet();

    if (rows.length == 1) return Direction.horizontal;
    if (cols.length == 1) return Direction.vertical;

    // Cas invalide (tuiles ni alignées horizontalement ni verticalement)
    throw ArgumentError('Les tuiles doivent être alignées');
  }

  /// Extrait le mot principal formé par les nouvelles tuiles
  static String _extractMainWord(
    Board board,
    List<PlacedTile> newTiles,
    Direction direction,
  ) {
    if (direction == Direction.both) {
      // Une seule tuile - vérifier les deux directions
      final tile = newTiles.first;

      // Essayer horizontal
      final hWord = _extractWordAt(board, tile.row, tile.col, Direction.horizontal);
      if (hWord.length > 1) return hWord;

      // Essayer vertical
      final vWord = _extractWordAt(board, tile.row, tile.col, Direction.vertical);
      return vWord;
    }

    // Trouver les positions min/max
    if (direction == Direction.horizontal) {
      final row = newTiles.first.row;
      final minCol = newTiles.map((t) => t.col).reduce((a, b) => a < b ? a : b);
      final maxCol = newTiles.map((t) => t.col).reduce((a, b) => a > b ? a : b);

      return _extractHorizontalWord(board, row, minCol, maxCol);
    } else {
      final col = newTiles.first.col;
      final minRow = newTiles.map((t) => t.row).reduce((a, b) => a < b ? a : b);
      final maxRow = newTiles.map((t) => t.row).reduce((a, b) => a > b ? a : b);

      return _extractVerticalWord(board, col, minRow, maxRow);
    }
  }

  /// Extrait un mot à une position donnée dans une direction
  static String _extractWordAt(
    Board board,
    int row,
    int col,
    Direction direction,
  ) {
    if (direction == Direction.horizontal) {
      return _extractHorizontalWord(board, row, col, col);
    } else {
      return _extractVerticalWord(board, col, row, row);
    }
  }

  /// Extrait un mot horizontal en incluant les tuiles adjacentes
  static String _extractHorizontalWord(
    Board board,
    int row,
    int startCol,
    int endCol,
  ) {
    // Étendre vers la gauche
    int leftCol = startCol;
    while (leftCol > 0 && board.getSquare(row, leftCol - 1).placedTile != null) {
      leftCol--;
    }

    // Étendre vers la droite
    int rightCol = endCol;
    while (rightCol < Board.size - 1 &&
        board.getSquare(row, rightCol + 1).placedTile != null) {
      rightCol++;
    }

    // Construire le mot
    final letters = <String>[];
    for (int col = leftCol; col <= rightCol; col++) {
      final tile = board.getSquare(row, col).placedTile;
      if (tile == null) {
        // Trou dans le mot - invalide
        return '';
      }
      letters.add(tile.displayLetter);
    }

    return letters.join().toUpperCase();
  }

  /// Extrait un mot vertical en incluant les tuiles adjacentes
  static String _extractVerticalWord(
    Board board,
    int col,
    int startRow,
    int endRow,
  ) {
    // Étendre vers le haut
    int topRow = startRow;
    while (topRow > 0 && board.getSquare(topRow - 1, col).placedTile != null) {
      topRow--;
    }

    // Étendre vers le bas
    int bottomRow = endRow;
    while (bottomRow < Board.size - 1 &&
        board.getSquare(bottomRow + 1, col).placedTile != null) {
      bottomRow++;
    }

    // Construire le mot
    final letters = <String>[];
    for (int row = topRow; row <= bottomRow; row++) {
      final tile = board.getSquare(row, col).placedTile;
      if (tile == null) {
        // Trou dans le mot - invalide
        return '';
      }
      letters.add(tile.displayLetter);
    }

    return letters.join().toUpperCase();
  }

  /// Vérifie si les tuiles placées sont alignées (horizontal ou vertical)
  static bool areAligned(List<PlacedTile> tiles) {
    if (tiles.length <= 1) return true;

    final rows = tiles.map((t) => t.row).toSet();
    final cols = tiles.map((t) => t.col).toSet();

    return rows.length == 1 || cols.length == 1;
  }

  /// Vérifie si les tuiles placées sont contiguës (pas de trous)
  static bool areContiguous(List<PlacedTile> tiles, Board board) {
    if (tiles.length <= 1) return true;

    final direction = _determineDirection(tiles);

    if (direction == Direction.horizontal) {
      final row = tiles.first.row;
      final cols = tiles.map((t) => t.col).toList()..sort();

      for (int i = 0; i < cols.length - 1; i++) {
        final currentCol = cols[i];
        final nextCol = cols[i + 1];

        // Vérifier qu'il n'y a pas de trou entre les deux tuiles
        for (int col = currentCol + 1; col < nextCol; col++) {
          if (board.getSquare(row, col).placedTile == null) {
            return false; // Trou trouvé
          }
        }
      }
    } else if (direction == Direction.vertical) {
      final col = tiles.first.col;
      final rows = tiles.map((t) => t.row).toList()..sort();

      for (int i = 0; i < rows.length - 1; i++) {
        final currentRow = rows[i];
        final nextRow = rows[i + 1];

        // Vérifier qu'il n'y a pas de trou entre les deux tuiles
        for (int row = currentRow + 1; row < nextRow; row++) {
          if (board.getSquare(row, col).placedTile == null) {
            return false; // Trou trouvé
          }
        }
      }
    }

    return true;
  }

  /// Obtient la direction d'un ensemble de tuiles
  static Direction getDirection(List<PlacedTile> tiles) {
    return _determineDirection(tiles);
  }
}
