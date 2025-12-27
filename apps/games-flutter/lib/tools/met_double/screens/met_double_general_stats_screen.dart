import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../services/met_double_service.dart';

class MetDoubleGeneralStatsScreen extends StatefulWidget {
  const MetDoubleGeneralStatsScreen({super.key});

  @override
  State<MetDoubleGeneralStatsScreen> createState() => _MetDoubleGeneralStatsScreenState();
}

class _MetDoubleGeneralStatsScreenState extends State<MetDoubleGeneralStatsScreen>
    with SingleTickerProviderStateMixin {
  final MetDoubleService _metDoubleService = MetDoubleService();
  final AuthService _authService = AuthService();

  late TabController _tabController;
  bool _isLoading = true;

  // Statistiques personnelles
  int _nombreManches = 0;
  int _nombrePartenaires = 0;

  // Statistiques générales (globales)
  int _totalParties = 0;
  int _totalManches = 0;
  int _totalAbonnes = 0;

  // Classements
  List<Map<String, dynamic>> _topJoueurs = [];
  List<Map<String, dynamic>> _topMetDouble = [];
  List<Map<String, dynamic>> _topMetCochon = [];

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
    setState(() => _isLoading = true);

    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Charger les statistiques personnelles et générales
      final stats = await _metDoubleService.getPlayerGeneralStats(userId);

      setState(() {
        // Statistiques personnelles
        _nombreManches = stats['nombreManches'] ?? 0;
        _nombrePartenaires = stats['nombrePartenaires'] ?? 0;

        // Statistiques globales
        _totalParties = stats['totalParties'] ?? 0;
        _totalManches = stats['totalManches'] ?? 0;
        _totalAbonnes = stats['totalAbonnes'] ?? 0;

        // Classements
        _topJoueurs = List<Map<String, dynamic>>.from(stats['topJoueurs'] ?? []);
        _topMetDouble = List<Map<String, dynamic>>.from(stats['topMetDouble'] ?? []);
        _topMetCochon = List<Map<String, dynamic>>.from(stats['topMetCochon'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.public),
              text: 'Général',
            ),
            Tab(
              icon: Icon(Icons.person),
              text: 'Personnel',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralView(),
                _buildPersonalView(),
              ],
            ),
    );
  }

  // Vue générale (tous les joueurs)
  Widget _buildGeneralView() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistiques globales
            const Text(
              'Statistiques globales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people,
                    title: 'Abonnés',
                    value: '$_totalAbonnes',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.casino,
                    title: 'Parties',
                    value: '$_totalParties',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.sports_esports,
                    title: 'Manches',
                    value: '$_totalManches',
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Top joueurs
            const Text(
              'Meilleurs joueurs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Classement par nombre de victoires',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            if (_topJoueurs.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucune donnée disponible'),
                ),
              )
            else
              ..._topJoueurs.asMap().entries.map((entry) {
                final index = entry.key;
                final joueur = entry.value;
                return _buildPlayerRankingCard(
                  rank: index + 1,
                  name: joueur['name'] as String,
                  victories: joueur['victories'] as int,
                  isTop: index < 3,
                );
              }),

            const SizedBox(height: 32),

            // Top met double
            const Text(
              'Meilleurs met double',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Joueurs qui donnent le plus de cochons',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            if (_topMetDouble.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucune donnée disponible'),
                ),
              )
            else
              ..._topMetDouble.asMap().entries.map((entry) {
                final index = entry.key;
                final joueur = entry.value;
                return _buildCochonRankingCard(
                  rank: index + 1,
                  name: joueur['name'] as String,
                  cochons: joueur['cochons'] as int,
                  isTop: index < 3,
                  color: Colors.green,
                );
              }),

            const SizedBox(height: 32),

            // Top met cochon
            const Text(
              'Meilleurs met cochon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Joueurs qui reçoivent le plus de cochons',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            if (_topMetCochon.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucune donnée disponible'),
                ),
              )
            else
              ..._topMetCochon.asMap().entries.map((entry) {
                final index = entry.key;
                final joueur = entry.value;
                return _buildCochonRankingCard(
                  rank: index + 1,
                  name: joueur['name'] as String,
                  cochons: joueur['cochons'] as int,
                  isTop: index < 3,
                  color: Colors.pink,
                );
              }),
          ],
        ),
      ),
    );
  }

  // Vue personnelle
  Widget _buildPersonalView() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes statistiques',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people,
                    title: 'Partenaires',
                    value: '$_nombrePartenaires',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.sports_esports,
                    title: 'Manches jouées',
                    value: '$_nombreManches',
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Mes performances',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Consultez l\'onglet "Général" pour voir votre classement parmi tous les joueurs',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRankingCard({
    required int rank,
    required String name,
    required int victories,
    required bool isTop,
  }) {
    Color? cardColor;
    IconData? medalIcon;

    if (isTop) {
      switch (rank) {
        case 1:
          cardColor = Colors.amber.shade100;
          medalIcon = Icons.emoji_events;
          break;
        case 2:
          cardColor = Colors.grey.shade300;
          medalIcon = Icons.military_tech;
          break;
        case 3:
          cardColor = Colors.orange.shade100;
          medalIcon = Icons.stars;
          break;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$rank',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (medalIcon != null) ...[
              const SizedBox(width: 8),
              Icon(
                medalIcon,
                color: rank == 1 ? Colors.amber : Colors.grey[700],
                size: 24,
              ),
            ],
          ],
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$victories',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 4),
              const Text('🏆', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCochonRankingCard({
    required int rank,
    required String name,
    required int cochons,
    required bool isTop,
    required Color color,
  }) {
    Color? cardColor;

    if (isTop) {
      switch (rank) {
        case 1:
          cardColor = color.withOpacity(0.3);
          break;
        case 2:
          cardColor = color.withOpacity(0.15);
          break;
        case 3:
          cardColor = color.withOpacity(0.15);
          break;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      child: ListTile(
        leading: Text(
          '$rank',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$cochons',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              const Text('🐷', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
