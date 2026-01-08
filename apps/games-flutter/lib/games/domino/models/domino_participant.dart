/// Représente un participant dans une session de dominos
class DominoParticipant {
  final String id;
  final String sessionId;
  final String? userId;       // NULL si invité ou IA
  final String? guestName;    // NULL si utilisateur enregistré
  final String? userName;     // Nom depuis la table users
  final int turnOrder;        // 0, 1, ou 2
  final int roundsWon;        // Nombre de manches gagnées (0-3)
  final bool isCochon;        // True si termine avec 0 manche
  final bool isHost;          // True si créateur de la session
  final DateTime joinedAt;
  final bool isAI;            // True si joueur IA (mode solo)
  final String? aiDifficulty; // 'easy', 'normal', 'hard' (si isAI)

  const DominoParticipant({
    required this.id,
    required this.sessionId,
    this.userId,
    this.guestName,
    this.userName,
    required this.turnOrder,
    this.roundsWon = 0,
    this.isCochon = false,
    this.isHost = false,
    required this.joinedAt,
    this.isAI = false,
    this.aiDifficulty,
  });

  /// Factory pour créer un joueur IA
  factory DominoParticipant.ai({
    required String id,
    required String sessionId,
    required String name,
    required int turnOrder,
    required String difficulty,
  }) {
    return DominoParticipant(
      id: id,
      sessionId: sessionId,
      guestName: name,
      turnOrder: turnOrder,
      joinedAt: DateTime.now(),
      isAI: true,
      aiDifficulty: difficulty,
    );
  }

  /// Nom d'affichage du participant
  String get displayName => userName ?? guestName ?? 'Joueur';

  /// True si c'est un invité (pas enregistré)
  bool get isGuest => userId == null;

  /// JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'session_id': sessionId,
    'user_id': userId,
    'guest_name': guestName,
    'user_name': userName,
    'turn_order': turnOrder,
    'rounds_won': roundsWon,
    'is_cochon': isCochon,
    'is_host': isHost,
    'joined_at': joinedAt.toIso8601String(),
    'is_ai': isAI,
    'ai_difficulty': aiDifficulty,
  };

  factory DominoParticipant.fromJson(Map<String, dynamic> json) =>
      DominoParticipant(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        userId: json['user_id'] as String?,
        guestName: json['guest_name'] as String?,
        userName: json['user_name'] as String?,
        turnOrder: json['turn_order'] as int,
        roundsWon: json['rounds_won'] as int? ?? 0,
        isCochon: json['is_cochon'] as bool? ?? false,
        isHost: json['is_host'] as bool? ?? false,
        joinedAt: DateTime.parse(json['joined_at'] as String),
        isAI: json['is_ai'] as bool? ?? false,
        aiDifficulty: json['ai_difficulty'] as String?,
      );

  DominoParticipant copyWith({
    String? id,
    String? sessionId,
    String? userId,
    String? guestName,
    String? userName,
    int? turnOrder,
    int? roundsWon,
    bool? isCochon,
    bool? isHost,
    DateTime? joinedAt,
    bool? isAI,
    String? aiDifficulty,
  }) {
    return DominoParticipant(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      guestName: guestName ?? this.guestName,
      userName: userName ?? this.userName,
      turnOrder: turnOrder ?? this.turnOrder,
      roundsWon: roundsWon ?? this.roundsWon,
      isCochon: isCochon ?? this.isCochon,
      isHost: isHost ?? this.isHost,
      joinedAt: joinedAt ?? this.joinedAt,
      isAI: isAI ?? this.isAI,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
    );
  }

  @override
  String toString() =>
      'DominoParticipant(${displayName}, tour: $turnOrder, manches: $roundsWon${isCochon ? ', COCHON' : ''})';
}
