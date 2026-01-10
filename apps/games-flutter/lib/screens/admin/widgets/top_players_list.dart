import 'package:flutter/material.dart';
import '../../../models/admin_stats.dart';

/// Widget pour afficher la liste des meilleurs joueurs
class TopPlayersList extends StatelessWidget {
  final String title;
  final List<TopPlayerEntry> players;
  final String scoreLabel;
  final bool showWinRate;

  const TopPlayersList({
    super.key,
    required this.title,
    required this.players,
    this.scoreLabel = 'Score',
    this.showWinRate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Color(0xFFE67E22)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (players.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Aucun joueur',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: players.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final player = players[index];
                  final rank = index + 1;

                  return ListTile(
                    leading: _buildRankBadge(rank),
                    title: Text(
                      player.username,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${player.gamesPlayed} parties',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${player.totalScore}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFE67E22),
                          ),
                        ),
                        if (showWinRate && player.winRate != null)
                          Text(
                            '${player.winRate!.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          )
                        else
                          Text(
                            'moy: ${player.avgScore.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    IconData? icon;

    switch (rank) {
      case 1:
        badgeColor = const Color(0xFFFFD700); // Or
        icon = Icons.looks_one;
        break;
      case 2:
        badgeColor = const Color(0xFFC0C0C0); // Argent
        icon = Icons.looks_two;
        break;
      case 3:
        badgeColor = const Color(0xFFCD7F32); // Bronze
        icon = Icons.looks_3;
        break;
      default:
        badgeColor = Colors.grey.shade400;
        icon = null;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: badgeColor, width: 2),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: badgeColor, size: 20)
            : Text(
                '$rank',
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
