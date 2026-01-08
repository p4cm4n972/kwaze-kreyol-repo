import 'dart:math';
import '../models/domino_tile.dart';

/// Niveaux de difficulté de l'IA
enum AIDifficulty {
  easy,   // Facile: choix aléatoire
  normal, // Normal: priorité doubles + haute valeur
  hard,   // Difficile: stratégie de blocage
}

/// Représente un coup choisi par l'IA
class AIMove {
  final DominoTile tile;
  final String side; // 'left' ou 'right'

  const AIMove({required this.tile, required this.side});

  @override
  String toString() => 'AIMove($tile sur $side)';
}

/// Service de décision IA pour le jeu de dominos
class DominoAIService {
  static final Random _random = Random();

  /// Sélectionne le meilleur coup pour l'IA selon la difficulté
  static AIMove? selectMove({
    required List<DominoTile> hand,
    required int? leftEnd,
    required int? rightEnd,
    required List<PlacedTile> board,
    required AIDifficulty difficulty,
  }) {
    // Si plateau vide, jouer n'importe quelle tuile
    if (board.isEmpty) {
      if (hand.isEmpty) return null;
      final tile = _selectTileForEmptyBoard(hand, difficulty);
      return AIMove(tile: tile, side: 'right');
    }

    // Trouver les tuiles jouables
    final playableMoves = <AIMove>[];

    for (final tile in hand) {
      if (leftEnd != null && tile.canConnect(leftEnd)) {
        playableMoves.add(AIMove(tile: tile, side: 'left'));
      }
      if (rightEnd != null && tile.canConnect(rightEnd)) {
        // Éviter les doublons si les deux extrémités ont la même valeur
        if (leftEnd == null || leftEnd != rightEnd || !tile.canConnect(leftEnd)) {
          playableMoves.add(AIMove(tile: tile, side: 'right'));
        } else if (!playableMoves.any((m) => m.tile == tile)) {
          playableMoves.add(AIMove(tile: tile, side: 'right'));
        }
      }
    }

    if (playableMoves.isEmpty) return null;

    // Sélection selon la difficulté
    switch (difficulty) {
      case AIDifficulty.easy:
        return _selectEasy(playableMoves);
      case AIDifficulty.normal:
        return _selectNormal(playableMoves);
      case AIDifficulty.hard:
        return _selectHard(playableMoves, board, leftEnd, rightEnd);
    }
  }

  /// Détermine si l'IA doit passer son tour
  static bool shouldPass({
    required List<DominoTile> hand,
    required int? leftEnd,
    required int? rightEnd,
    required bool boardEmpty,
  }) {
    if (boardEmpty) return false;
    if (hand.isEmpty) return true;

    for (final tile in hand) {
      if (leftEnd != null && tile.canConnect(leftEnd)) return false;
      if (rightEnd != null && tile.canConnect(rightEnd)) return false;
    }
    return true;
  }

  /// Retourne le délai de réflexion en millisecondes selon la difficulté
  static int getThinkingDelay(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return 800 + _random.nextInt(400); // 800-1200ms
      case AIDifficulty.normal:
        return 600 + _random.nextInt(400); // 600-1000ms
      case AIDifficulty.hard:
        return 500 + _random.nextInt(300); // 500-800ms
    }
  }

  /// Sélection pour plateau vide selon la difficulté
  static DominoTile _selectTileForEmptyBoard(List<DominoTile> hand, AIDifficulty difficulty) {
    if (difficulty == AIDifficulty.easy) {
      return hand[_random.nextInt(hand.length)];
    }

    // Normal et Hard: jouer le double le plus haut ou la tuile la plus haute
    final doubles = hand.where((t) => t.isDouble).toList();
    if (doubles.isNotEmpty) {
      doubles.sort((a, b) => b.totalValue.compareTo(a.totalValue));
      return doubles.first;
    }

    final sorted = List<DominoTile>.from(hand)
      ..sort((a, b) => b.totalValue.compareTo(a.totalValue));
    return sorted.first;
  }

  /// Stratégie FACILE: choix aléatoire
  static AIMove _selectEasy(List<AIMove> moves) {
    return moves[_random.nextInt(moves.length)];
  }

  /// Stratégie NORMALE: priorité doubles, puis haute valeur
  static AIMove _selectNormal(List<AIMove> moves) {
    // 1. Chercher les doubles (pour s'en débarrasser)
    final doubleMoves = moves.where((m) => m.tile.isDouble).toList();
    if (doubleMoves.isNotEmpty) {
      // Jouer le double le plus haut
      doubleMoves.sort((a, b) => b.tile.totalValue.compareTo(a.tile.totalValue));
      return doubleMoves.first;
    }

    // 2. Sinon, jouer la tuile avec le plus de points
    final sorted = List<AIMove>.from(moves)
      ..sort((a, b) => b.tile.totalValue.compareTo(a.tile.totalValue));
    return sorted.first;
  }

  /// Stratégie DIFFICILE: blocage et optimisation
  static AIMove _selectHard(
    List<AIMove> moves,
    List<PlacedTile> board,
    int? leftEnd,
    int? rightEnd,
  ) {
    // Compter les valeurs jouées sur le plateau
    final valueCounts = <int, int>{};
    for (var i = 0; i <= 6; i++) {
      valueCounts[i] = 0;
    }
    for (final placed in board) {
      valueCounts[placed.tile.value1] = valueCounts[placed.tile.value1]! + 1;
      valueCounts[placed.tile.value2] = valueCounts[placed.tile.value2]! + 1;
    }

    // Scorer chaque coup
    final scoredMoves = <MapEntry<AIMove, double>>[];

    for (final move in moves) {
      double score = 0;

      // Points de base: valeur de la tuile (se débarrasser des gros points)
      score += move.tile.totalValue * 2;

      // Bonus pour les doubles (s'en débarrasser tôt)
      if (move.tile.isDouble) {
        score += 15;
      }

      // Stratégie de blocage: jouer des valeurs rares
      // Si une valeur est très jouée (6+ fois), elle est rare en main adverse
      final exposedValue = move.tile.getOppositeValue(
        move.side == 'left' ? leftEnd! : rightEnd!
      );
      final exposedCount = valueCounts[exposedValue] ?? 0;
      if (exposedCount >= 5) {
        // Cette valeur est rare, bon pour bloquer
        score += 10;
      }

      // Pénalité pour exposer des valeurs très disponibles
      if (exposedCount <= 2) {
        score -= 5;
      }

      scoredMoves.add(MapEntry(move, score));
    }

    // Trier par score décroissant
    scoredMoves.sort((a, b) => b.value.compareTo(a.value));

    // Ajouter un peu d'aléatoire parmi les meilleurs coups (top 3)
    final topMoves = scoredMoves.take(3).toList();
    if (topMoves.length > 1 && _random.nextDouble() < 0.3) {
      // 30% de chance de prendre le 2ème ou 3ème meilleur coup
      return topMoves[_random.nextInt(topMoves.length)].key;
    }

    return scoredMoves.first.key;
  }
}
