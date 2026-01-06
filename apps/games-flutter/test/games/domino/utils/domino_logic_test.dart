import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol_games/games/domino/models/domino_tile.dart';
import 'package:kwaze_kreyol_games/games/domino/utils/domino_logic.dart';

void main() {
  group('DominoLogic', () {
    group('createFullSet', () {
      test('should create 28 unique tiles', () {
        final tiles = DominoLogic.createFullSet();
        expect(tiles.length, 28);

        final ids = tiles.map((t) => t.id).toSet();
        expect(ids.length, 28);
      });

      test('should include all doubles from 0-0 to 6-6', () {
        final tiles = DominoLogic.createFullSet();
        final doubles = tiles.where((t) => t.isDouble).toList();

        expect(doubles.length, 7);
        expect(doubles.any((t) => t.id == '0-0'), true);
        expect(doubles.any((t) => t.id == '1-1'), true);
        expect(doubles.any((t) => t.id == '2-2'), true);
        expect(doubles.any((t) => t.id == '3-3'), true);
        expect(doubles.any((t) => t.id == '4-4'), true);
        expect(doubles.any((t) => t.id == '5-5'), true);
        expect(doubles.any((t) => t.id == '6-6'), true);
      });
    });

    group('distributeTiles', () {
      test('should distribute 7 tiles to each of 3 players', () {
        final playerIds = ['player1', 'player2', 'player3'];
        final hands = DominoLogic.distributeTiles(playerIds);

        expect(hands.length, 3);
        expect(hands['player1']!.length, 7);
        expect(hands['player2']!.length, 7);
        expect(hands['player3']!.length, 7);
      });

      test('should distribute unique tiles (no duplicates)', () {
        final playerIds = ['player1', 'player2', 'player3'];
        final hands = DominoLogic.distributeTiles(playerIds);

        final allTiles = <String>[];
        hands.forEach((playerId, tiles) {
          allTiles.addAll(tiles.map((t) => t.id));
        });

        final uniqueTiles = allTiles.toSet();
        expect(uniqueTiles.length, 21); // 3 players * 7 tiles
      });

      test('should leave 7 tiles undistributed', () {
        final playerIds = ['player1', 'player2', 'player3'];
        final hands = DominoLogic.distributeTiles(playerIds);

        final distributedTiles = <String>[];
        hands.forEach((playerId, tiles) {
          distributedTiles.addAll(tiles.map((t) => t.id));
        });

        final fullSet = DominoLogic.createFullSet();
        final undistributedCount = fullSet.length - distributedTiles.length;

        expect(undistributedCount, 7);
      });
    });

    group('determineStartingPlayer', () {
      test('should return player with highest double', () {
        final hands = {
          'player1': [
            DominoTile(value1: 2, value2: 3),
            DominoTile(value1: 4, value2: 4), // double-4
          ],
          'player2': [
            DominoTile(value1: 1, value2: 2),
            DominoTile(value1: 6, value2: 6), // double-6 (highest)
          ],
          'player3': [
            DominoTile(value1: 0, value2: 5),
            DominoTile(value1: 3, value2: 3), // double-3
          ],
        };

        final starter = DominoLogic.determineStartingPlayer(hands);
        expect(starter, 'player2');
      });

      test('should return previous winner if no doubles', () {
        final hands = {
          'player1': [
            DominoTile(value1: 2, value2: 3),
            DominoTile(value1: 4, value2: 5),
          ],
          'player2': [
            DominoTile(value1: 1, value2: 2),
            DominoTile(value1: 0, value2: 6),
          ],
          'player3': [
            DominoTile(value1: 0, value2: 5),
            DominoTile(value1: 1, value2: 3),
          ],
        };

        final starter = DominoLogic.determineStartingPlayer(hands, previousWinnerId: 'player3');
        expect(starter, 'player3');
      });

      test('should return first player if no doubles and no previous winner', () {
        final hands = {
          'player1': [
            DominoTile(value1: 2, value2: 3),
          ],
          'player2': [
            DominoTile(value1: 1, value2: 2),
          ],
          'player3': [
            DominoTile(value1: 0, value2: 5),
          ],
        };

        final starter = DominoLogic.determineStartingPlayer(hands);
        expect(starter, 'player1');
      });
    });

    group('canPlaceTile', () {
      test('should return true if tile matches left end', () {
        final tile = DominoTile(value1: 3, value2: 5);
        expect(DominoLogic.canPlaceTile(tile, 3, 6), true);
      });

      test('should return true if tile matches right end', () {
        final tile = DominoTile(value1: 3, value2: 5);
        expect(DominoLogic.canPlaceTile(tile, 2, 5), true);
      });

      test('should return true if tile matches both ends', () {
        final tile = DominoTile(value1: 3, value2: 5);
        expect(DominoLogic.canPlaceTile(tile, 3, 5), true);
      });

      test('should return false if tile matches neither end', () {
        final tile = DominoTile(value1: 3, value2: 5);
        expect(DominoLogic.canPlaceTile(tile, 2, 6), false);
      });

      test('should return true if board is empty (no ends)', () {
        final tile = DominoTile(value1: 3, value2: 5);
        expect(DominoLogic.canPlaceTile(tile, null, null), true);
      });
    });

    group('canPlayerPlay', () {
      test('should return true if player has playable tile', () {
        final hand = [
          DominoTile(value1: 3, value2: 5),
          DominoTile(value1: 2, value2: 4),
        ];

        expect(DominoLogic.canPlayerPlay(hand, 3, 6), true);
      });

      test('should return false if player has no playable tiles', () {
        final hand = [
          DominoTile(value1: 3, value2: 5),
          DominoTile(value1: 2, value2: 4),
        ];

        expect(DominoLogic.canPlayerPlay(hand, 0, 1), false);
      });

      test('should return true if board is empty', () {
        final hand = [
          DominoTile(value1: 3, value2: 5),
        ];

        expect(DominoLogic.canPlayerPlay(hand, null, null), true);
      });
    });

    group('getPlayableTiles', () {
      test('should return tiles that match either end', () {
        final hand = [
          DominoTile(value1: 3, value2: 5),
          DominoTile(value1: 2, value2: 4),
          DominoTile(value1: 1, value2: 6),
        ];

        final playable = DominoLogic.getPlayableTiles(hand, 3, 6);

        expect(playable.length, 2);
        expect(playable.any((t) => t.id == '3-5'), true); // matches left (3)
        expect(playable.any((t) => t.id == '1-6'), true); // matches right (6)
      });

      test('should return all tiles if board is empty', () {
        final hand = [
          DominoTile(value1: 3, value2: 5),
          DominoTile(value1: 2, value2: 4),
        ];

        final playable = DominoLogic.getPlayableTiles(hand, null, null);
        expect(playable.length, 2);
      });

      test('should return empty list if no tiles match', () {
        final hand = [
          DominoTile(value1: 3, value2: 5),
          DominoTile(value1: 2, value2: 4),
        ];

        final playable = DominoLogic.getPlayableTiles(hand, 0, 1);
        expect(playable.length, 0);
      });
    });

    group('isGameBlocked', () {
      test('should return true if all 3 players have passed', () {
        expect(DominoLogic.isGameBlocked(['p1', 'p2', 'p3'], 3), true);
      });

      test('should return false if less than 3 players have passed', () {
        expect(DominoLogic.isGameBlocked(['p1', 'p2'], 3), false);
        expect(DominoLogic.isGameBlocked(['p1'], 3), false);
        expect(DominoLogic.isGameBlocked([], 3), false);
      });

      test('should return false if passed list is empty', () {
        expect(DominoLogic.isGameBlocked([], 3), false);
      });
    });

    group('determineBlockedWinner', () {
      test('should return player with lowest points', () {
        final hands = {
          'player1': [
            DominoTile(value1: 3, value2: 5), // 8 points
            DominoTile(value1: 2, value2: 4), // 6 points
          ], // Total: 14
          'player2': [
            DominoTile(value1: 1, value2: 2), // 3 points
            DominoTile(value1: 0, value2: 1), // 1 point
          ], // Total: 4 (lowest)
          'player3': [
            DominoTile(value1: 6, value2: 6), // 12 points
          ], // Total: 12
        };

        final winner = DominoLogic.determineBlockedWinner(hands);
        expect(winner, 'player2');
      });

      test('should handle player with empty hand', () {
        final hands = {
          'player1': [
            DominoTile(value1: 3, value2: 5),
          ],
          'player2': <DominoTile>[], // Empty hand = 0 points (wins)
          'player3': [
            DominoTile(value1: 6, value2: 6),
          ],
        };

        final winner = DominoLogic.determineBlockedWinner(hands);
        expect(winner, 'player2');
      });
    });
  });
}
