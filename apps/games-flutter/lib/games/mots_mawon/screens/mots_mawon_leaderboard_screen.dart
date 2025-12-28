import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/mots_mawon_game.dart';
import '../services/mots_mawon_service.dart';

class MotsMawonLeaderboardScreen extends StatefulWidget {
  const MotsMawonLeaderboardScreen({super.key});

  @override
  State<MotsMawonLeaderboardScreen> createState() =>
      _MotsMawonLeaderboardScreenState();
}

class _MotsMawonLeaderboardScreenState
    extends State<MotsMawonLeaderboardScreen> {
  final MotsMawonService _service = MotsMawonService();

  bool _isLoading = true;
  MotsMawonPlayerStats? _playerStats;
  List<MotsMawonLeaderboardEntry> _leaderboard = [];
  String? _error;
  int? _playerRank;

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
      final stats = await _service.getPlayerStats();
      final leaderboard = await _service.getLeaderboard(limit: 100);
      final rank = await _service.getPlayerRank();

      setState(() {
        _playerStats = stats;
        _leaderboard = leaderboard;
        _playerRank = rank;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/mots-mawon'),
        ),
        title: const Text('Classement'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_playerStats != null) _buildPlayerStatsCard(),
        const SizedBox(height: 24),
        _buildLeaderboardSection(),
      ],
    );
  }

  Widget _buildPlayerStatsCard() {
    final stats = _playerStats!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mes Statistiques',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_playerRank != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRankColor(_playerRank!),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        if (_playerRank! <= 3)
                          Text(
                            _getRankBadge(_playerRank!),
                            style: const TextStyle(fontSize: 16),
                          ),
                        const SizedBox(width: 4),
                        Text(
                          'Rang #$_playerRank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Parties jouées',
                    stats.completedGames.toString(),
                    Icons.games,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Meilleur score',
                    stats.bestScore.toString(),
                    Icons.stars,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Score moyen',
                    stats.averageScore.toStringAsFixed(0),
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Meilleur temps',
                    stats.formattedBestTime,
                    Icons.timer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Mots trouvés',
                    stats.totalWordsFound.toString(),
                    Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Temps total',
                    stats.formattedTotalTime,
                    Icons.schedule,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLeaderboardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Classement Global',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (_leaderboard.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Aucune partie terminée pour le moment'),
            ),
          )
        else
          ..._leaderboard.map((entry) => _buildLeaderboardItem(entry)),
      ],
    );
  }

  Widget _buildLeaderboardItem(MotsMawonLeaderboardEntry entry) {
    final isTopThree = entry.rank <= 3;
    final badge = entry.badge;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isTopThree ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isTopThree
            ? BorderSide(color: _getRankColor(entry.rank), width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: SizedBox(
          width: 50,
          child: Row(
            children: [
              if (badge != null)
                Text(
                  badge,
                  style: const TextStyle(fontSize: 24),
                )
              else
                Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        isTopThree ? FontWeight.bold : FontWeight.normal,
                    color: isTopThree
                        ? _getRankColor(entry.rank)
                        : Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          entry.username,
          style: TextStyle(
            fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          'Temps: ${entry.formattedTime}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${entry.score}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isTopThree
                        ? _getRankColor(entry.rank)
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Or
      case 2:
        return Colors.grey; // Argent
      case 3:
        return Colors.brown; // Bronze
      default:
        return Colors.blue;
    }
  }

  String _getRankBadge(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }
}
