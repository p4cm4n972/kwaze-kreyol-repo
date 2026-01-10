import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';
import '../../../models/admin_stats.dart';
import '../widgets/stat_card.dart';
import '../widgets/line_chart_widget.dart';
import '../widgets/top_players_list.dart';

/// Onglet des statistiques du jeu Skrabb
class SkrabbTab extends StatefulWidget {
  const SkrabbTab({super.key});

  @override
  State<SkrabbTab> createState() => _SkrabbTabState();
}

class _SkrabbTabState extends State<SkrabbTab> {
  final AdminService _adminService = AdminService();

  AdminGameStats? _stats;
  List<TimeSeriesDataPoint>? _gamesOverTime;
  List<TopPlayerEntry>? _topPlayers;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _adminService.getSkrabbStats(),
        _adminService.getSkrabbOverTime(daysBack: 30),
        _adminService.getTopSkrabbPlayers(limit: 10),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as AdminGameStats;
          _gamesOverTime = results[1] as List<TimeSeriesDataPoint>;
          _topPlayers = results[2] as List<TopPlayerEntry>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${minutes}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec icône
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.grid_on, color: Colors.blue, size: 32),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Statistiques Skrabb',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Cartes principales
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    StatCard(
                      title: 'Total parties',
                      value: '${_stats?.totalGames ?? 0}',
                      icon: Icons.sports_esports,
                      color: Colors.blue,
                    ),
                    StatCard(
                      title: 'Score moyen',
                      value: '${(_stats?.avgScore ?? 0).toStringAsFixed(0)}',
                      icon: Icons.score,
                      color: Colors.green,
                    ),
                    StatCard(
                      title: 'Meilleur score',
                      value: '${_stats?.highestScore ?? 0}',
                      icon: Icons.emoji_events,
                      color: Colors.amber,
                    ),
                    StatCard(
                      title: 'Temps moyen',
                      value: _formatTime(_stats?.avgTimeSeconds ?? 0),
                      icon: Icons.timer,
                      color: Colors.orange,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Activité récente
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 1;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.5,
                  children: [
                    StatCardCompact(
                      title: 'Aujourd\'hui',
                      value: '${_stats?.gamesToday ?? 0}',
                      icon: Icons.today,
                      color: Colors.green,
                    ),
                    StatCardCompact(
                      title: 'Cette semaine',
                      value: '${_stats?.gamesThisWeek ?? 0}',
                      icon: Icons.date_range,
                      color: Colors.blue,
                    ),
                    StatCardCompact(
                      title: 'Ce mois',
                      value: '${_stats?.gamesThisMonth ?? 0}',
                      icon: Icons.calendar_month,
                      color: Colors.purple,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Statut des parties
            const Text(
              'État des parties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_stats != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatusRow('En cours', _stats!.byStatus['in_progress'] ?? 0, Colors.blue),
                      _buildStatusRow('Terminées', _stats!.byStatus['completed'] ?? 0, Colors.green),
                      _buildStatusRow('Abandonnées', _stats!.byStatus['abandoned'] ?? 0, Colors.red),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Graphique des parties
            if (_gamesOverTime != null)
              LineChartWidget(
                title: 'Parties jouées (30 derniers jours)',
                data: _gamesOverTime!,
                lineColor: Colors.blue,
              ),

            const SizedBox(height: 24),

            // Top joueurs
            if (_topPlayers != null)
              TopPlayersList(
                title: 'Top 10 Joueurs Skrabb',
                players: _topPlayers!,
                scoreLabel: 'Score total',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    final total = _stats?.totalGames ?? 1;
    final percentage = total > 0 ? (count / total * 100) : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              '(${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
