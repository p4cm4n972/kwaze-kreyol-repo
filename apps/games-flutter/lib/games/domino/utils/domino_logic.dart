import 'dart:math';
import '../models/domino_tile.dart';

/// Logique de jeu pour les dominos martiniquais
class DominoLogic {
  /// Crée l'ensemble complet de 28 tuiles (0-0 à 6-6)
  static List<DominoTile> createFullSet() {
    return DominoTile.createFullSet();
  }

  /// Mélange et distribue les tuiles à 3 joueurs
  /// Retourne: Map<participantId, List<DominoTile>>
  /// - 7 tuiles par joueur (21 total)
  /// - 7 tuiles restent inutilisées
  static Map<String, List<DominoTile>> distributeTiles(
    List<String> participantIds,
  ) {
    assert(participantIds.length == 3, '3 joueurs requis');

    final tiles = createFullSet()..shuffle();

    return {
      participantIds[0]: tiles.sublist(0, 7),
      participantIds[1]: tiles.sublist(7, 14),
      participantIds[2]: tiles.sublist(14, 21),
      // tiles.sublist(21, 28) restent inutilisées
    };
  }

  /// Détermine le joueur qui commence
  ///
  /// Règles:
  /// - Si previousWinnerId fourni: le gagnant précédent commence
  /// - Sinon: joueur avec le double le plus haut
  /// - Fallback: joueur avec la tuile de valeur totale la plus haute
  static String determineStartingPlayer(
    Map<String, List<DominoTile>> hands, {
    String? previousWinnerId,
  }) {
    // Si gagnant précédent spécifié, il commence
    if (previousWinnerId != null && hands.containsKey(previousWinnerId)) {
      return previousWinnerId;
    }

    // Chercher le double le plus haut
    String? highestDoublePlayer;
    int highestDouble = -1;

    for (var entry in hands.entries) {
      final doubles = entry.value.where((t) => t.isDouble);
      if (doubles.isNotEmpty) {
        final maxDouble = doubles.map((t) => t.value1).reduce(max);
        if (maxDouble > highestDouble) {
          highestDouble = maxDouble;
          highestDoublePlayer = entry.key;
        }
      }
    }

    if (highestDoublePlayer != null) {
      return highestDoublePlayer;
    }

    // Fallback: tuile avec la valeur totale la plus haute
    String highestTilePlayer = hands.keys.first;
    int highestTotal = 0;

    for (var entry in hands.entries) {
      final maxTile = entry.value.map((t) => t.totalValue).reduce(max);
      if (maxTile > highestTotal) {
        highestTotal = maxTile;
        highestTilePlayer = entry.key;
      }
    }

    return highestTilePlayer;
  }

  /// Vérifie si une tuile peut être placée sur le plateau
  ///
  /// Règles:
  /// - Plateau vide: toujours possible
  /// - Sinon: la tuile doit se connecter à leftEnd OU rightEnd
  static bool canPlaceTile(
    DominoTile tile,
    int? leftEnd,
    int? rightEnd,
  ) {
    // Première tuile du plateau
    if (leftEnd == null && rightEnd == null) {
      return true;
    }

    // Vérifie connexion avec les bouts disponibles
    if (leftEnd != null && tile.canConnect(leftEnd)) {
      return true;
    }

    if (rightEnd != null && tile.canConnect(rightEnd)) {
      return true;
    }

    return false;
  }

  /// Vérifie si un joueur peut jouer au moins une tuile
  static bool canPlayerPlay(
    List<DominoTile> hand,
    int? leftEnd,
    int? rightEnd,
  ) {
    // Plateau vide: peut jouer si a des tuiles
    if (leftEnd == null && rightEnd == null) {
      return hand.isNotEmpty;
    }

    // Vérifie si au moins une tuile peut se connecter
    return hand.any((tile) => canPlaceTile(tile, leftEnd, rightEnd));
  }

  /// Vérifie si le jeu est bloqué (tous les joueurs ont passé)
  static bool isGameBlocked(
    List<String> passedPlayerIds,
    int totalPlayers,
  ) {
    return passedPlayerIds.length >= totalPlayers;
  }

