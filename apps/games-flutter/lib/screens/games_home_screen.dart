import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GamesHomeScreen extends StatelessWidget {
  const GamesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final games = [
      {
        'id': 'mots-mawon',
        'name': 'Mots Mawon',
        'description': 'Jeu de mots cachés en créole martiniquais',
        'icon': Icons.grid_on,
        'color': Colors.amber,
        'available': true,
      },
      {
        'id': 'skrabb',
        'name': 'Skrabb',
        'description': 'Scrabble créole ! Forme des mots et marque des points',
        'icon': Icons.grid_4x4,
        'color': Colors.green,
        'available': false,
      },
      {
        'id': 'endorlisseur',
        'name': 'Endorlisseur',
        'description': 'Jeu de stratégie créole',
        'icon': Icons.casino,
        'color': Colors.orange,
        'available': false,
      },
      {
        'id': 'double-siz',
        'name': 'Double Siz',
        'description': 'Dominos martiniquais',
        'icon': Icons.view_module,
        'color': Colors.blue,
        'available': false,
      },
      {
        'id': 'koze-kwaze',
        'name': 'Kozé Kwazé',
        'description': 'Quiz sur la culture créole',
        'icon': Icons.quiz,
        'color': Colors.purple,
        'available': false,
      },
      {
        'id': 'met-double',
        'name': 'Mét Double',
        'description': 'Jeu de cartes traditionnel',
        'icon': Icons.style,
        'color': Colors.red,
        'available': false,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kwazé Kréyol Games'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.sports_esports,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Jeux 100% Créole',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Découvre nos jeux en créole martiniquais',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Games Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 800
                        ? 3
                        : constraints.maxWidth > 500
                            ? 2
                            : 1;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        return _GameCard(
                          name: game['name'] as String,
                          description: game['description'] as String,
                          icon: game['icon'] as IconData,
                          color: game['color'] as Color,
                          available: game['available'] as bool,
                          onTap: game['available'] as bool
                              ? () => context.go('/${game['id']}')
                              : null,
                        );
                      },
                    );
                  },
                ),

                // Footer
                const SizedBox(height: 32),
                Card(
                  color: Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '📱 Télécharge nos apps',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Joue hors ligne sur Android et iOS',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Link to Play Store
                              },
                              icon: const Icon(Icons.android),
                              label: const Text('Play Store'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Link to App Store
                              },
                              icon: const Icon(Icons.apple),
                              label: const Text('App Store'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  '© 2025 ITMade Studio',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool available;
  final VoidCallback? onTap;

  const _GameCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.available,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: available ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 48,
                      color: available ? color : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: available ? null : Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Expanded(
                    child: Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: available ? Colors.grey[700] : Colors.grey,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Button
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: available ? color : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      available ? '🎮 Jouer' : 'Bientôt disponible',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Badge "Nouveau" pour les jeux disponibles
            if (available)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'NOUVEAU',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
