import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../../../services/supabase_service.dart';
import '../../../services/auth_service.dart';
import '../models/domino_session.dart';
import '../models/domino_participant.dart';
import '../models/domino_game_state.dart';
import '../models/domino_tile.dart';
import '../utils/domino_scoring.dart';

/// Service pour gérer les sessions de dominos martiniquais
class DominoService {
  final SupabaseClient _supabase = SupabaseService.client;
  final AuthService _authService = AuthService();

  // ============================================================================
  // GESTION DES SESSIONS
  // ============================================================================

  /// Crée une nouvelle session de dominos
  Future<DominoSession> createSession({required String hostId}) async {
    try {
      // Générer un code de session unique
      final joinCode = await _supabase.rpc('generate_domino_join_code');

      final response = await _supabase
          .from('domino_sessions')
          .insert({
            'host_id': hostId,
            'join_code': joinCode,
            'status': 'waiting',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Ajouter l'hôte comme premier participant (turn_order = 0)
      await _supabase.from('domino_participants').insert({
        'session_id': response['id'],
        'user_id': hostId,
        'turn_order': 0,
        'is_host': true,
        'joined_at': DateTime.now().toIso8601String(),
      });

      return await getSession(response['id']);
    } catch (e) {
      throw Exception('Erreur lors de la création de la session: $e');
    }
  }

  /// Récupère une session complète avec tous ses participants et manches
  Future<DominoSession> getSession(String sessionId) async {
    try {
      final response = await _supabase
          .from('domino_sessions')
          .select('''
            *,
            domino_participants (
              *,
              users (username)
            ),
            domino_rounds (*)
          ''')
          .eq('id', sessionId)
          .single();

      // Mapper les participants avec les noms d'utilisateur
      if (response['domino_participants'] != null) {
        for (var participant in response['domino_participants']) {
          if (participant['users'] != null) {
            participant['user_name'] = participant['users']['username'];
          }
        }
      }

      // Renommer les clés pour matcher le modèle DominoSession
      response['participants'] = response['domino_participants'];
      response['rounds'] = response['domino_rounds'];

      return DominoSession.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la session: $e');
    }
  }

  /// Rejoint une session en tant qu'utilisateur inscrit
  Future<void> joinSessionAsUser({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final session = await getSession(sessionId);

      if (session.participants.length >= 3) {
        throw Exception('La session est déjà complète (3/3 joueurs)');
      }

      if (session.status != 'waiting') {
        throw Exception('La session n\'est plus en attente de joueurs');
      }

      // Déterminer le turn_order (0, 1, 2)
      final existingOrders = session.participants.map((p) => p.turnOrder).toList();
      int turnOrder = 0;
      while (existingOrders.contains(turnOrder)) {
        turnOrder++;
      }

      await _supabase.from('domino_participants').insert({
        'session_id': sessionId,
        'user_id': userId,
        'turn_order': turnOrder,
        'is_host': false,
        'joined_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la jonction: $e');
    }
  }

  /// Rejoint une session en tant qu'invité
  Future<void> joinSessionAsGuest({
    required String sessionId,
    required String guestName,
  }) async {
    try {
      final session = await getSession(sessionId);

      if (session.participants.length >= 3) {
        throw Exception('La session est déjà complète (3/3 joueurs)');
      }

      if (session.status != 'waiting') {
        throw Exception('La session n\'est plus en attente de joueurs');
      }

      final existingOrders = session.participants.map((p) => p.turnOrder).toList();
      int turnOrder = 0;
      while (existingOrders.contains(turnOrder)) {
        turnOrder++;
      }

      await _supabase.from('domino_participants').insert({
        'session_id': sessionId,
        'guest_name': guestName,
        'turn_order': turnOrder,
        'is_host': false,
        'joined_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la jonction: $e');
    }
  }

  /// Rejoint une session avec un code
  Future<DominoSession> joinSessionWithCode({
    required String joinCode,
    String? userId,
    String? guestName,
  }) async {
    try {
      // Rechercher la session par code
      final response = await _supabase
          .from('domino_sessions')
          .select('id')
          .eq('join_code', joinCode)
          .eq('status', 'waiting')
          .maybeSingle();

      if (response == null) {
        throw Exception('Code de session invalide ou session déjà démarrée');
      }

      final sessionId = response['id'] as String;

      // Rejoindre la session
      if (userId != null) {
        await joinSessionAsUser(sessionId: sessionId, userId: userId);
      } else if (guestName != null) {
        await joinSessionAsGuest(sessionId: sessionId, guestName: guestName);
      } else {
        throw Exception('userId ou guestName requis');
      }

      return await getSession(sessionId);
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Démarre une session (quand 3 joueurs sont présents)
  Future<void> startSession(String sessionId) async {
    try {
      final session = await getSession(sessionId);

      if (session.participants.length != 3) {
        throw Exception('3 joueurs requis pour démarrer (${session.participants.length}/3)');
      }

      await _supabase.from('domino_sessions').update({
        'status': 'in_progress',
        'started_at': DateTime.now().toIso8601String(),
      }).eq('id', sessionId);

      // Démarrer la première manche
      await startNewRound(sessionId);
    } catch (e) {
      throw Exception('Erreur au démarrage: $e');
    }
  }

  /// Annule une session
  Future<void> cancelSession(String sessionId) async {
    try {
      await _supabase.from('domino_sessions').update({
        'status': 'cancelled',
      }).eq('id', sessionId);
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation: $e');
    }
  }

  // ============================================================================
  // GESTION DES INVITATIONS
  // ============================================================================

  /// Envoie une invitation à un ami
  Future<void> sendInvitation({
    required String sessionId,
    required String inviterId,
    required String inviteeId,
  }) async {
    try {
      await _supabase.from('domino_invitations').insert({
        'session_id': sessionId,
        'inviter_id': inviterId,
        'invitee_id': inviteeId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'invitation: $e');
    }
  }

  /// Récupère les invitations en attente d'un utilisateur
  Future<List<Map<String, dynamic>>> getPendingInvitations(String userId) async {
    try {
      final response = await _supabase
          .from('domino_invitations')
          .select('''
            *,
            domino_sessions (*),
            inviter:users!inviter_id (username)
          ''')
          .eq('invitee_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Accepte une invitation
  Future<DominoSession> acceptInvitation(String invitationId) async {
    try {
      // Récupérer l'invitation
      final invitation = await _supabase
          .from('domino_invitations')
          .select('session_id, invitee_id')
          .eq('id', invitationId)
          .single();

      // Rejoindre la session
      await joinSessionAsUser(
        sessionId: invitation['session_id'],
        userId: invitation['invitee_id'],
      );

      // Marquer l'invitation comme acceptée
      await _supabase.from('domino_invitations').update({
        'status': 'accepted',
        'responded_at': DateTime.now().toIso8601String(),
      }).eq('id', invitationId);

      return await getSession(invitation['session_id']);
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Décline une invitation
  Future<void> declineInvitation(String invitationId) async {
    try {
      await _supabase.from('domino_invitations').update({
        'status': 'declined',
        'responded_at': DateTime.now().toIso8601String(),
      }).eq('id', invitationId);
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // ============================================================================
  // LOGIQUE DE JEU
  // ============================================================================

  /// Démarre une nouvelle manche
  Future<void> startNewRound(String sessionId) async {
    try {
      final session = await getSession(sessionId);

      // Créer et mélanger les tuiles
      final allTiles = DominoTile.createFullSet()..shuffle();

      // Distribuer 7 tuiles à chaque joueur (21 total, 7 restent)
      final participantIds = session.participants.map((p) => p.id).toList()
        ..sort((a, b) => session.participants
            .firstWhere((p) => p.id == a)
            .turnOrder
            .compareTo(session.participants.firstWhere((p) => p.id == b).turnOrder));

      final playerHands = <String, List<DominoTile>>{
        participantIds[0]: allTiles.sublist(0, 7),
        participantIds[1]: allTiles.sublist(7, 14),
        participantIds[2]: allTiles.sublist(14, 21),
      };

      // Déterminer qui commence
      String startingPlayerId;
      if (session.rounds.isEmpty) {
        // Première manche: celui avec le double le plus haut
        startingPlayerId = _determineStartingPlayer(playerHands);
      } else {
        // Manches suivantes: gagnant de la manche précédente
        final lastRound = session.rounds.last;
        startingPlayerId = lastRound.winnerParticipantId ?? participantIds[0];
      }

      final roundNumber = session.rounds.length + 1;

      // Créer l'état initial de la manche
      final gameState = DominoGameState(
        roundNumber: roundNumber,
        board: [],
        leftEnd: null,
        rightEnd: null,
        playerHands: playerHands,
        currentTurnParticipantId: startingPlayerId,
        passedPlayerIds: [],
        isBlocked: false,
        lastMoveAt: DateTime.now(),
      );

      // Mettre à jour la session
      await _supabase.from('domino_sessions').update({
        'current_game_state': gameState.toJson(),
      }).eq('id', sessionId);
    } catch (e) {
      throw Exception('Erreur au démarrage de la manche: $e');
    }
  }

  /// Détermine le joueur qui commence (double le plus haut)
  String _determineStartingPlayer(Map<String, List<DominoTile>> hands) {
    String? highestDoublePlayer;
    int highestDouble = -1;

    for (var entry in hands.entries) {
      final doubles = entry.value.where((t) => t.isDouble);
      if (doubles.isNotEmpty) {
        final maxDouble = doubles.map((t) => t.value1).reduce(max);
        if (maxDouble > highestDouble) {
          highestDouble = maxDouble;
          highestDoublePlayer = entry.key;
        }
      }
    }

    if (highestDoublePlayer != null) return highestDoublePlayer;

    // Fallback: joueur avec la tuile de valeur totale la plus haute
    String highestTilePlayer = hands.keys.first;
    int highestTotal = 0;

    for (var entry in hands.entries) {
      final maxTile = entry.value.map((t) => t.totalValue).reduce(max);
      if (maxTile > highestTotal) {
        highestTotal = maxTile;
        highestTilePlayer = entry.key;
      }
    }

    return highestTilePlayer;
  }

  /// Place une tuile sur le plateau
  Future<void> placeTile({
    required String sessionId,
    required String participantId,
    required DominoTile tile,
    required String side, // "left" ou "right"
  }) async {
    try {
      final session = await getSession(sessionId);
      final gameState = session.currentGameState!;

      // Validation: c'est le tour du joueur
      if (gameState.currentTurnParticipantId != participantId) {
        throw Exception('Ce n\'est pas votre tour');
      }

      // Validation: le joueur possède la tuile
      final hand = gameState.playerHands[participantId]!;
      if (!hand.any((t) => t.id == tile.id)) {
        throw Exception('Vous ne possédez pas cette tuile');
      }

      // Validation et placement
      int connectedValue;
      int exposedValue;

      if (gameState.board.isEmpty) {
        // Première tuile: n'importe quelle valeur
        connectedValue = tile.value1;
        exposedValue = tile.value2;
      } else {
        final targetEnd = side == 'left' ? gameState.leftEnd! : gameState.rightEnd!;

        if (!tile.canConnect(targetEnd)) {
          throw Exception('Cette tuile ne peut pas se connecter à $targetEnd');
        }

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
      final newBoard = List<PlacedTile>.from(gameState.board);
      if (gameState.board.isEmpty || side == 'right') {
        newBoard.add(placedTile);
      } else {
        newBoard.insert(0, placedTile);
      }

      // Mettre à jour les bouts
      int? newLeftEnd = gameState.leftEnd;
      int? newRightEnd = gameState.rightEnd;

      if (gameState.board.isEmpty) {
        // Première tuile: les deux bouts sont les valeurs de la tuile
        newLeftEnd = tile.value1;
        newRightEnd = tile.value2;
      } else if (side == 'left') {
        newLeftEnd = exposedValue;
      } else {
        newRightEnd = exposedValue;
      }

      // Retirer la tuile de la main
      final newHand = List<DominoTile>.from(hand)..removeWhere((t) => t.id == tile.id);
      final newHands = Map<String, List<DominoTile>>.from(gameState.playerHands);
      newHands[participantId] = newHand;

      // Vérifier capot (main vide)
      if (newHand.isEmpty) {
        await _endRound(
          sessionId: sessionId,
          winnerParticipantId: participantId,
          endType: 'capot',
          finalHands: newHands,
        );
        return;
      }

      // Passer au joueur suivant
      final participants = session.participants..sort((a, b) => a.turnOrder.compareTo(b.turnOrder));
      final currentIndex = participants.indexWhere((p) => p.id == participantId);
      final nextPlayer = participants[(currentIndex + 1) % 3];

      // Mettre à jour l'état
      final newGameState = gameState.copyWith(
        board: newBoard,
        leftEnd: newLeftEnd,
        rightEnd: newRightEnd,
        playerHands: newHands,
        currentTurnParticipantId: nextPlayer.id,
        passedPlayerIds: [], // Reset des passes
        lastMoveAt: DateTime.now(),
      );

      await _supabase.from('domino_sessions').update({
        'current_game_state': newGameState.toJson(),
      }).eq('id', sessionId);
    } catch (e) {
      throw Exception('Erreur placement: $e');
    }
  }

  /// Passe le tour
  Future<void> passTurn({
    required String sessionId,
    required String participantId,
  }) async {
    try {
      final session = await getSession(sessionId);
      final gameState = session.currentGameState!;

      if (gameState.currentTurnParticipantId != participantId) {
        throw Exception('Ce n\'est pas votre tour');
      }

      // Vérifier que le joueur ne peut vraiment pas jouer
      final hand = gameState.playerHands[participantId]!;
      final canPlay = hand.any((tile) => gameState.canPlaceTile(tile));

      if (canPlay) {
        throw Exception('Vous pouvez encore jouer');
      }

      // Ajouter à la liste des joueurs qui ont passé
      final newPassedList = [...gameState.passedPlayerIds, participantId];

      // Vérifier blocage (tous ont passé)
      if (newPassedList.length >= 3) {
        // Calculer le gagnant (moins de points)
        final scores = gameState.playerHands.map(
          (key, tiles) => MapEntry(key, tiles.fold(0, (sum, t) => sum + t.totalValue)),
        );

        final winnerEntry = scores.entries.reduce(
          (a, b) => a.value < b.value ? a : b,
        );

        await _endRound(
          sessionId: sessionId,
          winnerParticipantId: winnerEntry.key,
          endType: 'blocked',
          finalHands: gameState.playerHands,
        );
        return;
      }

      // Passer au joueur suivant
      final participants = session.participants..sort((a, b) => a.turnOrder.compareTo(b.turnOrder));
      final currentIndex = participants.indexWhere((p) => p.id == participantId);
      final nextPlayer = participants[(currentIndex + 1) % 3];

      final newGameState = gameState.copyWith(
        currentTurnParticipantId: nextPlayer.id,
        passedPlayerIds: newPassedList,
        lastMoveAt: DateTime.now(),
      );

      await _supabase.from('domino_sessions').update({
        'current_game_state': newGameState.toJson(),
      }).eq('id', sessionId);
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Termine une manche
  Future<void> _endRound({
    required String sessionId,
    required String winnerParticipantId,
    required String endType,
    required Map<String, List<DominoTile>> finalHands,
  }) async {
    try {
      final session = await getSession(sessionId);
      final gameState = session.currentGameState!;

      // Calculer les scores finaux
      final finalScores = finalHands.map(
        (key, tiles) => MapEntry(key, tiles.fold(0, (sum, t) => sum + t.totalValue)),
      );

      // Créer l'enregistrement de la manche
      final roundResponse = await _supabase.from('domino_rounds').insert({
        'session_id': sessionId,
        'round_number': gameState.roundNumber,
        'winner_participant_id': winnerParticipantId,
        'end_type': endType,
        'final_scores': finalScores,
        'played_at': DateTime.now().toIso8601String(),
      }).select().single();

      // Incrémenter rounds_won du gagnant
      await _supabase.rpc('increment_domino_rounds_won', params: {
        'participant_id': winnerParticipantId,
      });

      // Recharger la session
      final updatedSession = await getSession(sessionId);
      final winner = updatedSession.participants.firstWhere(
        (p) => p.id == winnerParticipantId,
      );

      // Vérifier CHIRÉE (tous ont ≥1 manche ET aucun n'a 3)
      final isChiree = DominoScoring.isChiree(updatedSession.participants);
      if (isChiree) {
        await _completeSessionWithChiree(sessionId);
        return;
      }

      // Vérifier si le gagnant a atteint 3 manches (victoire classique)
      if (winner.roundsWon >= 3) {
        await _completeSession(sessionId, winner);
        return;
      }

      // Démarrer nouvelle manche
      await startNewRound(sessionId);
    } catch (e) {
      throw Exception('Erreur fin de manche: $e');
    }
  }

  /// Termine la session (victoire classique)
  Future<void> _completeSession(String sessionId, DominoParticipant winner) async {
    try {
      final session = await getSession(sessionId);

      // Marquer les cochons (0 manche)
      for (var participant in session.participants) {
        if (participant.roundsWon == 0) {
          await _supabase.from('domino_participants').update({
            'is_cochon': true,
          }).eq('id', participant.id);
        }
      }

      // Terminer la session
      await _supabase.from('domino_sessions').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'winner_id': winner.userId,
        'winner_name': winner.guestName,
        'total_rounds': session.rounds.length + 1,
        'current_game_state': null,
      }).eq('id', sessionId);
    } catch (e) {
      throw Exception('Erreur fin de session: $e');
    }
  }

  /// Termine la session en chirée (match nul)
  Future<void> _completeSessionWithChiree(String sessionId) async {
    try {
      final session = await getSession(sessionId);

      // Aucun cochon en cas de chirée (tous ont au moins 1 manche)
      // Pas besoin de marquer les cochons

      // Terminer la session avec status 'chiree'
      await _supabase.from('domino_sessions').update({
        'status': 'chiree',
        'completed_at': DateTime.now().toIso8601String(),
        'winner_id': null, // Pas de gagnant en chirée
        'winner_name': 'CHIRÉE',
        'total_rounds': session.rounds.length + 1,
        'current_game_state': null,
      }).eq('id', sessionId);
    } catch (e) {
      throw Exception('Erreur fin de session en chirée: $e');
    }
  }

  // ============================================================================
  // STATISTIQUES
  // ============================================================================

  /// Récupère les statistiques d'un joueur
  Future<Map<String, dynamic>> getPlayerStats(String userId) async {
    try {
      final response = await _supabase.rpc('get_domino_player_stats', params: {
        'player_id': userId,
      });

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Récupère le classement
  Future<List<Map<String, dynamic>>> getLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc('get_domino_leaderboard', params: {
        'limit_count': limit,
        'offset_count': offset,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Récupère les sessions d'un utilisateur
  Future<List<DominoSession>> getUserSessions(
    String userId, {
    int limit = 20,
  }) async {
    try {
      // Étape 1: Récupérer les IDs des sessions où l'utilisateur participe
      final participations = await _supabase
          .from('domino_participants')
          .select('session_id')
          .eq('user_id', userId);

      final sessionIds = (participations as List)
          .map((p) => p['session_id'] as String)
          .toList();

      if (sessionIds.isEmpty) {
        return [];
      }

      // Étape 2: Récupérer ces sessions avec TOUS leurs participants
      final response = await _supabase
          .from('domino_sessions')
          .select('''
            *,
            domino_participants (
              *,
              users (username)
            ),
            domino_rounds (*)
          ''')
          .inFilter('id', sessionIds)
          .order('created_at', ascending: false)
          .limit(limit);

      // Mapper les noms pour correspondre au modèle
      return (response as List).map((json) {
        // Mapper les noms d'utilisateur
        if (json['domino_participants'] != null) {
          for (var participant in json['domino_participants']) {
            if (participant['users'] != null) {
              participant['user_name'] = participant['users']['username'];
            }
          }
        }

        // Renommer les clés pour matcher le modèle DominoSession
        json['participants'] = json['domino_participants'];
        json['rounds'] = json['domino_rounds'];

        return DominoSession.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }
}
