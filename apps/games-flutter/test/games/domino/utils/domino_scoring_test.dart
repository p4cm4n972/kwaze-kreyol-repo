import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol_games/games/domino/models/domino_tile.dart';
import 'package:kwaze_kreyol_games/games/domino/models/domino_participant.dart';
import 'package:kwaze_kreyol_games/games/domino/utils/domino_scoring.dart';

void main() {
  final testDate = DateTime(2024, 1, 1);

  group('DominoScoring', () {
    group('calculateHandPoints', () {
      test('should calculate total points in hand correctly', () {
        final hand = [
          DominoTile(value1: 3, value2: 5), // 8
          DominoTile(value1: 2, value2: 4), // 6
          DominoTile(value1: 1, value2: 0), // 1
        ];

        expect(DominoScoring.calculateHandPoints(hand), 15);
      });

      test('should return 0 for empty hand', () {
        final hand = <DominoTile>[];
        expect(DominoScoring.calculateHandPoints(hand), 0);
      });

      test('should handle hand with doubles', () {
        final hand = [
          DominoTile(value1: 6, value2: 6), // 12
          DominoTile(value1: 4, value2: 4), // 8
          DominoTile(value1: 0, value2: 0), // 0
        ];

        expect(DominoScoring.calculateHandPoints(hand), 20);
      });
    });

    group('calculateFinalScores', () {
      test('should calculate scores for all players', () {
        final hands = {
          'player1': [
            DominoTile(value1: 3, value2: 5), // 8
            DominoTile(value1: 2, value2: 4), // 6
          ],
          'player2': [
            DominoTile(value1: 1, value2: 2), // 3
          ],
          'player3': <DominoTile>[],
        };

        final scores = DominoScoring.calculateFinalScores(hands);

        expect(scores['player1'], 14);
        expect(scores['player2'], 3);
        expect(scores['player3'], 0);
      });
    });

    group('determineCochons', () {
      test('should identify players with 0 rounds won', () {
        final participants = [
          DominoParticipant(
            id: 'p1',
            sessionId: 's1',
            userId: 'u1',
            roundsWon: 2,
            turnOrder: 0,
            joinedAt: testDate,
          ),
          DominoParticipant(
            id: 'p2',
            sessionId: 's1',
            userId: 'u2',
            roundsWon: 0, // Cochon
            turnOrder: 1,
            joinedAt: testDate,
          ),
          DominoParticipant(
            id: 'p3',
            sessionId: 's1',
            userId: 'u3',
            roundsWon: 1,
            turnOrder: 2,
            joinedAt: testDate,
          ),
        ];

        final cochons = DominoScoring.determineCochons(participants);

        expect(cochons.length, 1);
        expect(cochons.first, 'p2');
      });

      test('should return empty list if no cochons', () {
        final participants = [
          DominoParticipant(
            id: 'p1',
            sessionId: 's1',
            userId: 'u1',
            roundsWon: 2,
            turnOrder: 0,
            joinedAt: testDate,
          ),
          DominoParticipant(
            id: 'p2',
            sessionId: 's1',
            userId: 'u2',
            roundsWon: 1,
            turnOrder: 1,
            joinedAt: testDate,
          ),
          DominoParticipant(
            id: 'p3',
            sessionId: 's1',
            userId: 'u3',
            roundsWon: 1,
            turnOrder: 2,
            joinedAt: testDate,
          ),
        ];

        final cochons = DominoScoring.determineCochons(participants);
        expect(cochons.length, 0);
      });

      test('should handle multiple cochons', () {
        final participants = [
          DominoParticipant(
            id: 'p1',
            sessionId: 's1',
            userId: 'u1',
            roundsWon: 3,
            turnOrder: 0,
            joinedAt: testDate,
          ),
          DominoParticipant(
            id: 'p2',
            sessionId: 's1',
            userId: 'u2',
            roundsWon: 0, // Cochon
            turnOrder: 1,
            joinedAt: testDate,
          ),
          DominoParticipant(
            id: 'p3',
            sessionId: 's1',
            userId: 'u3',
            roundsWon: 0, // Cochon
            turnOrder: 2,
            joinedAt: testDate,
          ),
        ];

        final cochons = DominoScoring.determineCochons(participants);
        expect(cochons.length, 2);
      });
    });

    group('isChiree', () {
      test('should return true if all players have at least 1 round won', () {
        final participants = [
          DominoParticipant(
            id: 'p1',
            sessionId: 's1',
            userId: 'u1',
            roundsWon: 1,
            turnOrder: 0,
            joinedAt: testDate,
          ),
          DominoParticipant(
            id: 'p2',
            sessionId: 's1',
            userId: 'u2',
            roundsWon: 2,
            turnOrder: 1,
            joinedAt: testDate,
          ),
          DominoParticipant(
            id: 'p3',
            sessionId: 's1',
            userId: 'u3',
            roundsWon: 1,
            turnOrder: 2,
            joinedAt: testDate,
          ),
        ];

        expect(DominoScoring.isChiree(participants), true);
      });

      test('should return false if any player has 0 rounds won', () {
        final participants = [
          DominoParticipant(
            id: 'p1',
            sessionId: 's1',
            userId: 'u1',
            roundsWon: 2,
            turnOrder: 0,
            joinedAt: testDate,
          ),
          DominoParticipant(
            id: 'p2',
            sessionId: 's1',
            userId: 'u2',
            roundsWon: 0, // Cochon
            turnOrder: 1,
            joinedAt: testDate,
          ),
          DominoParticipant(
            id: 'p3',
            sessionId: 's1',
            userId: 'u3',
            roundsWon: 1,
            turnOrder: 2,
            joinedAt: testDate,
          ),
        ];

        expect(DominoScoring.isChiree(participants), false);
      });
    });

    group('getRanking', () {
      test('should sort participants by rounds won (descending)', () {
        final participants = [
          DominoParticipant(
            id: 'p1',
            sessionId: 's1',
            userId: 'u1',
            roundsWon: 1,
            turnOrder: 0,
            joinedAt: testDate,
          ),
          DominoParticipant(
            id: 'p2',
            sessionId: 's1',
            userId: 'u2',
            roundsWon: 3,
            turnOrder: 1,
            joinedAt: testDate,
          ),
          DominoParticipant(
            id: 'p3',
            sessionId: 's1',
            userId: 'u3',
            roundsWon: 0,
            turnOrder: 2,
            joinedAt: testDate,
          ),
        ];

        final ranking = DominoScoring.getRanking(participants);

        expect(ranking.length, 3);
        expect(ranking[0].id, 'p2'); // 3 rounds
        expect(ranking[1].id, 'p1'); // 1 round
        expect(ranking[2].id, 'p3'); // 0 rounds
      });

      test('should handle ties in rounds won', () {
        final participants = [
          DominoParticipant(
            id: 'p1',
            sessionId: 's1',
            userId: 'u1',
            roundsWon: 2,
            turnOrder: 0,
            joinedAt: testDate,
          ),
          DominoParticipant(
            id: 'p2',
            sessionId: 's1',
            userId: 'u2',
            roundsWon: 2,
            turnOrder: 1,
            joinedAt: testDate,
          ),
          DominoParticipant(
            id: 'p3',
            sessionId: 's1',
            userId: 'u3',
            roundsWon: 1,
            turnOrder: 2,
            joinedAt: testDate,
          ),
        ];

        final ranking = DominoScoring.getRanking(participants);

        expect(ranking.length, 3);
        expect(ranking[0].roundsWon, 2);
        expect(ranking[1].roundsWon, 2);
        expect(ranking[2].roundsWon, 1);
      });
    });
  });
}
