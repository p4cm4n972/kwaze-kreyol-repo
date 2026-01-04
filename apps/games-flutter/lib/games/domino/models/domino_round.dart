/// Représente une manche terminée de dominos
class DominoRound {
  final String id;
  final String sessionId;
  final int roundNumber;
  final String? winnerParticipantId;  // NULL si égalité (rare)
  final String endType;               // "capot" ou "blocked"
  final Map<String, int> finalScores; // participant_id -> points restants
  final DateTime playedAt;

  const DominoRound({
    required this.id,
    required this.sessionId,
    required this.roundNumber,
    this.winnerParticipantId,
    required this.endType,
    required this.finalScores,
    required this.playedAt,
  });

  /// True si la manche s'est terminée par un capot
  bool get isCapot => endType == 'capot';

  /// True si la manche s'est terminée par un blocage
  bool get isBlocked => endType == 'blocked';

  /// Score du gagnant (0 si capot, minimum si bloqué)
  int? get winnerScore =>
      winnerParticipantId != null ? finalScores[winnerParticipantId] : null;

  /// JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'session_id': sessionId,
    'round_number': roundNumber,
    'winner_participant_id': winnerParticipantId,
    'end_type': endType,
    'final_scores': finalScores,
    'played_at': playedAt.toIso8601String(),
  };

  factory DominoRound.fromJson(Map<String, dynamic> json) => DominoRound(
    id: json['id'] as String,
    sessionId: json['session_id'] as String,
    roundNumber: json['round_number'] as int,
    winnerParticipantId: json['winner_participant_id'] as String?,
    endType: json['end_type'] as String,
    finalScores: (json['final_scores'] as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, value as int)),
    playedAt: DateTime.parse(json['played_at'] as String),
  );

  DominoRound copyWith({
    String? id,
    String? sessionId,
    int? roundNumber,
    String? winnerParticipantId,
    String? endType,
    Map<String, int>? finalScores,
    DateTime? playedAt,
  }) {
    return DominoRound(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      roundNumber: roundNumber ?? this.roundNumber,
      winnerParticipantId: winnerParticipantId ?? this.winnerParticipantId,
      endType: endType ?? this.endType,
      finalScores: finalScores ?? this.finalScores,
      playedAt: playedAt ?? this.playedAt,
    );
  }

  @override
  String toString() =>
      'DominoRound(#$roundNumber, type: $endType, gagnant: $winnerParticipantId)';
}
