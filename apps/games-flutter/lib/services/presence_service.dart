import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

/// Service pour gérer la présence des utilisateurs en temps réel
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final SupabaseClient _supabase = SupabaseService.client;
  final AuthService _authService = AuthService();

  static const String _visitorIdKey = 'visitor_session_id';

  RealtimeChannel? _presenceChannel;
  final _onlineUsersController = StreamController<PresenceStats>.broadcast();
  final List<OnlineUser> _connectedUsers = [];
  final List<OnlineUser> _visitors = [];

  /// Stream des statistiques de présence
  Stream<PresenceStats> get presenceStatsStream => _onlineUsersController.stream;

  /// Statistiques actuelles
  PresenceStats get currentStats => PresenceStats(
    connectedUsers: List.unmodifiable(_connectedUsers),
    visitors: List.unmodifiable(_visitors),
  );

  /// Nombre d'utilisateurs connectés
  int get connectedCount => _connectedUsers.length;

  /// Nombre de visiteurs anonymes
  int get visitorCount => _visitors.length;

  /// Nombre total en ligne
  int get totalOnline => _connectedUsers.length + _visitors.length;

  /// Génère ou récupère un ID de session pour les visiteurs
  Future<String> _getOrCreateVisitorId() async {
    final prefs = await SharedPreferences.getInstance();
    String? visitorId = prefs.getString(_visitorIdKey);

    if (visitorId == null) {
      // Générer un nouvel ID de visiteur
      visitorId = 'visitor_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      await prefs.setString(_visitorIdKey, visitorId);
    }

    return visitorId;
  }

  /// Initialise le tracking de présence pour tout utilisateur (connecté ou visiteur)
  Future<void> initialize() async {
    final userId = _authService.getUserIdOrNull();
    final isAuthenticated = userId != null;

    String odentifier;
    String username;
    String? avatarUrl;
    bool isVisitor;

    if (isAuthenticated) {
      // Utilisateur connecté
      final user = await _authService.getCurrentUser();
      odentifier = userId;
      username = user?.username ?? 'Utilisateur';
      avatarUrl = user?.avatarUrl;
      isVisitor = false;
    } else {
      // Visiteur anonyme
      odentifier = await _getOrCreateVisitorId();
      username = 'Visiteur';
      avatarUrl = null;
      isVisitor = true;
    }

    // Créer le channel de présence
    _presenceChannel = _supabase.channel(
      'online-users',
      opts: const RealtimeChannelConfig(
        self: true,
      ),
    );

    // Écouter les changements de présence
    _presenceChannel!.onPresenceSync((payload) {
      _updatePresenceStats();
    });

    _presenceChannel!.onPresenceJoin((payload) {
      _updatePresenceStats();
    });

    _presenceChannel!.onPresenceLeave((payload) {
      _updatePresenceStats();
    });

    // S'abonner et tracker la présence
    _presenceChannel!.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        // Envoyer notre état de présence
        _presenceChannel!.track({
          'user_id': odentifier,
          'username': username,
          'avatar_url': avatarUrl,
          'is_visitor': isVisitor,
          'online_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Met à jour les statistiques de présence
  void _updatePresenceStats() {
    if (_presenceChannel == null) return;

    final presenceState = _presenceChannel!.presenceState();
    _connectedUsers.clear();
    _visitors.clear();

    // presenceState est une List<SinglePresenceState>
    for (final presence in presenceState) {
      for (final p in presence.presences) {
        final data = p.payload;
        final isVisitor = data['is_visitor'] as bool? ?? false;

        final user = OnlineUser(
          id: data['user_id'] as String? ?? '',
          username: data['username'] as String? ?? 'Utilisateur',
          avatarUrl: data['avatar_url'] as String?,
          isVisitor: isVisitor,
          onlineAt: DateTime.tryParse(data['online_at'] as String? ?? '') ?? DateTime.now(),
        );

        if (isVisitor) {
          _visitors.add(user);
        } else {
          _connectedUsers.add(user);
        }
      }
    }

    _onlineUsersController.add(currentStats);
  }

  /// Se déconnecter du channel de présence
  Future<void> dispose() async {
    await _presenceChannel?.untrack();
    await _presenceChannel?.unsubscribe();
    _presenceChannel = null;
    _connectedUsers.clear();
    _visitors.clear();
  }

  /// Rafraîchir l'état de présence (heartbeat)
  Future<void> refresh() async {
    if (_presenceChannel == null) return;

    final userId = _authService.getUserIdOrNull();
    final isAuthenticated = userId != null;

    String odentifier;
    String username;
    String? avatarUrl;

    if (isAuthenticated) {
      final user = await _authService.getCurrentUser();
      odentifier = userId;
      username = user?.username ?? 'Utilisateur';
      avatarUrl = user?.avatarUrl;
    } else {
      odentifier = await _getOrCreateVisitorId();
      username = 'Visiteur';
      avatarUrl = null;
    }

    _presenceChannel!.track({
      'user_id': odentifier,
      'username': username,
      'avatar_url': avatarUrl,
      'is_visitor': !isAuthenticated,
      'online_at': DateTime.now().toIso8601String(),
    });
  }
}

/// Statistiques de présence
class PresenceStats {
  final List<OnlineUser> connectedUsers;
  final List<OnlineUser> visitors;

  const PresenceStats({
    required this.connectedUsers,
    required this.visitors,
  });

  int get connectedCount => connectedUsers.length;
  int get visitorCount => visitors.length;
  int get totalOnline => connectedCount + visitorCount;
}

/// Modèle représentant un utilisateur en ligne
class OnlineUser {
  final String id;
  final String username;
  final String? avatarUrl;
  final bool isVisitor;
  final DateTime onlineAt;

  const OnlineUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.isVisitor,
    required this.onlineAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnlineUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
