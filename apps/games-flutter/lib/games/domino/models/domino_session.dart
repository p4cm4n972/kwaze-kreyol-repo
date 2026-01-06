import 'domino_participant.dart';
import 'domino_round.dart';
import 'domino_game_state.dart';

/// Représente une session complète de jeu de dominos (3 joueurs)
class DominoSession {
  final String id;
  final String hostId;
  final String? joinCode;              // Code à 6 chiffres pour rejoindre
  final String status;                 // waiting, in_progress, completed, cancelled, chiree
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? winnerId;              // user_id du gagnant
  final String? winnerName;            // Pour les invités
  final int totalRounds;
  final List<DominoParticipant> participants;
  final List<DominoRound> rounds;
  final DominoGameState? currentGameState;  // État de la manche en cours

  const DominoSession({
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
    this.currentGameState,
  });

  /// True si la session peut démarrer (3 joueurs)
  bool get canStart => participants.length == 3 && status == 'waiting';

  /// True si la session est en attente de joueurs
  bool get isWaiting => status == 'waiting';

  /// True si la partie est en cours
  bool get isInProgress => status == 'in_progress';

  /// True si la partie est terminée
  bool get isCompleted => status == 'completed';

  /// True si la partie est terminée en chirée (match nul)
  bool get isChiree => status == 'chiree';

  /// True si la partie est annulée
  bool get isCancelled => status == 'cancelled';

  /// Participant qui joue actuellement
  DominoParticipant? get currentTurnPlayer {
    if (currentGameState == null) return null;
    return participants.firstWhere(
      (p) => p.id == currentGameState!.currentTurnParticipantId,
      orElse: () => participants.first,
    );
  }

  /// Gagnant de la session
  DominoParticipant? get winner {
    if (winnerId == null) return null;
    return participants.firstWhere(
      (p) => p.userId == winnerId,
      orElse: () => participants.first,
    );
  }

  /// Nombre de places disponibles
  int get availableSlots => 3 - participants.length;

  /// Liste des cochons (participants avec 0 manche à la fin)
  List<DominoParticipant> get cochons {
    if (!isCompleted) return [];
    return participants.where((p) => p.isCochon).toList();
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'host_id': hostId,
    'join_code': joinCode,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'started_at': startedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'winner_id': winnerId,
    'winner_name': winnerName,
    'total_rounds': totalRounds,
    'participants': participants.map((p) => p.toJson()).toList(),
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'current_game_state': currentGameState?.toJson(),
  };

  factory DominoSession.fromJson(Map<String, dynamic> json) => DominoSession(
    id: json['id'] as String,
    hostId: json['host_id'] as String,
    joinCode: json['join_code'] as String?,
    status: json['status'] as String,
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
    participants: (json['participants'] as List<dynamic>?)
            ?.map((e) => DominoParticipant.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    rounds: (json['rounds'] as List<dynamic>?)
            ?.map((e) => DominoRound.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    currentGameState: json['current_game_state'] != null
        ? DominoGameState.fromJson(
            json['current_game_state'] as Map<String, dynamic>)
        : null,
  );

  DominoSession copyWith({
    String? id,
    String? hostId,
    String? joinCode,
    String? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? winnerId,
    String? winnerName,
    int? totalRounds,
    List<DominoParticipant>? participants,
    List<DominoRound>? rounds,
    DominoGameState? currentGameState,
  }) {
    return DominoSession(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      joinCode: joinCode ?? this.joinCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      winnerId: winnerId ?? this.winnerId,
      winnerName: winnerName ?? this.winnerName,
      totalRounds: totalRounds ?? this.totalRounds,
      participants: participants ?? this.participants,
      rounds: rounds ?? this.rounds,
      currentGameState: currentGameState ?? this.currentGameState,
    );
  }

  @override
  String toString() =>
      'DominoSession($status, code: $joinCode, joueurs: ${participants.length}/3, manches: ${rounds.length})';
}
