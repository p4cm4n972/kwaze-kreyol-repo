import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/game_header.dart';
import '../services/skrabb_service.dart';

/// Écran d'accueil du jeu Skrabb
class SkrabbHomeScreen extends StatefulWidget {
  const SkrabbHomeScreen({super.key});

  @override
  State<SkrabbHomeScreen> createState() => _SkrabbHomeScreenState();
}

class _SkrabbHomeScreenState extends State<SkrabbHomeScreen> {
  final AuthService _authService = AuthService();
  final SkrabbService _skrabbService = SkrabbService();

  bool _isLoading = true;
  bool _hasInProgressGame = false;
  String? _inProgressGameId;
  int? _inProgressScore;
  int? _inProgressTime;

  @override
  void initState() {
    super.initState();
    _checkForInProgressGame();
  }

  Future<void> _checkForInProgressGame() async {
    setState(() => _isLoading = true);

    final userId = _authService.getUserIdOrNull();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final game = await _skrabbService.loadInProgressGame();
      if (game != null && mounted) {
        setState(() {
          _hasInProgressGame = true;
          _inProgressGameId = game.id;
          _inProgressScore = game.score;
          _inProgressTime = game.timeElapsed;
        });
      } else if (mounted) {
        setState(() {
          _hasInProgressGame = false;
          _inProgressGameId = null;
          _inProgressScore = null;
          _inProgressTime = null;
        });
      }
    } catch (e) {
      debugPrint('Erreur vérification partie en cours: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// Supprime la partie en cours après confirmation
  Future<void> _deleteInProgressGame() async {
    if (_inProgressGameId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la partie ?'),
        content: const Text(
          'Cette action est irréversible. '
          'Votre progression sera définitivement perdue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _skrabbService.deleteGame(_inProgressGameId!);
      if (mounted) {
        setState(() {
          _hasInProgressGame = false;
          _inProgressGameId = null;
          _inProgressScore = null;
          _inProgressTime = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partie supprimée'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFE74C3C),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFD700), // Or
              Color(0xFFFF8C00), // Orange
              Color(0xFFE74C3C), // Rouge
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              GameHeader(
                title: 'Skrabb',
                iconPath: 'assets/icons/skrabb.png',
                onBack: () => context.go('/home'),
                gradientColors: const [Color(0xFFFFD700), Color(0xFFFF8C00)],
                actions: [
                  GameHeaderAction(
                    icon: Icons.leaderboard,
                    onPressed: () => context.go('/skrabb/leaderboard'),
                    tooltip: 'Classement',
                    iconColor: Colors.amber,
                  ),
                  GameHeaderAction(
                    icon: Icons.help_outline,
                    onPressed: () => context.go('/skrabb/help'),
                    tooltip: 'Aide',
                  ),
                ],
              ),

              // Contenu
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // Description du jeu
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Scrabble en créole martiniquais !',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Forme des mots en créole sur le plateau et marque des points. '
                                    'Utilise les cases bonus pour maximiser ton score !',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Bouton reprendre (si partie en cours)
                            if (_hasInProgressGame) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildActionButton(
                                      icon: Icons.play_arrow,
                                      label: 'Reprendre la partie',
                                      subtitle: _inProgressScore != null
                                          ? '${_inProgressScore} pts • ${_formatTime(_inProgressTime ?? 0)}'
                                          : null,
                                      color: const Color(0xFF27AE60),
                                      onTap: () => context.go('/skrabb/game'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Bouton supprimer
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _deleteInProgressGame,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE74C3C),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFE74C3C).withValues(alpha: 0.4),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Bouton nouvelle partie
                            _buildActionButton(
                              icon: Icons.add,
                              label: _hasInProgressGame
                                  ? 'Nouvelle partie'
                                  : 'Commencer une partie',
                              color: const Color(0xFF3498DB),
                              onTap: () async {
                                if (_hasInProgressGame) {
                                  // Demander confirmation
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Nouvelle partie ?'),
                                      content: const Text(
                                        'Vous avez une partie en cours. '
                                        'Voulez-vous l\'abandonner et en commencer une nouvelle ?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Annuler'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFE74C3C),
                                          ),
                                          child: const Text('Nouvelle partie'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true && mounted) {
                                    context.go('/skrabb/game?new=true');
                                  }
                                } else {
                                  context.go('/skrabb/game');
                                }
                              },
                            ),

                            const SizedBox(height: 16),

                            // Bouton classement
                            _buildActionButton(
                              icon: Icons.leaderboard,
                              label: 'Classement',
                              color: const Color(0xFFF39C12),
                              onTap: () => context.go('/skrabb/leaderboard'),
                            ),

                            const SizedBox(height: 16),

                            // Bouton aide
                            _buildActionButton(
                              icon: Icons.help_outline,
                              label: 'Comment jouer ?',
                              color: const Color(0xFF9B59B6),
                              onTap: () => context.go('/skrabb/help'),
                            ),

                            const SizedBox(height: 30),

                            // Légende des cases bonus
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Cases bonus',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      _buildBonusLegend(
                                        'MT',
                                        'Mot Triple',
                                        const Color(0xFFE74C3C),
                                      ),
                                      _buildBonusLegend(
                                        'MD',
                                        'Mot Double',
                                        const Color(0xFFFF9999),
                                      ),
                                      _buildBonusLegend(
                                        'LT',
                                        'Lettre Triple',
                                        const Color(0xFF3498DB),
                                      ),
                                      _buildBonusLegend(
                                        'LD',
                                        'Lettre Double',
                                        const Color(0xFF85C1E9),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.7),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBonusLegend(String code, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
