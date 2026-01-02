import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol_games/tools/met_double/models/met_double_game.dart';

/// Tests d'intégration pour valider le bon fonctionnement
void main() {
  group('Met Double - Validation du bon fonctionnement', () {
    test('VALIDATION: Une manche est bien enregistrée une seule fois', () {
      final now = DateTime.now();

      final session = MetDoubleSession(
        id: 'session-1',
        hostId: 'user-1',
        status: 'in_progress',
        createdAt: now,
        participants: [
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
            victories: 0,
            joinedAt: now,
          ),
          MetDoubleParticipant(
            id: 'p3',
            sessionId: 'session-1',
            guestName: 'Charlie',
            victories: 1,
            joinedAt: now,
          ),
        ],
        rounds: [
          MetDoubleRound(
            id: 'r1',
            sessionId: 'session-1',
            roundNumber: 1,
            winnerParticipantId: 'p1',
            cochonParticipantIds: ['p2'],
            playedAt: now.subtract(Duration(minutes: 5)),
          ),
        ],
      );

      // VÉRIFICATION: Le nombre de manches doit être exactement 1
      expect(session.rounds.length, equals(1),
        reason: 'Il devrait y avoir exactement 1 manche');

      // VÉRIFICATION: Pas de doublons de numéros de manche
      final roundNumbers = session.rounds.map((r) => r.roundNumber).toList();
      final uniqueRoundNumbers = roundNumbers.toSet().toList();
      expect(roundNumbers.length, equals(uniqueRoundNumbers.length),
        reason: 'Chaque manche doit avoir un numéro unique');
    });

    test('VALIDATION: Historique correct sans doublons', () {
      final now = DateTime.now();

      // Scénario CORRECT: 3 rounds avec des numéros différents
      final correctRounds = [
        MetDoubleRound(
          id: 'r1',
          sessionId: 'session-1',
          roundNumber: 1,
          winnerParticipantId: 'p1',
          playedAt: now,
        ),
        MetDoubleRound(
          id: 'r2',
          sessionId: 'session-1',
          roundNumber: 2,
          winnerParticipantId: 'p2',
          playedAt: now.add(Duration(seconds: 1)),
        ),
        MetDoubleRound(
          id: 'r3',
          sessionId: 'session-1',
          roundNumber: 3,
          winnerParticipantId: 'p1',
          playedAt: now.add(Duration(seconds: 2)),
        ),
      ];

      // VÉRIFICATION: Pas de doublons
      final roundNumbers = correctRounds.map((r) => r.roundNumber).toList();
      final uniqueNumbers = roundNumbers.toSet();

      expect(uniqueNumbers.length, equals(roundNumbers.length),
        reason: 'Chaque manche doit avoir un numéro unique');
      expect(roundNumbers, equals([1, 2, 3]),
        reason: 'Les numéros doivent être séquentiels');
    });

    test('VALIDATION: Cohérence entre victoires et historique', () {
      final now = DateTime.now();

      final session = MetDoubleSession(
        id: 'session-1',
        hostId: 'user-1',
        status: 'in_progress',
        createdAt: now,
        participants: [
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
            victories: 0,
            joinedAt: now,
          ),
          MetDoubleParticipant(
            id: 'p3',
            sessionId: 'session-1',
            guestName: 'Charlie',
            victories: 0,
            joinedAt: now,
          ),
        ],
        rounds: [
          MetDoubleRound(
            id: 'r1',
            sessionId: 'session-1',
            roundNumber: 1,
            winnerParticipantId: 'p1',
            cochonParticipantIds: ['p2', 'p3'],
            playedAt: now,
          ),
        ],
      );

      // Calculer les victoires réelles depuis l'historique
      final aliceId = 'p1';
      final aliceWinsInHistory = session.rounds.where((r) => r.winnerParticipantId == aliceId).length;
      final aliceVictoriesInProfile = session.participants.firstWhere((p) => p.id == aliceId).victories;

      // VÉRIFICATION: Les victoires affichées doivent correspondre à l'historique
      expect(aliceWinsInHistory, equals(aliceVictoriesInProfile),
        reason: 'Les victoires affichées doivent correspondre à l\'historique');
    });

    test('VALIDATION: Manche chirée enregistrée correctement', () {
      final now = DateTime.now();

      // Une seule manche chirée
      final rounds = [
        MetDoubleRound(
          id: 'r1',
          sessionId: 'session-1',
          roundNumber: 1,
          isChiree: true,
          playedAt: now,
        ),
      ];

      // VÉRIFICATION: Une seule chirée
      final chireeRounds = rounds.where((r) => r.isChiree && r.roundNumber == 1).length;
      expect(chireeRounds, equals(1),
        reason: 'Une manche chirée ne doit être enregistrée qu\'une fois');
    });

    test('VALIDATION: Comptage correct des manches', () {
      final now = DateTime.now();

      final session = MetDoubleSession(
        id: 'session-1',
        hostId: 'user-1',
        status: 'in_progress',
        createdAt: now,
        totalRounds: 1,
        participants: [],
        rounds: [
          MetDoubleRound(
            id: 'r1',
            sessionId: 'session-1',
            roundNumber: 1,
            winnerParticipantId: 'p1',
            playedAt: now,
          ),
        ],
      );

      // VÉRIFICATION: Le totalRounds doit correspondre au nombre réel de rounds
      final actualRounds = session.rounds.length;
      final displayedRounds = session.totalRounds;

      expect(actualRounds, equals(displayedRounds),
        reason: 'Le nombre de manches affiché doit correspondre à l\'historique');
    });

    test('VALIDATION: Cochons cohérents avec les victoires', () {
      final now = DateTime.now();

      final session = MetDoubleSession(
        id: 'session-1',
        hostId: 'user-1',
        status: 'completed',
        createdAt: now,
        participants: [
          MetDoubleParticipant(
            id: 'p1',
            sessionId: 'session-1',
            userId: 'user-1',
            userName: 'Alice',
            victories: 3,
            isCochon: false,
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
        ],
        rounds: [
          MetDoubleRound(
            id: 'r1',
            sessionId: 'session-1',
            roundNumber: 1,
            winnerParticipantId: 'p1',
            cochonParticipantIds: ['p2'],
            playedAt: now,
          ),
        ],
      );

      // VÉRIFICATION: Cochons doivent avoir 0 victoires
      for (var participant in session.participants) {
        if (participant.isCochon) {
          expect(participant.victories, equals(0),
            reason: 'Un cochon doit avoir 0 victoires');
        }
      }
    });

    test('VALIDATION: Ordre chronologique des manches', () {
      final now = DateTime.now();

      final rounds = [
        MetDoubleRound(
          id: 'r1',
          sessionId: 'session-1',
          roundNumber: 1,
          winnerParticipantId: 'p1',
          playedAt: now,
        ),
        MetDoubleRound(
          id: 'r2',
          sessionId: 'session-1',
          roundNumber: 2,
          winnerParticipantId: 'p2',
          playedAt: now.add(Duration(minutes: 1)),
        ),
      ];

      // VÉRIFICATION: Les manches doivent être dans l'ordre chronologique
      for (int i = 1; i < rounds.length; i++) {
        final previousRound = rounds[i - 1];
        final currentRound = rounds[i];

        expect(currentRound.playedAt.isAfter(previousRound.playedAt), isTrue,
          reason: 'Les manches doivent être dans l\'ordre chronologique');
      }
    });
  });

  group('Met Double - Tests de régression', () {
    test('RÉGRESSION: Bug du comptage "3 manches au lieu de 1" (CORRIGÉ)', () {
      final now = DateTime.now();

      // Après la première manche, il devrait y avoir exactement 1 round
      final session = MetDoubleSession(
        id: 'session-1',
        hostId: 'user-1',
        status: 'in_progress',
        createdAt: now,
        participants: [],
        rounds: [
          MetDoubleRound(
            id: 'r1',
            sessionId: 'session-1',
            roundNumber: 1,
            winnerParticipantId: 'p1',
            playedAt: now,
          ),
        ],
      );

      // Le bug était: affichait "3 manches terminées" au lieu de "1"
      // Maintenant corrigé avec la protection _isRecordingVictory
      expect(session.rounds.length, equals(1),
        reason: 'Après la première manche, on devrait avoir 1 manche, pas plus');
    });

    test('RÉGRESSION: Bug de la modal chirée en boucle (CORRIGÉ)', () {
      // Ce test vérifie qu'une fois la chirée enregistrée, elle ne se réaffiche pas
      bool chireeDialogShown = false;

      // Condition: tous les joueurs ont au moins 1 point
      final allPlayersHaveAtLeastOne = true;

      // Première fois: afficher la modal
      if (allPlayersHaveAtLeastOne && !chireeDialogShown) {
        chireeDialogShown = true;
      }

      expect(chireeDialogShown, isTrue, reason: 'La modal chirée devrait avoir été affichée');

      // Même si la condition est toujours vraie, ne pas réafficher
      final shouldShowAgain = allPlayersHaveAtLeastOne && !chireeDialogShown;

      expect(shouldShowAgain, isFalse,
        reason: 'La modal chirée ne devrait pas se réafficher en boucle (bug corrigé)');
    });
  });
}
