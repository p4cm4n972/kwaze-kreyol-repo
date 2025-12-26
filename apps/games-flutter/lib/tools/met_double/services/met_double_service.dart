import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../../../services/auth_service.dart';
import '../models/met_double_game.dart';

class MetDoubleService {
  final SupabaseClient _supabase = SupabaseService.client;
  final AuthService _authService = AuthService();

  // Créer une nouvelle session
  Future<MetDoubleSession> createSession({
    required String hostId,
  }) async {
    try {
      final response = await _supabase
          .from('met_double_sessions')
          .insert({
            'host_id': hostId,
            'status': 'waiting',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Ajouter automatiquement l'hôte comme participant
      await _supabase.from('met_double_participants').insert({
        'session_id': response['id'],
        'user_id': hostId,
        'is_host': true,
        'joined_at': DateTime.now().toIso8601String(),
      });

      return await getSession(response['id']);
    } catch (e) {
      throw Exception('Erreur lors de la création de la session: $e');
    }
  }

  // Récupérer une session complète
  Future<MetDoubleSession> getSession(String sessionId) async {
    try {
      final response = await _supabase
          .from('met_double_sessions')
          .select('''
            *,
            met_double_participants (
              *,
              users (username)
            ),
            met_double_rounds (*)
          ''')
          .eq('id', sessionId)
          .single();

      return MetDoubleSession.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la session: $e');
    }
  }

  // Rejoindre une session en tant qu'utilisateur inscrit
  Future<void> joinSessionAsUser({
    required String sessionId,
    required String userId,
  }) async {
    try {
      // Vérifier que la session n'est pas complète (max 3 joueurs)
      final session = await getSession(sessionId);
      if (session.participants.length >= 3) {
        throw Exception('La session est déjà complète');
      }

      await _supabase.from('met_double_participants').insert({
        'session_id': sessionId,
        'user_id': userId,
        'is_host': false,
        'joined_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la jonction à la session: $e');
    }
  }

  // Rejoindre une session en tant qu'invité
  Future<void> joinSessionAsGuest({
    required String sessionId,
    required String guestName,
  }) async {
    try {
      final session = await getSession(sessionId);
      if (session.participants.length >= 3) {
        throw Exception('La session est déjà complète');
      }

      await _supabase.from('met_double_participants').insert({
        'session_id': sessionId,
        'guest_name': guestName,
        'is_host': false,
        'joined_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la jonction à la session: $e');
    }
  }

  // Envoyer une invitation
  Future<void> sendInvitation({
    required String sessionId,
    required String inviterId,
    required String inviteeId,
  }) async {
    try {
      await _supabase.from('met_double_invitations').insert({
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

  // Accepter une invitation
  Future<void> acceptInvitation(String invitationId) async {
    try {
      // Mettre à jour l'invitation
      await _supabase.from('met_double_invitations').update({
        'status': 'accepted',
        'responded_at': DateTime.now().toIso8601String(),
      }).eq('id', invitationId);

      // Récupérer l'invitation pour obtenir les infos
      final invitation = await _supabase
          .from('met_double_invitations')
          .select()
          .eq('id', invitationId)
          .single();

      // Ajouter l'utilisateur à la session
      final userId = _authService.getUserIdOrNull();
      if (userId != null) {
        await joinSessionAsUser(
          sessionId: invitation['session_id'],
          userId: userId,
        );
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'acceptation de l\'invitation: $e');
    }
  }

  // Démarrer la session (quand 3 joueurs sont prêts)
  Future<void> startSession(String sessionId) async {
    try {
      final session = await getSession(sessionId);
      if (!session.canStart) {
        throw Exception('Il faut exactement 3 joueurs pour démarrer');
      }

      await _supabase.from('met_double_sessions').update({
        'status': 'in_progress',
        'started_at': DateTime.now().toIso8601String(),
      }).eq('id', sessionId);
    } catch (e) {
      throw Exception('Erreur lors du démarrage de la session: $e');
    }
  }

  // Enregistrer le résultat d'une manche
  Future<void> recordRound({
    required String sessionId,
    required int roundNumber,
    required String winnerParticipantId,
    required bool isChiree,
  }) async {
    try {
      final userId = _authService.getUserIdOrNull();

      // Enregistrer la manche
      await _supabase.from('met_double_rounds').insert({
        'session_id': sessionId,
        'round_number': roundNumber,
        'winner_participant_id': isChiree ? null : winnerParticipantId,
        'is_chiree': isChiree,
        'recorded_by_user_id': userId,
        'played_at': DateTime.now().toIso8601String(),
      });

      // Si pas chirée, incrémenter les victoires du gagnant
      if (!isChiree) {
        await _supabase.rpc('increment_participant_victories', params: {
          'participant_id': winnerParticipantId,
        });
      }

      // Vérifier si quelqu'un a 3 victoires
      final session = await getSession(sessionId);
      final winner = session.participants.firstWhere(
        (p) => p.victories >= 3,
        orElse: () => session.participants.first,
      );

      if (winner.victories >= 3) {
        await _completeSession(sessionId, winner);
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement de la manche: $e');
    }
  }

  // Terminer la session et marquer les cochons
  Future<void> _completeSession(
      String sessionId, MetDoubleParticipant winner) async {
    try {
      await _supabase.from('met_double_sessions').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'winner_id': winner.userId,
        'winner_name': winner.guestName,
      }).eq('id', sessionId);

      // Marquer les cochons (ceux avec 0 victoires)
      final session = await getSession(sessionId);
      final cochons =
          session.participants.where((p) => p.victories == 0).toList();

      for (var cochon in cochons) {
        await _supabase
            .from('met_double_participants')
            .update({'is_cochon': true}).eq('id', cochon.id);
      }
    } catch (e) {
      throw Exception('Erreur lors de la complétion de la session: $e');
    }
  }

  // Récupérer les sessions de l'utilisateur
  Future<List<MetDoubleSession>> getUserSessions(String userId) async {
    try {
      final response = await _supabase
          .from('met_double_sessions')
          .select('''
            *,
            met_double_participants!inner (
              *,
              users (username)
            ),
            met_double_rounds (*)
          ''')
          .eq('met_double_participants.user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MetDoubleSession.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des sessions utilisateur: $e');
    }
  }

  // Récupérer les statistiques de cochons donnés par un joueur
  Future<List<CochonStats>> getCochonsDonnes(String userId) async {
    try {
      final response = await _supabase.rpc('get_cochons_donnes', params: {
        'player_id': userId,
      });

      return (response as List)
          .map((json) => CochonStats.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des cochons donnés: $e');
    }
  }

  // Récupérer les statistiques de cochons reçus par un joueur
  Future<List<CochonStats>> getCochonsRecus(String userId) async {
    try {
      final response = await _supabase.rpc('get_cochons_recus', params: {
        'victim_id': userId,
      });

      return (response as List)
          .map((json) => CochonStats.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des cochons reçus: $e');
    }
  }

  // Comparer deux joueurs
  Future<PlayerComparison> comparePlayers({
    required String player1Id,
    required String player2Id,
  }) async {
    try {
      final response = await _supabase.rpc('compare_players', params: {
        'player1_id': player1Id,
        'player2_id': player2Id,
      });

      return PlayerComparison.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la comparaison des joueurs: $e');
    }
  }

  // Annuler une session
  Future<void> cancelSession(String sessionId) async {
    try {
      await _supabase.from('met_double_sessions').update({
        'status': 'cancelled',
      }).eq('id', sessionId);
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de la session: $e');
    }
  }
}
