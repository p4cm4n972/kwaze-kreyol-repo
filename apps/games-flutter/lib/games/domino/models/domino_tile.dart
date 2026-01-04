/// Représente une tuile de domino (0-0 à 6-6)
class DominoTile {
  final int value1;
  final int value2;

  const DominoTile({
    required this.value1,
    required this.value2,
  }) : assert(value1 >= 0 && value1 <= 6),
       assert(value2 >= 0 && value2 <= 6);

  /// Identifiant unique de la tuile
  String get id => '${value1}-${value2}';

  /// Vérifie si c'est un double (ex: 3-3)
  bool get isDouble => value1 == value2;

  /// Valeur totale de la tuile (somme des deux côtés)
  int get totalValue => value1 + value2;

  /// Vérifie si la tuile peut se connecter à une valeur donnée
  bool canConnect(int value) => value1 == value || value2 == value;

  /// Obtient la valeur opposée sur la tuile
  /// Si on connecte avec `value`, retourne l'autre côté
  int getOppositeValue(int connectedValue) {
    if (value1 == connectedValue) return value2;
    if (value2 == connectedValue) return value1;
    throw Exception('Cette tuile ne peut pas se connecter à $connectedValue');
  }

  /// Crée l'ensemble complet de 28 tuiles (0-0 à 6-6)
  static List<DominoTile> createFullSet() {
    final tiles = <DominoTile>[];
    for (int i = 0; i <= 6; i++) {
      for (int j = i; j <= 6; j++) {
        tiles.add(DominoTile(value1: i, value2: j));
      }
    }
    return tiles;
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
    'value1': value1,
    'value2': value2,
  };

  factory DominoTile.fromJson(Map<String, dynamic> json) => DominoTile(
    value1: json['value1'] as int,
    value2: json['value2'] as int,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DominoTile &&
          runtimeType == other.runtimeType &&
          ((value1 == other.value1 && value2 == other.value2) ||
           (value1 == other.value2 && value2 == other.value1));

  @override
  int get hashCode => value1.hashCode ^ value2.hashCode;

  @override
  String toString() => '[$value1|$value2]';

  DominoTile copyWith({
    int? value1,
    int? value2,
  }) {
    return DominoTile(
      value1: value1 ?? this.value1,
      value2: value2 ?? this.value2,
    );
  }
}

/// Représente une tuile placée sur le plateau
class PlacedTile {
  final DominoTile tile;
  final int connectedValue;  // La valeur qui s'est connectée
  final String side;         // "left" ou "right"
  final DateTime placedAt;

  const PlacedTile({
    required this.tile,
    required this.connectedValue,
    required this.side,
    required this.placedAt,
  });

  /// La valeur exposée après placement
  int get exposedValue => tile.getOppositeValue(connectedValue);

  Map<String, dynamic> toJson() => {
    'tile': tile.toJson(),
    'connected_value': connectedValue,
    'side': side,
    'placed_at': placedAt.toIso8601String(),
  };

  factory PlacedTile.fromJson(Map<String, dynamic> json) => PlacedTile(
    tile: DominoTile.fromJson(json['tile'] as Map<String, dynamic>),
    connectedValue: json['connected_value'] as int,
    side: json['side'] as String,
    placedAt: DateTime.parse(json['placed_at'] as String),
  );

  @override
  String toString() => '${tile.toString()} (${side}, connected: $connectedValue, exposed: $exposedValue)';
}
