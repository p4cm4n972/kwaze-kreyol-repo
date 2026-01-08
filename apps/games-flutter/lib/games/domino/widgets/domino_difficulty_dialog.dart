import 'package:flutter/material.dart';
import '../services/domino_ai_service.dart';

/// Dialog pour sélectionner la difficulté de l'IA
class DominoDifficultyDialog extends StatelessWidget {
  const DominoDifficultyDialog({super.key});

  /// Affiche le dialog et retourne la difficulté choisie (ou null si annulé)
  static Future<AIDifficulty?> show(BuildContext context) {
    return showDialog<AIDifficulty>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const DominoDifficultyDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titre
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.purple,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Choisir la difficulté',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Affrontez 2 adversaires IA',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Options de difficulté
              _buildDifficultyCard(
                context,
                difficulty: AIDifficulty.easy,
                title: 'Facile',
                description: 'IA joue au hasard, parfait pour apprendre',
                icon: Icons.sentiment_satisfied,
                colors: [const Color(0xFF4CAF50), const Color(0xFF81C784)],
              ),
              const SizedBox(height: 12),
              _buildDifficultyCard(
                context,
                difficulty: AIDifficulty.normal,
                title: 'Normal',
                description: 'IA joue intelligemment, bon challenge',
                icon: Icons.sentiment_neutral,
                colors: [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
              ),
              const SizedBox(height: 12),
              _buildDifficultyCard(
                context,
                difficulty: AIDifficulty.hard,
                title: 'Difficile',
                description: 'IA stratégique, pour les experts',
                icon: Icons.sentiment_very_dissatisfied,
                colors: [const Color(0xFFF44336), const Color(0xFFE57373)],
              ),

              const SizedBox(height: 20),

              // Bouton annuler
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(
    BuildContext context, {
    required AIDifficulty difficulty,
    required String title,
    required String description,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(difficulty),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
