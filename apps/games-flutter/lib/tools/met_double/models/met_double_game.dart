class MetDoubleSession {
  final String id;
  final String hostId;
  final String? joinCode; // Code à 6 chiffres pour rejoindre la session
  final String status; // waiting, in_progress, completed, cancelled
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? winnerId;
  final String? winnerName; // Pour les invités
  final int totalRounds;
  final List<MetDoubleParticipant> participants;
  final List<MetDoubleRound> rounds;

  MetDoubleSession({
    required this.id,
    required this.hostId,
    this.joinCode,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.winnerId,
    this.winnerName,
    this.totalRounds = 0,
    this.participants = const [],
    this.rounds = const [],
  });

  factory MetDoubleSession.fromJson(Map<String, dynamic> json) {
    return MetDoubleSession(
      id: json['id'] as String,
      hostId: json['host_id'] as String,
      joinCode: json['join_code'] as String?,
      status: json['status'] as String? ?? 'waiting',
      createdAt: DateTime.parse(json['created_at'] as String),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      winnerId: json['winner_id'] as String?,
      winnerName: json['winner_name'] as String?,
      totalRounds: json['total_rounds'] as int? ?? 0,
      participants: (json['met_double_participants'] as List<dynamic>?)
              ?.map((p) =>
                  MetDoubleParticipant.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      rounds: (json['met_double_rounds'] as List<dynamic>?)
              ?.map(
                  (r) => MetDoubleRound.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'host_id': hostId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (completedAt != null)
        'completed_at': completedAt!.toIso8601String(),
      if (winnerId != null) 'winner_id': winnerId,
      if (winnerName != null) 'winner_name': winnerName,
      'total_rounds': totalRounds,
    };
  }

  /// Vérifier si c'est prêt à démarrer (3 joueurs)
  bool get canStart => participants.length == 3;

  /// Obtenir le gagnant
  MetDoubleParticipant? get winner {
    return participants.firstWhere(
      (p) =>
          (winnerId != null && p.userId == winnerId) ||
          (winnerName != null && p.guestName == winnerName),
      orElse: () => participants.first,
    );
  }
}

class MetDoubleParticipant {
  final String id;
  final String sessionId;
  final String? userId; // NULL si invité
  final String? guestName; // NULL si utilisateur inscrit
  final String? userName; // Nom d'utilisateur (pour affichage)
  final int victories;
  final bool isCochon;
  final bool isHost;
  final DateTime joinedAt;

  MetDoubleParticipant({
    required this.id,
    required this.sessionId,
    this.userId,
    this.guestName,
    this.userName,
    this.victories = 0,
    this.isCochon = false,
    this.isHost = false,
    required this.joinedAt,
  });

  factory MetDoubleParticipant.fromJson(Map<String, dynamic> json) {
    return MetDoubleParticipant(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as String?,
      guestName: json['guest_name'] as String?,
      userName: json['users']?['username'] as String?,
      victories: json['victories'] as int? ?? 0,
      isCochon: json['is_cochon'] as bool? ?? false,
      isHost: json['is_host'] as bool? ?? false,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      if (userId != null) 'user_id': userId,
      if (guestName != null) 'guest_name': guestName,
      'victories': victories,
      'is_cochon': isCochon,
      'is_host': isHost,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  /// Nom à afficher
  String get displayName => userName ?? guestName ?? 'Joueur';

  /// Est un invité ?
  bool get isGuest => userId == null;

  /// Est un utilisateur inscrit ?
  bool get isRegistered => userId != null;
}

class MetDoubleRound {
  final String id;
  final String sessionId;
  final int roundNumber;
  final String? winnerParticipantId;
  final bool isChiree;
  final String? recordedByUserId;
  final DateTime playedAt;

  MetDoubleRound({
    required this.id,
    required this.sessionId,
    required this.roundNumber,
    this.winnerParticipantId,
    this.isChiree = false,
    this.recordedByUserId,
    required this.playedAt,
  });

  factory MetDoubleRound.fromJson(Map<String, dynamic> json) {
    return MetDoubleRound(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      roundNumber: json['round_number'] as int,
      winnerParticipantId: json['winner_participant_id'] as String?,
      isChiree: json['is_chiree'] as bool? ?? false,
      recordedByUserId: json['recorded_by_user_id'] as String?,
      playedAt: DateTime.parse(json['played_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'round_number': roundNumber,
      if (winnerParticipantId != null)
        'winner_participant_id': winnerParticipantId,
      'is_chiree': isChiree,
      if (recordedByUserId != null) 'recorded_by_user_id': recordedByUserId,
      'played_at': playedAt.toIso8601String(),
    };
  }
}

class MetDoubleInvitation {
  final String id;
  final String sessionId;
  final String inviterId;
  final String inviteeId;
  final String status; // pending, accepted, declined
  final DateTime createdAt;
  final DateTime? respondedAt;

  // Info enrichie
  final String? inviterUsername;
  final String? inviteeUsername;

  MetDoubleInvitation({
    required this.id,
    required this.sessionId,
    required this.inviterId,
    required this.inviteeId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.inviterUsername,
    this.inviteeUsername,
  });

  factory MetDoubleInvitation.fromJson(Map<String, dynamic> json) {
    return MetDoubleInvitation(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      inviterId: json['inviter_id'] as String,
      inviteeId: json['invitee_id'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      inviterUsername: json['inviter']?['username'] as String?,
      inviteeUsername: json['invitee']?['username'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'inviter_id': inviterId,
      'invitee_id': inviteeId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (respondedAt != null) 'responded_at': respondedAt!.toIso8601String(),
    };
  }
}

/// Statistiques de cochons
class CochonStats {
  final String playerId;
  final String victimId;
  final String victimName;
  final String sessionId;
  final DateTime completedAt;
  final int totalRounds;

  CochonStats({
    required this.playerId,
    required this.victimId,
    required this.victimName,
    required this.sessionId,
    required this.completedAt,
    required this.totalRounds,
  });

  factory CochonStats.fromJson(Map<String, dynamic> json) {
    return CochonStats(
      playerId: json['player_id'] as String,
      victimId: json['victim_id'] as String? ?? json['victim_user_id'] as String,
      victimName: json['victim_name'] as String,
      sessionId: json['session_id'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      totalRounds: json['total_rounds'] as int? ?? 0,
    );
  }
}

/// Comparaison entre 2 joueurs
class PlayerComparison {
  final int totalSessionsPlayed;
  final int player1Wins;
  final int player2Wins;
  final int player1CochonsGiven;
  final int player2CochonsGiven;
  final int player1CochonsReceived;
  final int player2CochonsReceived;
  final DateTime? lastPlayedAt;

  PlayerComparison({
    required this.totalSessionsPlayed,
    required this.player1Wins,
    required this.player2Wins,
    required this.player1CochonsGiven,
    required this.player2CochonsGiven,
    required this.player1CochonsReceived,
    required this.player2CochonsReceived,
    this.lastPlayedAt,
  });

  factory PlayerComparison.fromJson(Map<String, dynamic> json) {
    return PlayerComparison(
      totalSessionsPlayed: json['total_sessions_played'] as int? ?? 0,
      player1Wins: json['player1_wins'] as int? ?? 0,
      player2Wins: json['player2_wins'] as int? ?? 0,
      player1CochonsGiven: json['player1_cochons_given'] as int? ?? 0,
      player2CochonsGiven: json['player2_cochons_given'] as int? ?? 0,
      player1CochonsReceived: json['player1_cochons_received'] as int? ?? 0,
      player2CochonsReceived: json['player2_cochons_received'] as int? ?? 0,
      lastPlayedAt: json['last_played_at'] != null
          ? DateTime.parse(json['last_played_at'] as String)
          : null,
    );
  }

  double get player1WinRate =>
      totalSessionsPlayed > 0 ? (player1Wins / totalSessionsPlayed) * 100 : 0;

  double get player2WinRate =>
      totalSessionsPlayed > 0 ? (player2Wins / totalSessionsPlayed) * 100 : 0;
}
