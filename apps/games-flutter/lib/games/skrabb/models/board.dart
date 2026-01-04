import 'tile.dart';

/// Types de cases bonus sur le plateau Scrabble
enum BonusType {
  none,          // Case normale
  doubleLetter,  // Lettre compte double (DL)
  tripleLetter,  // Lettre compte triple (TL)
  doubleWord,    // Mot compte double (DW)
  tripleWord,    // Mot compte triple (TW)
  center,        // Case centrale (★) - compte comme doubleWord
}

/// Extension pour obtenir des infos sur les bonus
extension BonusTypeExtension on BonusType {
  String get shortName {
    switch (this) {
      case BonusType.doubleLetter:
        return 'LD'; // Lettre Double
      case BonusType.tripleLetter:
        return 'LT'; // Lettre Triple
      case BonusType.doubleWord:
        return 'MD'; // Mot Double
      case BonusType.tripleWord:
        return 'MT'; // Mot Triple
      case BonusType.center:
        return '★';
      case BonusType.none:
        return '';
    }
  }

  int get letterMultiplier {
    switch (this) {
      case BonusType.doubleLetter:
        return 2;
      case BonusType.tripleLetter:
        return 3;
      default:
        return 1;
    }
  }

  int get wordMultiplier {
    switch (this) {
      case BonusType.doubleWord:
      case BonusType.center:
        return 2;
      case BonusType.tripleWord:
        return 3;
      default:
        return 1;
    }
  }
}

/// Une case sur le plateau
class BoardSquare {
  final int row;
  final int col;
  final BonusType bonusType;
  Tile? placedTile;
  bool isLocked;  // True après validation du coup

  BoardSquare({
    required this.row,
    required this.col,
    required this.bonusType,
    this.placedTile,
    this.isLocked = false,
  });

  /// Copie la case avec de nouvelles valeurs
  BoardSquare copyWith({
    int? row,
    int? col,
    BonusType? bonusType,
    Tile? placedTile,
    bool? isLocked,
  }) {
    return BoardSquare(
      row: row ?? this.row,
      col: col ?? this.col,
      bonusType: bonusType ?? this.bonusType,
      placedTile: placedTile ?? this.placedTile,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  /// Convertit la case en JSON
  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
      'bonusType': bonusType.name,
      if (placedTile != null) 'placedTile': placedTile!.toJson(),
      'isLocked': isLocked,
    };
  }

  /// Crée une case à partir de JSON
  factory BoardSquare.fromJson(Map<String, dynamic> json) {
    return BoardSquare(
      row: json['row'] as int,
      col: json['col'] as int,
      bonusType: BonusType.values.firstWhere(
        (e) => e.name == json['bonusType'],
        orElse: () => BonusType.none,
      ),
      placedTile: json['placedTile'] != null
          ? Tile.fromJson(json['placedTile'] as Map<String, dynamic>)
          : null,
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'BoardSquare($row,$col, bonus: ${bonusType.shortName}, '
        'tile: ${placedTile?.letter ?? "empty"}, locked: $isLocked)';
  }
}

/// Pattern des cases bonus Scrabble standard 15x15
class BonusSquaresPattern {
  /// Détermine le type de bonus pour une position donnée
  static BonusType getBonusType(int row, int col) {
    // Case centrale (7,7)
    if (row == 7 && col == 7) return BonusType.center;

    // Triple Mot (TW) - 8 cases
    // 4 coins
    if ((row == 0 || row == 14) && (col == 0 || col == 14)) {
      return BonusType.tripleWord;
    }
    // Croix centrale
    if ((row == 0 || row == 14) && col == 7) return BonusType.tripleWord;
    if (row == 7 && (col == 0 || col == 14)) return BonusType.tripleWord;

    // Double Mot (DW) - 16 cases (diagonales)
    final dwPositions = [
      [1, 1], [2, 2], [3, 3], [4, 4],
      [1, 13], [2, 12], [3, 11], [4, 10],
      [13, 1], [12, 2], [11, 3], [10, 4],
      [13, 13], [12, 12], [11, 11], [10, 10],
    ];
    if (_containsPosition(dwPositions, row, col)) {
      return BonusType.doubleWord;
    }

    // Triple Lettre (TL) - 12 cases
    final tlPositions = [
      [1, 5], [1, 9],
      [5, 1], [5, 5], [5, 9], [5, 13],
      [9, 1], [9, 5], [9, 9], [9, 13],
      [13, 5], [13, 9],
    ];
    if (_containsPosition(tlPositions, row, col)) {
      return BonusType.tripleLetter;
    }

    // Double Lettre (DL) - 24 cases
    final dlPositions = [
      [0, 3], [0, 11],
      [2, 6], [2, 8],
      [3, 0], [3, 7], [3, 14],
      [6, 2], [6, 6], [6, 8], [6, 12],
      [7, 3], [7, 11],
      [8, 2], [8, 6], [8, 8], [8, 12],
      [11, 0], [11, 7], [11, 14],
      [12, 6], [12, 8],
      [14, 3], [14, 11],
    ];
    if (_containsPosition(dlPositions, row, col)) {
      return BonusType.doubleLetter;
    }

    return BonusType.none;
  }

