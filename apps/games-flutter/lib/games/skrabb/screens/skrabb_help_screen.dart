import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SkrabbHelpScreen extends StatelessWidget {
  const SkrabbHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/skrabb'),
        ),
        title: const Text('Comment Jouer'),
        backgroundColor: const Color(0xFFE74C3C),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'Objectif',
            'Former des mots en créole sur le plateau pour marquer le plus de points possible!',
            Icons.emoji_events,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Comment Jouer',
            '''PLACER DES TUILES (2 méthodes):
• Glisser-déposer: Maintenez une tuile et glissez-la sur le plateau
• Tap-tap: Cliquez sur une tuile, puis sur une case du plateau

RÉCUPÉRER UNE TUILE:
• Cliquez sur une tuile NON VALIDÉE pour la remettre dans votre chevalet

VALIDER:
• Cliquez sur "Valider" pour confirmer votre coup
• Ou "Annuler" pour tout retirer
• Ou "Mélanger" pour réorganiser votre chevalet

RÈGLES:
• Le premier mot DOIT passer par la case centrale (★)
• Les mots suivants doivent se connecter aux mots déjà placés
• Tous les mots formés doivent être valides''',
            Icons.play_arrow,
          ),
          const SizedBox(height: 16),
          _buildBonusSection(context),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Calcul des Points',
            '''Chaque lettre a une valeur de 1 à 10 points.

Les multiplicateurs de bonus s'appliquent uniquement aux lettres nouvellement placées ce tour.

BINGO! Si vous utilisez vos 7 tuiles en un seul tour, vous gagnez +50 points bonus!''',
            Icons.calculate,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Fin de Partie',
            '''La partie se termine quand:
- Le sac de lettres est vide ET
- Votre chevalet est vide

Votre score final est sauvegardé dans le classement!''',
            Icons.flag,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Astuces',
            '''• Utilisez les cases bonus stratégiquement
• Formez plusieurs mots en un coup pour multiplier vos points
• Les mots plus longs rapportent généralement plus de points
• Gardez des voyelles dans votre chevalet pour plus de flexibilité''',
            Icons.lightbulb,
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => context.go('/skrabb'),
              icon: const Icon(Icons.close),
              label: const Text('Fermer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFE74C3C), size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE74C3C),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBonusSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFE74C3C), size: 28),
                const SizedBox(width: 12),
                Text(
                  'Cases Bonus',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE74C3C),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBonusItem(
              'Mot Triple (MT)',
              'Le mot entier compte triple',
              Colors.red.shade700,
            ),
            _buildBonusItem(
              'Mot Double (MD)',
              'Le mot entier compte double',
              Colors.pink.shade300,
            ),
            _buildBonusItem(
              'Lettre Triple (LT)',
              'La lettre compte triple',
              Colors.blue.shade700,
            ),
            _buildBonusItem(
              'Lettre Double (LD)',
              'La lettre compte double',
              Colors.blue.shade300,
            ),
            _buildBonusItem(
              'Centre (★)',
              'Double Mot - Premier mot obligatoire',
              Colors.pink.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBonusItem(String label, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                label.split('(')[1].replaceAll(')', ''),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
