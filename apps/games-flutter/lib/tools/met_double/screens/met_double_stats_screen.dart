import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../services/met_double_service.dart';
import '../models/met_double_game.dart';

class MetDoubleStatsScreen extends StatefulWidget {
  const MetDoubleStatsScreen({super.key});

  @override
  State<MetDoubleStatsScreen> createState() => _MetDoubleStatsScreenState();
}

class _MetDoubleStatsScreenState extends State<MetDoubleStatsScreen>
    with SingleTickerProviderStateMixin {
  final MetDoubleService _metDoubleService = MetDoubleService();
  final AuthService _authService = AuthService();

  late TabController _tabController;

  List<CochonStats> _cochonsDonnes = [];
  List<CochonStats> _cochonsRecus = [];
  bool _isLoading = true;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    _isGuest = await _authService.isGuestMode();

    if (!_isGuest) {
      final userId = _authService.getUserIdOrNull();
      if (userId != null) {
        try {
          final donnes = await _metDoubleService.getCochonsDonnes(userId);
          final recus = await _metDoubleService.getCochonsRecus(userId);

          setState(() {
            _cochonsDonnes = donnes;
            _cochonsRecus = recus;
          });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques Cochons'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        bottom: _isGuest
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.trending_up),
                    text: 'Cochons donnés',
                  ),
                  Tab(
                    icon: Icon(Icons.trending_down),
                    text: 'Cochons reçus',
                  ),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isGuest
              ? _buildGuestView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCochonsDonnesList(),
                    _buildCochonsRecusList(),
                  ],
                ),
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
            const Text(
              'Fonctionnalité réservée aux utilisateurs inscrits',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Créez un compte pour accéder à vos statistiques de cochons',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCochonsDonnesList() {
    if (_cochonsDonnes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.sentiment_neutral,
        title: 'Aucun cochon donné',
        message:
            'Vous n\'avez pas encore mis de joueur cochon. Jouez et gagnez !',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Statistiques globales
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 48,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_cochonsDonnes.length}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'cochon${_cochonsDonnes.length > 1 ? 's' : ''} donné${_cochonsDonnes.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Liste des victimes
          const Text(
            'Vos victimes 😈',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ..._cochonsDonnes.map((stat) => _buildCochonCard(
                victimName: stat.victimName,
                sessionId: stat.sessionId,
                date: stat.completedAt,
                totalRounds: stat.totalRounds,
                isDonne: true,
              )),
        ],
      ),
    );
  }

  Widget _buildCochonsRecusList() {
    if (_cochonsRecus.isEmpty) {
      return _buildEmptyState(
        icon: Icons.sentiment_satisfied,
        title: 'Aucun cochon reçu',
        message: 'Bien joué ! Vous n\'avez jamais été mis cochon.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Statistiques globales
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.sentiment_dissatisfied,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_cochonsRecus.length}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'cochon${_cochonsRecus.length > 1 ? 's' : ''} reçu${_cochonsRecus.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Liste des bourreaux
          const Text(
            'Vos bourreaux 😢',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ..._cochonsRecus.map((stat) => _buildCochonCard(
                victimName: stat.victimName,
                sessionId: stat.sessionId,
                date: stat.completedAt,
                totalRounds: stat.totalRounds,
                isDonne: false,
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCochonCard({
    required String victimName,
    required String sessionId,
    required DateTime date,
    required int totalRounds,
    required bool isDonne,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDonne ? Colors.green : Colors.red,
          child: Text(
            victimName[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          victimName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$totalRounds manches jouées'),
            Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDonne
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '🐷',
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'Aujourd\'hui';
    }
  }
}
