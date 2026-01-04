import 'tile.dart';

/// Représente une tuile placée à une position spécifique
class PlacedTile {
  final Tile tile;
  final int row;
  final int col;

  PlacedTile({
    required this.tile,
    required this.row,
    required this.col,
  });

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'tile': tile.toJson(),
      'row': row,
      'col': col,
    };
  }

  /// Crée à partir de JSON
  factory PlacedTile.fromJson(Map<String, dynamic> json) {
    return PlacedTile(
      tile: Tile.fromJson(json['tile'] as Map<String, dynamic>),
      row: json['row'] as int,
      col: json['col'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlacedTile &&
        other.tile == tile &&
        other.row == row &&
        other.col == col;
  }

  @override
  int get hashCode => tile.hashCode ^ row.hashCode ^ col.hashCode;

  @override
  String toString() {
    return 'PlacedTile(${tile.letter} at $row,$col)';
  }
}

/// Représente un coup joué dans une partie de Skrabb
class Move {
  /// Tuiles placées lors de ce coup
  final List<PlacedTile> placedTiles;

  /// Tous les mots formés (mot principal + mots croisés)
  final List<String> formedWords;

  /// Score obtenu pour ce coup
  final int score;

  /// True si le joueur a utilisé ses 7 tuiles (bonus +50)
  final bool isBingo;

  /// Date et heure du coup
  final DateTime timestamp;

  Move({
    required this.placedTiles,
    required this.formedWords,
    required this.score,
    this.isBingo = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Nombre de tuiles placées
  int get tileCount => placedTiles.length;

  /// Convertit en JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'placedTiles':
          placedTiles.map((pt) => pt.toJson()).toList(),
      'formedWords': formedWords,
      'score': score,
      'isBingo': isBingo,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Crée à partir de JSON
  factory Move.fromJson(Map<String, dynamic> json) {
    return Move(
      placedTiles: (json['placedTiles'] as List)
          .map((pt) => PlacedTile.fromJson(pt as Map<String, dynamic>))
          .toList(),
      formedWords: (json['formedWords'] as List).cast<String>(),
      score: json['score'] as int,
      isBingo: json['isBingo'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    final bingoText = isBingo ? ' (BINGO!)' : '';
    return 'Move(${formedWords.join(", ")}, $score pts$bingoText, '
        '${placedTiles.length} tuiles)';
  }
}
