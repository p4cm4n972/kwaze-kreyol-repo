import '../models/board.dart';
import '../models/move.dart';
import '../services/word_validator.dart';
import 'word_extractor.dart';

/// Résultat de validation d'un coup
class MoveValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> formedWords;
  final List<String> invalidWords;

  MoveValidationResult({
    required this.isValid,
    this.errorMessage,
    this.formedWords = const [],
    this.invalidWords = const [],
  });

  factory MoveValidationResult.valid(List<String> formedWords) {
    return MoveValidationResult(
      isValid: true,
      formedWords: formedWords,
    );
  }

  factory MoveValidationResult.invalid(String errorMessage) {
    return MoveValidationResult(
      isValid: false,
      errorMessage: errorMessage,
    );
  }

  factory MoveValidationResult.invalidWords(List<String> invalidWords) {
    return MoveValidationResult(
      isValid: false,
      errorMessage: 'Mots invalides: ${invalidWords.join(", ")}',
      invalidWords: invalidWords,
    );
  }
}

/// Utilitaire pour valider les coups selon les règles du Scrabble
class MoveValidator {
  final WordValidator _wordValidator;

  MoveValidator(this._wordValidator);

  /// Valide un coup complet
  ///
  /// Vérifie:
  /// 1. Les tuiles sont alignées (horizontal ou vertical)
  /// 2. Les tuiles sont contiguës (pas de trous)
  /// 3. Premier coup: traverse la case centrale (7,7)
  /// 4. Coups suivants: se connectent à un mot existant
  /// 5. Tous les mots formés sont valides dans le dictionnaire
  Future<MoveValidationResult> validateMove(
    Board board,
    List<PlacedTile> newTiles,
    bool isFirstMove,
  ) async {
    if (newTiles.isEmpty) {
      return MoveValidationResult.invalid('Aucune tuile placée');
    }

    // 1. Vérifier l'alignement
    if (!WordExtractor.areAligned(newTiles)) {
      return MoveValidationResult.invalid(
        'Les tuiles doivent être alignées horizontalement ou verticalement',
      );
    }

    // 2. Vérifier la contiguïté
    if (!WordExtractor.areContiguous(newTiles, board)) {
      return MoveValidationResult.invalid(
        'Les tuiles doivent être contiguës (pas de trous)',
      );
    }

    // 3. Premier coup: vérifier case centrale
    if (isFirstMove) {
      if (!MoveValidator._crossesCenter(newTiles)) {
        return MoveValidationResult.invalid(
          'Le premier mot doit traverser la case centrale (★)',
        );
      }
    } else {
      // 4. Coups suivants: vérifier connexion
      if (!_connectsToExistingWord(board, newTiles)) {
        return MoveValidationResult.invalid(
          'Le mot doit se connecter à un mot existant',
        );
      }
    }

    // 5. Extraire tous les mots formés
    final formedWords = WordExtractor.extractFormedWords(board, newTiles);

    if (formedWords.isEmpty) {
      return MoveValidationResult.invalid('Aucun mot formé');
    }

    // 6. Valider tous les mots dans le dictionnaire
    final invalidWords = await _wordValidator.getInvalidWords(formedWords);

    if (invalidWords.isNotEmpty) {
      return MoveValidationResult.invalidWords(invalidWords);
    }

    // Tout est valide!
    return MoveValidationResult.valid(formedWords);
  }

  /// Vérifie si les nouvelles tuiles se connectent à un mot existant
  bool _connectsToExistingWord(Board board, List<PlacedTile> newTiles) {
    for (final placedTile in newTiles) {
      final row = placedTile.row;
      final col = placedTile.col;

      // Vérifier les 4 cases adjacentes
      final adjacentPositions = [
        (row - 1, col), // Haut
        (row + 1, col), // Bas
        (row, col - 1), // Gauche
        (row, col + 1), // Droite
      ];

      for (final (adjRow, adjCol) in adjacentPositions) {
        // Vérifier si la position est dans les limites du plateau
        if (adjRow >= 0 &&
            adjRow < Board.size &&
            adjCol >= 0 &&
            adjCol < Board.size) {
          final adjacentSquare = board.getSquare(adjRow, adjCol);

          // Si la case adjacente a une tuile verrouillée (existante)
          if (adjacentSquare.placedTile != null && adjacentSquare.isLocked) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Valide qu'un coup peut être placé sur le plateau
  /// (vérifie que les cases sont vides)
  static bool canPlaceTiles(Board board, List<PlacedTile> tiles) {
    for (final tile in tiles) {
      // Vérifier que la position est dans les limites
      if (tile.row < 0 ||
          tile.row >= Board.size ||
          tile.col < 0 ||
          tile.col >= Board.size) {
        return false;
      }

      // Vérifier que la case est vide
      final square = board.getSquare(tile.row, tile.col);
      if (square.placedTile != null) {
        return false; // Case déjà occupée
      }
    }

    return true;
  }

  /// Vérifie si les tuiles placées forment au moins un mot de 2+ lettres
  static bool formsValidWord(Board board, List<PlacedTile> newTiles) {
    final words = WordExtractor.extractFormedWords(board, newTiles);
    return words.isNotEmpty;
  }

  /// Valide les règles de placement sans vérification du dictionnaire
  /// Utile pour pré-validation en temps réel (avant soumission)
  static MoveValidationResult validatePlacement(
    Board board,
    List<PlacedTile> newTiles,
    bool isFirstMove,
  ) {
    if (newTiles.isEmpty) {
      return MoveValidationResult.invalid('Aucune tuile placée');
    }

    // Vérifier que les cases sont disponibles
    if (!canPlaceTiles(board, newTiles)) {
      return MoveValidationResult.invalid(
        'Certaines cases sont déjà occupées ou hors limites',
      );
    }

    // Vérifier l'alignement
    if (!WordExtractor.areAligned(newTiles)) {
      return MoveValidationResult.invalid(
        'Les tuiles doivent être alignées horizontalement ou verticalement',
      );
    }

    // Vérifier la contiguïté
    if (!WordExtractor.areContiguous(newTiles, board)) {
      return MoveValidationResult.invalid(
        'Les tuiles doivent être contiguës (pas de trous)',
      );
    }

    // Premier coup: case centrale
    if (isFirstMove) {
      if (!_crossesCenter(newTiles)) {
        return MoveValidationResult.invalid(
          'Le premier mot doit traverser la case centrale (★)',
        );
      }
    } else {
      // Vérifier connexion
      if (!MoveValidator(WordValidator())._connectsToExistingWord(board, newTiles)) {
        return MoveValidationResult.invalid(
          'Le mot doit se connecter à un mot existant',
        );
      }
    }

    // Vérifier qu'au moins un mot est formé
    if (!formsValidWord(board, newTiles)) {
      return MoveValidationResult.invalid('Aucun mot formé');
    }

    return MoveValidationResult.valid([]);
  }

  /// Vérifie si les tuiles traversent la case centrale (méthode statique)
  static bool _crossesCenter(List<PlacedTile> tiles) {
    return tiles.any((tile) => tile.row == 7 && tile.col == 7);
  }
}
