import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol_games/games/domino/models/domino_tile.dart';

void main() {
  group('DominoTile', () {
    test('should create tile with correct values', () {
      final tile = DominoTile(value1: 3, value2: 5);
      expect(tile.value1, 3);
      expect(tile.value2, 5);
      expect(tile.id, '3-5');
    });

    test('should identify double tiles', () {
      final doubleTile = DominoTile(value1: 4, value2: 4);
      final normalTile = DominoTile(value1: 2, value2: 5);

      expect(doubleTile.isDouble, true);
      expect(normalTile.isDouble, false);
    });

    test('should calculate total value correctly', () {
      final tile1 = DominoTile(value1: 3, value2: 5);
      final tile2 = DominoTile(value1: 6, value2: 6);
      final tile3 = DominoTile(value1: 0, value2: 1);

      expect(tile1.totalValue, 8);
      expect(tile2.totalValue, 12);
      expect(tile3.totalValue, 1);
    });

    test('should check if tile can connect to value', () {
      final tile = DominoTile(value1: 3, value2: 5);

      expect(tile.canConnect(3), true);
      expect(tile.canConnect(5), true);
      expect(tile.canConnect(2), false);
      expect(tile.canConnect(6), false);
    });

    test('should create full set of 28 tiles', () {
      final fullSet = DominoTile.createFullSet();

      expect(fullSet.length, 28);

      // Vérifier qu'il y a exactement 7 doubles (0-0 à 6-6)
      final doubles = fullSet.where((t) => t.isDouble).toList();
      expect(doubles.length, 7);

      // Vérifier qu'il n'y a pas de doublons
      final ids = fullSet.map((t) => t.id).toSet();
      expect(ids.length, 28);

      // Vérifier que toutes les valeurs sont entre 0 et 6
      for (final tile in fullSet) {
        expect(tile.value1, greaterThanOrEqualTo(0));
        expect(tile.value1, lessThanOrEqualTo(6));
        expect(tile.value2, greaterThanOrEqualTo(0));
        expect(tile.value2, lessThanOrEqualTo(6));
      }
    });

    test('should serialize to JSON correctly', () {
      final tile = DominoTile(value1: 3, value2: 5);
      final json = tile.toJson();

      expect(json['value1'], 3);
      expect(json['value2'], 5);
      // Note: id is not in JSON, it's computed from value1-value2
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'value1': 4,
        'value2': 6,
      };

      final tile = DominoTile.fromJson(json);

      expect(tile.value1, 4);
      expect(tile.value2, 6);
      expect(tile.id, '4-6'); // id is computed
    });

    test('should have correct equality', () {
      final tile1 = DominoTile(value1: 3, value2: 5);
      final tile2 = DominoTile(value1: 3, value2: 5);
      final tile3 = DominoTile(value1: 5, value2: 3);

      expect(tile1.id, tile2.id);
      expect(tile1.id, isNot(tile3.id));
    });
  });
}