  static bool _containsPosition(List<List<int>> positions, int row, int col) {
    return positions.any((pos) => pos[0] == row && pos[1] == col);
  }
}

/// Plateau de jeu 15x15
class Board {
  static const int size = 15;
  final List<List<BoardSquare>> squares;

  Board() : squares = _initializeBoard();

  /// Crée un plateau à partir de données existantes
  Board.fromSquares(this.squares);

  /// Initialise un nouveau plateau vide avec les cases bonus
  static List<List<BoardSquare>> _initializeBoard() {
    return List.generate(
      size,
      (row) => List.generate(
        size,
        (col) => BoardSquare(
          row: row,
          col: col,
          bonusType: BonusSquaresPattern.getBonusType(row, col),
        ),
      ),
    );
  }

  /// Récupère une case à une position donnée
  BoardSquare getSquare(int row, int col) {
    if (row < 0 || row >= size || col < 0 || col >= size) {
      throw RangeError('Position hors du plateau: ($row, $col)');
    }
    return squares[row][col];
  }

  /// Vérifie si le plateau est vide (aucune tuile placée)
  bool get isEmpty {
    for (var row in squares) {
      for (var square in row) {
        if (square.placedTile != null) return false;
      }
    }
    return true;
  }

  /// Vérifie si le plateau est vide sauf pour les tuiles non verrouillées
  bool get isEmptyExceptPending {
    for (var row in squares) {
      for (var square in row) {
        if (square.placedTile != null && square.isLocked) return false;
      }
    }
    return true;
  }

  /// Place une tuile sur le plateau
  void placeTile(int row, int col, Tile tile) {
    final square = getSquare(row, col);
    if (square.isLocked) {
      throw StateError('Case verrouillée à ($row, $col)');
    }
    square.placedTile = tile;
  }

  /// Retire une tuile du plateau
  Tile? removeTile(int row, int col) {
    final square = getSquare(row, col);
    if (square.isLocked) {
      throw StateError('Impossible de retirer une tuile verrouillée');
    }
    final tile = square.placedTile;
    square.placedTile = null;
    return tile;
  }

  /// Verrouille toutes les tuiles placées (après validation)
  void lockAllTiles() {
    for (var row in squares) {
      for (var square in row) {
        if (square.placedTile != null) {
          square.isLocked = true;
        }
      }
    }
  }

  /// Copie le plateau
  Board copyWith() {
    final newSquares = List.generate(
      size,
      (row) => List.generate(
        size,
        (col) => squares[row][col].copyWith(),
      ),
    );
    return Board.fromSquares(newSquares);
  }

  /// Convertit le plateau en JSON
  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'squares': squares
          .map((row) => row.map((square) => square.toJson()).toList())
          .toList(),
    };
  }

  /// Crée un plateau à partir de JSON
  factory Board.fromJson(Map<String, dynamic> json) {
    final squaresData = json['squares'] as List;
    final squares = squaresData.map((rowData) {
      final row = rowData as List;
      return row.map((squareData) {
        return BoardSquare.fromJson(squareData as Map<String, dynamic>);
      }).toList();
    }).toList();

    return Board.fromSquares(squares);
  }

  @override
  String toString() {
    int tilesCount = 0;
    int lockedCount = 0;
    for (var row in squares) {
      for (var square in row) {
        if (square.placedTile != null) {
          tilesCount++;
          if (square.isLocked) lockedCount++;
        }
      }
    }
    return 'Board(${size}x$size, tiles: $tilesCount, locked: $lockedCount)';
  }
}
