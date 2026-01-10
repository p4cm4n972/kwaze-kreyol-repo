/// Statistiques utilisateurs pour le dashboard admin
class AdminUserStats {
  final int totalUsers;
  final Map<String, int> usersByRole;
  final int newUsersToday;
  final int newUsersThisWeek;
  final int newUsersThisMonth;

  AdminUserStats({
    required this.totalUsers,
    required this.usersByRole,
    required this.newUsersToday,
    required this.newUsersThisWeek,
    required this.newUsersThisMonth,
  });

  factory AdminUserStats.fromJson(Map<String, dynamic> json) {
    return AdminUserStats(
      totalUsers: json['total_users'] as int? ?? 0,
      usersByRole: Map<String, int>.from(json['users_by_role'] as Map? ?? {}),
      newUsersToday: json['new_users_today'] as int? ?? 0,
      newUsersThisWeek: json['new_users_this_week'] as int? ?? 0,
      newUsersThisMonth: json['new_users_this_month'] as int? ?? 0,
    );
  }
}

/// Point de données pour les graphiques temporels
class TimeSeriesDataPoint {
  final DateTime date;
  final int value;
  final int? cumulativeValue;

  TimeSeriesDataPoint({
    required this.date,
    required this.value,
    this.cumulativeValue,
  });

  factory TimeSeriesDataPoint.fromJson(Map<String, dynamic> json) {
    return TimeSeriesDataPoint(
      date: DateTime.parse(json['date'] as String),
      value: json['new_users'] as int? ?? json['games_count'] as int? ?? 0,
      cumulativeValue: json['cumulative_users'] as int?,
    );
  }
}

/// Statistiques de jeu pour le dashboard admin
class AdminGameStats {
  final int totalGames;
  final Map<String, int> byStatus;
  final double avgScore;
  final double avgTimeSeconds;
  final int? highestScore;
  final double? avgWordsFound;
  final double? avgRoundsPerSession;
  final double? avgDurationMinutes;
  final int gamesToday;
  final int gamesThisWeek;
  final int gamesThisMonth;

  AdminGameStats({
    required this.totalGames,
    required this.byStatus,
    required this.avgScore,
    required this.avgTimeSeconds,
    this.highestScore,
    this.avgWordsFound,
    this.avgRoundsPerSession,
    this.avgDurationMinutes,
    required this.gamesToday,
    required this.gamesThisWeek,
    required this.gamesThisMonth,
  });

  factory AdminGameStats.fromJson(Map<String, dynamic> json) {
    return AdminGameStats(
      totalGames: json['total_games'] as int? ?? json['total_sessions'] as int? ?? 0,
      byStatus: Map<String, int>.from(json['by_status'] as Map? ?? {}),
      avgScore: (json['avg_score'] as num?)?.toDouble() ?? 0,
      avgTimeSeconds: (json['avg_time_seconds'] as num?)?.toDouble() ?? 0,
      highestScore: json['highest_score'] as int?,
      avgWordsFound: (json['avg_words_found'] as num?)?.toDouble(),
      avgRoundsPerSession: (json['avg_rounds_per_session'] as num?)?.toDouble(),
      avgDurationMinutes: (json['avg_duration_minutes'] as num?)?.toDouble(),
      gamesToday: json['games_today'] as int? ?? json['sessions_today'] as int? ?? 0,
      gamesThisWeek: json['games_this_week'] as int? ?? json['sessions_this_week'] as int? ?? 0,
      gamesThisMonth: json['games_this_month'] as int? ?? json['sessions_this_month'] as int? ?? 0,
    );
  }
}

/// Statistiques des utilisateurs actifs
class AdminActiveUsers {
  final int periodDays;
  final int dominoActive;
  final int skrabbActive;
  final int motsMawonActive;
  final int totalActive;

  AdminActiveUsers({
    required this.periodDays,
    required this.dominoActive,
    required this.skrabbActive,
    required this.motsMawonActive,
    required this.totalActive,
  });

  factory AdminActiveUsers.fromJson(Map<String, dynamic> json) {
    return AdminActiveUsers(
      periodDays: json['period_days'] as int? ?? 7,
      dominoActive: json['domino_active'] as int? ?? 0,
      skrabbActive: json['skrabb_active'] as int? ?? 0,
      motsMawonActive: json['mots_mawon_active'] as int? ?? 0,
      totalActive: json['total_active'] as int? ?? 0,
    );
  }
}

/// Entrée du classement des meilleurs joueurs
class TopPlayerEntry {
  final String? oderId;
  final String username;
  final int gamesPlayed;
  final int totalScore;
  final double avgScore;
  final double? winRate;

  TopPlayerEntry({
    this.oderId,
    required this.username,
    required this.gamesPlayed,
    required this.totalScore,
    required this.avgScore,
    this.winRate,
  });

  factory TopPlayerEntry.fromJson(Map<String, dynamic> json) {
    return TopPlayerEntry(
      oderId: json['user_id'] as String?,
      username: json['username'] as String? ?? 'Anonyme',
      gamesPlayed: json['games_played'] as int? ?? 0,
      totalScore: json['total_score'] as int? ?? json['total_wins'] as int? ?? 0,
      avgScore: (json['avg_score'] as num?)?.toDouble() ?? 0,
      winRate: (json['win_rate'] as num?)?.toDouble(),
    );
  }
}
