import 'dart:math';
import 'tile.dart';

/// Configuration de la distribution des lettres pour Skrabb
/// Définit combien de chaque lettre et leur valeur en points
class LetterDistribution {
  /// Nombre de tuiles de chaque lettre
  final Map<String, int> counts;

  /// Valeur en points de chaque lettre
  final Map<String, int> values;

  /// Nombre de tuiles blanches (jokers)
  final int blankCount;

  LetterDistribution({
    required this.counts,
    required this.values,
    this.blankCount = 2,
  });

  /// Distribution créole initiale
  /// Cette distribution sera affinée en Phase 5 après analyse du dictionnaire
  factory LetterDistribution.creole() {
    return LetterDistribution(
      counts: {
        // Voyelles (très fréquentes)
        'A': 9,
        'E': 12,
        'I': 8,
        'O': 6,
        'U': 6,

        // Consonnes fréquentes
        'L': 4,
        'N': 6,
        'R': 6,
        'S': 6,
        'T': 6,

        // Consonnes moyennement fréquentes
        'B': 2,
        'C': 2,
        'D': 3,
        'F': 2,
        'G': 2,
        'H': 2,
        'M': 3,
        'P': 2,
        'V': 2,
        'Y': 2,

        // Consonnes rares
        'J': 1,
        'K': 1,
        'W': 2,
        'Z': 1,

        // Lettres accentuées créoles
        'É': 2,
        'È': 2,
        'Ê': 1,
        'À': 1,
        'Ô': 1,
        'Ç': 1,
      },
      values: {
        // Voyelles communes: 1 pt
        'A': 1,
        'E': 1,
        'I': 1,
        'O': 1,
        'U': 1,

        // Consonnes fréquentes: 1 pt
        'L': 1,
        'N': 1,
        'R': 1,
        'S': 1,
        'T': 1,

        // Consonnes moyennement fréquentes: 2-3 pts
        'B': 3,
        'C': 3,
        'D': 2,
        'F': 4,
        'G': 2,
        'H': 4,
        'M': 2,
        'P': 3,
        'V': 4,
        'Y': 4,

        // Consonnes rares: 8-10 pts
        'J': 8,
        'K': 10,
        'W': 10,
        'Z': 10,

        // Lettres accentuées: 2-3 pts
        'É': 2,
        'È': 2,
        'Ê': 3,
        'À': 2,
        'Ô': 3,
        'Ç': 3,
      },
      blankCount: 2,
    );
  }

  /// Crée le sac de lettres complet avec toutes les tuiles
  List<Tile> createTileBag() {
    final tiles = <Tile>[];

    // Ajouter les lettres selon leur quantité
    counts.forEach((letter, count) {
      final value = values[letter] ?? 0;
      for (int i = 0; i < count; i++) {
        tiles.add(Tile(letter: letter, value: value));
      }
    });

    // Ajouter les tuiles blanches (jokers)
    for (int i = 0; i < blankCount; i++) {
      tiles.add(Tile.blank());
    }

    // Mélanger le sac
    tiles.shuffle(Random());

    return tiles;
  }

  /// Nombre total de tuiles (sans compter les blancs)
  int get totalTiles {
    return counts.values.fold(0, (sum, count) => sum + count);
  }

  /// Nombre total de tuiles incluant les blancs
  int get totalTilesWithBlanks {
    return totalTiles + blankCount;
  }

  /// Obtient la valeur d'une lettre
  int getLetterValue(String letter) {
    return values[letter] ?? 0;
  }

  /// Obtient la quantité d'une lettre
  int getLetterCount(String letter) {
    return counts[letter] ?? 0;
  }

  /// Liste de toutes les lettres disponibles
  List<String> get allLetters {
    return counts.keys.toList()..sort();
  }

  @override
  String toString() {
    return 'LetterDistribution(${allLetters.length} lettres, '
        '$totalTilesWithBlanks tuiles total, $blankCount blancs)';
  }
}
