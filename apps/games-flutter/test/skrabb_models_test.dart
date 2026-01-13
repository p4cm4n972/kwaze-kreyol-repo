import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol_games/games/skrabb/models/tile.dart';
import 'package:kwaze_kreyol_games/games/skrabb/models/board.dart';
import 'package:kwaze_kreyol_games/games/skrabb/models/move.dart';
import 'package:kwaze_kreyol_games/games/skrabb/models/letter_distribution.dart';
import 'package:kwaze_kreyol_games/games/skrabb/models/skrabb_game.dart';

void main() {
  group('Tile', () {
    test('devrait créer une tuile normale', () {
      final tile = Tile(letter: 'A', value: 1);

      expect(tile.letter, 'A');
      expect(tile.value, 1);
      expect(tile.isBlank, false);
      expect(tile.assignedLetter, null);
      expect(tile.displayLetter, 'A');
    });

    test('devrait créer une tuile blanche (joker)', () {
      final tile = Tile.blank();

      expect(tile.letter, '');
      expect(tile.value, 0);
      expect(tile.isBlank, true);
      expect(tile.assignedLetter, null);
    });

    test('devrait assigner une lettre à une tuile blanche', () {
      final tile = Tile.blank().copyWith(assignedLetter: 'E');

      expect(tile.isBlank, true);
      expect(tile.assignedLetter, 'E');
      expect(tile.displayLetter, 'E');
    });

    test('devrait sérialiser et désérialiser en JSON', () {
      final original = Tile(letter: 'B', value: 3);
      final json = original.toJson();
      final restored = Tile.fromJson(json);

      expect(restored.letter, original.letter);
      expect(restored.value, original.value);
      expect(restored.isBlank, original.isBlank);
    });

    test('devrait sérialiser une tuile blanche avec lettre assignée', () {
      final original = Tile.blank().copyWith(assignedLetter: 'Z');
      final json = original.toJson();
      final restored = Tile.fromJson(json);

      expect(restored.isBlank, true);
      expect(restored.assignedLetter, 'Z');
      expect(restored.displayLetter, 'Z');
    });
  });

  group('BonusType', () {
    test('devrait avoir les bons multiplicateurs de lettres', () {
      expect(BonusType.doubleLetter.letterMultiplier, 2);
      expect(BonusType.tripleLetter.letterMultiplier, 3);
      expect(BonusType.none.letterMultiplier, 1);
    });

    test('devrait avoir les bons multiplicateurs de mots', () {
      expect(BonusType.doubleWord.wordMultiplier, 2);
      expect(BonusType.tripleWord.wordMultiplier, 3);
      expect(BonusType.center.wordMultiplier, 2);
      expect(BonusType.none.wordMultiplier, 1);
    });

    test('devrait avoir les bons noms courts', () {
      expect(BonusType.doubleLetter.shortName, 'LD'); // Lettre Double
      expect(BonusType.tripleLetter.shortName, 'LT'); // Lettre Triple
      expect(BonusType.doubleWord.shortName, 'MD');   // Mot Double
      expect(BonusType.tripleWord.shortName, 'MT');   // Mot Triple
      expect(BonusType.center.shortName, '★');
    });
  });

  group('BonusSquaresPattern', () {
    test('devrait placer la case centrale correctement', () {
      expect(BonusSquaresPattern.getBonusType(7, 7), BonusType.center);
    });

    test('devrait placer les coins en Triple Mot', () {
      expect(BonusSquaresPattern.getBonusType(0, 0), BonusType.tripleWord);
      expect(BonusSquaresPattern.getBonusType(0, 14), BonusType.tripleWord);
      expect(BonusSquaresPattern.getBonusType(14, 0), BonusType.tripleWord);
      expect(BonusSquaresPattern.getBonusType(14, 14), BonusType.tripleWord);
    });

    test('devrait placer les doubles mots sur les diagonales', () {
      expect(BonusSquaresPattern.getBonusType(1, 1), BonusType.doubleWord);
      expect(BonusSquaresPattern.getBonusType(2, 2), BonusType.doubleWord);
      expect(BonusSquaresPattern.getBonusType(13, 13), BonusType.doubleWord);
    });

    test('devrait avoir des cases normales', () {
      expect(BonusSquaresPattern.getBonusType(5, 5), BonusType.tripleLetter);
      expect(BonusSquaresPattern.getBonusType(6, 6), BonusType.doubleLetter);
      expect(BonusSquaresPattern.getBonusType(8, 10), BonusType.none);
    });
  });

  group('Board', () {
    test('devrait créer un plateau 15x15', () {
      final board = Board();

      expect(board.squares.length, 15);
      expect(board.squares[0].length, 15);
      expect(board.isEmpty, true);
    });

    test('devrait avoir les bonus correctement placés', () {
      final board = Board();

      expect(board.getSquare(7, 7).bonusType, BonusType.center);
      expect(board.getSquare(0, 0).bonusType, BonusType.tripleWord);
      expect(board.getSquare(1, 1).bonusType, BonusType.doubleWord);
    });

    test('devrait permettre de placer une tuile', () {
      final board = Board();
      final tile = Tile(letter: 'A', value: 1);

      board.placeTile(7, 7, tile);

      expect(board.getSquare(7, 7).placedTile, tile);
      expect(board.isEmpty, false);
    });

    test('devrait permettre de retirer une tuile', () {
      final board = Board();
      final tile = Tile(letter: 'A', value: 1);

      board.placeTile(7, 7, tile);
      final removed = board.removeTile(7, 7);

      expect(removed, tile);
      expect(board.getSquare(7, 7).placedTile, null);
      expect(board.isEmpty, true);
    });

    test('ne devrait pas permettre de retirer une tuile verrouillée', () {
      final board = Board();
      final tile = Tile(letter: 'A', value: 1);

      board.placeTile(7, 7, tile);
      board.lockAllTiles();

      expect(() => board.removeTile(7, 7), throwsStateError);
    });

    test('devrait verrouiller toutes les tuiles', () {
      final board = Board();

      board.placeTile(7, 7, Tile(letter: 'A', value: 1));
      board.placeTile(7, 8, Tile(letter: 'B', value: 3));

      board.lockAllTiles();

      expect(board.getSquare(7, 7).isLocked, true);
      expect(board.getSquare(7, 8).isLocked, true);
    });

    test('devrait sérialiser et désérialiser en JSON', () {
      final board = Board();
      board.placeTile(7, 7, Tile(letter: 'A', value: 1));

      final json = board.toJson();
      final restored = Board.fromJson(json);

      expect(restored.getSquare(7, 7).placedTile?.letter, 'A');
      expect(restored.getSquare(7, 7).bonusType, BonusType.center);
    });
  });

  group('Move', () {
    test('devrait créer un coup valide', () {
      final placedTiles = [
        PlacedTile(
          tile: Tile(letter: 'M', value: 2),
          row: 7,
          col: 7,
        ),
        PlacedTile(
          tile: Tile(letter: 'O', value: 1),
          row: 7,
          col: 8,
        ),
        PlacedTile(
          tile: Tile(letter: 'T', value: 1),
          row: 7,
          col: 9,
        ),
      ];

      final move = Move(
        placedTiles: placedTiles,
        formedWords: ['MOT'],
        score: 12,
      );

      expect(move.tileCount, 3);
      expect(move.formedWords.first, 'MOT');
      expect(move.score, 12);
      expect(move.isBingo, false);
    });

    test('devrait marquer un bingo', () {
      final placedTiles = List.generate(
        7,
        (i) => PlacedTile(
          tile: Tile(letter: 'A', value: 1),
          row: 7,
          col: 7 + i,
        ),
      );

      final move = Move(
        placedTiles: placedTiles,
        formedWords: ['AAAAAAA'],
        score: 57, // 7 pts + 50 bonus
        isBingo: true,
      );

      expect(move.tileCount, 7);
      expect(move.isBingo, true);
    });

    test('devrait sérialiser et désérialiser en JSON', () {
      final move = Move(
        placedTiles: [
          PlacedTile(
            tile: Tile(letter: 'X', value: 10),
            row: 5,
            col: 5,
          ),
        ],
        formedWords: ['AXE'],
        score: 20,
      );

      final json = move.toJson();
      final restored = Move.fromJson(json);

      expect(restored.placedTiles.length, 1);
      expect(restored.placedTiles.first.tile.letter, 'X');
      expect(restored.formedWords.first, 'AXE');
      expect(restored.score, 20);
    });
  });

  group('LetterDistribution', () {
    test('devrait créer la distribution créole', () {
      final distribution = LetterDistribution.creole();

      expect(distribution.counts.isNotEmpty, true);
      expect(distribution.values.isNotEmpty, true);
      expect(distribution.blankCount, 2);
    });

    test('devrait avoir des lettres très fréquentes avec valeur 1', () {
      final distribution = LetterDistribution.creole();

      // Lettres très fréquentes en créole (>8%): 1 pt
      expect(distribution.getLetterValue('A'), 1);  // 22.85%
      expect(distribution.getLetterValue('N'), 1);  // 11.09%
      expect(distribution.getLetterValue('T'), 1);  // 8.95%
      expect(distribution.getLetterValue('I'), 1);  // 8.59%
    });

    test('devrait avoir des lettres rares avec valeur élevée', () {
      final distribution = LetterDistribution.creole();

      // Lettres très rares en créole (<0.4%): 10 pts
      expect(distribution.getLetterValue('C'), 10);  // 0.36%
      expect(distribution.getLetterValue('H'), 10);  // 0.36%
      expect(distribution.getLetterValue('F'), 10);  // 0.36%
      expect(distribution.getLetterValue('À'), 10);  // 0.05%
    });

    test('devrait créer un sac de lettres complet', () {
      final distribution = LetterDistribution.creole();
      final tileBag = distribution.createTileBag();

      expect(tileBag.length, distribution.totalTilesWithBlanks);
    });

    test('le sac devrait contenir le bon nombre de blancs', () {
      final distribution = LetterDistribution.creole();
      final tileBag = distribution.createTileBag();

      final blankCount = tileBag.where((t) => t.isBlank).length;
      expect(blankCount, distribution.blankCount);
    });
  });

  group('SkrabbGame', () {
    test('devrait créer une nouvelle partie', () {
      final game = SkrabbGame.create(
        id: 'test-id',
        userId: 'user-123',
      );

      expect(game.id, 'test-id');
      expect(game.userId, 'user-123');
      expect(game.status, 'in_progress');
      expect(game.score, 0);
      expect(game.timeElapsed, 0);
      expect(game.rack.length, 7); // Chevalet initial de 7 tuiles
      expect(game.board.isEmpty, true);
      expect(game.moveHistory.isEmpty, true);
    });

    test('le sac devrait avoir moins de tuiles après création du chevalet', () {
      final distribution = LetterDistribution.creole();
      final totalTiles = distribution.totalTilesWithBlanks;

      final game = SkrabbGame.create(
        id: 'test-id',
        userId: 'user-123',
      );

      expect(game.tileBag.length, totalTiles - 7);
    });

    test('devrait sérialiser et désérialiser en JSON', () {
      final game = SkrabbGame.create(
        id: 'test-id',
        userId: 'user-123',
      );

      final json = game.toJson();
      final restored = SkrabbGame.fromJson(json);

      expect(restored.id, game.id);
      expect(restored.userId, game.userId);
      expect(restored.status, game.status);
      expect(restored.rack.length, game.rack.length);
      expect(restored.tileBag.length, game.tileBag.length);
    });

    test('devrait permettre de copier avec de nouvelles valeurs', () {
      final game = SkrabbGame.create(
        id: 'test-id',
        userId: 'user-123',
      );

      final updated = game.copyWith(
        score: 100,
        timeElapsed: 300,
      );

      expect(updated.score, 100);
      expect(updated.timeElapsed, 300);
      expect(updated.id, game.id); // Autres valeurs inchangées
    });

    test('devrait avoir les bonnes propriétés calculées', () {
      final game = SkrabbGame.create(
        id: 'test-id',
        userId: 'user-123',
      );

      expect(game.isInProgress, true);
      expect(game.isCompleted, false);
      expect(game.movesCount, 0);
      expect(game.tilesInRack, 7);
    });
  });
}
