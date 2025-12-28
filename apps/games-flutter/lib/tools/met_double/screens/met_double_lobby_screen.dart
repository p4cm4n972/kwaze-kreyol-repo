import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../services/auth_service.dart';
import '../../../services/realtime_service.dart';
import '../../../services/friends_service.dart';
import '../../../models/friend.dart';
import '../services/met_double_service.dart';
import '../models/met_double_game.dart';
import 'met_double_game_screen.dart';

class MetDoubleLobbyScreen extends StatefulWidget {
  final MetDoubleSession session;

  const MetDoubleLobbyScreen({super.key, required this.session});

  @override
  State<MetDoubleLobbyScreen> createState() => _MetDoubleLobbyScreenState();
}

class _MetDoubleLobbyScreenState extends State<MetDoubleLobbyScreen> {
  final MetDoubleService _metDoubleService = MetDoubleService();
  final AuthService _authService = AuthService();
  final RealtimeService _realtimeService = RealtimeService();
  final FriendsService _friendsService = FriendsService();

  late MetDoubleSession _currentSession;
  StreamSubscription<MetDoubleSession>? _sessionSubscription;
  bool _isHost = false;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    _checkIfHost();
    _checkIfGuest();
    _subscribeToSession();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _realtimeService.unsubscribeFromSession(_currentSession.id);
    super.dispose();
  }

  Future<void> _checkIfHost() async {
    final userId = _authService.getUserIdOrNull();
    setState(() {
      _isHost = userId == _currentSession.hostId;
    });
  }

  Future<void> _checkIfGuest() async {
    _isGuest = await _authService.isGuestMode();
  }

  void _subscribeToSession() {
    _sessionSubscription = _realtimeService
        .subscribeToSession(_currentSession.id)
        .listen((session) {
          setState(() {
            _currentSession = session;
          });

          // Si la session a démarré, naviguer vers l'écran de jeu
          if (_currentSession.status == 'in_progress' && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MetDoubleGameScreen(session: _currentSession),
              ),
            );
          }
        });
  }

  Future<void> _addGuestPlayer() async {
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un joueur invité'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du joueur',
            hintText: 'Entrez le nom',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      try {
        await _metDoubleService.joinSessionAsGuest(
          sessionId: _currentSession.id,
          guestName: name,
        );

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$name a rejoint la session')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    }
  }

  Future<void> _inviteFriend() async {
    try {
      // Récupérer la liste des amis
      final friends = await _friendsService.getFriends();

      if (friends.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous n\'avez pas encore d\'amis à inviter'),
            ),
          );
        }
        return;
      }

      // Afficher la liste des amis dans un dialog
      final selectedFriend = await showDialog<Friend>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Inviter un ami'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: friend.avatarUrl != null
                        ? NetworkImage(friend.avatarUrl!)
                        : null,
                    child: friend.avatarUrl == null
                        ? Text(friend.username[0].toUpperCase())
                        : null,
                  ),
                  title: Text(friend.username),
                  trailing: friend.isOnline
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  onTap: () => Navigator.pop(context, friend),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      );

      if (selectedFriend != null) {
        final userId = _authService.getUserIdOrNull();
        if (userId == null) return;

        await _metDoubleService.sendInvitation(
          sessionId: _currentSession.id,
          inviterId: userId,
          inviteeId: selectedFriend.id,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invitation envoyée à ${selectedFriend.username}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _startSession() async {
    if (!_currentSession.canStart) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Il faut exactement 3 joueurs pour démarrer'),
        ),
      );
      return;
    }

    try {
      await _metDoubleService.startSession(_currentSession.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _cancelSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la session'),
        content: const Text('Voulez-vous vraiment annuler cette session ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _metDoubleService.cancelSession(_currentSession.id);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    }
  }

  void _copySessionCode() {
    // Utiliser le code généré par Supabase
    final code = _currentSession.joinCode ?? '';
    if (code.isEmpty) return;

    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copié dans le presse-papiers')),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Salle d\'attente'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
            tooltip: 'Retour aux sessions',
          );
        },
      ),
      actions: [
        if (_isHost)
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: _cancelSession,
            tooltip: 'Annuler la session',
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Code de session
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Column(
                children: [
                  const Text(
                    'Code de session',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentSession.joinCode ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copySessionCode,
                        tooltip: 'Copier le code',
                      ),
                    ],
                  ),
                  const Text(
                    'Partagez ce code avec vos amis',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            // Liste des joueurs
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Joueurs (${_currentSession.participants.length}/3)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _currentSession.participants.length,
                        itemBuilder: (context, index) {
                          final participant =
                              _currentSession.participants[index];
                          return _buildPlayerCard(participant);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Boutons d'action
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_currentSession.participants.length < 3) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _inviteFriend,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Inviter un ami'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFFFFD700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addGuestPlayer,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Ajouter un joueur invité'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_isHost) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _currentSession.canStart
                            ? _startSession
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          _currentSession.canStart
                              ? 'Démarrer la partie'
                              : 'En attente de joueurs...',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.hourglass_empty, color: Colors.orange),
                          SizedBox(height: 8),
                          Text(
                            'En attente de l\'hôte...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            'L\'hôte lancera la partie quand tous les joueurs seront prêts',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(MetDoubleParticipant participant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: participant.isHost
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
          child: Icon(
            participant.isGuest ? Icons.person_outline : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Text(
              participant.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (participant.isHost) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Hôte',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          participant.isGuest ? 'Joueur invité' : 'Joueur inscrit',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Icon(Icons.check_circle, color: Colors.green[400]),
      ),
    );
  }
}
