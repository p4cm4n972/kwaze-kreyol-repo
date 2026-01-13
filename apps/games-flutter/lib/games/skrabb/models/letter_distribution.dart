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

  /// Distribution créole optimisée
  /// Basée sur l'analyse de fréquence du dictionnaire créole martiniquais
  /// A=23%, N=11%, T=9%, I=9%, R=5%, É=5%, S=5%, etc.
  factory LetterDistribution.creole() {
    return LetterDistribution(
      counts: {
        // Voyelles (fréquences créoles)
        'A': 14,  // 22.85% - très fréquent en créole
        'I': 6,   // 8.59%
        'O': 4,   // 4.01%
        'E': 3,   // 2.19% - rare sans accent en créole
        'U': 2,   // 1.20% - rare en créole

        // Consonnes très fréquentes
        'N': 8,   // 11.09%
        'T': 6,   // 8.95%
        'R': 4,   // 5.31%
        'S': 4,   // 4.53%

        // Consonnes fréquentes
        'P': 3,   // 4.16%
        'V': 3,   // 2.55%
        'W': 3,   // 2.50% - fréquent en créole!
        'L': 3,   // 2.39%
        'M': 3,   // 2.34%

        // Consonnes moyennement fréquentes
        'Z': 2,   // 1.46%
        'Y': 2,   // 1.41%
        'J': 2,   // 1.25%
        'K': 2,   // 1.15%
        'D': 2,   // 0.83%
        'B': 2,   // 0.68%

        // Consonnes rares
        'G': 1,   // 0.52%
        'C': 1,   // 0.36%
        'H': 1,   // 0.36%
        'F': 1,   // 0.36%

        // Lettres accentuées créoles (importantes!)
        'É': 4,   // 4.58%
        'È': 3,   // 3.28%
        'Ò': 2,   // 0.52% - spécifique créole
        'À': 1,   // 0.05%
      },
      values: {
        // Très fréquentes (>8%): 1 pt
        'A': 1,   // 22.85%
        'N': 1,   // 11.09%
        'T': 1,   // 8.95%
        'I': 1,   // 8.59%

        // Fréquentes (4-6%): 2 pts
        'R': 2,   // 5.31%
        'É': 2,   // 4.58%
        'S': 2,   // 4.53%
        'P': 2,   // 4.16%
        'O': 2,   // 4.01%

        // Moyennement fréquentes (2-4%): 3 pts
        'È': 3,   // 3.28%
        'V': 3,   // 2.55%
        'W': 3,   // 2.50%
        'L': 3,   // 2.39%
        'M': 3,   // 2.34%
        'E': 3,   // 2.19%

        // Peu fréquentes (1-2%): 5 pts
        'Z': 5,   // 1.46%
        'Y': 5,   // 1.41%
        'J': 5,   // 1.25%
        'U': 5,   // 1.20%
        'K': 5,   // 1.15%
        'D': 5,   // 0.83%
        'B': 5,   // 0.68%

        // Rares (<0.6%): 8 pts
        'Ò': 8,   // 0.52%
        'G': 8,   // 0.52%

        // Très rares (<0.4%): 10 pts
        'C': 10,  // 0.36%
        'H': 10,  // 0.36%
        'F': 10,  // 0.36%
        'À': 10,  // 0.05%
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
