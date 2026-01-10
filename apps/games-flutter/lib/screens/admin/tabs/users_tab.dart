import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';
import '../../../services/presence_service.dart';
import '../../../models/admin_stats.dart';
import '../widgets/stat_card.dart';
import '../widgets/line_chart_widget.dart';

/// Onglet des statistiques utilisateurs
class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final AdminService _adminService = AdminService();
  final PresenceService _presenceService = PresenceService();

  AdminUserStats? _userStats;
  List<TimeSeriesDataPoint>? _usersOverTime;
  AdminActiveUsers? _activeUsers;
  int _connectedCount = 0;
  int _visitorCount = 0;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<PresenceStats>? _presenceSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToPresence();
  }

  @override
  void dispose() {
    _presenceSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToPresence() {
    // S'abonner aux changements de présence
    _presenceSubscription = _presenceService.presenceStatsStream.listen((stats) {
      if (mounted) {
        setState(() {
          _connectedCount = stats.connectedCount;
          _visitorCount = stats.visitorCount;
        });
      }
    });
    // Initialiser avec les valeurs actuelles
    final currentStats = _presenceService.currentStats;
    _connectedCount = currentStats.connectedCount;
    _visitorCount = currentStats.visitorCount;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _adminService.getUserStats(),
        _adminService.getUsersOverTime(daysBack: 30),
        _adminService.getActiveUsers(days: 7),
      ]);

      if (mounted) {
        setState(() {
          _userStats = results[0] as AdminUserStats;
          _usersOverTime = results[1] as List<TimeSeriesDataPoint>;
          _activeUsers = results[2] as AdminActiveUsers;
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
            // Titre de section
            const Text(
              'Vue d\'ensemble',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Cartes principales
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1200 ? 6 : (constraints.maxWidth > 800 ? 4 : 2);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    StatCard(
                      title: 'Total utilisateurs',
                      value: '${_userStats?.totalUsers ?? 0}',
                      icon: Icons.people,
                      color: const Color(0xFFE67E22),
                    ),
                    StatCard(
                      title: 'Connectés',
                      value: '$_connectedCount',
                      icon: Icons.person,
                      color: Colors.green,
                      subtitle: 'utilisateurs en ligne',
                      isLive: true,
                    ),
                    StatCard(
                      title: 'Visiteurs',
                      value: '$_visitorCount',
                      icon: Icons.visibility,
                      color: Colors.teal,
                      subtitle: 'anonymes en ligne',
                      isLive: true,
                    ),
                    StatCard(
                      title: 'Aujourd\'hui',
                      value: '+${_userStats?.newUsersToday ?? 0}',
                      icon: Icons.person_add,
                      color: Colors.blue,
                      subtitle: 'nouvelles inscriptions',
                    ),
                    StatCard(
                      title: 'Cette semaine',
                      value: '+${_userStats?.newUsersThisWeek ?? 0}',
                      icon: Icons.trending_up,
                      color: Colors.indigo,
                    ),
                    StatCard(
                      title: 'Ce mois',
                      value: '+${_userStats?.newUsersThisMonth ?? 0}',
                      icon: Icons.calendar_month,
                      color: Colors.purple,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Graphique des inscriptions
            if (_usersOverTime != null)
              LineChartWidget(
                title: 'Inscriptions (30 derniers jours)',
                data: _usersOverTime!,
                lineColor: const Color(0xFFE67E22),
              ),

            const SizedBox(height: 24),

            // Répartition par rôle
            const Text(
              'Répartition par rôle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_userStats != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildRoleRow('Utilisateurs', _userStats!.usersByRole['user'] ?? 0, Colors.blue),
                      _buildRoleRow('Contributeurs', _userStats!.usersByRole['contributor'] ?? 0, Colors.green),
                      _buildRoleRow('Administrateurs', _userStats!.usersByRole['admin'] ?? 0, Colors.orange),
                      _buildRoleRow('En attente', _userStats!.usersByRole['register'] ?? 0, Colors.grey),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Utilisateurs actifs
            const Text(
              'Utilisateurs actifs (7 derniers jours)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_activeUsers != null)
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2,
                    children: [
                      StatCardCompact(
                        title: 'Total actifs',
                        value: '${_activeUsers!.totalActive}',
                        icon: Icons.people,
                        color: const Color(0xFFE67E22),
                      ),
                      StatCardCompact(
                        title: 'Domino',
                        value: '${_activeUsers!.dominoActive}',
                        icon: Icons.casino,
                        color: Colors.purple,
                      ),
                      StatCardCompact(
                        title: 'Skrabb',
                        value: '${_activeUsers!.skrabbActive}',
                        icon: Icons.grid_on,
                        color: Colors.blue,
                      ),
                      StatCardCompact(
                        title: 'Mots Mawon',
                        value: '${_activeUsers!.motsMawonActive}',
                        icon: Icons.search,
                        color: Colors.green,
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleRow(String label, int count, Color color) {
    final total = _userStats?.totalUsers ?? 1;
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
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
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
