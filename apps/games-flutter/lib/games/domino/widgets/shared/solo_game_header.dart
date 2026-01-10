import 'package:flutter/material.dart';
import '../../services/domino_ai_service.dart';

/// Header pour le mode solo avec badge difficulté et indicateur IA
class SoloGameHeader extends StatelessWidget {
  final int roundNumber;
  final AIDifficulty difficulty;
  final bool isAIPlaying;
  final VoidCallback? onBack;

  const SoloGameHeader({
    super.key,
    required this.roundNumber,
    required this.difficulty,
    this.isAIPlaying = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final difficultyText = {
      AIDifficulty.easy: 'Facile',
      AIDifficulty.normal: 'Normal',
      AIDifficulty.hard: 'Difficile',
    }[difficulty]!;

    final difficultyColor = {
      AIDifficulty.easy: Colors.green,
      AIDifficulty.normal: Colors.orange,
      AIDifficulty.hard: Colors.red,
    }[difficulty]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          _buildRoundBadge(),
          const SizedBox(width: 12),
          _buildDifficultyBadge(difficultyText, difficultyColor),
          const Spacer(),
          if (isAIPlaying) _buildAIThinkingIndicator(),
        ],
      ),
    );
  }

  Widget _buildRoundBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Text(
        'Manche $roundNumber',
        style: const TextStyle(
          color: Colors.amber,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.smart_toy, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIThinkingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.purple.shade200,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'IA réfléchit...',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
