import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/game_header.dart';
import '../services/met_double_service.dart';
import '../models/met_double_game.dart';
import '../../../screens/auth_screen.dart';
import 'met_double_lobby_screen.dart';

class MetDoubleHomeScreen extends StatefulWidget {
  const MetDoubleHomeScreen({super.key});

  @override
  State<MetDoubleHomeScreen> createState() => _MetDoubleHomeScreenState();
}

class _MetDoubleHomeScreenState extends State<MetDoubleHomeScreen> {
  final MetDoubleService _metDoubleService = MetDoubleService();
  final AuthService _authService = AuthService();

  List<MetDoubleSession> _sessions = [];
  List<MetDoubleInvitation> _pendingInvitations = [];
  bool _isLoading = true;
  bool _isGuest = false;
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Vérifier si en mode invité
    _isGuest = await _authService.isGuestMode();

    if (_isGuest) {
      _displayName = await _authService.getGuestName();
    } else {
      final user = await _authService.getCurrentUser();
      _displayName = user?.username ?? user?.email;
    }

    // Charger les sessions et invitations de l'utilisateur (si connecté)
    if (!_isGuest) {
      final userId = _authService.getUserIdOrNull();
      if (userId != null) {
        try {
          _sessions = await _metDoubleService.getUserSessions(userId);
          _pendingInvitations = await _metDoubleService.getPendingInvitations(userId);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: $e')),
            );
          }
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createNewSession() async {
    final userId = _authService.getUserIdOrNull();

    // Si pas connecté, rediriger vers l'écran de connexion
    if (userId == null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuthScreen(onSuccess: _loadData),
        ),
      );

      if (result == true) {
        // Réessayer après connexion
        _createNewSession();
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final session = await _metDoubleService.createSession(hostId: userId);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MetDoubleLobbyScreen(session: session),
          ),
        ).then((_) => _loadData());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      context.go('/'); // Retourner à l'écran d'accueil avec go_router
    }
  }

  Future<void> _joinSessionWithCode() async {
    final codeController = TextEditingController();

    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejoindre une session'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Code de session',
            hintText: 'Entrez le code à 6 chiffres',
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, codeController.text),
            child: const Text('Rejoindre'),
          ),
        ],
      ),
    );

    if (code == null || code.isEmpty || code.length != 6) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Récupérer l'ID utilisateur ou le nom d'invité
      final userId = _authService.getUserIdOrNull();
      String? guestName;

      if (userId == null) {
        guestName = await _authService.getGuestName();
      }

      // Rejoindre la session
      final session = await _metDoubleService.joinSessionWithCode(
        joinCode: code,
        userId: userId,
        guestName: guestName,
      );

      if (mounted) {
        // Naviguer vers le lobby de la session
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MetDoubleLobbyScreen(session: session),
          ),
        ).then((_) => _loadData());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteSession(MetDoubleSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la session'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer cette session ?\n\nSession ${session.id.substring(0, 8)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _metDoubleService.deleteSession(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session supprimée avec succès')),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptInvitation(MetDoubleInvitation invitation) async {
    setState(() => _isLoading = true);

    try {
      await _metDoubleService.acceptInvitation(invitation.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitation acceptée de ${invitation.inviterUsername ?? "l\'hôte"}')),
        );

        // Recharger les données pour obtenir la session mise à jour
        await _loadData();

        // Récupérer la session et y naviguer
        final session = await _metDoubleService.getSession(invitation.sessionId);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MetDoubleLobbyScreen(session: session),
            ),
          ).then((_) => _loadData());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _declineInvitation(MetDoubleInvitation invitation) async {
    setState(() => _isLoading = true);

    try {
      await _metDoubleService.declineInvitation(invitation.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitation refusée de ${invitation.inviterUsername ?? "l\'hôte"}')),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildUserMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: PopupMenuButton<String>(
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isGuest ? Icons.person_outline : Icons.person,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20, color: Colors.white),
          ],
        ),
        itemBuilder: (context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            enabled: false,
            value: 'profile',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _isGuest ? 'Invité' : 'Utilisateur',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout),
                SizedBox(width: 8),
                Text('Déconnexion'),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'logout') {
            _logout();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF9B59B6).withValues(alpha: 0.3), // Violet
              const Color(0xFF8E44AD).withValues(alpha: 0.3), // Violet foncé
              const Color(0xFF3498DB).withValues(alpha: 0.3), // Bleu
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header unifié
              GameHeader(
                title: 'Mét Double',
                emoji: '🎯',
                onBack: () => context.go('/home'),
                gradientColors: const [Color(0xFF9B59B6), Color(0xFF8E44AD)],
                actions: [
                  GameHeaderAction(
                    icon: Icons.bar_chart,
                    onPressed: () => context.push('/met-double/stats'),
                    tooltip: 'Statistiques',
                    iconColor: Colors.amber,
                  ),
                  if (_displayName != null)
                    _buildUserMenu(),
                ],
              ),
              // Contenu
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: _buildContent(),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _joinSessionWithCode,
            icon: const Icon(Icons.login),
            label: const Text('Rejoindre'),
            heroTag: 'join',
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: _createNewSession,
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle session'),
            heroTag: 'create',
            foregroundColor: Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isGuest) {
      return _buildGuestView();
    }

    if (_sessions.isEmpty && _pendingInvitations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Afficher les invitations en attente en premier
        if (_pendingInvitations.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.mail, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Invitations reçues (${_pendingInvitations.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          ..._pendingInvitations.map((invitation) => _buildInvitationCard(invitation)),
          const SizedBox(height: 24),
        ],

        // Afficher les sessions
        if (_sessions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.history),
                const SizedBox(width: 8),
                const Text(
                  'Mes sessions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ..._sessions.map((session) => _buildSessionCard(session)),
        ],
      ],
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Mode Invité',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Vous êtes connecté en tant qu\'invité ($_displayName)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            const Text(
              'En mode invité, vous pouvez rejoindre des sessions existantes mais vous ne pouvez pas en créer.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _joinSessionWithCode,
              icon: const Icon(Icons.login),
              label: const Text('Rejoindre une session'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.casino_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune session',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Créez une nouvelle session pour commencer à jouer',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(MetDoubleSession session) {
    final statusColor = _getStatusColor(session.status);
    final statusText = _getStatusText(session.status);
    final currentUserId = _authService.getUserIdOrNull();
    final isHost = currentUserId != null && currentUserId == session.hostId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MetDoubleLobbyScreen(session: session),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Session ${session.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (isHost) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: Colors.red,
                          onPressed: () => _deleteSession(session),
                          tooltip: 'Supprimer la session',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.people, size: 16),
                  const SizedBox(width: 4),
                  Text('${session.participants.length}/3 joueurs'),
                ],
              ),
              if (session.totalRounds > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.sports_esports, size: 16),
                    const SizedBox(width: 4),
                    Text('${session.totalRounds} manches jouées'),
                  ],
                ),
              ],
              if (session.winner != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('Gagnant: ${session.winner!.displayName}'),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _formatDate(session.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationCard(MetDoubleInvitation invitation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_add, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${invitation.inviterUsername ?? "Un joueur"} vous invite',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(invitation.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _declineInvitation(invitation),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Refuser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _acceptInvitation(invitation),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accepter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'waiting':
        return Colors.orange;
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'waiting':
        return 'En attente';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}
