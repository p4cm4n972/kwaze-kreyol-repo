import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/supabase_service.dart';
import '../services/met_double_service.dart';
import '../models/met_double_game.dart';
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

    // Charger les sessions de l'utilisateur (si connecté)
    if (!_isGuest) {
      final userId = _authService.getUserIdOrNull();
      if (userId != null) {
        try {
          _sessions = await _metDoubleService.getUserSessions(userId);
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
    if (_isGuest) {
      // Les invités ne peuvent pas créer de sessions
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Les invités ne peuvent pas créer de sessions. Connectez-vous pour créer une session.'),
        ),
      );
      return;
    }

    final userId = _authService.getUserIdOrNull();
    if (userId == null) return;

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

    if (code != null && code.isNotEmpty) {
      // TODO: Implémenter la jonction par code
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fonctionnalité à venir')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mét Double'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          if (_displayName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Row(
                  children: [
                    Icon(
                      _isGuest ? Icons.person_outline : Icons.person,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _displayName!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _buildContent(),
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
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: _createNewSession,
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle session'),
            heroTag: 'create',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isGuest) {
      return _buildGuestView();
    }

    if (_sessions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (context, index) => _buildSessionCard(_sessions[index]),
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
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
