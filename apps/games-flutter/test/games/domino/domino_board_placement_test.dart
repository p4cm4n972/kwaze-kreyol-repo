import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol_games/games/domino/models/domino_tile.dart';
import 'package:kwaze_kreyol_games/games/domino/utils/domino_board_layout.dart';

/// ============================================================================
/// TESTS DE POSITIONNEMENT DES DOMINOS SUR LE PLATEAU
/// ============================================================================
///
/// Ces tests vérifient:
/// 1. L'orientation correcte des dominos (doubles verticaux, autres horizontaux)
/// 2. Les connexions entre dominos (valeurs exposées correspondantes)
/// 3. Le mouvement en serpentin (virages après N dominos)
/// 4. Le calcul des bounds et du centrage
/// 5. La logique de flip (inversion des valeurs)

void main() {
  group('🎯 Positionnement des Dominos -', () {

    // Dimensions de test standard
    const tileWidth = 70.0;
    const tileHeight = 35.0;
    const availableWidth = 800.0;
    const availableHeight = 400.0;

    late DominoBoardLayout layout;

    setUp(() {
      layout = DominoBoardLayout(
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        maxTilesBeforeTurn: 6,
        availableWidth: availableWidth,
        availableHeight: availableHeight,
      );
    });

    test('📐 Test 1: Positions initiales alignées horizontalement', () {
      final positions = layout.calculatePositions(3);

      expect(positions.length, 3);

      // Les 3 premiers dominos vont vers la droite
      expect(positions[0].direction, PlacementDirection.right);
      expect(positions[1].direction, PlacementDirection.right);
      expect(positions[2].direction, PlacementDirection.right);

      // Positions X croissantes
      expect(positions[1].x, greaterThan(positions[0].x));
      expect(positions[2].x, greaterThan(positions[1].x));

      // Même Y (alignés horizontalement)
      expect(positions[0].y, equals(positions[1].y));
      expect(positions[1].y, equals(positions[2].y));

      print('✅ 3 dominos alignés horizontalement vers la droite');
    });

    test('🔄 Test 2: Serpentin - virage après 6 dominos', () {
      final positions = layout.calculatePositions(8);

      expect(positions.length, 8);

      // Les 6 premiers vont vers la droite
      for (int i = 0; i < 6; i++) {
        expect(positions[i].direction, PlacementDirection.right,
            reason: 'Domino $i doit aller vers la droite');
      }

      // Après le virage, ils descendent
      expect(positions[6].direction, PlacementDirection.down,
          reason: 'Domino 6 doit descendre (après virage)');
      expect(positions[7].direction, PlacementDirection.down,
          reason: 'Domino 7 doit descendre');

      print('✅ Virage correctement effectué après 6 dominos');
      print('   Direction après virage: ${positions[6].direction}');
    });

    test('🔄 Test 3: Serpentin complet - double virage', () {
      final positions = layout.calculatePositions(14);

      // Premiers 6: droite
      for (int i = 0; i < 6; i++) {
        expect(positions[i].direction, PlacementDirection.right);
      }

      // 6-11: bas
      for (int i = 6; i < 12; i++) {
        expect(positions[i].direction, PlacementDirection.down);
      }

      // 12-13: gauche
      expect(positions[12].direction, PlacementDirection.left);
      expect(positions[13].direction, PlacementDirection.left);

      print('✅ Double virage: droite → bas → gauche');
    });

    test('📏 Test 4: Orientation verticale/horizontale selon direction', () {
      final positions = layout.calculatePositions(10);

      // Les dominos qui vont droite/gauche sont horizontaux
      for (int i = 0; i < 6; i++) {
        expect(positions[i].isVertical, false,
            reason: 'Domino $i (direction droite) doit être horizontal');
      }

      // Les dominos qui vont haut/bas sont verticaux
      for (int i = 6; i < 10; i++) {
        expect(positions[i].isVertical, true,
            reason: 'Domino $i (direction bas) doit être vertical');
      }

      print('✅ Orientation correcte selon direction');
    });

    test('📦 Test 5: Calcul des bounds', () {
      final positions = layout.calculatePositions(5);
      final bounds = layout.calculateBounds(positions);

      expect(bounds.width, greaterThan(0));
      expect(bounds.height, greaterThan(0));

      // 5 dominos horizontaux = ~5 * tileWidth
      expect(bounds.width, greaterThanOrEqualTo(5 * tileWidth * 0.8));

      print('✅ Bounds calculés: ${bounds.width.toStringAsFixed(0)} x ${bounds.height.toStringAsFixed(0)}');
    });

    test('🎯 Test 6: Zoom initial calculé correctement', () {
      // Peu de dominos - zoom = 1.0 (pas besoin de zoomer)
      final positions3 = layout.calculatePositions(3);
      final scale3 = layout.calculateInitialScale(positions3);
      expect(scale3, closeTo(1.0, 0.1),
          reason: 'Peu de dominos ne nécessite pas de zoom');

      // Beaucoup de dominos - zoom >= 0.3 et <= 1.0
      final positions20 = layout.calculatePositions(20);
      final scale20 = layout.calculateInitialScale(positions20);
      expect(scale20, lessThanOrEqualTo(1.0),
          reason: 'Zoom max respecté');
      expect(scale20, greaterThanOrEqualTo(0.3),
          reason: 'Zoom minimum respecté');

      print('✅ Zoom 3 dominos: ${scale3.toStringAsFixed(2)}');
      print('✅ Zoom 20 dominos: ${scale20.toStringAsFixed(2)}');
    });

    test('🏠 Test 7: Centrage du contenu', () {
      final positions = layout.calculatePositions(5);
      final bounds = layout.calculateBounds(positions);

      // Vérifier que le contenu est centré
      final centerX = bounds.left + bounds.width / 2;
      final centerY = bounds.top + bounds.height / 2;

      // Le centre du contenu devrait être proche du centre de l'espace disponible
      expect(centerX, closeTo(availableWidth / 2, availableWidth * 0.3),
          reason: 'Contenu doit être centré horizontalement');
      expect(centerY, closeTo(availableHeight / 2, availableHeight * 0.3),
          reason: 'Contenu doit être centré verticalement');

      print('✅ Contenu centré à ($centerX, $centerY)');
    });

    test('📍 Test 8: Espacement entre dominos', () {
      final positions = layout.calculatePositions(3);

      // Calculer l'espacement entre dominos consécutifs
      final spacing1 = positions[1].x - (positions[0].x + tileWidth);
      final spacing2 = positions[2].x - (positions[1].x + tileWidth);

      // L'espacement devrait être petit (quelques pixels)
      expect(spacing1.abs(), lessThan(10),
          reason: 'Espacement entre domino 0 et 1 trop grand');
      expect(spacing2.abs(), lessThan(10),
          reason: 'Espacement entre domino 1 et 2 trop grand');

      print('✅ Espacements: ${spacing1.toStringAsFixed(1)}px, ${spacing2.toStringAsFixed(1)}px');
    });

    test('🎲 Test 9: Création des tuiles avec valeurs correctes', () {
      // Test de la création du jeu complet
      final fullSet = DominoTile.createFullSet();

      // Vérifier quelques tuiles spécifiques
      final doubleSix = fullSet.firstWhere((t) => t.value1 == 6 && t.value2 == 6);
      final fiveThree = fullSet.firstWhere((t) =>
          (t.value1 == 5 && t.value2 == 3) || (t.value1 == 3 && t.value2 == 5));

      expect(doubleSix.isDouble, true);
      expect(doubleSix.totalValue, 12);
      expect(fiveThree.isDouble, false);
      expect(fiveThree.totalValue, 8);

      print('✅ Tuile 6-6: double=${doubleSix.isDouble}, total=${doubleSix.totalValue}');
      print('✅ Tuile 5-3: double=${fiveThree.isDouble}, total=${fiveThree.totalValue}');
    });

    test('🔗 Test 10: Connexions de tuiles', () {
      final tile1 = DominoTile(value1: 3, value2: 5);
      final tile2 = DominoTile(value1: 5, value2: 2);
      final tile3 = DominoTile(value1: 6, value2: 6);
      final tile4 = DominoTile(value1: 1, value2: 4);

      // tile1 (3-5) peut se connecter à 3 ou 5
      expect(tile1.canConnect(3), true);
      expect(tile1.canConnect(5), true);
      expect(tile1.canConnect(4), false);

      // tile2 (5-2) peut se connecter à 5 (avec tile1)
      expect(tile2.canConnect(5), true);

      // tile3 (6-6) ne peut se connecter qu'à 6
      expect(tile3.canConnect(6), true);
      expect(tile3.canConnect(5), false);

      // tile4 (1-4) ne peut pas se connecter au bout exposé de tile2 (2)
      // Car tile2 expose 2 (après connexion par 5)
      expect(tile4.canConnect(2), false);

      print('✅ Connexions validées:');
      print('   3-5 → connect(5) = true');
      print('   5-2 → connect(5) = true');
      print('   6-6 → connect(6) = true, connect(5) = false');
    });

    test('↔️ Test 11: Valeur opposée pour connexion', () {
      final tile = DominoTile(value1: 3, value2: 6);

      // Si on connecte par le 3, l'autre bout expose 6
      expect(tile.getOppositeValue(3), 6);

      // Si on connecte par le 6, l'autre bout expose 3
      expect(tile.getOppositeValue(6), 3);

      // Erreur si valeur invalide
      expect(() => tile.getOppositeValue(5), throwsException);

      print('✅ Valeur opposée: connect(3) expose 6, connect(6) expose 3');
    });

    test('🎮 Test 12: Simulation de chaîne de placement', () {
      // Simuler une chaîne: 6-3 → 3-5 → 5-5 → 5-2
      final tiles = [
        DominoTile(value1: 6, value2: 3), // Premier: expose 3 à droite
        DominoTile(value1: 3, value2: 5), // Connecte au 3, expose 5
        DominoTile(value1: 5, value2: 5), // Double 5
        DominoTile(value1: 5, value2: 2), // Connecte au 5, expose 2
      ];

      // Vérifier la chaîne de connexions
      int exposed = tiles[0].value2; // Commence par exposer 3

      for (int i = 1; i < tiles.length; i++) {
        final tile = tiles[i];
        expect(tile.canConnect(exposed), true,
            reason: 'Tuile $i doit pouvoir se connecter à $exposed');

        // Calculer la nouvelle valeur exposée
        exposed = tile.getOppositeValue(exposed);
      }

      expect(exposed, 2, reason: 'La chaîne doit exposer 2 à la fin');

      print('✅ Chaîne: 6-3 → 3-5 → 5-5 → 5-2');
      print('   Bouts: 6 (gauche) | 2 (droite)');
    });

    test('🎲 Test 13: PlacedTile - valeurs exposées', () {
      final tile = DominoTile(value1: 4, value2: 6);

      // Placement à droite: connexion par value1 (4)
      final placedRight = PlacedTile(
        tile: tile,
        side: 'right',
        connectedValue: 4,
        placedAt: DateTime.now(),
      );

      expect(placedRight.connectedValue, 4);
      expect(placedRight.exposedValue, 6);

      // Placement à gauche: connexion par value2 (6)
      final placedLeft = PlacedTile(
        tile: tile,
        side: 'left',
        connectedValue: 6,
        placedAt: DateTime.now(),
      );

      expect(placedLeft.connectedValue, 6);
      expect(placedLeft.exposedValue, 4);

      print('✅ PlacedTile exposedValue calculé correctement');
    });

    test('🔄 Test 14: Double expose la même valeur des deux côtés', () {
      final double6 = DominoTile(value1: 6, value2: 6);

      expect(double6.isDouble, true);

      // Un double expose la même valeur quel que soit le côté
      final placed = PlacedTile(
        tile: double6,
        side: 'right',
        connectedValue: 6,
        placedAt: DateTime.now(),
      );

      expect(placed.exposedValue, 6);
      expect(placed.connectedValue, 6);

      print('✅ Double 6-6 expose 6 des deux côtés');
    });

    test('🎯 Test 15: Serpentin complet - 4 directions', () {
      // Avec maxTilesBeforeTurn=6, il faut 24 dominos pour 4 virages complets
      final layoutSmall = DominoBoardLayout(
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        maxTilesBeforeTurn: 4, // Plus petit pour tester plus vite
        availableWidth: availableWidth,
        availableHeight: availableHeight,
      );

      final positions = layoutSmall.calculatePositions(16);

      // 0-3: droite
      expect(positions[0].direction, PlacementDirection.right);
      expect(positions[3].direction, PlacementDirection.right);

      // 4-7: bas
      expect(positions[4].direction, PlacementDirection.down);
      expect(positions[7].direction, PlacementDirection.down);

      // 8-11: gauche
      expect(positions[8].direction, PlacementDirection.left);
      expect(positions[11].direction, PlacementDirection.left);

      // 12-15: haut
      expect(positions[12].direction, PlacementDirection.up);
      expect(positions[15].direction, PlacementDirection.up);

      print('✅ Serpentin 4 directions: → ↓ ← ↑');
    });

    test('📊 Test 16: Performance - calcul de 50 positions', () {
      final stopwatch = Stopwatch()..start();

      final positions = layout.calculatePositions(50);

      stopwatch.stop();

      expect(positions.length, 50);
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Le calcul de 50 positions doit être rapide (<100ms)');

      print('✅ 50 positions calculées en ${stopwatch.elapsedMilliseconds}ms');
    });

    test('🎮 Test 17: Plateau vide', () {
      final positions = layout.calculatePositions(0);
      expect(positions, isEmpty);

      final bounds = layout.calculateBounds([]);
      expect(bounds, Rect.zero);

      print('✅ Plateau vide géré correctement');
    });

    test('1️⃣ Test 18: Un seul domino centré', () {
      final positions = layout.calculatePositions(1);

      expect(positions.length, 1);
      expect(positions[0].direction, PlacementDirection.right);

      // Le domino unique doit être centré
      final bounds = layout.calculateBounds(positions);
      final centerX = bounds.left + bounds.width / 2;
      final centerY = bounds.top + bounds.height / 2;

      expect(centerX, closeTo(availableWidth / 2, availableWidth / 4));
      expect(centerY, closeTo(availableHeight / 2, availableHeight / 4));

      print('✅ Domino unique centré');
    });
  });
}
