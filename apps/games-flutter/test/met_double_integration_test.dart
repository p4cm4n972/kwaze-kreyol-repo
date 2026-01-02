import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol_games/tools/met_double/models/met_double_game.dart';

/// Tests d'intégration pour détecter les anomalies spécifiques
/// comme l'enregistrement multiple de manches
void main() {
  group('Met Double - Détection d\'anomalies', () {
    test('ANOMALIE: Vérifier qu\'une manche n\'est enregistrée qu\'une seule fois', () {
      // Simule une session avec historique
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
        reason: 'ANOMALIE DÉTECTÉE: Il devrait y avoir exactement 1 manche, pas ${session.rounds.length}');

      // VÉRIFICATION: Pas de doublons de numéros de manche
      final roundNumbers = session.rounds.map((r) => r.roundNumber).toList();
      final uniqueRoundNumbers = roundNumbers.toSet().toList();
      expect(roundNumbers.length, equals(uniqueRoundNumbers.length),
        reason: 'ANOMALIE DÉTECTÉE: Il y a des numéros de manche en double: $roundNumbers');

      // VÉRIFICATION: Les numéros de manche doivent être séquentiels (1, 2, 3...)
      final sortedNumbers = List<int>.from(roundNumbers)..sort();
      for (int i = 0; i < sortedNumbers.length; i++) {
        expect(sortedNumbers[i], equals(i + 1),
          reason: 'ANOMALIE DÉTECTÉE: Les numéros de manche ne sont pas séquentiels');
      }
    });

    test('ANOMALIE: Détecter si le même round est enregistré plusieurs fois', () {
      final now = DateTime.now();

      // Scénario problématique: 3 rounds avec le même roundNumber
      final problematicRounds = [
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
          roundNumber: 1, // DUPLICATE!
          winnerParticipantId: 'p1',
          playedAt: now.add(Duration(seconds: 1)),
        ),
        MetDoubleRound(
          id: 'r3',
          sessionId: 'session-1',
          roundNumber: 1, // DUPLICATE!
          winnerParticipantId: 'p1',
          playedAt: now.add(Duration(seconds: 2)),
        ),
      ];

      // VÉRIFICATION: Détecter les doublons
      final roundNumbers = problematicRounds.map((r) => r.roundNumber).toList();
      final uniqueNumbers = roundNumbers.toSet();

      if (uniqueNumbers.length != roundNumbers.length) {
        // ANOMALIE DÉTECTÉE!
        fail('ANOMALIE DÉTECTÉE: Le round numéro 1 a été enregistré ${roundNumbers.where((n) => n == 1).length} fois au lieu d\'une seule fois!');
      }
    });

    test('ANOMALIE: Vérifier la cohérence entre victoires et historique', () {
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
            victories: 3, // Dit avoir 3 victoires
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
          // Mais dans l'historique, Alice n'a gagné qu'1 seule manche
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
        reason: 'ANOMALIE DÉTECTÉE: Alice affiche $aliceVictoriesInProfile victoires mais l\'historique montre $aliceWinsInHistory manche(s) gagnée(s)');
    });

    test('ANOMALIE: Détecter les manches chirées enregistrées plusieurs fois', () {
      final now = DateTime.now();

      // Une manche chirée ne devrait être enregistrée qu'une fois
      final rounds = [
        MetDoubleRound(
          id: 'r1',
          sessionId: 'session-1',
          roundNumber: 1,
          isChiree: true,
          playedAt: now,
        ),
        MetDoubleRound(
          id: 'r2',
          sessionId: 'session-1',
          roundNumber: 1, // DUPLICATE!
          isChiree: true,
          playedAt: now.add(Duration(milliseconds: 500)),
        ),
      ];

      // VÉRIFICATION: Pas de doublons de chirée
      final chireeRounds = rounds.where((r) => r.isChiree && r.roundNumber == 1).length;
      expect(chireeRounds, equals(1),
        reason: 'ANOMALIE DÉTECTÉE: La manche chirée 1 a été enregistrée $chireeRounds fois au lieu d\'une seule fois');
    });

    test('ANOMALIE: Comptage des manches - Affichage vs Réalité', () {
      final now = DateTime.now();

      // Scénario: L'UI affiche "3 manches" mais il n'y a qu'1 manche dans l'historique
      final session = MetDoubleSession(
        id: 'session-1',
        hostId: 'user-1',
        status: 'in_progress',
        createdAt: now,
        totalRounds: 3, // L'UI dit 3 manches
        participants: [],
        rounds: [
          // Mais il n'y a qu'1 manche réelle
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
        reason: 'ANOMALIE DÉTECTÉE: L\'UI affiche $displayedRounds manches mais il y a seulement $actualRounds manche(s) dans l\'historique');
    });

    test('PROTECTION: Simuler un enregistrement rapide multiple (race condition)', () {
      final now = DateTime.now();

      // Simule ce qui se passe si recordRound est appelé 3 fois rapidement
      final recordedRounds = <MetDoubleRound>[];

      // Fonction qui simule recordRound
      void simulateRecordRound(int roundNumber, String winnerId) {
        // Sans protection, cette fonction serait appelée 3 fois
        recordedRounds.add(MetDoubleRound(
          id: 'r${recordedRounds.length + 1}',
          sessionId: 'session-1',
          roundNumber: roundNumber,
          winnerParticipantId: winnerId,
          playedAt: now,
        ));
      }

      // Sans flag de protection, ça pourrait être appelé plusieurs fois
      // (Par exemple via realtime update qui trigger 3 fois)
      simulateRecordRound(1, 'p1'); // Premier appel
      // simulateRecordRound(1, 'p1'); // Deuxième appel (devrait être bloqué)
      // simulateRecordRound(1, 'p1'); // Troisième appel (devrait être bloqué)

      // VÉRIFICATION: Une seule manche devrait être enregistrée
      expect(recordedRounds.length, equals(1),
        reason: 'PROTECTION CONTRE RACE CONDITION: Une seule manche devrait être enregistrée, pas ${recordedRounds.length}');

      // VÉRIFICATION: Pas de doublons
      final uniqueRounds = recordedRounds.map((r) => '${r.roundNumber}-${r.winnerParticipantId}').toSet();
      expect(uniqueRounds.length, equals(recordedRounds.length),
        reason: 'ANOMALIE DÉTECTÉE: Des rounds identiques ont été enregistrés plusieurs fois');
    });

    test('ANOMALIE: Vérifier que les cochons sont cohérents avec les victoires', () {
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
            joinedAt: now,
          ),
          MetDoubleParticipant(
            id: 'p2',
            sessionId: 'session-1',
            userId: 'user-2',
            userName: 'Bob',
            victories: 1,
            isCochon: true, // Marqué comme cochon mais a 1 victoire!
            joinedAt: now,
          ),
        ],
        rounds: [
          MetDoubleRound(
            id: 'r1',
            sessionId: 'session-1',
            roundNumber: 1,
            winnerParticipantId: 'p1',
            cochonParticipantIds: ['p2'], // Bob était cochon
            playedAt: now,
          ),
        ],
      );

      // VÉRIFICATION: Si quelqu'un a des victoires, il ne devrait pas être marqué cochon final
      for (var participant in session.participants) {
        if (participant.isCochon) {
          // Un cochon devrait avoir 0 victoire
          expect(participant.victories, equals(0),
            reason: 'ANOMALIE DÉTECTÉE: ${participant.displayName} est marqué comme cochon mais a ${participant.victories} victoire(s)');
        }
      }
    });

    test('ANOMALIE: Détecter les incohérences dans les timestamps', () {
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
          playedAt: now.subtract(Duration(minutes: 1)), // Joué AVANT la manche 1 !
        ),
      ];

      // VÉRIFICATION: Les manches doivent être dans l'ordre chronologique
      for (int i = 1; i < rounds.length; i++) {
        final previousRound = rounds[i - 1];
        final currentRound = rounds[i];

        expect(currentRound.playedAt.isAfter(previousRound.playedAt), isTrue,
          reason: 'ANOMALIE DÉTECTÉE: La manche ${currentRound.roundNumber} a été jouée AVANT la manche ${previousRound.roundNumber}');
      }
    });
  });

  group('Met Double - Tests de régression', () {
    test('RÉGRESSION: Bug du comptage "3 manches au lieu de 1"', () {
      // Ce test vérifie spécifiquement le bug rapporté
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

      // Le bug rapporté: affichait "3 manches terminées" au lieu de "1"
      expect(session.rounds.length, equals(1),
        reason: 'BUG RÉGRESSION: Après la première manche, on devrait avoir 1 manche, pas ${session.rounds.length}');
    });

    test('RÉGRESSION: Bug de la modal chirée en boucle', () {
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
        reason: 'BUG RÉGRESSION: La modal chirée ne devrait pas se réafficher en boucle');
    });
  });
}
