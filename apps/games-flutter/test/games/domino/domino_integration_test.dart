import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol_games/games/domino/models/domino_tile.dart';
import 'package:kwaze_kreyol_games/games/domino/models/domino_game_state.dart';
import 'package:kwaze_kreyol_games/games/domino/models/domino_participant.dart';
import 'package:kwaze_kreyol_games/games/domino/utils/domino_logic.dart';
import 'package:kwaze_kreyol_games/games/domino/utils/domino_scoring.dart';

void main() {
  group('Domino Integration Tests -', () {
    test('Scénario complet: Distribution → Placement → Victoire', () {
      // Setup: 3 joueurs
      final participantIds = ['p1', 'p2', 'p3'];

      // 1. Distribution des tuiles
      final hands = DominoLogic.distributeTiles(participantIds);

      // Vérifier que chaque joueur a 7 tuiles
      expect(hands['p1']!.length, 7);
      expect(hands['p2']!.length, 7);
      expect(hands['p3']!.length, 7);

      // Vérifier que toutes les tuiles sont uniques
      final allTiles = [
        ...hands['p1']!,
        ...hands['p2']!,
        ...hands['p3']!,
      ];
      final uniqueTiles = <String>{};
      for (final tile in allTiles) {
        uniqueTiles.add(tile.id);
      }
      expect(uniqueTiles.length, 21); // 21 tuiles distribuées

      // 2. Déterminer le premier joueur
      final startingPlayer = DominoLogic.determineStartingPlayer(hands);
      expect(participantIds.contains(startingPlayer), true);

      // 3. Simuler un premier placement
      final firstTile = hands[startingPlayer]!.first;
      final board = [
        PlacedTile(
          tile: firstTile,
          side: 'left',
          connectedValue: firstTile.value1,
          placedAt: DateTime.now(),
        ),
      ];

      // 4. Vérifier que les bouts sont corrects
      expect(board.first.connectedValue, firstTile.value1);
      expect(board.first.exposedValue, firstTile.value2);

      // 5. Retirer la tuile de la main du joueur
      final updatedHands = Map<String, List<DominoTile>>.from(hands);
      updatedHands[startingPlayer] = List.from(hands[startingPlayer]!)
        ..removeWhere((t) => t.id == firstTile.id);

      expect(updatedHands[startingPlayer]!.length, 6);
    });

    test('Scénario: Blocage du jeu (tous les joueurs passent)', () {
      final participantIds = ['p1', 'p2', 'p3'];

      // Simuler un état où personne ne peut jouer
      final passedPlayers = ['p1', 'p2'];

      // Le jeu n'est pas encore bloqué
      expect(DominoLogic.isGameBlocked(passedPlayers, 3), false);

      // Tous les joueurs ont passé
      passedPlayers.add('p3');
      expect(DominoLogic.isGameBlocked(passedPlayers, 3), true);
    });

    test('Scénario: Détermination du gagnant en cas de blocage', () {
      final hands = {
        'p1': [
          DominoTile(value1: 6, value2: 6), // 12 points
          DominoTile(value1: 5, value2: 5), // 10 points
        ], // Total: 22 points
        'p2': [
          DominoTile(value1: 1, value2: 1), // 2 points
          DominoTile(value1: 2, value2: 2), // 4 points
        ], // Total: 6 points (GAGNANT)
        'p3': [
          DominoTile(value1: 3, value2: 3), // 6 points
          DominoTile(value1: 4, value2: 4), // 8 points
        ], // Total: 14 points
      };

      final winner = DominoLogic.determineBlockedWinner(hands);
      expect(winner, 'p2'); // Le joueur avec le moins de points
    });

    test('Scénario: Calcul des scores finaux', () {
      final hands = {
        'p1': [
          DominoTile(value1: 6, value2: 5), // 11 points
        ],
        'p2': [
          DominoTile(value1: 0, value2: 0), // 0 points
        ],
        'p3': [
          DominoTile(value1: 3, value2: 2), // 5 points
        ],
      };

      final scores = DominoScoring.calculateFinalScores(hands);

      expect(scores['p1'], 11);
      expect(scores['p2'], 0);
      expect(scores['p3'], 5);
    });

    test('Scénario: Détection des cochons (0 manche gagnée)', () {
      final participants = [
        DominoParticipant(
          id: 'p1',
          sessionId: 's1',
          userId: 'u1',
          roundsWon: 0, // COCHON
          isCochon: false,
          isHost: true,
          turnOrder: 0,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'p2',
          sessionId: 's1',
          userId: 'u2',
          roundsWon: 2,
          isCochon: false,
          isHost: false,
          turnOrder: 1,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'p3',
          sessionId: 's1',
          userId: 'u3',
          roundsWon: 1,
          isCochon: false,
          isHost: false,
          turnOrder: 2,
          joinedAt: DateTime.now(),
        ),
      ];

      final cochons = DominoScoring.determineCochons(participants);

      expect(cochons.length, 1);
      expect(cochons.contains('p1'), true);
    });

    test('Scénario: Détection de chirée (scénario progressif)', () {
      // Situation : J1: 2, J2: 1, J3: 0
      var participants = [
        DominoParticipant(
          id: 'p1',
          sessionId: 's1',
          userId: 'u1',
          roundsWon: 2,
          isCochon: false,
          isHost: true,
          turnOrder: 0,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'p2',
          sessionId: 's1',
          userId: 'u2',
          roundsWon: 1,
          isCochon: false,
          isHost: false,
          turnOrder: 1,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'p3',
          sessionId: 's1',
          userId: 'u3',
          roundsWon: 0,
          isCochon: false,
          isHost: false,
          turnOrder: 2,
          joinedAt: DateTime.now(),
        ),
      ];

      // Pas encore de chirée (J3 n'a pas de manche)
      expect(DominoScoring.isChiree(participants), false);

      // J3 gagne une manche → J1: 2, J2: 1, J3: 1
      participants[2] = participants[2].copyWith(roundsWon: 1);

      // CHIRÉE ! Tous ont au moins 1 manche et personne n'a atteint 3
      // La partie se termine IMMÉDIATEMENT en match nul
      expect(DominoScoring.isChiree(participants), true);

      // Aucun cochon (tous ont au moins 1 manche)
      final cochons = DominoScoring.determineCochons(participants);
      expect(cochons.length, 0);
    });

    test('Scénario: Pas de chirée (un joueur reste à 0)', () {
      final participantsNoChiree = [
        DominoParticipant(
          id: 'p1',
          sessionId: 's1',
          userId: 'u1',
          roundsWon: 3, // Gagnant
          isCochon: false,
          isHost: true,
          turnOrder: 0,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'p2',
          sessionId: 's1',
          userId: 'u2',
          roundsWon: 1,
          isCochon: false,
          isHost: false,
          turnOrder: 1,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'p3',
          sessionId: 's1',
          userId: 'u3',
          roundsWon: 0, // Cochon! Donc pas de chirée
          isCochon: false,
          isHost: false,
          turnOrder: 2,
          joinedAt: DateTime.now(),
        ),
      ];

      // Pas de chirée car J3 n'a aucune manche
      expect(DominoScoring.isChiree(participantsNoChiree), false);

      // J3 est cochon
      final cochons = DominoScoring.determineCochons(participantsNoChiree);
      expect(cochons.length, 1);
      expect(cochons.contains('p3'), true);
    });

    test('Scénario: Validation de placement de tuile', () {
      // Bout gauche = 3, bout droit = 5
      final leftEnd = 3;
      final rightEnd = 5;

      // Tuiles qui peuvent se connecter
      final canConnect3 = DominoTile(value1: 3, value2: 6);
      final canConnect5 = DominoTile(value1: 5, value2: 2);

      expect(DominoLogic.canPlaceTile(canConnect3, leftEnd, rightEnd), true);
      expect(DominoLogic.canPlaceTile(canConnect5, leftEnd, rightEnd), true);

      // Tuile qui ne peut pas se connecter
      final cannotConnect = DominoTile(value1: 1, value2: 2);
      expect(DominoLogic.canPlaceTile(cannotConnect, leftEnd, rightEnd), false);
    });

    test('Scénario: Vérification si un joueur peut jouer', () {
      final hand = [
        DominoTile(value1: 3, value2: 4),
        DominoTile(value1: 6, value2: 6),
        DominoTile(value1: 0, value2: 1),
      ];

      // Le joueur peut jouer si les bouts sont 3 ou 4
      expect(DominoLogic.canPlayerPlay(hand, 3, 5), true);
      expect(DominoLogic.canPlayerPlay(hand, 2, 4), true);

      // Le joueur ne peut pas jouer si les bouts sont 2 et 5
      expect(DominoLogic.canPlayerPlay(hand, 2, 5), false);
    });

    test('Scénario: Un joueur atteint 3 manches gagnées (victoire rapide)', () {
      // Simuler une partie où p1 gagne 3 manches d'affilée
      final participants = [
        DominoParticipant(
          id: 'p1',
          sessionId: 's1',
          userId: 'u1',
          roundsWon: 0,
          isCochon: false,
          isHost: true,
          turnOrder: 0,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'p2',
          sessionId: 's1',
          userId: 'u2',
          roundsWon: 0,
          isCochon: false,
          isHost: false,
          turnOrder: 1,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'p3',
          sessionId: 's1',
          userId: 'u3',
          roundsWon: 0,
          isCochon: false,
          isHost: false,
          turnOrder: 2,
          joinedAt: DateTime.now(),
        ),
      ];

      // Manche 1: p1 gagne
      participants[0] = participants[0].copyWith(roundsWon: 1);
      expect(participants[0].roundsWon, 1);

      // Manche 2: p1 gagne encore
      participants[0] = participants[0].copyWith(roundsWon: 2);
      expect(participants[0].roundsWon, 2);

      // Manche 3: p1 gagne (VICTOIRE! 3 manches gagnées)
      participants[0] = participants[0].copyWith(roundsWon: 3);
      expect(participants[0].roundsWon, 3);

      // p2 et p3 sont des cochons (0 manche gagnée)
      final cochons = DominoScoring.determineCochons(participants);
      expect(cochons.length, 2);
      expect(cochons.contains('p2'), true);
      expect(cochons.contains('p3'), true);
    });

    test('Scénario: Partie se termine en chirée (tous atteignent 1)', () {
      // Simuler une partie équilibrée où tous atteignent 1 manche
      var participants = [
        DominoParticipant(
          id: 'p1',
          sessionId: 's1',
          userId: 'u1',
          roundsWon: 0,
          isCochon: false,
          isHost: true,
          turnOrder: 0,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'p2',
          sessionId: 's1',
          userId: 'u2',
          roundsWon: 0,
          isCochon: false,
          isHost: false,
          turnOrder: 1,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'p3',
          sessionId: 's1',
          userId: 'u3',
          roundsWon: 0,
          isCochon: false,
          isHost: false,
          turnOrder: 2,
          joinedAt: DateTime.now(),
        ),
      ];

      // Manche 1: p1 gagne → J1:1, J2:0, J3:0
      participants[0] = participants[0].copyWith(roundsWon: 1);
      expect(DominoScoring.isChiree(participants), false);

      // Manche 2: p2 gagne → J1:1, J2:1, J3:0
      participants[1] = participants[1].copyWith(roundsWon: 1);
      expect(DominoScoring.isChiree(participants), false);

      // Manche 3: p3 gagne → J1:1, J2:1, J3:1
      participants[2] = participants[2].copyWith(roundsWon: 1);

      // CHIRÉE ! Tous ont 1 manche, personne n'a atteint 3
      // La partie se termine en match nul
      expect(DominoScoring.isChiree(participants), true);

      // Aucun cochon
      final cochons = DominoScoring.determineCochons(participants);
      expect(cochons.length, 0);
    });

    test('Scénario: Victoire J1:3, J2:0, J3:0 (double cochon)', () {
      final participants = [
        DominoParticipant(id: 'p1', sessionId: 's1', userId: 'u1', roundsWon: 3, isCochon: false, isHost: true, turnOrder: 0, joinedAt: DateTime.now()),
        DominoParticipant(id: 'p2', sessionId: 's1', userId: 'u2', roundsWon: 0, isCochon: false, isHost: false, turnOrder: 1, joinedAt: DateTime.now()),
        DominoParticipant(id: 'p3', sessionId: 's1', userId: 'u3', roundsWon: 0, isCochon: false, isHost: false, turnOrder: 2, joinedAt: DateTime.now()),
      ];

      expect(DominoScoring.isChiree(participants), false); // Victoire classique
      final cochons = DominoScoring.determineCochons(participants);
      expect(cochons.length, 2); // J2 et J3 sont cochons
      expect(cochons.contains('p2'), true);
      expect(cochons.contains('p3'), true);
    });

    test('Scénario: Victoire J1:3, J2:1, J3:0 (un cochon)', () {
      final participants = [
        DominoParticipant(id: 'p1', sessionId: 's1', userId: 'u1', roundsWon: 3, isCochon: false, isHost: true, turnOrder: 0, joinedAt: DateTime.now()),
        DominoParticipant(id: 'p2', sessionId: 's1', userId: 'u2', roundsWon: 1, isCochon: false, isHost: false, turnOrder: 1, joinedAt: DateTime.now()),
        DominoParticipant(id: 'p3', sessionId: 's1', userId: 'u3', roundsWon: 0, isCochon: false, isHost: false, turnOrder: 2, joinedAt: DateTime.now()),
      ];

      expect(DominoScoring.isChiree(participants), false); // Victoire classique
      final cochons = DominoScoring.determineCochons(participants);
      expect(cochons.length, 1); // Seul J3 est cochon
      expect(cochons.contains('p3'), true);
    });

    test('Scénario: Victoire J1:3, J2:2, J3:0 (un cochon)', () {
      final participants = [
        DominoParticipant(id: 'p1', sessionId: 's1', userId: 'u1', roundsWon: 3, isCochon: false, isHost: true, turnOrder: 0, joinedAt: DateTime.now()),
        DominoParticipant(id: 'p2', sessionId: 's1', userId: 'u2', roundsWon: 2, isCochon: false, isHost: false, turnOrder: 1, joinedAt: DateTime.now()),
        DominoParticipant(id: 'p3', sessionId: 's1', userId: 'u3', roundsWon: 0, isCochon: false, isHost: false, turnOrder: 2, joinedAt: DateTime.now()),
      ];

      expect(DominoScoring.isChiree(participants), false); // Victoire classique
      final cochons = DominoScoring.determineCochons(participants);
      expect(cochons.length, 1); // Seul J3 est cochon
      expect(cochons.contains('p3'), true);
    });

    test('Scénario: Chirée J1:1, J2:1, J3:1 (tous égaux)', () {
      final participants = [
        DominoParticipant(id: 'p1', sessionId: 's1', userId: 'u1', roundsWon: 1, isCochon: false, isHost: true, turnOrder: 0, joinedAt: DateTime.now()),
        DominoParticipant(id: 'p2', sessionId: 's1', userId: 'u2', roundsWon: 1, isCochon: false, isHost: false, turnOrder: 1, joinedAt: DateTime.now()),
        DominoParticipant(id: 'p3', sessionId: 's1', userId: 'u3', roundsWon: 1, isCochon: false, isHost: false, turnOrder: 2, joinedAt: DateTime.now()),
      ];

      expect(DominoScoring.isChiree(participants), true); // CHIRÉE !
      final cochons = DominoScoring.determineCochons(participants);
      expect(cochons.length, 0); // Aucun cochon
    });

    test('Scénario: Chirée J1:2, J2:1, J3:1', () {
      final participants = [
        DominoParticipant(id: 'p1', sessionId: 's1', userId: 'u1', roundsWon: 2, isCochon: false, isHost: true, turnOrder: 0, joinedAt: DateTime.now()),
        DominoParticipant(id: 'p2', sessionId: 's1', userId: 'u2', roundsWon: 1, isCochon: false, isHost: false, turnOrder: 1, joinedAt: DateTime.now()),
        DominoParticipant(id: 'p3', sessionId: 's1', userId: 'u3', roundsWon: 1, isCochon: false, isHost: false, turnOrder: 2, joinedAt: DateTime.now()),
      ];

      expect(DominoScoring.isChiree(participants), true); // CHIRÉE !
      final cochons = DominoScoring.determineCochons(participants);
      expect(cochons.length, 0); // Aucun cochon
    });

    test('Scénario: Chirée J1:2, J2:2, J3:1', () {
      final participants = [
        DominoParticipant(id: 'p1', sessionId: 's1', userId: 'u1', roundsWon: 2, isCochon: false, isHost: true, turnOrder: 0, joinedAt: DateTime.now()),
        DominoParticipant(id: 'p2', sessionId: 's1', userId: 'u2', roundsWon: 2, isCochon: false, isHost: false, turnOrder: 1, joinedAt: DateTime.now()),
        DominoParticipant(id: 'p3', sessionId: 's1', userId: 'u3', roundsWon: 1, isCochon: false, isHost: false, turnOrder: 2, joinedAt: DateTime.now()),
      ];

      expect(DominoScoring.isChiree(participants), true); // CHIRÉE !
      final cochons = DominoScoring.determineCochons(participants);
      expect(cochons.length, 0); // Aucun cochon
    });
  });
}
