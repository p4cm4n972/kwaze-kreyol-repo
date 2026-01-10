import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/domino_session.dart';
import '../../models/domino_participant.dart';
import '../../utils/responsive_utils.dart';

/// Header du jeu de dominos affichant le numéro de manche et les scores
class DominoGameHeader extends StatelessWidget {
  final DominoSession session;
  final DominoParticipant? currentParticipant;
  final VoidCallback? onBack;

  const DominoGameHeader({
    super.key,
    required this.session,
    this.currentParticipant,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final gameState = session.currentGameState;
    final roundNumber = gameState?.roundNumber ?? 1;

    return Container(
      margin: EdgeInsets.all(context.responsivePadding(12)),
      padding: EdgeInsets.symmetric(
        horizontal: context.responsivePadding(20),
        vertical: context.responsivePadding(16),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.4),
            Colors.black.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildBackButton(context),
          SizedBox(width: context.responsivePadding(16)),
          Expanded(
            child: Column(
              children: [
                _buildRoundBadge(context, roundNumber),
                SizedBox(height: context.responsivePadding(8)),
                _buildPlayerBadges(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: context.responsive(mobile: 20.0, tablet: 24.0, desktop: 28.0),
        ),
        onPressed: onBack ?? () => context.go('/domino'),
      ),
    );
  }

  Widget _buildRoundBadge(BuildContext context, int roundNumber) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsivePadding(16),
        vertical: context.responsivePadding(8),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C00).withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '🎲 Manche $roundNumber',
        style: TextStyle(
          fontSize: context.responsiveFontSize(18),
          fontWeight: FontWeight.w900,
          color: Colors.black,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPlayerBadges(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: session.participants.map((p) {
        final isCurrentPlayer = p.id == currentParticipant?.id;
        final maxLen = context.isMobile ? 6 : 10;
        final shortName = p.displayName.length > maxLen
            ? p.displayName.substring(0, maxLen)
            : p.displayName;

        return _PlayerBadge(
          name: shortName,
          roundsWon: p.roundsWon,
          isCurrentPlayer: isCurrentPlayer,
          isMobile: context.isMobile,
        );
      }).toList(),
    );
  }
}

class _PlayerBadge extends StatelessWidget {
  final String name;
  final int roundsWon;
  final bool isCurrentPlayer;
  final bool isMobile;

  const _PlayerBadge({
    required this.name,
    required this.roundsWon,
    required this.isCurrentPlayer,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCurrentPlayer
            ? Colors.amber.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentPlayer
              ? Colors.amber
              : Colors.white.withValues(alpha: 0.2),
          width: isCurrentPlayer ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: isMobile ? 11 : 13,
              color: isCurrentPlayer ? Colors.amber : Colors.white,
              fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: roundsWon > 0 ? Colors.green.shade600 : Colors.grey.shade600,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$roundsWon',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
