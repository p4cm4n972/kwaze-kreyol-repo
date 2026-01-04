/// Représente une tuile (lettre) du jeu Skrabb
class Tile {
  /// La lettre sur la tuile (ex: "A", "É", "B")
  final String letter;

  /// Valeur en points de la lettre (1-10)
  final int value;

  /// True si c'est une tuile blanche (joker)
  final bool isBlank;

  /// Lettre assignée pour une tuile blanche (joker)
  /// Null si pas une tuile blanche ou pas encore assignée
  String? assignedLetter;

  Tile({
    required this.letter,
    required this.value,
    this.isBlank = false,
    this.assignedLetter,
  });

  /// Crée une tuile blanche (joker)
  factory Tile.blank() {
    return Tile(
      letter: '',
      value: 0,
      isBlank: true,
    );
  }

  /// Copie la tuile avec de nouvelles valeurs
  Tile copyWith({
    String? letter,
    int? value,
    bool? isBlank,
    String? assignedLetter,
  }) {
    return Tile(
      letter: letter ?? this.letter,
      value: value ?? this.value,
      isBlank: isBlank ?? this.isBlank,
      assignedLetter: assignedLetter ?? this.assignedLetter,
    );
  }

  /// Convertit la tuile en JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'letter': letter,
      'value': value,
      'isBlank': isBlank,
      if (assignedLetter != null) 'assignedLetter': assignedLetter,
    };
  }

  /// Crée une tuile à partir de JSON
  factory Tile.fromJson(Map<String, dynamic> json) {
    return Tile(
      letter: json['letter'] as String,
      value: json['value'] as int,
      isBlank: json['isBlank'] as bool? ?? false,
      assignedLetter: json['assignedLetter'] as String?,
    );
  }

  /// Retourne la lettre à afficher (assignedLetter si joker, sinon letter)
  String get displayLetter {
    if (isBlank && assignedLetter != null) {
      return assignedLetter!;
    }
    return letter;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Tile &&
        other.letter == letter &&
        other.value == value &&
        other.isBlank == isBlank &&
        other.assignedLetter == assignedLetter;
  }

  @override
  int get hashCode {
    return letter.hashCode ^
        value.hashCode ^
        isBlank.hashCode ^
        (assignedLetter?.hashCode ?? 0);
  }

  @override
  String toString() {
    if (isBlank) {
      return 'Tile.blank(assigned: $assignedLetter, value: $value)';
    }
    return 'Tile($letter, $value pts)';
  }
}
