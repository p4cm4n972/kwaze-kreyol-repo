import 'domino_tile.dart';

/// Représente l'état actuel d'une manche de dominos
class DominoGameState {
  final int roundNumber;
  final List<PlacedTile> board;             // Chaîne de dominos sur le plateau
  final int? leftEnd;                       // Valeur disponible à gauche
  final int? rightEnd;                      // Valeur disponible à droite
  final Map<String, List<DominoTile>> playerHands;  // participant_id -> tuiles
  final String currentTurnParticipantId;
  final List<String> passedPlayerIds;       // Joueurs qui ont passé ce tour
  final bool isBlocked;                     // Jeu bloqué (tous ont passé)
  final DateTime lastMoveAt;

  const DominoGameState({
    required this.roundNumber,
    required this.board,
    this.leftEnd,
    this.rightEnd,
    required this.playerHands,
    required this.currentTurnParticipantId,
    this.passedPlayerIds = const [],
    this.isBlocked = false,
    required this.lastMoveAt,
  });

  /// Vérifie si une tuile peut être placée
  bool canPlaceTile(DominoTile tile) {
    // Première tuile du plateau
    if (board.isEmpty) return true;

    // Vérifie si la tuile se connecte à l'un des bouts
    if (leftEnd != null && tile.canConnect(leftEnd!)) return true;
    if (rightEnd != null && tile.canConnect(rightEnd!)) return true;

    return false;
  }

  /// Obtient les valeurs des bouts disponibles
  List<int> getValidEnds() {
    final ends = <int>[];
    if (leftEnd != null) ends.add(leftEnd!);
    if (rightEnd != null && rightEnd != leftEnd) ends.add(rightEnd!);
    return ends;
  }

  /// Compte le nombre total de tuiles sur le plateau
  int get tilesOnBoard => board.length;

  /// JSON serialization
  Map<String, dynamic> toJson() => {
    'round_number': roundNumber,
    'board': board.map((pt) => pt.toJson()).toList(),
    'left_end': leftEnd,
    'right_end': rightEnd,
    'player_hands': playerHands.map(
      (key, tiles) => MapEntry(key, tiles.map((t) => t.toJson()).toList()),
    ),
    'current_turn_participant_id': currentTurnParticipantId,
    'passed_player_ids': passedPlayerIds,
    'is_blocked': isBlocked,
    'last_move_at': lastMoveAt.toIso8601String(),
  };

  factory DominoGameState.fromJson(Map<String, dynamic> json) =>
      DominoGameState(
        roundNumber: json['round_number'] as int,
        board: (json['board'] as List<dynamic>)
            .map((e) => PlacedTile.fromJson(e as Map<String, dynamic>))
            .toList(),
        leftEnd: json['left_end'] as int?,
        rightEnd: json['right_end'] as int?,
        playerHands: (json['player_hands'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            key,
            (value as List<dynamic>)
                .map((e) => DominoTile.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
        ),
        currentTurnParticipantId: json['current_turn_participant_id'] as String,
        passedPlayerIds: (json['passed_player_ids'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        isBlocked: json['is_blocked'] as bool? ?? false,
        lastMoveAt: DateTime.parse(json['last_move_at'] as String),
      );

  DominoGameState copyWith({
    int? roundNumber,
    List<PlacedTile>? board,
    int? leftEnd,
    int? rightEnd,
    Map<String, List<DominoTile>>? playerHands,
    String? currentTurnParticipantId,
    List<String>? passedPlayerIds,
    bool? isBlocked,
    DateTime? lastMoveAt,
  }) {
    return DominoGameState(
      roundNumber: roundNumber ?? this.roundNumber,
      board: board ?? this.board,
      leftEnd: leftEnd ?? this.leftEnd,
      rightEnd: rightEnd ?? this.rightEnd,
      playerHands: playerHands ?? this.playerHands,
      currentTurnParticipantId:
          currentTurnParticipantId ?? this.currentTurnParticipantId,
      passedPlayerIds: passedPlayerIds ?? this.passedPlayerIds,
      isBlocked: isBlocked ?? this.isBlocked,
      lastMoveAt: lastMoveAt ?? this.lastMoveAt,
    );
  }

  @override
  String toString() =>
      'DominoGameState(manche: $roundNumber, plateau: $tilesOnBoard tuiles, bouts: $leftEnd-$rightEnd, tour: $currentTurnParticipantId)';
}
