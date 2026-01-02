import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol/tools/met_double/models/met_double_game.dart';

void main() {
  group('Met Double - Modèles', () {
    test('MetDoubleSession - Peut démarrer avec 3 joueurs', () {
      final session = MetDoubleSession(
        id: 'test-session-1',
        hostId: 'host-1',
        status: 'waiting',
        createdAt: DateTime.now(),
        participants: [
          MetDoubleParticipant(
            id: 'p1',
            sessionId: 'test-session-1',
            userId: 'user-1',
            isHost: true,
            joinedAt: DateTime.now(),
          ),
          MetDoubleParticipant(
            id: 'p2',
            sessionId: 'test-session-1',
            userId: 'user-2',
            joinedAt: DateTime.now(),
          ),
          MetDoubleParticipant(
            id: 'p3',
            sessionId: 'test-session-1',
            guestName: 'Invité 1',
            joinedAt: DateTime.now(),
          ),
        ],
      );

      expect(session.canStart, isTrue);
      expect(session.participants.length, equals(3));
    });

    test('MetDoubleSession - Ne peut pas démarrer avec moins de 3 joueurs', () {
      final session = MetDoubleSession(
        id: 'test-session-2',
        hostId: 'host-1',
        status: 'waiting',
        createdAt: DateTime.now(),
        participants: [
          MetDoubleParticipant(
            id: 'p1',
            sessionId: 'test-session-2',
            userId: 'user-1',
            isHost: true,
            joinedAt: DateTime.now(),
          ),
          MetDoubleParticipant(
            id: 'p2',
            sessionId: 'test-session-2',
            userId: 'user-2',
            joinedAt: DateTime.now(),
          ),
        ],
      );

      expect(session.canStart, isFalse);
      expect(session.participants.length, equals(2));
    });

    test('MetDoubleParticipant - Utilisateur inscrit', () {
      final participant = MetDoubleParticipant(
        id: 'p1',
        sessionId: 'session-1',
        userId: 'user-1',
        userName: 'JohnDoe',
        isHost: true,
        joinedAt: DateTime.now(),
      );

      expect(participant.isGuest, isFalse);
      expect(participant.isRegistered, isTrue);
      expect(participant.displayName, equals('JohnDoe'));
    });

    test('MetDoubleParticipant - Invité', () {
      final participant = MetDoubleParticipant(
        id: 'p2',
        sessionId: 'session-1',
        guestName: 'Invité Pierre',
        joinedAt: DateTime.now(),
      );

      expect(participant.isGuest, isTrue);
      expect(participant.isRegistered, isFalse);
      expect(participant.displayName, equals('Invité Pierre'));
    });

    test('MetDoubleRound - Manche normale avec gagnant', () {
      final round = MetDoubleRound(
        id: 'round-1',
        sessionId: 'session-1',
        roundNumber: 1,
        winnerParticipantId: 'p1',
        cochonParticipantIds: ['p2'],
        isChiree: false,
        playedAt: DateTime.now(),
      );

      expect(round.isChiree, isFalse);
      expect(round.winnerParticipantId, equals('p1'));
      expect(round.cochonParticipantIds.length, equals(1));
      expect(round.cochonParticipantIds, contains('p2'));
    });

    test('MetDoubleRound - Manche chirée', () {
      final round = MetDoubleRound(
        id: 'round-2',
        sessionId: 'session-1',
        roundNumber: 2,
        isChiree: true,
        playedAt: DateTime.now(),
      );

      expect(round.isChiree, isTrue);
      expect(round.winnerParticipantId, isNull);
    });
  });

  group('Met Double - Logique de jeu', () {
    test('Partie avec manches gagnées - Identifier le gagnant', () {
      final now = DateTime.now();

      final participants = [
        MetDoubleParticipant(
          id: 'p1',
          sessionId: 'session-1',
          userId: 'user-1',
          userName: 'Alice',
          victories: 3,
          isHost: true,
          joinedAt: now,
        ),
        MetDoubleParticipant(
          id: 'p2',
          sessionId: 'session-1',
          userId: 'user-2',
          userName: 'Bob',
          victories: 1,
          joinedAt: now,
        ),
        MetDoubleParticipant(
          id: 'p3',
          sessionId: 'session-1',
          guestName: 'Charlie',
          victories: 2,
          joinedAt: now,
        ),
      ];

      final rounds = [
        MetDoubleRound(
          id: 'r1',
          sessionId: 'session-1',
          roundNumber: 1,
          winnerParticipantId: 'p1',
          cochonParticipantIds: ['p2'],
          playedAt: now,
        ),
        MetDoubleRound(
          id: 'r2',
          sessionId: 'session-1',
          roundNumber: 2,
          winnerParticipantId: 'p3',
          cochonParticipantIds: ['p2'],
          playedAt: now,
        ),
        MetDoubleRound(
          id: 'r3',
          sessionId: 'session-1',
          roundNumber: 3,
          winnerParticipantId: 'p1',
          cochonParticipantIds: [],
          playedAt: now,
        ),
      ];

      final session = MetDoubleSession(
        id: 'session-1',
        hostId: 'user-1',
        status: 'completed',
        createdAt: now,
        winnerId: 'user-1',
        participants: participants,
        rounds: rounds,
      );

      // Vérifier le gagnant (celui avec 3 victoires)
      final winner = session.participants.firstWhere((p) => p.victories >= 3);
      expect(winner.displayName, equals('Alice'));
      expect(winner.victories, equals(3));

      // Vérifier le nombre de manches
      expect(session.rounds.length, equals(3));

      // Vérifier qu'Alice a gagné 2 manches
      final aliceWins = rounds.where((r) => r.winnerParticipantId == 'p1').length;
      expect(aliceWins, equals(2));
    });

    test('Partie avec manche chirée - Aucun point marqué', () {
      final now = DateTime.now();

      final participants = [
        MetDoubleParticipant(
          id: 'p1',
          sessionId: 'session-1',
          userId: 'user-1',
          userName: 'Alice',
          victories: 1,
          isHost: true,
          joinedAt: now,
        ),
        MetDoubleParticipant(
          id: 'p2',
          sessionId: 'session-1',
          userId: 'user-2',
          userName: 'Bob',
          victories: 1,
          joinedAt: now,
        ),
        MetDoubleParticipant(
          id: 'p3',
          sessionId: 'session-1',
          guestName: 'Charlie',
          victories: 1,
          joinedAt: now,
        ),
      ];

      final chireeRound = MetDoubleRound(
        id: 'r1',
        sessionId: 'session-1',
        roundNumber: 1,
        isChiree: true,
        playedAt: now,
      );

      // Vérifier qu'une manche chirée n'a pas de gagnant
      expect(chireeRound.isChiree, isTrue);
      expect(chireeRound.winnerParticipantId, isNull);

      // Vérifier que tous les joueurs ont au moins 1 victoire (condition pour chirée)
      final allHaveAtLeastOne = participants.every((p) => p.victories >= 1);
      expect(allHaveAtLeastOne, isTrue);
    });

    test('Identification des cochons - Joueurs avec 0 point', () {
      final now = DateTime.now();

      final participants = [
        MetDoubleParticipant(
          id: 'p1',
          sessionId: 'session-1',
          userId: 'user-1',
          userName: 'Alice',
          victories: 3,
          isHost: true,
          joinedAt: now,
        ),
        MetDoubleParticipant(
          id: 'p2',
          sessionId: 'session-1',
          userId: 'user-2',
          userName: 'Bob',
          victories: 0,
          isCochon: true,
          joinedAt: now,
        ),
        MetDoubleParticipant(
          id: 'p3',
          sessionId: 'session-1',
          guestName: 'Charlie',
          victories: 2,
          joinedAt: now,
        ),
      ];

      final round = MetDoubleRound(
        id: 'r1',
        sessionId: 'session-1',
        roundNumber: 1,
        winnerParticipantId: 'p1',
        cochonParticipantIds: ['p2'],
        playedAt: now,
      );

      // Vérifier que Bob est cochon
      final cochons = participants.where((p) => p.victories == 0).toList();
      expect(cochons.length, equals(1));
      expect(cochons.first.displayName, equals('Bob'));
      expect(cochons.first.isCochon, isTrue);

      // Vérifier que le round a bien enregistré le cochon
      expect(round.cochonParticipantIds, contains('p2'));
    });

    test('Met Double - Joueur qui donne le plus de cochons', () {
      final now = DateTime.now();

      final participants = [
        MetDoubleParticipant(
          id: 'p1',
          sessionId: 'session-1',
          userId: 'user-1',
          userName: 'Alice',
          victories: 3,
          isHost: true,
          joinedAt: now,
        ),
        MetDoubleParticipant(
          id: 'p2',
          sessionId: 'session-1',
          userId: 'user-2',
          userName: 'Bob',
          victories: 0,
          isCochon: true,
          joinedAt: now,
        ),
        MetDoubleParticipant(
          id: 'p3',
          sessionId: 'session-1',
          guestName: 'Charlie',
          victories: 0,
          isCochon: true,
          joinedAt: now,
        ),
      ];

      final rounds = [
        MetDoubleRound(
          id: 'r1',
          sessionId: 'session-1',
          roundNumber: 1,
          winnerParticipantId: 'p1',
          cochonParticipantIds: ['p2', 'p3'],
          playedAt: now,
        ),
        MetDoubleRound(
          id: 'r2',
          sessionId: 'session-1',
          roundNumber: 2,
          winnerParticipantId: 'p1',
          cochonParticipantIds: ['p2'],
          playedAt: now,
        ),
      ];

      // Calculer combien de cochons Alice a donnés
      int cochonsDonnes = 0;
      for (var round in rounds) {
        if (round.winnerParticipantId == 'p1') {
          cochonsDonnes += round.cochonParticipantIds.length;
        }
      }

      expect(cochonsDonnes, equals(3)); // 2 cochons en manche 1 + 1 en manche 2
    });

    test('Met Cochon - Joueur qui reçoit le plus de cochons', () {
      final now = DateTime.now();

      final rounds = [
        MetDoubleRound(
          id: 'r1',
          sessionId: 'session-1',
          roundNumber: 1,
          winnerParticipantId: 'p1',
          cochonParticipantIds: ['p2', 'p3'],
          playedAt: now,
        ),
        MetDoubleRound(
          id: 'r2',
          sessionId: 'session-1',
          roundNumber: 2,
          winnerParticipantId: 'p1',
          cochonParticipantIds: ['p2'],
          playedAt: now,
        ),
        MetDoubleRound(
          id: 'r3',
          sessionId: 'session-1',
          roundNumber: 3,
          winnerParticipantId: 'p3',
          cochonParticipantIds: ['p2'],
          playedAt: now,
        ),
      ];

      // Calculer combien de fois p2 a reçu un cochon
      int cochonsRecus = rounds.where((r) => r.cochonParticipantIds.contains('p2')).length;

      expect(cochonsRecus, equals(3)); // p2 a été cochon dans les 3 manches
    });

    test('Progression de partie - De waiting à completed', () {
      final now = DateTime.now();

      // État initial : waiting
      var session = MetDoubleSession(
        id: 'session-1',
        hostId: 'user-1',
        status: 'waiting',
        createdAt: now,
        participants: [],
      );
      expect(session.status, equals('waiting'));
      expect(session.canStart, isFalse);

      // Ajout de 3 joueurs
      session = MetDoubleSession(
        id: 'session-1',
        hostId: 'user-1',
        status: 'waiting',
        createdAt: now,
        participants: [
          MetDoubleParticipant(
            id: 'p1',
            sessionId: 'session-1',
            userId: 'user-1',
            isHost: true,
            joinedAt: now,
          ),
          MetDoubleParticipant(
            id: 'p2',
            sessionId: 'session-1',
            userId: 'user-2',
            joinedAt: now,
          ),
          MetDoubleParticipant(
            id: 'p3',
            sessionId: 'session-1',
            guestName: 'Invité',
            joinedAt: now,
          ),
        ],
      );
      expect(session.canStart, isTrue);

      // Démarrage de la partie
      session = MetDoubleSession(
        id: 'session-1',
        hostId: 'user-1',
        status: 'in_progress',
        createdAt: now,
        startedAt: now,
        participants: session.participants,
      );
      expect(session.status, equals('in_progress'));
      expect(session.startedAt, isNotNull);

      // Fin de partie
      session = MetDoubleSession(
        id: 'session-1',
        hostId: 'user-1',
        status: 'completed',
        createdAt: now,
        startedAt: now,
        completedAt: now,
        winnerId: 'user-1',
        participants: session.participants,
      );
      expect(session.status, equals('completed'));
      expect(session.completedAt, isNotNull);
      expect(session.winnerId, isNotNull);
    });
  });

  group('Met Double - Sérialisation JSON', () {
    test('MetDoubleSession - toJson et fromJson', () {
      final now = DateTime.now();
      final session = MetDoubleSession(
        id: 'session-1',
        hostId: 'user-1',
        status: 'waiting',
        createdAt: now,
      );

      final json = session.toJson();
      expect(json['host_id'], equals('user-1'));
      expect(json['status'], equals('waiting'));
    });

    test('MetDoubleParticipant - toJson', () {
      final now = DateTime.now();
      final participant = MetDoubleParticipant(
        id: 'p1',
        sessionId: 'session-1',
        userId: 'user-1',
        victories: 2,
        isHost: true,
        joinedAt: now,
      );

      final json = participant.toJson();
      expect(json['session_id'], equals('session-1'));
      expect(json['user_id'], equals('user-1'));
      expect(json['victories'], equals(2));
      expect(json['is_host'], isTrue);
    });

    test('MetDoubleRound - fromJson avec cochonParticipantIds', () {
      final json = {
        'id': 'round-1',
        'session_id': 'session-1',
        'round_number': 1,
        'winner_participant_id': 'p1',
        'cochon_participant_ids': ['p2', 'p3'],
        'is_chiree': false,
        'played_at': DateTime.now().toIso8601String(),
      };

      final round = MetDoubleRound.fromJson(json);
      expect(round.cochonParticipantIds.length, equals(2));
      expect(round.cochonParticipantIds, containsAll(['p2', 'p3']));
    });
  });
}
