import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'supabase_service.dart';
import '../tools/met_double/models/met_double_game.dart';

class RealtimeService {
  final SupabaseClient _supabase = SupabaseService.client;
  final Map<String, RealtimeChannel> _channels = {};

  // S'abonner aux changements d'une session Mét Double
  Stream<MetDoubleSession> subscribeToSession(String sessionId) {
    final controller = StreamController<MetDoubleSession>.broadcast();

    // Créer un canal unique pour cette session
    final channelName = 'met_double_session_$sessionId';

    if (_channels.containsKey(channelName)) {
      // Si déjà abonné, retirer l'ancien canal
      unsubscribeFromSession(sessionId);
    }

    final channel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'met_double_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sessionId,
          ),
          callback: (payload) async {
            // Recharger toute la session avec les relations
            await _loadAndEmitSession(sessionId, controller);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'met_double_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) async {
            await _loadAndEmitSession(sessionId, controller);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'met_double_rounds',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) async {
            await _loadAndEmitSession(sessionId, controller);
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    // Charger la session initiale
    _loadAndEmitSession(sessionId, controller);

    return controller.stream;
  }

  // Charger et émettre la session complète
  Future<void> _loadAndEmitSession(
    String sessionId,
    StreamController<MetDoubleSession> controller,
  ) async {
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

      final session = MetDoubleSession.fromJson(response);
      controller.add(session);
    } catch (e) {
      controller.addError(e);
    }
  }

  // Se désabonner d'une session
  Future<void> unsubscribeFromSession(String sessionId) async {
    final channelName = 'met_double_session_$sessionId';
    final channel = _channels[channelName];

    if (channel != null) {
      await _supabase.removeChannel(channel);
      _channels.remove(channelName);
    }
  }

  // S'abonner aux invitations d'un utilisateur
  Stream<List<MetDoubleInvitation>> subscribeToInvitations(String userId) {
    final controller = StreamController<List<MetDoubleInvitation>>.broadcast();
    final channelName = 'invitations_$userId';

    if (_channels.containsKey(channelName)) {
      unsubscribeFromInvitations(userId);
    }

    final channel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'met_double_invitations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'invitee_id',
            value: userId,
          ),
          callback: (payload) async {
            await _loadAndEmitInvitations(userId, controller);
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    // Charger les invitations initiales
    _loadAndEmitInvitations(userId, controller);

    return controller.stream;
  }

  // Charger et émettre les invitations
  Future<void> _loadAndEmitInvitations(
    String userId,
    StreamController<List<MetDoubleInvitation>> controller,
  ) async {
    try {
      final response = await _supabase
          .from('met_double_invitations')
          .select('''
            *,
            inviter:users!inviter_id (username),
            invitee:users!invitee_id (username)
          ''')
          .eq('invitee_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final invitations = (response as List)
          .map((json) => MetDoubleInvitation.fromJson(json))
          .toList();

      controller.add(invitations);
    } catch (e) {
      controller.addError(e);
    }
  }

  // Se désabonner des invitations
  Future<void> unsubscribeFromInvitations(String userId) async {
    final channelName = 'invitations_$userId';
    final channel = _channels[channelName];

    if (channel != null) {
      await _supabase.removeChannel(channel);
      _channels.remove(channelName);
    }
  }

  // Nettoyer tous les canaux
  Future<void> dispose() async {
    for (var channel in _channels.values) {
      await _supabase.removeChannel(channel);
    }
    _channels.clear();
  }
}
