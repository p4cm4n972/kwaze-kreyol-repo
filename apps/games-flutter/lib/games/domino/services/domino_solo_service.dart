import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/domino_tile.dart';
import '../models/domino_participant.dart';
import '../models/domino_session.dart';
import '../models/domino_game_state.dart';
import '../models/domino_round.dart';
import '../utils/domino_logic.dart';
import '../utils/domino_scoring.dart';
import 'domino_ai_service.dart';

/// Clés pour le stockage local
const String _soloSessionKey = 'domino_solo_session';
const String _soloDifficultyKey = 'domino_solo_difficulty';

/// Service de gestion locale pour le mode solo (sans Supabase)
class DominoSoloService {
  static final Random _random = Random();

  /// Sauvegarde la session en cours dans le stockage local
  static Future<void> saveSession(
    DominoSession session, {
    AIDifficulty? difficulty,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(session.toJson());
    await prefs.setString(_soloSessionKey, json);
    if (difficulty != null) {
      await prefs.setString(_soloDifficultyKey, difficulty.name);
    }
  }

  /// Charge la session en cours depuis le stockage local
  /// Si [forDifficulty] est spécifié, ne charge que si la difficulté correspond
  static Future<DominoSession?> loadSession({AIDifficulty? forDifficulty}) async {
    final prefs = await SharedPreferences.getInstance();

    // Vérifier la difficulté si demandé
    if (forDifficulty != null) {
      final savedDifficulty = prefs.getString(_soloDifficultyKey);
      if (savedDifficulty != forDifficulty.name) {
        return null; // Difficulté différente, ne pas charger
      }
    }

    final json = prefs.getString(_soloSessionKey);
    if (json == null) return null;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return DominoSession.fromJson(data);
    } catch (e) {
      // Si erreur de parsing, supprimer la session corrompue
      await clearSession();
      return null;
    }
  }

  /// Vérifie si une session en cours existe pour une difficulté donnée
  static Future<bool> hasActiveSession({AIDifficulty? forDifficulty}) async {
    final session = await loadSession(forDifficulty: forDifficulty);
    if (session == null) return false;
    return session.status == 'in_progress';
  }

