import '../models/domino_tile.dart';
import '../models/domino_participant.dart';

/// Système de scoring pour les dominos martiniquais
class DominoScoring {
  /// Calcule les points dans une main (somme des valeurs des tuiles)
  ///
  /// Exemple:
  /// - [2|3] + [4|5] + [1|6] = 5 + 9 + 7 = 21 points
  static int calculateHandPoints(List<DominoTile> hand) {
    return hand.fold(0, (sum, tile) => sum + tile.totalValue);
  }

  /// Calcule les scores finaux pour tous les joueurs
  ///
  /// Retourne: Map<participantId, points>
  static Map<String, int> calculateFinalScores(
    Map<String, List<DominoTile>> hands,
  ) {
    return hands.map(
      (key, tiles) => MapEntry(key, calculateHandPoints(tiles)),
    );
  }

  /// Détermine les cochons (joueurs avec 0 manche à la fin de la partie)
  ///
  /// Un joueur est "cochon" s'il termine la partie sans avoir gagné
  /// une seule manche (rounds_won = 0)
  static List<String> determineCochons(List<DominoParticipant> participants) {
    return participants
        .where((p) => p.roundsWon == 0)
        .map((p) => p.id)
        .toList();
  }

  /// Vérifie si la partie est une "chirée"
  ///
  /// Une partie est chirée quand tous les joueurs ont gagné au moins
  /// une manche (tous ont rounds_won ≥ 1) ET aucun n'a atteint 3 manches.
  ///
  /// La chirée est une condition de fin de partie alternative (match nul).
  /// Si tous les joueurs atteignent ≥1 manche, la partie s'arrête
  /// immédiatement en égalité, sans attendre qu'un joueur atteigne 3.
  ///
  /// Règle martiniquaise: égalité honorable
  static bool isChiree(List<DominoParticipant> participants) {
    if (participants.length != 3) {
      return false;
    }

    // Tous les joueurs doivent avoir au moins 1 manche
    final allHaveAtLeastOne = participants.every((p) => p.roundsWon >= 1);

    // Aucun joueur ne doit avoir atteint 3 manches (sinon c'est une victoire)
    final noneHasThree = participants.every((p) => p.roundsWon < 3);

    return allHaveAtLeastOne && noneHasThree;
  }

  /// Obtient le classement des joueurs par nombre de manches gagnées
  ///
  /// Retourne: List<DominoParticipant> triée par rounds_won DESC
  static List<DominoParticipant> getRanking(
    List<DominoParticipant> participants,
  ) {
    final sorted = List<DominoParticipant>.from(participants);
    sorted.sort((a, b) => b.roundsWon.compareTo(a.roundsWon));
    return sorted;
  }

  /// Calcule la différence de points entre le gagnant et les autres
  ///
  /// Utile pour afficher les écarts dans l'UI
  static Map<String, int> calculatePointGaps(
    Map<String, int> finalScores,
    String winnerId,
  ) {
    final winnerScore = finalScores[winnerId] ?? 0;

    return finalScores.map(
      (key, score) => MapEntry(key, score - winnerScore),
    );
  }

  /// Détermine si un joueur peut encore gagner
  ///
  /// Un joueur peut gagner s'il peut atteindre 3 manches avant les autres
  static bool canStillWin(
    DominoParticipant player,
    List<DominoParticipant> allPlayers,
  ) {
    // Si déjà à 3 manches, a déjà gagné
    if (player.roundsWon >= 3) {
      return false;
    }

    // Si un autre joueur a déjà 3 manches, ne peut plus gagner
    if (allPlayers.any((p) => p.roundsWon >= 3)) {
      return false;
    }

    return true;
  }

  /// Calcule les statistiques de la manche
  static Map<String, dynamic> getRoundStats(
    Map<String, int> finalScores,
    String winnerId,
    String endType,
  ) {
    final scores = finalScores.values.toList();

    return {
      'winner_id': winnerId,
      'end_type': endType,
      'winner_score': finalScores[winnerId] ?? 0,
      'total_points': scores.fold(0, (sum, score) => sum + score),
      'average_points': scores.isEmpty
          ? 0
          : (scores.fold(0, (sum, score) => sum + score) / scores.length)
              .round(),
      'highest_score': scores.isEmpty ? 0 : scores.reduce((a, b) => a > b ? a : b),
      'lowest_score': scores.isEmpty ? 0 : scores.reduce((a, b) => a < b ? a : b),
      'is_capot': endType == 'capot',
      'is_blocked': endType == 'blocked',
    };
  }

  /// Obtient un message descriptif pour le type de fin de manche
  static String getEndTypeMessage(String endType, String winnerName) {
    switch (endType) {
      case 'capot':
        return '$winnerName a fait capot! (toutes les tuiles posées)';
      case 'blocked':
        return 'Jeu bloqué! $winnerName gagne avec le moins de points';
      default:
        return '$winnerName a gagné la manche';
    }
  }

  /// Calcule le taux de victoire d'un joueur
  static double calculateWinRate(int wins, int totalGames) {
    if (totalGames == 0) return 0.0;
    return (wins / totalGames * 100);
  }

  /// Détermine le statut final d'un joueur
  static String getPlayerStatus(DominoParticipant player, bool gameCompleted) {
    if (!gameCompleted) {
      return 'En cours...';
    }

    if (player.roundsWon >= 3) {
      return 'Gagnant! 🏆';
    }

    if (player.isCochon) {
      return 'Cochon 🐷';
    }

    return '${player.roundsWon} manche${player.roundsWon > 1 ? 's' : ''}';
  }

  /// Obtient un emoji pour le statut du joueur
  static String getPlayerEmoji(DominoParticipant player, bool isWinner) {
    if (isWinner) return '🏆';
    if (player.isCochon) return '🐷';
    if (player.roundsWon >= 2) return '🔥';
    if (player.roundsWon >= 1) return '👍';
    return '😐';
  }

  /// Calcule le score total d'une session (pour les stats)
  static Map<String, dynamic> calculateSessionStats(
    List<DominoParticipant> participants,
    int totalRounds,
  ) {
    final winner = participants.firstWhere(
      (p) => p.roundsWon >= 3,
      orElse: () => participants.first,
    );

    final cochons = determineCochons(participants);
    final isChireeResult = isChiree(participants);

    return {
      'winner_id': winner.id,
      'winner_name': winner.displayName,
      'winner_rounds': winner.roundsWon,
      'total_rounds': totalRounds,
      'cochons_count': cochons.length,
      'cochon_ids': cochons,
      'is_chiree': isChireeResult,
      'participants_count': participants.length,
    };
  }

  /// Vérifie si une manche est décisive (détermine le gagnant)
  static bool isDecisiveRound(List<DominoParticipant> participants) {
    // Décisive si un joueur atteint 3 manches
    return participants.any((p) => p.roundsWon >= 3);
  }

  /// Obtient le message de fin de partie
  static String getGameEndMessage(
    DominoParticipant winner,
    List<DominoParticipant> cochons,
    bool isChireeResult,
  ) {
    final cochonNames = cochons.map((c) => c.displayName).join(', ');

    if (isChireeResult) {
      return 'Partie chirée! ${winner.displayName} gagne mais tous ont au moins 1 manche.';
    }

    if (cochons.isNotEmpty) {
      return '${winner.displayName} gagne! Cochon${cochons.length > 1 ? 's' : ''}: $cochonNames 🐷';
    }

    return '${winner.displayName} remporte la partie!';
  }
}
