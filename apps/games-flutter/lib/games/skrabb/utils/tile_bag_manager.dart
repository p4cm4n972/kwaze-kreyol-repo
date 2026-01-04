import 'dart:math';
import '../models/tile.dart';
import '../models/letter_distribution.dart';

/// Gestionnaire du sac de tuiles pour le jeu Skrabb
class TileBagManager {
  final Random _random;

  TileBagManager({Random? random}) : _random = random ?? Random();

  /// Crée un sac initial de tuiles selon la distribution
  List<Tile> createInitialBag(LetterDistribution distribution) {
    final tiles = <Tile>[];

    // Ajouter les lettres normales
    distribution.counts.forEach((letter, count) {
      final value = distribution.values[letter] ?? 1;
      for (int i = 0; i < count; i++) {
        tiles.add(Tile(letter: letter, value: value, isBlank: false));
      }
    });

    // Ajouter les tuiles blanches (jokers)
    for (int i = 0; i < distribution.blankCount; i++) {
      tiles.add(Tile(letter: '', value: 0, isBlank: true));
    }

    // Mélanger le sac
    return shuffle(tiles);
  }

  /// Pioche N tuiles du sac
  ///
  /// Retourne les tuiles piochées et met à jour le sac (retire les tuiles piochées)
  List<Tile> drawTiles(List<Tile> bag, int count) {
    if (bag.isEmpty) return [];

    final drawCount = min(count, bag.length);
    final drawnTiles = bag.sublist(0, drawCount);

    // Retirer les tuiles piochées du sac
    bag.removeRange(0, drawCount);

    return drawnTiles;
  }

  /// Pioche des tuiles pour remplir un chevalet jusqu'à 7 tuiles
  ///
  /// Retourne les tuiles piochées
  List<Tile> refillRack(List<Tile> bag, List<Tile> currentRack) {
    const maxRackSize = 7;
    final tilesNeeded = maxRackSize - currentRack.length;

    if (tilesNeeded <= 0) return [];

    return drawTiles(bag, tilesNeeded);
  }

  /// Mélange le sac de tuiles
  List<Tile> shuffle(List<Tile> tiles) {
    final shuffled = List<Tile>.from(tiles);
    shuffled.shuffle(_random);
    return shuffled;
  }

  /// Échange des tuiles du chevalet avec le sac
  ///
  /// Retire les tuiles du chevalet, les remet dans le sac,
  /// mélange le sac, et pioche de nouvelles tuiles
  ///
  /// Retourne les nouvelles tuiles piochées
  List<Tile> exchangeTiles(
    List<Tile> bag,
    List<Tile> tilesToExchange,
  ) {
    if (tilesToExchange.isEmpty) return [];
    if (bag.length < tilesToExchange.length) {
      throw ArgumentError(
        'Pas assez de tuiles dans le sac pour l\'échange '
        '(${bag.length} disponibles, ${tilesToExchange.length} demandées)',
      );
    }

    // Piocher d'abord les nouvelles tuiles
    final newTiles = drawTiles(bag, tilesToExchange.length);

    // Remettre les anciennes tuiles dans le sac
    bag.addAll(tilesToExchange);

    // Mélanger le sac
    final shuffledBag = shuffle(bag);
    bag
      ..clear()
      ..addAll(shuffledBag);

    return newTiles;
  }

  /// Compte le nombre de tuiles restantes par lettre dans le sac
  Map<String, int> countRemainingTiles(List<Tile> bag) {
    final counts = <String, int>{};

    for (final tile in bag) {
      final letter = tile.isBlank ? 'JOKER' : tile.letter;
      counts[letter] = (counts[letter] ?? 0) + 1;
    }

    return counts;
  }

  /// Vérifie si le sac est vide
  bool isEmpty(List<Tile> bag) => bag.isEmpty;

  /// Retourne le nombre de tuiles restantes
  int remainingCount(List<Tile> bag) => bag.length;

  /// Crée une copie du sac (utile pour undo/redo ou simulation)
  List<Tile> copyBag(List<Tile> bag) {
    return bag.map((tile) => Tile(
      letter: tile.letter,
      value: tile.value,
      isBlank: tile.isBlank,
      assignedLetter: tile.assignedLetter,
    )).toList();
  }

  /// Retire des tuiles spécifiques du sac (utile pour tests ou setup)
  List<Tile> removeTiles(List<Tile> bag, List<Tile> tilesToRemove) {
    final removedTiles = <Tile>[];

    for (final tileToRemove in tilesToRemove) {
      final index = bag.indexWhere((tile) =>
          tile.letter == tileToRemove.letter &&
          tile.value == tileToRemove.value &&
          tile.isBlank == tileToRemove.isBlank);

      if (index != -1) {
        removedTiles.add(bag.removeAt(index));
      }
    }

    return removedTiles;
  }

  /// Ajoute des tuiles au sac
  void addTiles(List<Tile> bag, List<Tile> tilesToAdd) {
    bag.addAll(tilesToAdd);
  }

  /// Vérifie si le sac contient suffisamment de tuiles pour un échange
  bool canExchange(List<Tile> bag, int count) {
    return bag.length >= count;
  }

  /// Obtient une représentation textuelle du sac (pour debug)
  String debugBagContents(List<Tile> bag) {
    final counts = countRemainingTiles(bag);
    final sortedLetters = counts.keys.toList()..sort();

    final parts = sortedLetters.map((letter) {
      final count = counts[letter]!;
      return '$letter×$count';
    });

    return 'Sac (${bag.length} tuiles): ${parts.join(', ')}';
  }
}
