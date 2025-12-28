import '../../../models/word.dart';

/// Représente une partie de Mots Mawon avec toutes ses données
class MotsMawonGame {
  final String id;
  final String userId;
  final String status; // 'in_progress', 'completed', 'abandoned'
  final WordSearchGrid gridData;
  final Set<String> foundWords;
  final int score;
  final int timeElapsed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  MotsMawonGame({
    required this.id,
    required this.userId,
    required this.status,
    required this.gridData,
    required this.foundWords,
    required this.score,
    required this.timeElapsed,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  /// Vérifie si tous les mots ont été trouvés
  bool get isComplete => foundWords.length == gridData.words.length;

  /// Convertit la grille en JSON pour stockage dans Supabase
  static Map<String, dynamic> gridToJson(WordSearchGrid grid) {
    return {
      'grid': grid.grid,
      'size': grid.size,
      'words': grid.words.map((word) => {
        'text': word.text,
        'found': word.found,
        'definition': word.definition,
        'nature': word.nature,
        'cells': word.cells.map((cell) => {
          'row': cell.row,
          'col': cell.col,
        }).toList(),
      }).toList(),
    };
  }

  /// Reconstruit la grille à partir du JSON
  static WordSearchGrid gridFromJson(Map<String, dynamic> json) {
    return WordSearchGrid(
      grid: (json['grid'] as List)
          .map((row) => (row as List).map((cell) => cell as String).toList())
          .toList(),
      size: json['size'] as int,
      words: (json['words'] as List).map((wordJson) {
        return Word(
          text: wordJson['text'] as String,
          found: wordJson['found'] as bool? ?? false,
          definition: wordJson['definition'] as String?,
          nature: wordJson['nature'] as String?,
          cells: (wordJson['cells'] as List).map((cellJson) {
            return CellPosition(
              cellJson['row'] as int,
              cellJson['col'] as int,
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  /// Convertit l'instance en JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'grid_data': gridToJson(gridData),
      'found_words': foundWords.toList(),
      'score': score,
      'time_elapsed': timeElapsed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Crée une instance depuis le JSON Supabase
  factory MotsMawonGame.fromJson(Map<String, dynamic> json) {
    return MotsMawonGame(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      gridData: gridFromJson(json['grid_data'] as Map<String, dynamic>),
      foundWords: (json['found_words'] as List).map((e) => e as String).toSet(),
      score: json['score'] as int,
      timeElapsed: json['time_elapsed'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  /// Crée une copie avec des champs modifiés
  MotsMawonGame copyWith({
    String? id,
    String? userId,
    String? status,
    WordSearchGrid? gridData,
    Set<String>? foundWords,
    int? score,
    int? timeElapsed,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return MotsMawonGame(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      gridData: gridData ?? this.gridData,
      foundWords: foundWords ?? this.foundWords,
      score: score ?? this.score,
      timeElapsed: timeElapsed ?? this.timeElapsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Représente une entrée du leaderboard
class MotsMawonLeaderboardEntry {
  final String gameId;
  final String userId;
  final String username;
  final int score;
  final int timeElapsed;
  final DateTime completedAt;
  final int rank;

  MotsMawonLeaderboardEntry({
    required this.gameId,
    required this.userId,
    required this.username,
    required this.score,
    required this.timeElapsed,
    required this.completedAt,
    required this.rank,
  });

  /// Format le temps en minutes:secondes
  String get formattedTime {
    final mins = timeElapsed ~/ 60;
    final secs = timeElapsed % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// Retourne le badge selon le rang (or, argent, bronze)
  String? get badge {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return null;
  }

  /// Crée une instance depuis le JSON retourné par la fonction RPC
  factory MotsMawonLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return MotsMawonLeaderboardEntry(
      gameId: json['game_id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      score: json['score'] as int,
      timeElapsed: json['time_elapsed'] as int,
      completedAt: DateTime.parse(json['completed_at'] as String),
      rank: json['rank'] as int,
    );
  }
}

/// Représente les statistiques d'un joueur
class MotsMawonPlayerStats {
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
  final int totalWordsFound;

  MotsMawonPlayerStats({
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
    required this.totalWordsFound,
  });

  /// Format le temps total en heures:minutes
  String get formattedTotalTime {
    final hours = totalTime ~/ 3600;
    final mins = (totalTime % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${mins}min';
    }
    return '${mins}min';
  }

  /// Format le temps moyen en minutes:secondes
  String get formattedAverageTime {
    final mins = averageTime.toInt() ~/ 60;
    final secs = averageTime.toInt() % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// Format le meilleur temps en minutes:secondes
  String get formattedBestTime {
    final mins = bestTime ~/ 60;
    final secs = bestTime % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// Taux de complétion (%)
  double get completionRate {
    if (totalGames == 0) return 0;
    return (completedGames / totalGames) * 100;
  }

  /// Crée une instance depuis le JSON retourné par la fonction RPC
  factory MotsMawonPlayerStats.fromJson(Map<String, dynamic> json) {
    return MotsMawonPlayerStats(
      totalGames: json['total_games'] as int,
      completedGames: json['completed_games'] as int,
      inProgressGames: json['in_progress_games'] as int,
      abandonedGames: json['abandoned_games'] as int,
      totalScore: json['total_score'] as int,
      averageScore: (json['average_score'] as num).toDouble(),
      bestScore: json['best_score'] as int,
      totalTime: json['total_time'] as int,
      averageTime: (json['average_time'] as num).toDouble(),
      bestTime: json['best_time'] as int,
      totalWordsFound: json['total_words_found'] as int,
    );
  }

  /// Crée une instance vide (pour les nouveaux joueurs)
  factory MotsMawonPlayerStats.empty() {
    return MotsMawonPlayerStats(
      totalGames: 0,
      completedGames: 0,
      inProgressGames: 0,
      abandonedGames: 0,
      totalScore: 0,
      averageScore: 0.0,
      bestScore: 0,
      totalTime: 0,
      averageTime: 0.0,
      bestTime: 0,
      totalWordsFound: 0,
    );
  }
}
