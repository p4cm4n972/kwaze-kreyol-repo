import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol_games/games/domino/services/domino_solo_service.dart';
import 'package:kwaze_kreyol_games/games/domino/services/domino_ai_service.dart';
import 'package:kwaze_kreyol_games/games/domino/models/domino_tile.dart';
import 'package:kwaze_kreyol_games/games/domino/models/domino_session.dart';
import 'package:kwaze_kreyol_games/games/domino/models/domino_game_state.dart';

void main() {
  group('DominoSoloService', () {
    group('createSoloSession', () {
      test('crée une session avec 1 humain et 2 IA', () {
        final session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human-123',
          humanPlayerName: 'Joueur Test',
          difficulty: AIDifficulty.normal,
        );

        expect(session.participants.length, equals(3));
        expect(session.status, equals('in_progress'));
        expect(session.hostId, equals('human-123'));
      });

      test('humain a turnOrder 0', () {
        final session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human-123',
          humanPlayerName: 'Joueur Test',
          difficulty: AIDifficulty.easy,
        );

        final human = session.participants.firstWhere((p) => !p.isAI);
        expect(human.turnOrder, equals(0));
        expect(human.userName, equals('Joueur Test'));
        expect(human.isHost, isTrue);
      });

      test('IA ont turnOrder 1 et 2', () {
        final session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human-123',
          humanPlayerName: 'Joueur Test',
          difficulty: AIDifficulty.hard,
        );

        final ais = session.participants.where((p) => p.isAI).toList();
        expect(ais.length, equals(2));
        expect(ais.map((a) => a.turnOrder).toSet(), equals({1, 2}));
      });

      test('noms IA selon difficulté facile', () {
        final session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human',
          humanPlayerName: 'Test',
          difficulty: AIDifficulty.easy,
        );

        final ais = session.participants.where((p) => p.isAI).toList();
        final names = ais.map((a) => a.displayName).toSet();
        // Noms caribéens pour le contexte martiniquais
        expect(names.contains('Barbeloup') && names.contains('Pédro'), isTrue);
      });

      test('noms IA selon difficulté normale', () {
        final session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human',
          humanPlayerName: 'Test',
          difficulty: AIDifficulty.normal,
        );

        final ais = session.participants.where((p) => p.isAI).toList();
        final names = ais.map((a) => a.displayName).toSet();
        // Noms caribéens pour le contexte martiniquais
        expect(names.contains('Barbeloup') && names.contains('Pédro'), isTrue);
      });

      test('noms IA selon difficulté difficile', () {
        final session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human',
          humanPlayerName: 'Test',
          difficulty: AIDifficulty.hard,
        );

        final ais = session.participants.where((p) => p.isAI).toList();
        final names = ais.map((a) => a.displayName).toSet();
        // Noms caribéens pour le contexte martiniquais
        expect(names.contains('Barbeloup') && names.contains('Pédro'), isTrue);
      });
    });

    group('startNewRound', () {
      test('distribue 7 tuiles à chaque joueur', () {
        final session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human',
          humanPlayerName: 'Test',
          difficulty: AIDifficulty.normal,
        );

        final gameState = DominoSoloService.startNewRound(session);

        for (final participant in session.participants) {
          final hand = gameState.playerHands[participant.id];
          expect(hand, isNotNull);
          expect(hand!.length, equals(7));
        }
      });

      test('plateau vide au début', () {
        final session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human',
          humanPlayerName: 'Test',
          difficulty: AIDifficulty.normal,
        );

        final gameState = DominoSoloService.startNewRound(session);

        expect(gameState.board, isEmpty);
        expect(gameState.leftEnd, isNull);
        expect(gameState.rightEnd, isNull);
      });

      test('roundNumber correct', () {
        final session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human',
          humanPlayerName: 'Test',
          difficulty: AIDifficulty.normal,
        );

        final gameState = DominoSoloService.startNewRound(session);
        expect(gameState.roundNumber, equals(1));
      });

      test('détermine un premier joueur', () {
        final session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human',
          humanPlayerName: 'Test',
          difficulty: AIDifficulty.normal,
        );

        final gameState = DominoSoloService.startNewRound(session);

        expect(gameState.currentTurnParticipantId, isNotNull);
        expect(
          session.participants.any((p) => p.id == gameState.currentTurnParticipantId),
          isTrue,
        );
      });
    });

    group('placeTile', () {
      late DominoSession session;
      late DominoGameState gameState;
      late String humanId;

      setUp(() {
        session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human',
          humanPlayerName: 'Test',
          difficulty: AIDifficulty.normal,
        );
        gameState = DominoSoloService.startNewRound(session);
        humanId = session.participants.firstWhere((p) => !p.isAI).id;
      });

      test('erreur si ce n\'est pas le tour du joueur', () {
        // Mettre le tour sur une IA
        final aiId = session.participants.firstWhere((p) => p.isAI).id;
        final stateWithAITurn = gameState.copyWith(currentTurnParticipantId: aiId);

        final tile = stateWithAITurn.playerHands[humanId]!.first;

        expect(
          () => DominoSoloService.placeTile(
            state: stateWithAITurn,
            participantId: humanId,
            tile: tile,
            side: 'right',
            participants: session.participants,
          ),
          throwsException,
        );
      });

      test('erreur si le joueur ne possède pas la tuile', () {
        final stateWithHumanTurn = gameState.copyWith(currentTurnParticipantId: humanId);

        // Trouver une tuile qui n'est PAS dans la main du joueur humain
        final humanHand = stateWithHumanTurn.playerHands[humanId]!;
        final humanTileIds = humanHand.map((t) => t.id).toSet();

        // Chercher une tuile qui n'est pas dans la main
        DominoTile? fakeTile;
        for (int v1 = 0; v1 <= 6 && fakeTile == null; v1++) {
          for (int v2 = v1; v2 <= 6 && fakeTile == null; v2++) {
            final testId = '$v1-$v2';
            if (!humanTileIds.contains(testId)) {
              fakeTile = DominoTile(value1: v1, value2: v2);
            }
          }
        }

        expect(
          () => DominoSoloService.placeTile(
            state: stateWithHumanTurn,
            participantId: humanId,
            tile: fakeTile!,
            side: 'right',
            participants: session.participants,
          ),
          throwsException,
        );
      });

      test('place la première tuile correctement', () {
        final stateWithHumanTurn = gameState.copyWith(currentTurnParticipantId: humanId);
        final tile = stateWithHumanTurn.playerHands[humanId]!.first;

        final result = DominoSoloService.placeTile(
          state: stateWithHumanTurn,
          participantId: humanId,
          tile: tile,
          side: 'right',
          participants: session.participants,
        );

        expect(result.newState.board.length, equals(1));
        expect(result.newState.leftEnd, equals(tile.value1));
        expect(result.newState.rightEnd, equals(tile.value2));
        expect(result.newState.playerHands[humanId]!.length, equals(6));
      });

      test('passe au joueur suivant après placement', () {
        final stateWithHumanTurn = gameState.copyWith(currentTurnParticipantId: humanId);
        final tile = stateWithHumanTurn.playerHands[humanId]!.first;

        final result = DominoSoloService.placeTile(
          state: stateWithHumanTurn,
          participantId: humanId,
          tile: tile,
          side: 'right',
          participants: session.participants,
        );

        expect(result.newState.currentTurnParticipantId, isNot(humanId));
      });

      test('détecte capot (main vide)', () {
        // Créer un état avec une seule tuile en main
        final singleTile = gameState.playerHands[humanId]!.first;
        final customHands = Map<String, List<DominoTile>>.from(gameState.playerHands);
        customHands[humanId] = [singleTile];

        final stateWithOneTile = gameState.copyWith(
          currentTurnParticipantId: humanId,
          playerHands: customHands,
        );

        final result = DominoSoloService.placeTile(
          state: stateWithOneTile,
          participantId: humanId,
          tile: singleTile,
          side: 'right',
          participants: session.participants,
        );

        expect(result.roundEnded, isTrue);
        expect(result.roundWinnerId, equals(humanId));
        expect(result.isCapot, isTrue);
      });
    });

    group('passTurn', () {
      late DominoSession session;
      late DominoGameState gameState;
      late String humanId;

      setUp(() {
        session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human',
          humanPlayerName: 'Test',
          difficulty: AIDifficulty.normal,
        );
        gameState = DominoSoloService.startNewRound(session);
        humanId = session.participants.firstWhere((p) => !p.isAI).id;
      });

      test('erreur si ce n\'est pas le tour du joueur', () {
        final aiId = session.participants.firstWhere((p) => p.isAI).id;
        final stateWithAITurn = gameState.copyWith(currentTurnParticipantId: aiId);

        expect(
          () => DominoSoloService.passTurn(
            state: stateWithAITurn,
            participantId: humanId,
            participants: session.participants,
          ),
          throwsException,
        );
      });

      test('erreur si le joueur peut encore jouer', () {
        // Sur plateau vide, tout le monde peut jouer
        final stateWithHumanTurn = gameState.copyWith(currentTurnParticipantId: humanId);

        expect(
          () => DominoSoloService.passTurn(
            state: stateWithHumanTurn,
            participantId: humanId,
            participants: session.participants,
          ),
          throwsException,
        );
      });

      test('ajoute le joueur à la liste des passés', () {
        // Créer un état où le joueur ne peut pas jouer
        final customHands = Map<String, List<DominoTile>>.from(gameState.playerHands);
        customHands[humanId] = [const DominoTile(value1: 0, value2: 0)];

        final blockedState = gameState.copyWith(
          currentTurnParticipantId: humanId,
          board: [
            PlacedTile(
              tile: const DominoTile(value1: 5, value2: 6),
              connectedValue: 5,
              side: 'right',
              placedAt: DateTime.now(),
            ),
          ],
          leftEnd: 5,
          rightEnd: 6,
          playerHands: customHands,
        );

        final result = DominoSoloService.passTurn(
          state: blockedState,
          participantId: humanId,
          participants: session.participants,
        );

        expect(result.newState.passedPlayerIds.contains(humanId), isTrue);
      });
    });

    group('updateSessionAfterRound', () {
      test('incrémente roundsWon du gagnant', () {
        final session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human',
          humanPlayerName: 'Test',
          difficulty: AIDifficulty.normal,
        );

        final winnerId = session.participants.first.id;
        final updatedSession = DominoSoloService.updateSessionAfterRound(session, winnerId);

        final winner = updatedSession.participants.firstWhere((p) => p.id == winnerId);
        expect(winner.roundsWon, equals(1));
      });

      test('détecte victoire à 3 manches', () {
        var session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human',
          humanPlayerName: 'Test',
          difficulty: AIDifficulty.normal,
        );

        final winnerId = session.participants.first.id;

        // Simuler 3 victoires
        for (var i = 0; i < 3; i++) {
          session = DominoSoloService.updateSessionAfterRound(session, winnerId);
        }

        expect(session.status, equals('completed'));
        expect(session.winnerId, isNotNull);
      });

      test('marque les cochons', () {
        var session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human',
          humanPlayerName: 'Test',
          difficulty: AIDifficulty.normal,
        );

        final winnerId = session.participants.first.id;

        // Simuler 3 victoires du même joueur
        for (var i = 0; i < 3; i++) {
          session = DominoSoloService.updateSessionAfterRound(session, winnerId);
        }

        final losers = session.participants.where((p) => p.id != winnerId);
        for (final loser in losers) {
          expect(loser.isCochon, isTrue);
        }
      });
    });

    group('isGameOver', () {
      test('retourne true si status completed', () {
        var session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human',
          humanPlayerName: 'Test',
          difficulty: AIDifficulty.normal,
        );

        final winnerId = session.participants.first.id;

        for (var i = 0; i < 3; i++) {
          session = DominoSoloService.updateSessionAfterRound(session, winnerId);
        }

        expect(DominoSoloService.isGameOver(session), isTrue);
      });

      test('retourne false si partie en cours', () {
        final session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human',
          humanPlayerName: 'Test',
          difficulty: AIDifficulty.normal,
        );

        expect(DominoSoloService.isGameOver(session), isFalse);
      });
    });

    group('getHumanParticipant', () {
      test('retourne le participant humain', () {
        final session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human-123',
          humanPlayerName: 'TestPlayer',
          difficulty: AIDifficulty.normal,
        );

        final human = DominoSoloService.getHumanParticipant(session);
        expect(human.isAI, isFalse);
        expect(human.userId, equals('human-123'));
      });
    });

    group('getAIParticipants', () {
      test('retourne les 2 participants IA', () {
        final session = DominoSoloService.createSoloSession(
          humanPlayerId: 'human',
          humanPlayerName: 'Test',
          difficulty: AIDifficulty.normal,
        );

        final ais = DominoSoloService.getAIParticipants(session);
        expect(ais.length, equals(2));
        expect(ais.every((ai) => ai.isAI), isTrue);
      });
    });
  });
}
