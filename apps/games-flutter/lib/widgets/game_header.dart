import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Widget d'en-tête unifié pour tous les jeux
/// Style moderne avec gradient, shadow et bouton retour dans un cercle
class GameHeader extends StatelessWidget {
  final String title;
  final String? emoji;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final List<Color>? gradientColors;

  const GameHeader({
    super.key,
    required this.title,
    this.emoji,
    this.onBack,
    this.actions,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: EdgeInsets.all(isMobile ? 8 : 12),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton retour dans un cercle
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: isMobile ? 20 : 24,
              ),
              onPressed: onBack ?? () => context.go('/home'),
              tooltip: 'Retour',
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),

          // Titre avec gradient doré
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 20,
                vertical: isMobile ? 10 : 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors ?? [
                    const Color(0xFFFFD700),
                    const Color(0xFFFF8C00),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: (gradientColors?.last ?? const Color(0xFFFF8C00))
                        .withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                emoji != null ? '$emoji $title' : title,
                style: TextStyle(
                  fontSize: isMobile ? 20 : 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Actions (icônes supplémentaires)
          if (actions != null && actions!.isNotEmpty) ...[
            SizedBox(width: isMobile ? 8 : 12),
            ...actions!,
          ],
        ],
      ),
    );
  }
}

/// Bouton d'action pour le header (style unifié)
class GameHeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? iconColor;
  final Color? backgroundColor;

  const GameHeaderAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: iconColor ?? Colors.white,
          size: isMobile ? 20 : 24,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}
