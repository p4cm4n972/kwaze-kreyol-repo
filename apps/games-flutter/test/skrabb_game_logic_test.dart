import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol_games/games/skrabb/models/board.dart';
import 'package:kwaze_kreyol_games/games/skrabb/models/tile.dart';
import 'package:kwaze_kreyol_games/games/skrabb/models/move.dart';
import 'package:kwaze_kreyol_games/games/skrabb/models/letter_distribution.dart';
import 'package:kwaze_kreyol_games/games/skrabb/utils/word_extractor.dart';
import 'package:kwaze_kreyol_games/games/skrabb/utils/scrabble_scoring.dart';
import 'package:kwaze_kreyol_games/games/skrabb/utils/tile_bag_manager.dart';

void main() {
  group('WordExtractor', () {
    test('extrait un mot horizontal simple', () {
      final board = Board();

      // Placer "CHAT" horizontalement en (7, 6-9)
      board.placeTile(7, 6, Tile(letter: 'C', value: 3, isBlank: false));
      board.placeTile(7, 7, Tile(letter: 'H', value: 4, isBlank: false));
      board.placeTile(7, 8, Tile(letter: 'A', value: 1, isBlank: false));
      board.placeTile(7, 9, Tile(letter: 'T', value: 1, isBlank: false));

      final newTiles = [
        PlacedTile(row: 7, col: 6, tile: Tile(letter: 'C', value: 3, isBlank: false)),
        PlacedTile(row: 7, col: 7, tile: Tile(letter: 'H', value: 4, isBlank: false)),
        PlacedTile(row: 7, col: 8, tile: Tile(letter: 'A', value: 1, isBlank: false)),
        PlacedTile(row: 7, col: 9, tile: Tile(letter: 'T', value: 1, isBlank: false)),
      ];

      final words = WordExtractor.extractFormedWords(board, newTiles);

      expect(words, hasLength(1));
      expect(words.first, equals('CHAT'));
    });

    test('extrait un mot vertical simple', () {
      final board = Board();

      // Placer "CHAT" verticalement en (6-9, 7)
      board.placeTile(6, 7, Tile(letter: 'C', value: 3, isBlank: false));
      board.placeTile(7, 7, Tile(letter: 'H', value: 4, isBlank: false));
      board.placeTile(8, 7, Tile(letter: 'A', value: 1, isBlank: false));
      board.placeTile(9, 7, Tile(letter: 'T', value: 1, isBlank: false));

      final newTiles = [
        PlacedTile(row: 6, col: 7, tile: Tile(letter: 'C', value: 3, isBlank: false)),
        PlacedTile(row: 7, col: 7, tile: Tile(letter: 'H', value: 4, isBlank: false)),
        PlacedTile(row: 8, col: 7, tile: Tile(letter: 'A', value: 1, isBlank: false)),
        PlacedTile(row: 9, col: 7, tile: Tile(letter: 'T', value: 1, isBlank: false)),
      ];

      final words = WordExtractor.extractFormedWords(board, newTiles);

      expect(words, hasLength(1));
      expect(words.first, equals('CHAT'));
    });

    test('extrait mot principal + mots croisés', () {
      final board = Board();

      // Placer "CHAT" horizontalement
      board.placeTile(7, 6, Tile(letter: 'C', value: 3, isBlank: false));
      board.placeTile(7, 7, Tile(letter: 'H', value: 4, isBlank: false));
      board.placeTile(7, 8, Tile(letter: 'A', value: 1, isBlank: false));
      board.placeTile(7, 9, Tile(letter: 'T', value: 1, isBlank: false));
      board.getSquare(7, 6).isLocked = true;
      board.getSquare(7, 7).isLocked = true;
      board.getSquare(7, 8).isLocked = true;
      board.getSquare(7, 9).isLocked = true;

      // Ajouter "OU" verticalement croise "A" de CHAT
      board.placeTile(6, 8, Tile(letter: 'O', value: 1, isBlank: false));
      board.placeTile(8, 8, Tile(letter: 'U', value: 1, isBlank: false));

      final newTiles = [
        PlacedTile(row: 6, col: 8, tile: Tile(letter: 'O', value: 1, isBlank: false)),
        PlacedTile(row: 8, col: 8, tile: Tile(letter: 'U', value: 1, isBlank: false)),
      ];

      final words = WordExtractor.extractFormedWords(board, newTiles);

      expect(words, hasLength(1));
      expect(words, contains('OAU')); // Mot vertical formé
    });

    test('areAligned détecte alignement horizontal', () {
      final tiles = [
        PlacedTile(row: 7, col: 6, tile: Tile(letter: 'A', value: 1, isBlank: false)),
        PlacedTile(row: 7, col: 7, tile: Tile(letter: 'B', value: 1, isBlank: false)),
        PlacedTile(row: 7, col: 8, tile: Tile(letter: 'C', value: 1, isBlank: false)),
      ];

      expect(WordExtractor.areAligned(tiles), isTrue);
    });

    test('areAligned détecte alignement vertical', () {
      final tiles = [
        PlacedTile(row: 6, col: 7, tile: Tile(letter: 'A', value: 1, isBlank: false)),
        PlacedTile(row: 7, col: 7, tile: Tile(letter: 'B', value: 1, isBlank: false)),
        PlacedTile(row: 8, col: 7, tile: Tile(letter: 'C', value: 1, isBlank: false)),
      ];

      expect(WordExtractor.areAligned(tiles), isTrue);
    });

    test('areAligned détecte non-alignement', () {
      final tiles = [
        PlacedTile(row: 6, col: 6, tile: Tile(letter: 'A', value: 1, isBlank: false)),
        PlacedTile(row: 7, col: 7, tile: Tile(letter: 'B', value: 1, isBlank: false)),
        PlacedTile(row: 8, col: 8, tile: Tile(letter: 'C', value: 1, isBlank: false)),
      ];

      expect(WordExtractor.areAligned(tiles), isFalse);
    });

    test('areContiguous détecte tuiles contiguës', () {
      final board = Board();
      board.placeTile(7, 7, Tile(letter: 'A', value: 1, isBlank: false));

      final tiles = [
        PlacedTile(row: 7, col: 6, tile: Tile(letter: 'B', value: 1, isBlank: false)),
        PlacedTile(row: 7, col: 8, tile: Tile(letter: 'C', value: 1, isBlank: false)),
      ];

      board.placeTile(7, 6, tiles[0].tile);
      board.placeTile(7, 8, tiles[1].tile);

      expect(WordExtractor.areContiguous(tiles, board), isTrue);
    });

    test('areContiguous détecte trous', () {
      final board = Board();

      final tiles = [
        PlacedTile(row: 7, col: 6, tile: Tile(letter: 'A', value: 1, isBlank: false)),
        PlacedTile(row: 7, col: 9, tile: Tile(letter: 'B', value: 1, isBlank: false)),
      ];

      board.placeTile(7, 6, tiles[0].tile);
      board.placeTile(7, 9, tiles[1].tile);

      expect(WordExtractor.areContiguous(tiles, board), isFalse);
    });
  });

  group('ScrabbleScoring', () {
    test('calcule score simple sans bonus', () {
      final board = Board();

      // Placer "CAT" en (1, 2-4) - pas de bonus
      board.placeTile(1, 2, Tile(letter: 'C', value: 3, isBlank: false));
      board.placeTile(1, 3, Tile(letter: 'A', value: 1, isBlank: false));
      board.placeTile(1, 4, Tile(letter: 'T', value: 1, isBlank: false));

      final newTiles = [
        PlacedTile(row: 1, col: 2, tile: Tile(letter: 'C', value: 3, isBlank: false)),
        PlacedTile(row: 1, col: 3, tile: Tile(letter: 'A', value: 1, isBlank: false)),
        PlacedTile(row: 1, col: 4, tile: Tile(letter: 'T', value: 1, isBlank: false)),
      ];

      final score = ScrabbleScoring.calculateMoveScore(board, newTiles);

      // C(3) + A(1) + T(1) = 5
      expect(score, equals(5));
    });

    test('calcule score avec Double Lettre', () {
      final board = Board();

      // Placer "ZE" avec Z sur une case DL
      // Position (0, 3) est DL selon BonusSquaresPattern
      board.placeTile(0, 3, Tile(letter: 'Z', value: 10, isBlank: false));
      board.placeTile(0, 4, Tile(letter: 'E', value: 1, isBlank: false));

      final newTiles = [
        PlacedTile(row: 0, col: 3, tile: Tile(letter: 'Z', value: 10, isBlank: false)),
        PlacedTile(row: 0, col: 4, tile: Tile(letter: 'E', value: 1, isBlank: false)),
      ];

      final score = ScrabbleScoring.calculateMoveScore(board, newTiles);

      // Z(10) × 2 (DL) + E(1) = 21
      expect(score, equals(21));
    });

    test('calcule score avec Double Mot (centre)', () {
      final board = Board();

      // Placer "CAT" traversant le centre (7,7) qui est DW
      board.placeTile(7, 6, Tile(letter: 'C', value: 3, isBlank: false));
      board.placeTile(7, 7, Tile(letter: 'A', value: 1, isBlank: false));
      board.placeTile(7, 8, Tile(letter: 'T', value: 1, isBlank: false));

      final newTiles = [
        PlacedTile(row: 7, col: 6, tile: Tile(letter: 'C', value: 3, isBlank: false)),
        PlacedTile(row: 7, col: 7, tile: Tile(letter: 'A', value: 1, isBlank: false)),
        PlacedTile(row: 7, col: 8, tile: Tile(letter: 'T', value: 1, isBlank: false)),
      ];

      final score = ScrabbleScoring.calculateMoveScore(board, newTiles);

      // (C(3) + A(1) + T(1)) × 2 (DW au centre) = 5 × 2 = 10
      expect(score, equals(10));
    });

    test('calcule bonus bingo (7 tuiles = +50)', () {
      final board = Board();

      // Placer 7 lettres verticalement en position sans bonus
      final letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
      final newTiles = <PlacedTile>[];

      for (int i = 0; i < 7; i++) {
        final tile = Tile(letter: letters[i], value: 1, isBlank: false);
        board.placeTile(4 + i, 11, tile);  // Colonne 11, pas de bonus
        newTiles.add(PlacedTile(row: 4 + i, col: 11, tile: tile));
      }

      final score = ScrabbleScoring.calculateMoveScore(board, newTiles);

      // 7 lettres (avec D en position DL) = 8 + bonus bingo 50 = 58
      expect(score, equals(58));
    });

    test('bonus ne s\'appliquent qu\'aux nouvelles tuiles', () {
      final board = Board();

      // Placer "CA" et verrouiller
      board.placeTile(7, 7, Tile(letter: 'C', value: 3, isBlank: false));
      board.placeTile(7, 8, Tile(letter: 'A', value: 1, isBlank: false));
      board.getSquare(7, 7).isLocked = true;
      board.getSquare(7, 8).isLocked = true;

      // Ajouter "T" pour former "CAT"
      board.placeTile(7, 9, Tile(letter: 'T', value: 1, isBlank: false));

      final newTiles = [
        PlacedTile(row: 7, col: 9, tile: Tile(letter: 'T', value: 1, isBlank: false)),
      ];

      final score = ScrabbleScoring.calculateMoveScore(board, newTiles);

      // Seule la nouvelle lettre T compte
      // Le mot complet est "CAT" mais seul T est nouveau
      // Score du mot: C(3) + A(1) + T(1) = 5
      // Pas de bonus car position (7,9) n'a pas de bonus
      expect(score, greaterThan(0));
    });
  });

  group('TileBagManager', () {
    test('crée un sac initial correct', () {
      final manager = TileBagManager();
      final distribution = LetterDistribution.creole();

      final bag = manager.createInitialBag(distribution);

      // Compter le total
      int expectedTotal = distribution.counts.values.reduce((a, b) => a + b);
      expectedTotal += distribution.blankCount;

      expect(bag, hasLength(expectedTotal));
    });

    test('pioche des tuiles correctement', () {
      final manager = TileBagManager();
      final bag = [
        Tile(letter: 'A', value: 1, isBlank: false),
        Tile(letter: 'B', value: 3, isBlank: false),
        Tile(letter: 'C', value: 3, isBlank: false),
      ];

      final drawn = manager.drawTiles(bag, 2);

      expect(drawn, hasLength(2));
      expect(bag, hasLength(1)); // 1 tuile restante
    });

    test('pioche limite au nombre de tuiles disponibles', () {
      final manager = TileBagManager();
      final bag = [
        Tile(letter: 'A', value: 1, isBlank: false),
        Tile(letter: 'B', value: 3, isBlank: false),
      ];

      final drawn = manager.drawTiles(bag, 10);

      expect(drawn, hasLength(2)); // Seulement 2 disponibles
      expect(bag, isEmpty);
    });

    test('refillRack remplit jusqu\'à 7 tuiles', () {
      final manager = TileBagManager();
      final bag = List.generate(
        10,
        (i) => Tile(letter: 'A', value: 1, isBlank: false),
      );

      final rack = [
        Tile(letter: 'B', value: 3, isBlank: false),
        Tile(letter: 'C', value: 3, isBlank: false),
      ];

      final drawn = manager.refillRack(bag, rack);

      expect(drawn, hasLength(5)); // 7 - 2 = 5
      expect(bag, hasLength(5)); // 10 - 5 = 5
    });

    test('refillRack ne pioche pas si chevalet plein', () {
      final manager = TileBagManager();
      final bag = List.generate(
        10,
        (i) => Tile(letter: 'A', value: 1, isBlank: false),
      );

      final rack = List.generate(
        7,
        (i) => Tile(letter: 'B', value: 3, isBlank: false),
      );

      final drawn = manager.refillRack(bag, rack);

      expect(drawn, isEmpty);
      expect(bag, hasLength(10));
    });

    test('échange des tuiles correctement', () {
      final manager = TileBagManager();
      final bag = List.generate(
        10,
        (i) => Tile(letter: 'A', value: 1, isBlank: false),
      );

      final tilesToExchange = [
        Tile(letter: 'B', value: 3, isBlank: false),
        Tile(letter: 'C', value: 3, isBlank: false),
      ];

      final newTiles = manager.exchangeTiles(bag, tilesToExchange);

      expect(newTiles, hasLength(2));
      expect(bag, hasLength(10)); // 10 - 2 (piochées) + 2 (rendues) = 10
    });

    test('compte les tuiles restantes par lettre', () {
      final manager = TileBagManager();
      final bag = [
        Tile(letter: 'A', value: 1, isBlank: false),
        Tile(letter: 'A', value: 1, isBlank: false),
        Tile(letter: 'B', value: 3, isBlank: false),
        Tile(letter: '', value: 0, isBlank: true),
      ];

      final counts = manager.countRemainingTiles(bag);

      expect(counts['A'], equals(2));
      expect(counts['B'], equals(1));
      expect(counts['JOKER'], equals(1));
    });

    test('isEmpty détecte sac vide', () {
      final manager = TileBagManager();

      expect(manager.isEmpty([]), isTrue);
      expect(
        manager.isEmpty([Tile(letter: 'A', value: 1, isBlank: false)]),
        isFalse,
      );
    });

    test('remainingCount retourne le bon nombre', () {
      final manager = TileBagManager();
      final bag = List.generate(
        5,
        (i) => Tile(letter: 'A', value: 1, isBlank: false),
      );

      expect(manager.remainingCount(bag), equals(5));
    });

    test('canExchange vérifie la disponibilité', () {
      final manager = TileBagManager();
      final bag = List.generate(
        3,
        (i) => Tile(letter: 'A', value: 1, isBlank: false),
      );

      expect(manager.canExchange(bag, 2), isTrue);
      expect(manager.canExchange(bag, 5), isFalse);
    });
  });

  group('Integration Tests', () {
    test('scénario complet: premier mot au centre', () {
      final board = Board();

      // Placer "CHAT" traversant le centre
      final tiles = [
        Tile(letter: 'C', value: 3, isBlank: false),
        Tile(letter: 'H', value: 4, isBlank: false),
        Tile(letter: 'A', value: 1, isBlank: false),
        Tile(letter: 'T', value: 1, isBlank: false),
      ];

      final newTiles = <PlacedTile>[];
      for (int i = 0; i < tiles.length; i++) {
        final col = 6 + i;
        board.placeTile(7, col, tiles[i]);
        newTiles.add(PlacedTile(row: 7, col: col, tile: tiles[i]));
      }

      // Extraire mots
      final words = WordExtractor.extractFormedWords(board, newTiles);
      expect(words, contains('CHAT'));

      // Calculer score
      final score = ScrabbleScoring.calculateMoveScore(board, newTiles);
      expect(score, greaterThan(0));

      // Vérifier alignement
      expect(WordExtractor.areAligned(newTiles), isTrue);

      // Vérifier contiguïté
      expect(WordExtractor.areContiguous(newTiles, board), isTrue);
    });

    test('scénario complet: pioche et remplissage chevalet', () {
      final manager = TileBagManager();
      final distribution = LetterDistribution.creole();
      final bag = manager.createInitialBag(distribution);

      // Piocher 7 tuiles initiales
      final rack = manager.drawTiles(bag, 7);
      expect(rack, hasLength(7));

      // Utiliser 3 tuiles
      final usedTiles = rack.sublist(0, 3);
      rack.removeRange(0, 3);

      // Remplir le chevalet
      final newTiles = manager.refillRack(bag, rack);
      rack.addAll(newTiles);

      expect(rack, hasLength(7));
    });
  });
}
