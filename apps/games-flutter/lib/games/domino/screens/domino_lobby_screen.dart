import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';
import '../../../services/realtime_service.dart';
import '../services/domino_service.dart';
import '../models/domino_session.dart';
import '../models/domino_participant.dart';

/// Écran de lobby pour le jeu de dominos
/// Attend 3 joueurs avant de pouvoir démarrer la partie
class DominoLobbyScreen extends StatefulWidget {
  final String sessionId;

  const DominoLobbyScreen({
    super.key,
    required this.sessionId,
  });

  @override
  State<DominoLobbyScreen> createState() => _DominoLobbyScreenState();
}

class _DominoLobbyScreenState extends State<DominoLobbyScreen> {
  final DominoService _dominoService = DominoService();
  final RealtimeService _realtimeService = RealtimeService();
  final AuthService _authService = AuthService();
  final TextEditingController _guestNameController = TextEditingController();

  DominoSession? _session;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isHost = false;

  @override
  void initState() {
    super.initState();
    _subscribeToSession();
  }

  @override
  void dispose() {
    _realtimeService.unsubscribeFromDominoSession(widget.sessionId);
    _guestNameController.dispose();
    super.dispose();
  }

  void _subscribeToSession() {
    _realtimeService.subscribeToDominoSession(widget.sessionId).listen(
      (session) {
        setState(() {
          _session = session;
          _isHost = session.hostId == _authService.getUserIdOrNull();
        });

        // Auto-navigation vers le jeu si la partie a démarré
        if (session.status == 'in_progress' && mounted) {
          context.go('/domino/game/${widget.sessionId}');
        }
      },
      onError: (error) {
        setState(() {
          _errorMessage = error.toString();
        });
      },
    );
  }

  Future<void> _startSession() async {
    if (_session == null || !_session!.canStart) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _dominoService.startSession(widget.sessionId);
      // La navigation se fera automatiquement via le stream
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addGuest() async {
    final guestName = await showDialog<String>(
      context: context,
      builder: (context) => _buildGuestDialog(),
    );

    if (guestName == null || guestName.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _dominoService.joinSessionAsGuest(
        sessionId: widget.sessionId,
        guestName: guestName.trim(),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la partie?'),
        content: const Text('Êtes-vous sûr de vouloir annuler cette partie?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _dominoService.cancelSession(widget.sessionId);
      if (mounted) {
        context.go('/domino');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _copyJoinCode() {
    if (_session?.joinCode != null) {
      Clipboard.setData(ClipboardData(text: _session!.joinCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copié dans le presse-papier'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
              const Color(0xFFFF6B6B),
              const Color(0xFFFFB347),
              const Color(0xFFFFD93D),
              const Color(0xFFFF8C94),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _session == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _isHost ? _cancelSession : () => context.go('/domino'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700),
                    const Color(0xFFFF8C00),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Salle d\'attente',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final session = _session!;
    final playerCount = session.participants.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],

          // Code de session (pour inviter)
          if (session.joinCode != null) ...[
            _buildCard(
              title: 'Code de la partie',
              icon: Icons.qr_code,
              iconColor: Colors.green,
              children: [
                const Text(
                  'Partagez ce code pour inviter d\'autres joueurs:',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _copyJoinCode,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          session.joinCode!,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.copy,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Touchez pour copier',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Compteur de joueurs
          _buildCard(
            title: 'Joueurs ($playerCount/3)',
            icon: Icons.group,
            iconColor: playerCount == 3 ? Colors.green : Colors.orange,
            children: [
              ...session.participants.map((participant) {
                return _buildPlayerTile(participant);
              }),
              if (playerCount < 3) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'En attente de ${3 - playerCount} joueur${3 - playerCount > 1 ? 's' : ''}...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Actions pour l'hôte
          if (_isHost) ...[
            if (playerCount < 3) ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _addGuest,
                icon: const Icon(Icons.person_add),
                label: const Text('Ajouter un invité'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              onPressed: (_isLoading || !session.canStart) ? null : _startSession,
              icon: const Icon(Icons.play_arrow),
              label: Text(
                session.canStart ? 'Démarrer la partie' : 'En attente de 3 joueurs',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: session.canStart ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],

          // Info pour les joueurs non-hôtes
          if (!_isHost) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white70),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      playerCount < 3
                          ? 'En attente de joueurs...'
                          : 'En attente du démarrage par l\'hôte...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPlayerTile(DominoParticipant participant) {
    final isCurrentUser = participant.userId == _authService.getUserIdOrNull();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Colors.blue.withOpacity(0.3)
            : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentUser
              ? Colors.blue.withOpacity(0.5)
              : Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: participant.isHost
                ? Colors.amber
                : Colors.grey.withOpacity(0.5),
            child: Text(
              participant.displayName[0].toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      participant.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      const Text(
                        '(Vous)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
                if (participant.isHost)
                  const Text(
                    'Hôte',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (participant.isHost)
            const Icon(
              Icons.star,
              color: Colors.amber,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildGuestDialog() {
    return AlertDialog(
      title: const Text('Ajouter un invité'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Entrez le nom de l\'invité:'),
          const SizedBox(height: 12),
          TextField(
            controller: _guestNameController,
            decoration: const InputDecoration(
              hintText: 'Nom de l\'invité',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.pop(context, value.trim());
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            final name = _guestNameController.text.trim();
            if (name.isNotEmpty) {
              Navigator.pop(context, name);
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