  /// Détermine le gagnant en cas de jeu bloqué
  ///
  /// Règle: joueur avec le moins de points dans sa main
  /// (points = somme des valeurs des tuiles)
  static String determineBlockedWinner(
    Map<String, List<DominoTile>> hands,
  ) {
    assert(hands.isNotEmpty, 'Au moins un joueur requis');

    String winnerId = hands.keys.first;
    int lowestScore = _calculateHandPoints(hands.values.first);

    for (var entry in hands.entries) {
      final score = _calculateHandPoints(entry.value);
      if (score < lowestScore) {
        lowestScore = score;
        winnerId = entry.key;
      }
    }

    return winnerId;
  }

  /// Calcule les points dans une main (somme des valeurs des tuiles)
  static int _calculateHandPoints(List<DominoTile> hand) {
    return hand.fold(0, (sum, tile) => sum + tile.totalValue);
  }

  /// Obtient les tuiles jouables pour un joueur
  ///
  /// Retourne la liste des tuiles qui peuvent être placées
  static List<DominoTile> getPlayableTiles(
    List<DominoTile> hand,
    int? leftEnd,
    int? rightEnd,
  ) {
    // Plateau vide: toutes les tuiles sont jouables
    if (leftEnd == null && rightEnd == null) {
      return List.from(hand);
    }

    // Filtrer les tuiles qui peuvent se connecter
    return hand.where((tile) => canPlaceTile(tile, leftEnd, rightEnd)).toList();
  }

  /// Valide qu'un placement de tuile est légal
  ///
  /// Vérifie:
  /// - Le joueur possède la tuile
  /// - La tuile peut se connecter au bout choisi
  ///
  /// Lève une exception si invalide
  static void validateTilePlacement({
    required DominoTile tile,
    required List<DominoTile> hand,
    required String side,
    int? leftEnd,
    int? rightEnd,
  }) {
    // Vérifier que le joueur possède la tuile
    if (!hand.any((t) => t.id == tile.id)) {
      throw Exception('Vous ne possédez pas cette tuile');
    }

    // Première tuile: toujours valide
    if (leftEnd == null && rightEnd == null) {
      return;
    }

    // Vérifier la connexion selon le côté
    final targetEnd = side == 'left' ? leftEnd : rightEnd;

    if (targetEnd == null) {
      throw Exception('Côté invalide: $side');
    }

    if (!tile.canConnect(targetEnd)) {
      throw Exception(
        'Cette tuile ${tile.toString()} ne peut pas se connecter à $targetEnd',
      );
    }
  }

  /// Calcule le prochain joueur dans l'ordre de tour
  static String getNextPlayer(
    String currentPlayerId,
    List<String> playerIds,
  ) {
    assert(playerIds.length == 3, '3 joueurs requis');
    assert(playerIds.contains(currentPlayerId), 'Joueur actuel invalide');

    final currentIndex = playerIds.indexOf(currentPlayerId);
    final nextIndex = (currentIndex + 1) % 3;

    return playerIds[nextIndex];
  }

  /// Vérifie si un joueur a gagné par capot (main vide)
  static bool isCapot(List<DominoTile> hand) {
    return hand.isEmpty;
  }

  /// Compte le nombre de tuiles restantes au total
  static int countRemainingTiles(Map<String, List<DominoTile>> hands) {
    return hands.values.fold(0, (sum, hand) => sum + hand.length);
  }

  /// Obtient les statistiques d'une main
  static Map<String, dynamic> getHandStats(List<DominoTile> hand) {
    return {
      'tile_count': hand.length,
      'total_points': _calculateHandPoints(hand),
      'doubles_count': hand.where((t) => t.isDouble).length,
      'highest_tile': hand.isEmpty
          ? null
          : hand.reduce((a, b) => a.totalValue > b.totalValue ? a : b),
      'lowest_tile': hand.isEmpty
          ? null
          : hand.reduce((a, b) => a.totalValue < b.totalValue ? a : b),
    };
  }
}
