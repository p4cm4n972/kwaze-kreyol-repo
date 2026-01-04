import 'board.dart';
import 'tile.dart';
import 'move.dart';
import 'letter_distribution.dart';

/// Représente une partie de Skrabb (Scrabble créole)
class SkrabbGame {
  /// ID unique de la partie
  final String id;

  /// ID de l'utilisateur
  final String userId;

  /// Statut de la partie: 'in_progress', 'completed', 'abandoned'
  final String status;

  /// Plateau de jeu 15x15
  final Board board;

  /// Chevalet du joueur (7 tuiles maximum)
  final List<Tile> rack;

  /// Sac de lettres restantes
  final List<Tile> tileBag;

  /// Historique des coups joués
  final List<Move> moveHistory;

  /// Score total actuel
  final int score;

  /// Temps écoulé en secondes
  final int timeElapsed;

  /// Date de création de la partie
  final DateTime createdAt;

  /// Date de dernière mise à jour
  final DateTime updatedAt;

  /// Date de complétion (si completed)
  final DateTime? completedAt;

  SkrabbGame({
    required this.id,
    required this.userId,
    required this.status,
    required this.board,
    required this.rack,
    required this.tileBag,
    required this.moveHistory,
    required this.score,
    required this.timeElapsed,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  /// Crée une nouvelle partie
  factory SkrabbGame.create({
    required String id,
    required String userId,
  }) {
    final distribution = LetterDistribution.creole();
    final tileBag = distribution.createTileBag();

    // Piocher 7 tuiles pour le chevalet initial
    final rack = <Tile>[];
    for (int i = 0; i < 7 && tileBag.isNotEmpty; i++) {
      rack.add(tileBag.removeLast());
    }

    final now = DateTime.now();

    return SkrabbGame(
      id: id,
      userId: userId,
      status: 'in_progress',
      board: Board(),
      rack: rack,
      tileBag: tileBag,
      moveHistory: [],
      score: 0,
      timeElapsed: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copie la partie avec de nouvelles valeurs
  SkrabbGame copyWith({
    String? id,
    String? userId,
    String? status,
    Board? board,
    List<Tile>? rack,
    List<Tile>? tileBag,
    List<Move>? moveHistory,
    int? score,
    int? timeElapsed,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return SkrabbGame(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      board: board ?? this.board,
      rack: rack ?? this.rack,
      tileBag: tileBag ?? this.tileBag,
      moveHistory: moveHistory ?? this.moveHistory,
      score: score ?? this.score,
      timeElapsed: timeElapsed ?? this.timeElapsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Convertit la partie en JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'board_data': board.toJson(),
      'rack': rack.map((t) => t.toJson()).toList(),
      'tile_bag': tileBag.map((t) => t.toJson()).toList(),
      'move_history': moveHistory.map((m) => m.toJson()).toList(),
      'score': score,
      'time_elapsed': timeElapsed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
    };
  }

  /// Crée une partie à partir de JSON Supabase
  factory SkrabbGame.fromJson(Map<String, dynamic> json) {
    return SkrabbGame(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      board: Board.fromJson(json['board_data'] as Map<String, dynamic>),
      rack: (json['rack'] as List)
          .map((t) => Tile.fromJson(t as Map<String, dynamic>))
          .toList(),
      tileBag: (json['tile_bag'] as List)
          .map((t) => Tile.fromJson(t as Map<String, dynamic>))
          .toList(),
      moveHistory: (json['move_history'] as List)
          .map((m) => Move.fromJson(m as Map<String, dynamic>))
          .toList(),
      score: json['score'] as int,
      timeElapsed: json['time_elapsed'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  /// Nombre de coups joués
  int get movesCount => moveHistory.length;

  /// Tuiles restantes dans le sac
  int get tilesLeftInBag => tileBag.length;

  /// Tuiles dans le chevalet
  int get tilesInRack => rack.length;

  /// Partie terminée
  bool get isCompleted => status == 'completed';

  /// Partie en cours
  bool get isInProgress => status == 'in_progress';

  /// Partie abandonnée
  bool get isAbandoned => status == 'abandoned';

  @override
  String toString() {
    return 'SkrabbGame(id: $id, status: $status, score: $score, '
        'moves: $movesCount, time: ${timeElapsed}s, '
        'rack: $tilesInRack, bag: $tilesLeftInBag)';
  }
}

/// Entrée du classement Skrabb
class SkrabbLeaderboardEntry {
  final String gameId;
  final String userId;
  final String username;
  final int score;
  final int timeElapsed;
  final DateTime completedAt;
  final int rank;

  SkrabbLeaderboardEntry({
    required this.gameId,
    required this.userId,
    required this.username,
    required this.score,
    required this.timeElapsed,
    required this.completedAt,
    required this.rank,
  });

  factory SkrabbLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return SkrabbLeaderboardEntry(
      gameId: json['game_id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      score: json['score'] as int,
      timeElapsed: json['time_elapsed'] as int,
      completedAt: DateTime.parse(json['completed_at'] as String),
      rank: json['rank'] as int,
    );
  }

  @override
  String toString() {
    return 'LeaderboardEntry(#$rank: $username - $score pts)';
  }
}

/// Statistiques d'un joueur Skrabb
class SkrabbPlayerStats {
  final int totalGames;
  final int completedGames;
  final int inProgressGames;
  final int abandonedGames;
  final int totalScore;
  final double averageScore;
  final int bestScore;
  final int totalTime;
  final double averageTime;
  final int bestTime;

  SkrabbPlayerStats({
    required this.totalGames,
    required this.completedGames,
    required this.inProgressGames,
    required this.abandonedGames,
    required this.totalScore,
    required this.averageScore,
    required this.bestScore,
    required this.totalTime,
    required this.averageTime,
    required this.bestTime,
  });

  factory SkrabbPlayerStats.fromJson(Map<String, dynamic> json) {
    return SkrabbPlayerStats(
      totalGames: json['total_games'] as int? ?? 0,
      completedGames: json['completed_games'] as int? ?? 0,
      inProgressGames: json['in_progress_games'] as int? ?? 0,
      abandonedGames: json['abandoned_games'] as int? ?? 0,
      totalScore: json['total_score'] as int? ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
      bestScore: json['best_score'] as int? ?? 0,
      totalTime: json['total_time'] as int? ?? 0,
      averageTime: (json['average_time'] as num?)?.toDouble() ?? 0.0,
      bestTime: json['best_time'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'PlayerStats(games: $totalGames, best: $bestScore pts, avg: ${averageScore.toStringAsFixed(1)} pts)';
  }
}
