import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

/// Service pour gérer la présence des utilisateurs en temps réel
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final SupabaseClient _supabase = SupabaseService.client;
  final AuthService _authService = AuthService();

  RealtimeChannel? _presenceChannel;
  final _onlineUsersController = StreamController<List<OnlineUser>>.broadcast();
  final List<OnlineUser> _onlineUsers = [];

  /// Stream des utilisateurs en ligne
  Stream<List<OnlineUser>> get onlineUsersStream => _onlineUsersController.stream;

  /// Liste actuelle des utilisateurs en ligne
  List<OnlineUser> get onlineUsers => List.unmodifiable(_onlineUsers);

  /// Nombre d'utilisateurs en ligne
  int get onlineCount => _onlineUsers.length;

  /// Initialise le tracking de présence pour l'utilisateur courant
  Future<void> initialize() async {
    final userId = _authService.getUserIdOrNull();
    if (userId == null) return;

    // Récupérer les infos utilisateur
    final user = await _authService.getCurrentUser();

    // Créer le channel de présence
    _presenceChannel = _supabase.channel(
      'online-users',
      opts: const RealtimeChannelConfig(
        self: true,
      ),
    );

    // Écouter les changements de présence
    _presenceChannel!.onPresenceSync((payload) {
      _updateOnlineUsers();
    });

    _presenceChannel!.onPresenceJoin((payload) {
      _updateOnlineUsers();
    });

    _presenceChannel!.onPresenceLeave((payload) {
      _updateOnlineUsers();
    });

    // S'abonner et tracker la présence de l'utilisateur
    _presenceChannel!.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        // Envoyer notre état de présence
        _presenceChannel!.track({
          'user_id': userId,
          'username': user?.username ?? 'Utilisateur',
          'avatar_url': user?.avatarUrl,
          'online_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Met à jour la liste des utilisateurs en ligne
  void _updateOnlineUsers() {
    if (_presenceChannel == null) return;

    final presenceState = _presenceChannel!.presenceState();
    _onlineUsers.clear();

    // presenceState est une List<SinglePresenceState>
    for (final presence in presenceState) {
      for (final p in presence.presences) {
        final data = p.payload;
        _onlineUsers.add(OnlineUser(
          id: data['user_id'] as String? ?? '',
          username: data['username'] as String? ?? 'Utilisateur',
          avatarUrl: data['avatar_url'] as String?,
          onlineAt: DateTime.tryParse(data['online_at'] as String? ?? '') ?? DateTime.now(),
        ));
      }
    }

    _onlineUsersController.add(List.from(_onlineUsers));
  }

  /// Se déconnecter du channel de présence
  Future<void> dispose() async {
    await _presenceChannel?.untrack();
    await _presenceChannel?.unsubscribe();
    _presenceChannel = null;
    _onlineUsers.clear();
  }

  /// Rafraîchir l'état de présence (heartbeat)
  Future<void> refresh() async {
    final userId = _authService.getUserIdOrNull();
    if (userId == null || _presenceChannel == null) return;

    final user = await _authService.getCurrentUser();

    _presenceChannel!.track({
      'user_id': userId,
      'username': user?.username ?? 'Utilisateur',
      'avatar_url': user?.avatarUrl,
      'online_at': DateTime.now().toIso8601String(),
    });
  }
}

/// Modèle représentant un utilisateur en ligne
class OnlineUser {
  final String id;
  final String username;
  final String? avatarUrl;
  final DateTime onlineAt;

  const OnlineUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.onlineAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnlineUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
