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

  // Rejoindre une session via le code à 6 chiffres
  Future<MetDoubleSession> joinSessionWithCode({
    required String joinCode,
    String? userId,
    String? guestName,
  }) async {
    try {
      // Rechercher la session par le code
      final response = await _supabase
          .from('met_double_sessions')
          .select('id')
          .eq('join_code', joinCode)
          .eq('status', 'waiting') // Seulement les sessions en attente
          .maybeSingle();

      if (response == null) {
        throw Exception('Code invalide ou session déjà commencée');
      }

      final sessionId = response['id'] as String;

      // Rejoindre selon le type (utilisateur ou invité)
      if (userId != null) {
        await joinSessionAsUser(sessionId: sessionId, userId: userId);
      } else if (guestName != null) {
        await joinSessionAsGuest(sessionId: sessionId, guestName: guestName);
      } else {
        throw Exception('Utilisateur ou nom d\'invité requis');
      }

      // Retourner la session complète
      return await getSession(sessionId);
    } catch (e) {
      throw Exception('Erreur lors de la jonction avec le code: $e');
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
    List<String>? cochonParticipantIds, // IDs des joueurs avec 0 point
    required bool isChiree,
    bool skipIncrement = false, // Ne pas incrémenter si déjà fait
  }) async {
    try {
      final userId = _authService.getUserIdOrNull();

      // Enregistrer la manche avec les cochons
      await _supabase.from('met_double_rounds').insert({
        'session_id': sessionId,
        'round_number': roundNumber,
        'winner_participant_id': isChiree ? null : winnerParticipantId,
        'cochon_participant_ids': cochonParticipantIds ?? [],
        'is_chiree': isChiree,
        'recorded_by_user_id': userId,
        'played_at': DateTime.now().toIso8601String(),
      });

      // Si pas chirée et qu'on doit incrémenter, incrémenter les victoires du gagnant
      if (!isChiree && !skipIncrement) {
        await _supabase.rpc('increment_participant_victories', params: {
          'participant_id': winnerParticipantId,
        });
      }

      // Note: On ne termine plus automatiquement la session quand quelqu'un atteint 3 victoires
      // L'utilisateur doit cliquer sur "Terminer" ou accepter la popup de fin de manche
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement de la manche: $e');
    }
  }

  // Terminer la session et marquer les cochons
  Future<void> _completeSession(
      String sessionId, MetDoubleParticipant winner) async {
    try {
      // Définir le gagnant selon s'il est utilisateur ou invité
      final Map<String, dynamic> updateData = {
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      };

      if (winner.userId != null) {
        updateData['winner_id'] = winner.userId;
        updateData['winner_name'] = null; // Utilisateur inscrit
      } else {
        updateData['winner_id'] = null;
        updateData['winner_name'] = winner.guestName; // Invité
      }

      await _supabase.from('met_double_sessions').update(updateData).eq('id', sessionId);

      // Marquer les cochons : récupérer tous les participant_ids qui ont été cochons
      // dans au moins une manche (présents dans cochon_participant_ids de n'importe quel round)
      final session = await getSession(sessionId);
      final Set<String> allCochonIds = {};

      for (var round in session.rounds) {
        allCochonIds.addAll(round.cochonParticipantIds);
      }

      // Marquer ces participants comme cochons
      for (var cochonId in allCochonIds) {
        await _supabase
            .from('met_double_participants')
            .update({'is_cochon': true}).eq('id', cochonId);
      }
    } catch (e) {
      throw Exception('Erreur lors de la complétion de la session: $e');
    }
  }

  // Récupérer les sessions de l'utilisateur
  Future<List<MetDoubleSession>> getUserSessions(String userId) async {
    try {
      // D'abord récupérer les IDs des sessions où l'utilisateur participe
      final participantResponse = await _supabase
          .from('met_double_participants')
          .select('session_id')
          .eq('user_id', userId);

      final sessionIds = (participantResponse as List)
          .map((p) => p['session_id'] as String)
          .toList();

      if (sessionIds.isEmpty) {
        return [];
      }

      // Ensuite récupérer les sessions complètes avec TOUS les participants
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
          .inFilter('id', sessionIds)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MetDoubleSession.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des sessions utilisateur: $e');
    }
  }

  // Supprimer une session (seulement si host)
  Future<void> deleteSession(String sessionId) async {
    try {
      await _supabase
          .from('met_double_sessions')
          .delete()
          .eq('id', sessionId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la session: $e');
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

  // Incrémenter les victoires d'un participant
  Future<void> incrementParticipantVictories(String participantId) async {
    try {
      // Récupérer le participant
      final response = await _supabase
          .from('met_double_participants')
          .select('victories')
          .eq('id', participantId)
          .single();

      final currentVictories = response['victories'] as int;

      // Incrémenter seulement si < 3
      if (currentVictories < 3) {
        await _supabase
            .from('met_double_participants')
            .update({'victories': currentVictories + 1})
            .eq('id', participantId);
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'incrémentation: $e');
    }
  }

  // Décrémenter les victoires d'un participant
  Future<void> decrementParticipantVictories(String participantId) async {
    try {
      // Récupérer le participant
      final response = await _supabase
          .from('met_double_participants')
          .select('victories')
          .eq('id', participantId)
          .single();

      final currentVictories = response['victories'] as int;

      if (currentVictories > 0) {
        await _supabase
            .from('met_double_participants')
            .update({'victories': currentVictories - 1})
            .eq('id', participantId);
      }
    } catch (e) {
      throw Exception('Erreur lors de la décrémentation: $e');
    }
  }

  // Réinitialiser le score d'un participant
  Future<void> resetParticipantScore(String participantId) async {
    try {
      await _supabase
          .from('met_double_participants')
          .update({
            'victories': 0,
            'is_cochon': false, // Réinitialiser aussi le statut de cochon
          })
          .eq('id', participantId);
    } catch (e) {
      throw Exception('Erreur lors de la réinitialisation: $e');
    }
  }

  // Forcer la fin de la session
  Future<void> forceEndSession(String sessionId) async {
    try {
      final session = await getSession(sessionId);

      // Calculer le vrai gagnant en comptant les manches gagnées depuis l'historique
      MetDoubleParticipant? winner;
      int maxManches = 0;

      for (var participant in session.participants) {
        final manchesGagnees = session.rounds.where((r) => r.winnerParticipantId == participant.id).length;
        if (manchesGagnees > maxManches) {
          maxManches = manchesGagnees;
          winner = participant;
        }
      }

      // Si aucun gagnant trouvé (aucune manche jouée), prendre le premier participant
      winner ??= session.participants.first;

      await _completeSession(sessionId, winner);
    } catch (e) {
      throw Exception('Erreur lors de la fin forcée: $e');
    }
  }

  // Marquer un participant comme cochon
  Future<void> markParticipantAsCochon(String participantId) async {
    try {
      await _supabase
          .from('met_double_participants')
          .update({'is_cochon': true})
          .eq('id', participantId);
    } catch (e) {
      throw Exception('Erreur lors du marquage du cochon: $e');
    }
  }

  // Récupérer les statistiques générales d'un joueur
  Future<Map<String, dynamic>> getPlayerGeneralStats(String userId) async {
    try {
      // Récupérer toutes les sessions terminées où le joueur a participé (pour stats personnelles)
      final sessions = await getUserSessions(userId);
      final completedSessions = sessions.where((s) => s.status == 'completed').toList();

      // Calculer le nombre de manches jouées PERSONNELLES
      int nombreManches = 0;
      for (var session in completedSessions) {
        nombreManches += session.rounds.length;
      }

      // Calculer le nombre de partenaires uniques
      Set<String> partenaires = {};
      for (var session in completedSessions) {
        for (var participant in session.participants) {
          // Ajouter les autres joueurs (pas soi-même)
          if (participant.userId != userId) {
            partenaires.add(participant.userId ?? participant.guestName ?? '');
          }
        }
      }

      // STATISTIQUES GLOBALES (tous les joueurs)
      // Récupérer TOUTES les sessions terminées (pas seulement celles du joueur actuel)
      final allCompletedSessionsResponse = await _supabase
          .from('met_double_sessions')
          .select('''
            *,
            met_double_participants (
              *,
              users (username)
            ),
            met_double_rounds (*)
          ''')
          .eq('status', 'completed');

      final allCompletedSessions = (allCompletedSessionsResponse as List)
          .map((json) => MetDoubleSession.fromJson(json))
          .toList();

      // Compter le nombre total de parties terminées
      final totalParties = allCompletedSessions.length;

      // Compter le nombre total de manches
      final totalManchesResponse = await _supabase
          .from('met_double_rounds')
          .select('id');
      final totalManches = (totalManchesResponse as List).length;

      // Compter le nombre d'utilisateurs inscrits
      final totalAbonnesResponse = await _supabase
          .from('users')
          .select('id');
      final totalAbonnes = (totalAbonnesResponse as List).length;

      // Top joueurs : compter les victoires de chaque joueur (TOUTES les parties)
      Map<String, Map<String, dynamic>> joueursVictoires = {};

      for (var session in allCompletedSessions) {
        for (var participant in session.participants) {
          final participantKey = participant.userId ?? participant.guestName ?? '';
          final participantName = participant.displayName;

          if (!joueursVictoires.containsKey(participantKey)) {
            joueursVictoires[participantKey] = {
              'name': participantName,
              'victories': 0,
            };
          }

          // Compter les manches gagnées
          final manchesGagnees = session.rounds.where((r) => r.winnerParticipantId == participant.id).length;
          joueursVictoires[participantKey]!['victories'] =
            (joueursVictoires[participantKey]!['victories'] as int) + manchesGagnees;
        }
      }

      // Trier par victoires
      final topJoueurs = joueursVictoires.values.toList()
        ..sort((a, b) => (b['victories'] as int).compareTo(a['victories'] as int));

      // Top met double : compter les cochons DONNÉS par chaque joueur (TOUTES les parties)
      Map<String, Map<String, dynamic>> joueursMetDouble = {};

      for (var session in allCompletedSessions) {
        for (var round in session.rounds) {
          // Le gagnant a donné des cochons
          if (round.winnerParticipantId != null && round.cochonParticipantIds.isNotEmpty) {
            final winner = session.participants.firstWhere(
              (p) => p.id == round.winnerParticipantId,
              orElse: () => session.participants.first,
            );

            final winnerKey = winner.userId ?? winner.guestName ?? '';
            final winnerName = winner.displayName;

            if (!joueursMetDouble.containsKey(winnerKey)) {
              joueursMetDouble[winnerKey] = {
                'name': winnerName,
                'cochons': 0,
              };
            }

            // Compter le nombre de cochons donnés dans ce round
            joueursMetDouble[winnerKey]!['cochons'] =
              (joueursMetDouble[winnerKey]!['cochons'] as int) + round.cochonParticipantIds.length;
          }
        }
      }

      // Top met cochon : compter les cochons REÇUS par chaque joueur (TOUTES les parties)
      Map<String, Map<String, dynamic>> joueursMetCochon = {};

      for (var session in allCompletedSessions) {
        for (var round in session.rounds) {
          // Pour chaque participant qui a reçu un cochon
          for (var cochonId in round.cochonParticipantIds) {
            final cochonParticipant = session.participants.firstWhere(
              (p) => p.id == cochonId,
              orElse: () => session.participants.first,
            );

            final cochonKey = cochonParticipant.userId ?? cochonParticipant.guestName ?? '';
            final cochonName = cochonParticipant.displayName;

            if (!joueursMetCochon.containsKey(cochonKey)) {
              joueursMetCochon[cochonKey] = {
                'name': cochonName,
                'cochons': 0,
              };
            }

            // Incrémenter le nombre de cochons reçus
            joueursMetCochon[cochonKey]!['cochons'] =
              (joueursMetCochon[cochonKey]!['cochons'] as int) + 1;
          }
        }
      }

      // Trier par nombre de cochons
      final topMetDouble = joueursMetDouble.values.toList()
        ..sort((a, b) => (b['cochons'] as int).compareTo(a['cochons'] as int));

      final topMetCochon = joueursMetCochon.values.toList()
        ..sort((a, b) => (b['cochons'] as int).compareTo(a['cochons'] as int));

      return {
        // Statistiques personnelles
        'nombreManches': nombreManches,
        'nombrePartenaires': partenaires.length,

        // Statistiques globales
        'totalParties': totalParties,
        'totalManches': totalManches,
        'totalAbonnes': totalAbonnes,

        // Classements
        'topJoueurs': topJoueurs.take(10).toList(), // Top 10
        'topMetDouble': topMetDouble.take(10).toList(), // Top 10 - ceux qui donnent le plus
        'topMetCochon': topMetCochon.take(10).toList(), // Top 10 - ceux qui reçoivent le plus
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }
}
