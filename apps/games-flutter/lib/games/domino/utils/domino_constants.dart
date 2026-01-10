import 'package:flutter/material.dart';

/// Constantes centralisées pour le jeu de Domino
/// Permet de maintenir la cohérence et facilite les ajustements
class DominoConstants {
  DominoConstants._();

  // ============================================
  // RÈGLES DU JEU
  // ============================================

  /// Nombre de joueurs requis pour une partie
  static const int requiredPlayers = 3;

  /// Nombre de tuiles par joueur
  static const int tilesPerPlayer = 7;

  /// Nombre de manches pour gagner
  static const int roundsToWin = 3;

  /// Nombre maximum de dominos avant de tourner (serpentin)
  static const int maxTilesBeforeTurn = 5;

  // ============================================
  // DIMENSIONS DES TUILES
  // ============================================

  /// Largeur d'une tuile horizontale (mobile)
  static const double tileWidthMobile = 50.0;

  /// Hauteur d'une tuile horizontale (mobile)
  static const double tileHeightMobile = 25.0;

  /// Largeur d'une tuile horizontale (desktop)
  static const double tileWidthDesktop = 70.0;

  /// Hauteur d'une tuile horizontale (desktop)
  static const double tileHeightDesktop = 35.0;

  /// Espacement entre les tuiles sur le plateau
  static const double tileSpacing = 2.0;

  // ============================================
  // ANIMATIONS - Durées
  // ============================================

  /// Animation de pulsation (indicateur de tour)
  static const Duration pulseDuration = Duration(milliseconds: 1500);

  /// Animation de fondu
  static const Duration fadeDuration = Duration(milliseconds: 800);

  /// Animation de placement de tuile
  static const Duration placementDuration = Duration(milliseconds: 500);

  /// Animation de sélection
  static const Duration selectionDuration = Duration(milliseconds: 200);

  /// Animation de scale (zoom)
  static const Duration scaleDuration = Duration(milliseconds: 300);

  /// Animation de vague (effet cascade)
  static const Duration waveDuration = Duration(milliseconds: 600);

  /// Animation d'entrée/sortie
  static const Duration transitionDuration = Duration(milliseconds: 400);

  /// Délai entre les animations en cascade
  static const Duration cascadeDelay = Duration(milliseconds: 50);

  /// Durée d'affichage des snackbars
  static const Duration snackbarDuration = Duration(seconds: 2);

  /// Animation résultats
  static const Duration resultsDuration = Duration(milliseconds: 1000);

  // ============================================
  // IA - Timing
  // ============================================

  /// Délai minimum avant que l'IA joue
  static const int aiDelayMin = 800;

  /// Délai maximum avant que l'IA joue
  static const int aiDelayMax = 2000;

  // ============================================
  // COULEURS
  // ============================================

  /// Couleur primaire du jeu (orange)
  static const Color primaryColor = Color(0xFFE67E22);

  /// Couleur primaire foncée
  static const Color primaryDarkColor = Color(0xFFD35400);

  /// Couleur secondaire (bleu foncé)
  static const Color secondaryColor = Color(0xFF1a1a2e);

  /// Couleur du plateau de jeu
  static const Color boardColor = Color(0xFF2d5a27);

  /// Couleur du plateau foncée
  static const Color boardDarkColor = Color(0xFF1e3d1a);

  /// Couleur d'accent (or)
  static const Color accentColor = Color(0xFFFFD700);

  /// Couleur de succès
  static const Color successColor = Color(0xFF27ae60);

  /// Couleur d'erreur
  static const Color errorColor = Color(0xFFe74c3c);

  /// Couleur de warning
  static const Color warningColor = Color(0xFFf39c12);

  /// Couleur du texte clair
  static const Color lightTextColor = Colors.white;

  /// Couleur du texte foncé
  static const Color darkTextColor = Color(0xFF2c3e50);

  // ============================================
  // TAILLES DE TEXTE
  // ============================================

  /// Titre principal
  static const double titleFontSize = 24.0;

  /// Sous-titre
  static const double subtitleFontSize = 18.0;

  /// Texte normal
  static const double bodyFontSize = 14.0;

  /// Petit texte
  static const double smallFontSize = 12.0;

  /// Score/valeur importante
  static const double scoreFontSize = 32.0;

  // ============================================
  // RAYONS DE BORDURE
  // ============================================

  /// Petit rayon (boutons, badges)
  static const double borderRadiusSmall = 8.0;

  /// Rayon moyen (cartes)
  static const double borderRadiusMedium = 12.0;

  /// Grand rayon (modals)
  static const double borderRadiusLarge = 16.0;

  /// Rayon arrondi (avatars)
  static const double borderRadiusRound = 50.0;

  // ============================================
  // PADDINGS
  // ============================================

  /// Petit padding
  static const double paddingSmall = 8.0;

  /// Padding moyen
  static const double paddingMedium = 12.0;

  /// Grand padding
  static const double paddingLarge = 16.0;

  /// Très grand padding
  static const double paddingXLarge = 24.0;

  // ============================================
  // Z-INDEX / ELEVATION
  // ============================================

  /// Élévation des cartes
  static const double cardElevation = 4.0;

  /// Élévation des dialogs
  static const double dialogElevation = 24.0;

  /// Élévation du plateau
  static const double boardElevation = 8.0;
}
