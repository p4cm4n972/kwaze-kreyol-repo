import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';
import '../services/domino_service.dart';
import '../models/domino_session.dart';

/// Écran d'accueil pour le jeu de dominos
class DominoHomeScreen extends StatefulWidget {
  const DominoHomeScreen({super.key});

  @override
  State<DominoHomeScreen> createState() => _DominoHomeScreenState();
}

class _DominoHomeScreenState extends State<DominoHomeScreen>
    with SingleTickerProviderStateMixin {
  final DominoService _dominoService = DominoService();
  final AuthService _authService = AuthService();
  final TextEditingController _joinCodeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  List<DominoSession> _activeSessions = [];
  bool _loadingSessions = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _loadActiveSessions();
  }

  Future<void> _loadActiveSessions() async {
    final userId = _authService.getUserIdOrNull();
    if (userId == null) {
      setState(() {
        _loadingSessions = false;
      });
      return;
    }

    try {
      final sessions = await _dominoService.getUserSessions(userId);
      // Filtrer seulement les sessions en attente ou en cours
      final active = sessions.where((s) =>
        s.status == 'waiting' || s.status == 'in_progress'
      ).toList();

      if (mounted) {
        setState(() {
          _activeSessions = active;
          _loadingSessions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSessions = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) {
        throw Exception('Vous devez être connecté');
      }

      final session = await _dominoService.createSession(hostId: userId);

      if (mounted) {
        context.go('/domino/lobby/${session.id}');
      }
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

  Future<void> _joinWithCode() async {
    final code = _joinCodeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Entrez un code de partie';
      });
      return;
    }

    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Le code doit contenir 6 chiffres';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.getUserIdOrNull();

      final session = await _dominoService.joinSessionWithCode(
        joinCode: code,
        userId: userId,
      );

      if (mounted) {
        context.go('/domino/lobby/${session.id}');
      }
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
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : _buildContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => context.go('/'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700),
                    const Color(0xFFFF8C00),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8C00).withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                '🎲 Dominos',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 1,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade900.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Parties en cours
          if (_activeSessions.isNotEmpty) ...[
            _buildActiveSessionsSection(),
            const SizedBox(height: 24),
          ],

          // Carte: Créer une partie
          _buildActionCard(
            title: 'Créer une partie',
            icon: Icons.add_circle,
            iconColor: const Color(0xFF4CAF50),
            gradientColors: [
              const Color(0xFF4CAF50),
              const Color(0xFF81C784),
            ],
            onTap: _createSession,
            child: const Text(
              'Créez une nouvelle partie et invitez vos amis à vous rejoindre avec un code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          // Carte: Rejoindre avec code
          _buildActionCard(
            title: 'Rejoindre une partie',
            icon: Icons.group_add,
            iconColor: const Color(0xFF2196F3),
            gradientColors: [
              const Color(0xFF2196F3),
              const Color(0xFF64B5F6),
            ],
            child: Column(
              children: [
                const Text(
                  'Entrez le code de la partie:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _joinCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 12,
                      color: Color(0xFF2196F3),
                    ),
                    decoration: InputDecoration(
                      hintText: '000000',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade300,
                        letterSpacing: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _joinWithCode,
                  icon: const Icon(Icons.check_circle, size: 24),
                  label: const Text(
                    'Rejoindre',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Règles du jeu
          _buildRulesCard(),
        ],
      ),
    );
  }

  Widget _buildActiveSessionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_filled,
                color: const Color(0xFF4CAF50),
                size: 32,
              ),
              const SizedBox(width: 12),
              const Text(
                'Parties en cours',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._activeSessions.map((session) {
            final isWaiting = session.status == 'waiting';
            final participantCount = session.participants.length;
            final isHost = session.hostId == _authService.getUserIdOrNull();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isWaiting
                      ? [const Color(0xFFFF8C00), const Color(0xFFFFD700)]
                      : [const Color(0xFF4CAF50), const Color(0xFF81C784)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: (isWaiting ? const Color(0xFFFF8C00) : const Color(0xFF4CAF50))
                        .withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            if (isWaiting) {
                              context.go('/domino/lobby/${session.id}');
                            } else {
                              context.go('/domino/game/${session.id}');
                            }
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isWaiting ? 'En attente de joueurs' : 'Partie en cours',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$participantCount/3 joueurs',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (session.joinCode != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Code: ${session.joinCode}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                isWaiting ? Icons.hourglass_empty : Icons.sports_esports,
                                color: Colors.white,
                                size: 32,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isHost)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                            onPressed: () async {
                            // Confirmation avant suppression
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Annuler la partie ?'),
                                content: const Text(
                                  'Êtes-vous sûr de vouloir annuler cette partie ?'
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Non'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Oui', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _dominoService.cancelSession(session.id);
                              _loadActiveSessions(); // Recharger la liste
                            }
                          },
                          tooltip: 'Annuler la partie',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: iconColor, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade400,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Règles du jeu',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRuleItem('👥', '3 joueurs'),
          _buildRuleItem('🎯', '7 tuiles par joueur'),
          _buildRuleItem('🚫', 'Pas de pioche'),
          _buildRuleItem('🏆', 'Premier à 3 manches gagne'),
          _buildRuleItem('🐷', '0 manche = Cochon!'),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
