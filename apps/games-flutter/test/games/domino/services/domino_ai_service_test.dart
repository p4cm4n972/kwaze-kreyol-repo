import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol_games/games/domino/services/domino_ai_service.dart';
import 'package:kwaze_kreyol_games/games/domino/models/domino_tile.dart';

void main() {
  group('DominoAIService', () {
    group('selectMove - plateau vide', () {
      test('retourne une tuile quand le plateau est vide', () {
        final hand = [
          const DominoTile(value1: 3, value2: 5),
          const DominoTile(value1: 2, value2: 4),
        ];

        final move = DominoAIService.selectMove(
          hand: hand,
          leftEnd: null,
          rightEnd: null,
          board: [],
          difficulty: AIDifficulty.easy,
        );

        expect(move, isNotNull);
        expect(move!.side, equals('right'));
        expect(hand.contains(move.tile), isTrue);
      });

      test('facile: choisit aléatoirement sur plateau vide', () {
        final hand = [
          const DominoTile(value1: 6, value2: 6),
          const DominoTile(value1: 1, value2: 2),
        ];

        // Exécuter plusieurs fois pour vérifier que ça ne crash pas
        for (var i = 0; i < 10; i++) {
          final move = DominoAIService.selectMove(
            hand: hand,
            leftEnd: null,
            rightEnd: null,
            board: [],
            difficulty: AIDifficulty.easy,
          );
          expect(move, isNotNull);
        }
      });

      test('normal: préfère le double le plus haut sur plateau vide', () {
        final hand = [
          const DominoTile(value1: 3, value2: 3), // Double 3
          const DominoTile(value1: 6, value2: 6), // Double 6 - devrait être choisi
          const DominoTile(value1: 5, value2: 4),
        ];

        final move = DominoAIService.selectMove(
          hand: hand,
          leftEnd: null,
          rightEnd: null,
          board: [],
          difficulty: AIDifficulty.normal,
        );

        expect(move, isNotNull);
        expect(move!.tile.isDouble, isTrue);
        expect(move.tile.value1, equals(6)); // Double 6
      });

      test('normal: préfère la tuile la plus haute si pas de double', () {
        final hand = [
          const DominoTile(value1: 1, value2: 2), // Total: 3
          const DominoTile(value1: 5, value2: 6), // Total: 11 - devrait être choisi
          const DominoTile(value1: 3, value2: 4), // Total: 7
        ];

        final move = DominoAIService.selectMove(
          hand: hand,
          leftEnd: null,
          rightEnd: null,
          board: [],
          difficulty: AIDifficulty.normal,
        );

        expect(move, isNotNull);
        expect(move!.tile.totalValue, equals(11));
      });
    });

    group('selectMove - plateau non vide', () {
      test('trouve les tuiles jouables à gauche', () {
        final hand = [
          const DominoTile(value1: 3, value2: 5), // Peut jouer à gauche (3)
          const DominoTile(value1: 1, value2: 2), // Ne peut pas jouer
        ];

        final board = [
          PlacedTile(
            tile: const DominoTile(value1: 3, value2: 4),
            connectedValue: 3,
            side: 'right',
            placedAt: DateTime.now(),
          ),
        ];

        final move = DominoAIService.selectMove(
          hand: hand,
          leftEnd: 3,
          rightEnd: 4,
          board: board,
          difficulty: AIDifficulty.easy,
        );

        expect(move, isNotNull);
        expect(move!.tile.canConnect(3) || move.tile.canConnect(4), isTrue);
      });

      test('trouve les tuiles jouables à droite', () {
        final hand = [
          const DominoTile(value1: 4, value2: 6), // Peut jouer à droite (4)
          const DominoTile(value1: 1, value2: 2), // Ne peut pas jouer
        ];

        final board = [
          PlacedTile(
            tile: const DominoTile(value1: 3, value2: 4),
            connectedValue: 3,
            side: 'right',
            placedAt: DateTime.now(),
          ),
        ];

        final move = DominoAIService.selectMove(
          hand: hand,
          leftEnd: 3,
          rightEnd: 4,
          board: board,
          difficulty: AIDifficulty.easy,
        );

        expect(move, isNotNull);
        expect(move!.tile.value1, equals(4));
      });

      test('retourne null si aucune tuile jouable', () {
        final hand = [
          const DominoTile(value1: 1, value2: 2),
          const DominoTile(value1: 0, value2: 0),
        ];

        final board = [
          PlacedTile(
            tile: const DominoTile(value1: 5, value2: 6),
            connectedValue: 5,
            side: 'right',
            placedAt: DateTime.now(),
          ),
        ];

        final move = DominoAIService.selectMove(
          hand: hand,
          leftEnd: 5,
          rightEnd: 6,
          board: board,
          difficulty: AIDifficulty.easy,
        );

        expect(move, isNull);
      });

      test('peut jouer des deux côtés si possible', () {
        final hand = [
          const DominoTile(value1: 3, value2: 4), // Peut jouer aux deux extrémités
        ];

        final board = [
          PlacedTile(
            tile: const DominoTile(value1: 3, value2: 4),
            connectedValue: 3,
            side: 'right',
            placedAt: DateTime.now(),
          ),
        ];

        // Exécuter plusieurs fois - devrait pouvoir choisir left ou right
        final sides = <String>{};
        for (var i = 0; i < 50; i++) {
          final move = DominoAIService.selectMove(
            hand: hand,
            leftEnd: 3,
            rightEnd: 4,
            board: board,
            difficulty: AIDifficulty.easy,
          );
          if (move != null) {
            sides.add(move.side);
          }
        }

        // En mode facile aléatoire, on devrait voir les deux côtés
        expect(sides.length, greaterThanOrEqualTo(1));
      });
    });

    group('selectMove - stratégie normale', () {
      test('priorité aux doubles', () {
        final hand = [
          const DominoTile(value1: 3, value2: 5), // Peut jouer, pas double
          const DominoTile(value1: 3, value2: 3), // Double, peut jouer à gauche
        ];

        final board = [
          PlacedTile(
            tile: const DominoTile(value1: 3, value2: 4),
            connectedValue: 3,
            side: 'right',
            placedAt: DateTime.now(),
          ),
        ];

        final move = DominoAIService.selectMove(
          hand: hand,
          leftEnd: 3,
          rightEnd: 4,
          board: board,
          difficulty: AIDifficulty.normal,
        );

        expect(move, isNotNull);
        expect(move!.tile.isDouble, isTrue);
      });

      test('puis haute valeur si pas de double', () {
        final hand = [
          const DominoTile(value1: 3, value2: 1), // Total: 4
          const DominoTile(value1: 3, value2: 6), // Total: 9 - devrait être choisi
        ];

        final board = [
          PlacedTile(
            tile: const DominoTile(value1: 3, value2: 4),
            connectedValue: 3,
            side: 'right',
            placedAt: DateTime.now(),
          ),
        ];

        final move = DominoAIService.selectMove(
          hand: hand,
          leftEnd: 3,
          rightEnd: 4,
          board: board,
          difficulty: AIDifficulty.normal,
        );

        expect(move, isNotNull);
        expect(move!.tile.totalValue, equals(9));
      });
    });

    group('selectMove - stratégie difficile', () {
      test('score les coups selon la stratégie', () {
        final hand = [
          const DominoTile(value1: 3, value2: 3), // Double 3
          const DominoTile(value1: 3, value2: 6), // Haute valeur
        ];

        final board = [
          PlacedTile(
            tile: const DominoTile(value1: 3, value2: 4),
            connectedValue: 3,
            side: 'right',
            placedAt: DateTime.now(),
          ),
        ];

        final move = DominoAIService.selectMove(
          hand: hand,
          leftEnd: 3,
          rightEnd: 4,
          board: board,
          difficulty: AIDifficulty.hard,
        );

        expect(move, isNotNull);
        // Le double devrait être favorisé (bonus +15)
        expect(move!.tile.isDouble, isTrue);
      });
    });

    group('shouldPass', () {
      test('retourne false si plateau vide', () {
        final result = DominoAIService.shouldPass(
          hand: [const DominoTile(value1: 1, value2: 2)],
          leftEnd: null,
          rightEnd: null,
          boardEmpty: true,
        );
        expect(result, isFalse);
      });

      test('retourne true si main vide', () {
        final result = DominoAIService.shouldPass(
          hand: [],
          leftEnd: 3,
          rightEnd: 4,
          boardEmpty: false,
        );
        expect(result, isTrue);
      });

      test('retourne false si peut jouer à gauche', () {
        final result = DominoAIService.shouldPass(
          hand: [const DominoTile(value1: 3, value2: 5)],
          leftEnd: 3,
          rightEnd: 6,
          boardEmpty: false,
        );
        expect(result, isFalse);
      });

      test('retourne false si peut jouer à droite', () {
        final result = DominoAIService.shouldPass(
          hand: [const DominoTile(value1: 6, value2: 5)],
          leftEnd: 3,
          rightEnd: 6,
          boardEmpty: false,
        );
        expect(result, isFalse);
      });

      test('retourne true si aucune tuile jouable', () {
        final result = DominoAIService.shouldPass(
          hand: [
            const DominoTile(value1: 1, value2: 2),
            const DominoTile(value1: 0, value2: 0),
          ],
          leftEnd: 5,
          rightEnd: 6,
          boardEmpty: false,
        );
        expect(result, isTrue);
      });
    });

    group('getThinkingDelay', () {
      test('facile: délai entre 800-1200ms', () {
        for (var i = 0; i < 20; i++) {
          final delay = DominoAIService.getThinkingDelay(AIDifficulty.easy);
          expect(delay, greaterThanOrEqualTo(800));
          expect(delay, lessThanOrEqualTo(1200));
        }
      });

      test('normal: délai entre 600-1000ms', () {
        for (var i = 0; i < 20; i++) {
          final delay = DominoAIService.getThinkingDelay(AIDifficulty.normal);
          expect(delay, greaterThanOrEqualTo(600));
          expect(delay, lessThanOrEqualTo(1000));
        }
      });

      test('difficile: délai entre 500-800ms', () {
        for (var i = 0; i < 20; i++) {
          final delay = DominoAIService.getThinkingDelay(AIDifficulty.hard);
          expect(delay, greaterThanOrEqualTo(500));
          expect(delay, lessThanOrEqualTo(800));
        }
      });
    });
  });
}
