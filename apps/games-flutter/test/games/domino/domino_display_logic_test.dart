import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol_games/games/domino/models/domino_tile.dart';

/// Tests pour valider la logique d'affichage des dominos
///
/// RÈGLES:
/// - Les dominos sont stockés de GAUCHE à DROITE dans le board
/// - side='right' = domino ajouté à droite = connexion par sa GAUCHE
/// - side='left' = domino inséré à gauche = connexion par sa DROITE
///
/// Pour un domino horizontal: [value1 | value2]
/// - value1 est à GAUCHE
/// - value2 est à DROITE

void main() {
  group('Logique de flip des dominos', () {

    test('Premier domino (6-4) avec side=right - pas de flip si value1=connectedValue', () {
      // Premier domino [6|4] posé, connectedValue=6, side='right'
      final tile = DominoTile(value1: 6, value2: 4);
      final placedTile = PlacedTile(
        tile: tile,
        connectedValue: 6,  // value1
        side: 'right',
        placedAt: DateTime.now(),
      );

      final display = getDisplayValues(placedTile);

      // Pas de flip car value1 == connectedValue
      expect(display.$1, 6, reason: 'displayValue1 (gauche) doit être 6');
      expect(display.$2, 4, reason: 'displayValue2 (droite) doit être 4');
    });

    test('Domino (4-3) ajouté à droite du [6|4] - connexion par 4', () {
      // Board actuel: [6|4], rightEnd = 4
      // On ajoute [4|3] à droite, connexion par le 4
      final tile = DominoTile(value1: 4, value2: 3);
      final placedTile = PlacedTile(
        tile: tile,
        connectedValue: 4,  // doit être à gauche
        side: 'right',
        placedAt: DateTime.now(),
      );

      final display = getDisplayValues(placedTile);

      // value1=4=connectedValue, pas de flip
      // Affichage: [4|3] avec 4 à gauche pour toucher le 4 de [6|4]
      expect(display.$1, 4, reason: 'displayValue1 (gauche) doit être 4 pour toucher rightEnd=4');
      expect(display.$2, 3, reason: 'displayValue2 (droite) doit être 3');
    });

    test('Domino (3-4) ajouté à droite - flip nécessaire', () {
      // Board actuel: [6|4], rightEnd = 4
      // On ajoute [3|4] à droite, connexion par le 4
      final tile = DominoTile(value1: 3, value2: 4);
      final placedTile = PlacedTile(
        tile: tile,
        connectedValue: 4,  // doit être à gauche, mais c'est value2
        side: 'right',
        placedAt: DateTime.now(),
      );

      final display = getDisplayValues(placedTile);

      // value2=4=connectedValue, flip nécessaire
      // Affichage: [4|3] avec 4 à gauche
      expect(display.$1, 4, reason: 'displayValue1 (gauche) doit être 4 (flippé)');
      expect(display.$2, 3, reason: 'displayValue2 (droite) doit être 3 (flippé)');
    });

    test('Domino (6-2) inséré à gauche du [6|4] - connexion par 6', () {
      // Board actuel: [6|4], leftEnd = 6
      // On insère [6|2] à gauche, connexion par le 6
      // Le 6 doit être à DROITE du nouveau domino pour toucher le 6 de [6|4]
      final tile = DominoTile(value1: 6, value2: 2);
      final placedTile = PlacedTile(
        tile: tile,
        connectedValue: 6,  // doit être à droite
        side: 'left',
        placedAt: DateTime.now(),
      );

      final display = getDisplayValues(placedTile);

      // side='left' → connexion par la droite
      // value1=6=connectedValue, mais on veut 6 à droite
      // Donc flip: [2|6]
      expect(display.$1, 2, reason: 'displayValue1 (gauche) doit être 2');
      expect(display.$2, 6, reason: 'displayValue2 (droite) doit être 6 pour toucher leftEnd=6');
    });

    test('Domino (2-6) inséré à gauche - pas de flip', () {
      // Board actuel: [6|4], leftEnd = 6
      // On insère [2|6] à gauche, connexion par le 6
      final tile = DominoTile(value1: 2, value2: 6);
      final placedTile = PlacedTile(
        tile: tile,
        connectedValue: 6,  // doit être à droite, c'est value2
        side: 'left',
        placedAt: DateTime.now(),
      );

      final display = getDisplayValues(placedTile);

      // side='left' → connexion par la droite
      // value2=6=connectedValue, pas de flip
      expect(display.$1, 2, reason: 'displayValue1 (gauche) doit être 2');
      expect(display.$2, 6, reason: 'displayValue2 (droite) doit être 6');
    });

    test('Double (5-5) - pas de flip nécessaire', () {
      final tile = DominoTile(value1: 5, value2: 5);
      final placedTile = PlacedTile(
        tile: tile,
        connectedValue: 5,
        side: 'right',
        placedAt: DateTime.now(),
      );

      final display = getDisplayValues(placedTile);

      // Double: les deux valeurs sont identiques
      expect(display.$1, 5);
      expect(display.$2, 5);
    });

    test('Scénario complet: [2|6] ← [6|4] → [4|3]', () {
      // Simulation d'une chaîne de 3 dominos

      // 1. Premier domino [6|4] posé
      final tile1 = DominoTile(value1: 6, value2: 4);
      final placed1 = PlacedTile(
        tile: tile1,
        connectedValue: 6,
        side: 'right',
        placedAt: DateTime.now(),
      );
      final display1 = getDisplayValues(placed1);
      expect(display1.$1, 6, reason: 'Domino 1: gauche=6');
      expect(display1.$2, 4, reason: 'Domino 1: droite=4');

      // 2. Domino [4|3] ajouté à droite (se connecte au 4)
      final tile2 = DominoTile(value1: 4, value2: 3);
      final placed2 = PlacedTile(
        tile: tile2,
        connectedValue: 4,
        side: 'right',
        placedAt: DateTime.now(),
      );
      final display2 = getDisplayValues(placed2);
      expect(display2.$1, 4, reason: 'Domino 2: gauche=4 (touche le 4 du domino 1)');
      expect(display2.$2, 3, reason: 'Domino 2: droite=3');

      // 3. Domino [2|6] inséré à gauche (se connecte au 6)
      final tile3 = DominoTile(value1: 2, value2: 6);
      final placed3 = PlacedTile(
        tile: tile3,
        connectedValue: 6,
        side: 'left',
        placedAt: DateTime.now(),
      );
      final display3 = getDisplayValues(placed3);
      expect(display3.$1, 2, reason: 'Domino 3: gauche=2');
      expect(display3.$2, 6, reason: 'Domino 3: droite=6 (touche le 6 du domino 1)');

      // Vérification des connexions
      // Board ordre: [2|6], [6|4], [4|3]
      // Connexions: 6==6 ✓, 4==4 ✓
      expect(display3.$2, display1.$1, reason: 'Connexion gauche: 6==6');
      expect(display1.$2, display2.$1, reason: 'Connexion droite: 4==4');
    });
  });
}

/// Reproduit la logique de _getDisplayValues du widget
(int, int) getDisplayValues(PlacedTile placedTile) {
  final tile = placedTile.tile;
  final connectedValue = placedTile.connectedValue;

  // Pour un double, pas besoin de flip
  if (tile.isDouble) {
    return (tile.value1, tile.value2);
  }

  final side = placedTile.side;

  if (side == 'right') {
    // Connexion par la gauche: displayValue1 (gauche) doit être connectedValue
    if (tile.value1 == connectedValue) {
      return (tile.value1, tile.value2);
    } else {
      return (tile.value2, tile.value1);
    }
  } else {
    // Connexion par la droite: displayValue2 (droite) doit être connectedValue
    if (tile.value2 == connectedValue) {
      return (tile.value1, tile.value2);
    } else {
      return (tile.value2, tile.value1);
    }
  }
}