  /// Supprime la session sauvegardée
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_soloSessionKey);
    await prefs.remove(_soloDifficultyKey);
  }

  /// Génère un ID unique simple
  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(999999)}';
  }

  /// Crée une session solo avec 1 humain + 2 IA
  static DominoSession createSoloSession({
    required String humanPlayerId,
    required String humanPlayerName,
    required AIDifficulty difficulty,
  }) {
    final sessionId = _generateId();
    final difficultyName = difficulty.name;

    // Créer les 3 participants
    final humanParticipant = DominoParticipant(
      id: _generateId(),
      sessionId: sessionId,
      userId: humanPlayerId,
      userName: humanPlayerName,
      turnOrder: 0,
      isHost: true,
      joinedAt: DateTime.now(),
    );

    final aiParticipant1 = DominoParticipant.ai(
      id: _generateId(),
      sessionId: sessionId,
      name: _getAIName(1, difficulty),
      turnOrder: 1,
      difficulty: difficultyName,
    );

    final aiParticipant2 = DominoParticipant.ai(
      id: _generateId(),
      sessionId: sessionId,
      name: _getAIName(2, difficulty),
      turnOrder: 2,
      difficulty: difficultyName,
    );

    return DominoSession(
      id: sessionId,
      hostId: humanPlayerId,
      joinCode: null, // Pas de code pour le mode solo
      status: 'in_progress',
      createdAt: DateTime.now(),
      startedAt: DateTime.now(),
      participants: [humanParticipant, aiParticipant1, aiParticipant2],
      rounds: [],
      currentGameState: null,
    );
  }

  /// Génère un nom pour l'IA
  static String _getAIName(int index, AIDifficulty difficulty) {
    final names = {
      AIDifficulty.easy: ['Barbeloup', 'Pédro'],
      AIDifficulty.normal: ['Barbeloup', 'Pédro'],
      AIDifficulty.hard: ['Barbeloup', 'Pédro'],
    };
    return names[difficulty]![index - 1];
  }

  /// Démarre une nouvelle manche
  static DominoGameState startNewRound(
    DominoSession session, {
    String? previousWinnerId,
  }) {
    final participantIds = session.participants
        .map((p) => p.id)
        .toList()
      ..sort((a, b) {
        final pA = session.participants.firstWhere((p) => p.id == a);
        final pB = session.participants.firstWhere((p) => p.id == b);
        return pA.turnOrder.compareTo(pB.turnOrder);
      });

    // Distribuer les tuiles
    final hands = DominoLogic.distributeTiles(participantIds);

    // Déterminer le premier joueur
    final startingPlayer = DominoLogic.determineStartingPlayer(
      hands,
      previousWinnerId: previousWinnerId,
    );

    return DominoGameState(
      roundNumber: session.rounds.length + 1,
      board: [],
      leftEnd: null,
      rightEnd: null,
      playerHands: hands,
      currentTurnParticipantId: startingPlayer,
      passedPlayerIds: [],
      isBlocked: false,
      lastMoveAt: DateTime.now(),
    );
  }

  /// Place une tuile sur le plateau
  static PlaceTileResult placeTile({
    required DominoGameState state,
    required String participantId,
    required DominoTile tile,
    required String side,
    required List<DominoParticipant> participants,
  }) {
    // Vérifier que c'est le tour du joueur
    if (state.currentTurnParticipantId != participantId) {
      throw Exception("Ce n'est pas votre tour");
    }

    // Vérifier que le joueur possède la tuile
    final hand = state.playerHands[participantId];
    if (hand == null || !hand.any((t) => t.id == tile.id)) {
      throw Exception("Vous ne possédez pas cette tuile");
    }

    // Valider le placement
    DominoLogic.validateTilePlacement(
      tile: tile,
      hand: hand,
      side: side,
      leftEnd: state.leftEnd,
      rightEnd: state.rightEnd,
    );

    // Calculer les valeurs connectées et exposées
    int connectedValue;
    int exposedValue;

    if (state.board.isEmpty) {
      // Première tuile
      connectedValue = tile.value1;
      exposedValue = tile.value2;
    } else {
      final targetEnd = side == 'left' ? state.leftEnd! : state.rightEnd!;
      connectedValue = targetEnd;
      exposedValue = tile.getOppositeValue(targetEnd);
    }

    // Créer la tuile placée
    final placedTile = PlacedTile(
      tile: tile,
      connectedValue: connectedValue,
      side: side,
      placedAt: DateTime.now(),
    );

    // Mettre à jour le plateau
    final newBoard = List<PlacedTile>.from(state.board);
    if (state.board.isEmpty || side == 'right') {
      newBoard.add(placedTile);
    } else {
      newBoard.insert(0, placedTile);
    }

    // Mettre à jour les extrémités
    int? newLeftEnd;
    int? newRightEnd;

    if (state.board.isEmpty) {
      newLeftEnd = tile.value1;
      newRightEnd = tile.value2;
    } else if (side == 'left') {
      newLeftEnd = exposedValue;
      newRightEnd = state.rightEnd;
    } else {
      newLeftEnd = state.leftEnd;
      newRightEnd = exposedValue;
    }

    // Retirer la tuile de la main
    final newHand = hand.where((t) => t.id != tile.id).toList();
    final newHands = Map<String, List<DominoTile>>.from(state.playerHands);
    newHands[participantId] = newHand;

    // Vérifier si capot (main vide)
    if (newHand.isEmpty) {
      return PlaceTileResult(
        newState: state.copyWith(
          board: newBoard,
          leftEnd: newLeftEnd,
          rightEnd: newRightEnd,
          playerHands: newHands,
          lastMoveAt: DateTime.now(),
        ),
        roundEnded: true,
        roundWinnerId: participantId,
        isCapot: true,
      );
    }

    // Passer au joueur suivant
    final participantIds = participants
        .map((p) => p.id)
        .toList()
      ..sort((a, b) {
        final pA = participants.firstWhere((p) => p.id == a);
        final pB = participants.firstWhere((p) => p.id == b);
        return pA.turnOrder.compareTo(pB.turnOrder);
      });

    final nextPlayer = DominoLogic.getNextPlayer(participantId, participantIds);

    return PlaceTileResult(
      newState: state.copyWith(
        board: newBoard,
        leftEnd: newLeftEnd,
        rightEnd: newRightEnd,
        playerHands: newHands,
        currentTurnParticipantId: nextPlayer,
        passedPlayerIds: [], // Reset après un placement réussi
        lastMoveAt: DateTime.now(),
      ),
      roundEnded: false,
    );
  }

  /// Passe le tour du joueur
  static PassTurnResult passTurn({
    required DominoGameState state,
    required String participantId,
    required List<DominoParticipant> participants,
  }) {
    // Vérifier que c'est le tour du joueur
    if (state.currentTurnParticipantId != participantId) {
      throw Exception("Ce n'est pas votre tour");
    }

    // Vérifier que le joueur ne peut vraiment pas jouer
    final hand = state.playerHands[participantId] ?? [];
    if (DominoLogic.canPlayerPlay(hand, state.leftEnd, state.rightEnd)) {
      throw Exception("Vous pouvez encore jouer une tuile");
    }

    // Ajouter aux joueurs qui ont passé
    final newPassedList = List<String>.from(state.passedPlayerIds);
    if (!newPassedList.contains(participantId)) {
      newPassedList.add(participantId);
    }

    // Vérifier si le jeu est bloqué
    if (newPassedList.length >= 3) {
      // Tous ont passé = jeu bloqué
      final winnerId = DominoLogic.determineBlockedWinner(state.playerHands);

      return PassTurnResult(
        newState: state.copyWith(
          passedPlayerIds: newPassedList,
          isBlocked: true,
          lastMoveAt: DateTime.now(),
        ),
        roundEnded: true,
        roundWinnerId: winnerId,
      );
    }

    // Passer au joueur suivant
    final participantIds = participants
        .map((p) => p.id)
        .toList()
      ..sort((a, b) {
        final pA = participants.firstWhere((p) => p.id == a);
        final pB = participants.firstWhere((p) => p.id == b);
        return pA.turnOrder.compareTo(pB.turnOrder);
      });

    final nextPlayer = DominoLogic.getNextPlayer(participantId, participantIds);

    return PassTurnResult(
      newState: state.copyWith(
        currentTurnParticipantId: nextPlayer,
        passedPlayerIds: newPassedList,
        lastMoveAt: DateTime.now(),
      ),
      roundEnded: false,
    );
  }

  /// Met à jour la session après une fin de manche
  static DominoSession updateSessionAfterRound(
    DominoSession session,
    String roundWinnerId, {
    bool isCapot = false,
    Map<String, int>? finalScores,
  }) {
    // Créer l'enregistrement de la manche
    final newRound = DominoRound(
      id: _generateId(),
      sessionId: session.id,
      roundNumber: session.rounds.length + 1,
      winnerParticipantId: roundWinnerId,
      endType: isCapot ? 'capot' : 'blocked',
      finalScores: finalScores ?? {},
      playedAt: DateTime.now(),
    );

    // Ajouter la manche à la liste
    final updatedRounds = [...session.rounds, newRound];

    // Mettre à jour les manches gagnées
    final updatedParticipants = session.participants.map((p) {
      if (p.id == roundWinnerId) {
        return p.copyWith(roundsWon: p.roundsWon + 1);
      }
      return p;
    }).toList();

    // Vérifier si quelqu'un a gagné (3 manches)
    final winner = updatedParticipants.where((p) => p.roundsWon >= 3).firstOrNull;

    // Vérifier la chirée
    final isChiree = DominoScoring.isChiree(updatedParticipants);

    String newStatus = session.status;
    DateTime? completedAt;

    if (winner != null) {
      newStatus = 'completed';
      completedAt = DateTime.now();

      // Marquer les cochons
      final finalParticipants = updatedParticipants.map((p) {
        if (p.roundsWon == 0) {
          return p.copyWith(isCochon: true);
        }
        return p;
      }).toList();

      return session.copyWith(
        status: newStatus,
        completedAt: completedAt,
        participants: finalParticipants,
        rounds: updatedRounds,
        winnerId: winner.userId ?? winner.id,
      );
    } else if (isChiree) {
      newStatus = 'chiree';
      completedAt = DateTime.now();

      return session.copyWith(
        status: newStatus,
        completedAt: completedAt,
        participants: updatedParticipants,
        rounds: updatedRounds,
      );
    }

    return session.copyWith(
      participants: updatedParticipants,
      rounds: updatedRounds,
    );
  }

  /// Vérifie si la partie est terminée
  static bool isGameOver(DominoSession session) {
    return session.status == 'completed' || session.status == 'chiree';
  }

  /// Retourne le participant humain
  static DominoParticipant getHumanParticipant(DominoSession session) {
    return session.participants.firstWhere((p) => !p.isAI);
  }

  /// Retourne les participants IA
  static List<DominoParticipant> getAIParticipants(DominoSession session) {
    return session.participants.where((p) => p.isAI).toList();
  }
}

/// Résultat d'un placement de tuile
class PlaceTileResult {
  final DominoGameState newState;
  final bool roundEnded;
  final String? roundWinnerId;
  final bool isCapot;

  const PlaceTileResult({
    required this.newState,
    required this.roundEnded,
    this.roundWinnerId,
    this.isCapot = false,
  });
}

/// Résultat d'un passage de tour
class PassTurnResult {
  final DominoGameState newState;
  final bool roundEnded;
  final String? roundWinnerId;

  const PassTurnResult({
    required this.newState,
    required this.roundEnded,
    this.roundWinnerId,
  });
}
