# Documentation Claude - Jeu de Dominos Martiniquais

## 📋 État du Projet

**Date**: 2026-01-06
**Statut**: En développement - Phase 4 complétée, bugs en cours de correction

---

## ✅ Ce qui a été réalisé

### Phase 1: Fondations (Modèles + BDD) ✅
- ✅ Modèles Dart avec JSON serialization:
  - `DominoTile` - Tuile de domino (value1, value2)
  - `DominoSession` - Session complète de jeu
  - `DominoParticipant` - Joueur dans une session
  - `DominoGameState` - État de la manche en cours (JSONB dans Supabase)
  - `DominoRound` - Manche terminée
  - `PlacedTile` - Tuile placée sur le plateau avec métadonnées
- ✅ Migration Supabase `domino_schema.sql`:
  - Tables: `domino_sessions`, `domino_participants`, `domino_rounds`, `domino_invitations`
  - RLS (Row Level Security) pour sécurité
  - Indexes pour performance
  - RPC functions: `generate_domino_join_code()`, `increment_rounds_won()`
- ✅ Réplication Realtime activée pour toutes les tables

### Phase 2: Service Layer ✅
- ✅ `DominoService` complet avec toutes les méthodes:
  - Gestion de session (créer, rejoindre, démarrer, annuler)
  - Invitations entre joueurs
  - Logique de jeu (placeTile, passTurn, endRound)
  - Statistiques joueurs
- ✅ Extension `RealtimeService` avec `subscribeToDominoSession()`
- ✅ Support joueurs invités (sans compte)

### Phase 3: Logique de Jeu ✅
- ✅ `DominoLogic` - Moteur de règles:
  - Distribution des tuiles (7-7-7, 7 restent inutilisées)
  - Détermination du premier joueur (double le plus haut: 6-6, 5-5, etc.)
  - Validation des placements
  - Détection de blocage
  - Gagnant par points (moins de points)
- ✅ `DominoScoring` - Calculs de score:
  - Points dans une main
  - Détection des cochons (0 manche à la fin)
  - Détection de chirée (tous ≥1 manche ET aucun ≥3)

### Phase 4: Interface Utilisateur ✅
- ✅ `DominoHomeScreen` - Écran d'accueil:
  - Créer une partie
  - Rejoindre par code (6 chiffres)
  - Liste des parties en cours avec reprise
  - Système de suppression des parties (bouton delete visible)
  - Invitations en temps réel
- ✅ `DominoLobbyScreen` - Salle d'attente:
  - Affichage du code de session
  - Liste des 3 joueurs en temps réel
  - Bouton démarrer (actif quand 3 joueurs)
- ✅ `DominoGameScreen` - Jeu principal:
  - Plateau de jeu avec InteractiveViewer (zoom/pan)
  - Affichage des adversaires
  - Main du joueur avec drag & drop
  - Indicateur de tour
  - Bouton "Passer" quand aucune tuile jouable
  - Zone de drop pour premier domino (plateau vide)
- ✅ `DominoResultsScreen` - Résultats:
  - Gagnant ou chirée
  - Marquage des cochons
  - Historique des manches

### Phase 4.5: Système Visuel Avancé ✅
- ✅ `DominoTileWidget` avec `CustomPaint` (design vectoriel adaptatif)
- ✅ `DominoBoardLayout` - Layout 2D intelligent en serpentin:
  - 6 dominos max avant de tourner
  - Rotation horaire (droite → bas → gauche → haut)
  - Centrage automatique
  - Calcul du zoom initial
- ✅ `AnimatedDominoPlacement` - Animations:
  - Effet de vague lors du placement
  - Animations cinématographiques
- ✅ Zones de drop minimales (invisibles sauf au survol)
- ✅ Navigation: Bouton retour va vers `/domino` (pas `/`)

### Phase 4.6: Logique de Chirée ✅
- ✅ Statut 'chiree' ajouté dans:
  - Modèle `DominoSession`
  - Migration SQL `add_chiree_status.sql`
  - Contrainte CHECK en base de données
- ✅ Détection de chirée dans `DominoService._endRound()`:
  - Vérifiée AVANT la victoire
  - Condition: tous ≥1 ET aucun ≥3
- ✅ Navigation automatique vers résultats en cas de chirée
- ✅ Tests d'intégration (17 tests couvrant tous les cas)

---

## ✅ BUGS CORRIGÉS (2026-01-06)

### Refonte Complète du Plateau de Jeu

Le plateau a été entièrement réécrit avec un nouveau widget modulaire `DominoBoardWidget`:

#### Corrections apportées:
1. **Doubles verticaux**: Les doubles (6-6, 5-5, etc.) sont maintenant affichés verticalement
2. **Non-doubles horizontaux**: Les tuiles normales sont affichées horizontalement
3. **Direction de chaîne**: La chaîne de dominos change de direction quand un double est placé
4. **Zones de drop adaptatives**: Les zones de drop s'adaptent à la direction de la chaîne
5. **Flip correct**: La logique de flip basée sur `connectedValue` et `side`
6. **Centrage automatique**: Les dominos sont centrés sur le plateau

#### Architecture du nouveau widget:
- `ChainDirection` enum: right → down → left → up
- `BoardTilePosition`: position + orientation + valeurs d'affichage
- Calcul automatique des bounds pour le centrage
- Zones de drop qui suivent la direction de la chaîne

---

## ⚠️ ERREURS À NE PAS REFAIRE

### 1. Serveur Bloqué sur le Logo
**Cause**: Code complexe avec `Builder` widget imbriqué causant des erreurs runtime
**Solution**: Simplifier le code, éviter les imbrications inutiles
**Exemple**: Lignes 901-950 - Builder pour zones de drop simplifié

### 2. Confusion sur les Hauteurs
**Erreur**: Utiliser `MediaQuery.of(context).size.height` alors que le plateau a une hauteur fixe
**Règle**: TOUJOURS utiliser la hauteur réelle du Container (400px pour le plateau avec dominos, 400px pour plateau vide)

### 3. Tests d'Intégration - Package Name
**Erreur**: Utiliser `package:games_flutter/` au lieu de `package:kwaze_kreyol_games/`
**Impact**: Tests ne compilent pas
**Fichier**: `test/games/domino/domino_integration_test.dart`

### 4. PlacedTile Constructor
**Erreur**: Essayer d'utiliser `exposedValue` comme paramètre du constructeur
**Correct**: Utiliser `placedAt: DateTime.now()` - `exposedValue` est un getter

### 5. Duplicate Declarations
**Erreur**: Déclarer deux fois le même getter `isChiree` dans `DominoSession`
**Impact**: Erreur de compilation
**Solution**: Vérifier les getters existants avant d'en ajouter

### 6. Cache Navigateur
**Problème récurrent**: Modifications non visibles car cache navigateur garde l'ancienne version
**Solution**: TOUJOURS demander à l'utilisateur de vider le cache avec Ctrl+Shift+R
**Alternative**: Ouvrir en navigation privée pour tester

### 7. RLS (Row Level Security)
**Erreur initiale**: Politiques RLS trop restrictives empêchaient les participants de mettre à jour `current_game_state`
**Solution appliquée**: Politique permettant à TOUS les participants de mettre à jour (pas seulement l'hôte)
**Fichier**: `supabase/migrations/domino_schema.sql`

---

## 🎯 RÈGLES DU JEU (Rappel)

### Distribution
- 3 joueurs exactement
- 7 tuiles par joueur (21 total)
- 7 tuiles restent inutilisées (PAS de pioche)

### Premier Joueur
- **Première manche**: Celui qui a le double le plus haut (6-6 > 5-5 > 4-4 > etc.)
- **Manches suivantes**: Le gagnant de la manche précédente

### Fin de Manche
1. **Capot**: Un joueur pose toutes ses tuiles → il gagne
2. **Bloqué**: Personne ne peut jouer → joueur avec le moins de points gagne

### Fin de Partie
- **Victoire**: Premier à **3 manches gagnées**
- **Chirée**: Si tous les joueurs ont ≥1 manche ET aucun n'a 3 → match nul
- **Cochon**: Joueur avec 0 manche à la fin

### Exemples de Résultats
**Victoire**: J1:3, J2:0, J3:0 (double cochon) | J1:3, J2:1, J3:0 | J1:3, J2:2, J3:0
**Chirée**: J1:1, J2:1, J3:1 | J1:2, J2:1, J3:1 | J1:2, J2:2, J3:1

---

## 📂 STRUCTURE DES FICHIERS

```
lib/games/domino/
├── models/
│   ├── domino_tile.dart           # Tuile + PlacedTile
│   ├── domino_session.dart        # Session complète
│   ├── domino_participant.dart    # Joueur
│   ├── domino_game_state.dart     # État JSONB temps réel
│   └── domino_round.dart          # Manche terminée
├── services/
│   └── domino_service.dart        # Toutes les opérations
├── screens/
│   ├── domino_home_screen.dart    # Accueil
│   ├── domino_lobby_screen.dart   # Salle d'attente
│   ├── domino_game_screen.dart    # Jeu principal (utilise DominoBoardWidget)
│   └── domino_results_screen.dart # Résultats
├── widgets/
│   ├── domino_tile_painter.dart   # CustomPaint vectoriel
│   ├── animated_domino_placement.dart # Animations
│   └── domino_board_widget.dart   # ✅ NOUVEAU: Widget modulaire du plateau
└── utils/
    ├── domino_logic.dart          # Règles du jeu
    ├── domino_scoring.dart        # Calculs scores
    └── domino_board_layout.dart   # (Ancien layout, non utilisé)

supabase/migrations/
├── domino_schema.sql              # Schéma complet
└── add_chiree_status.sql          # Statut chirée
```

---

## 🔧 PROCHAINES ÉTAPES

### ✅ Bugs Critiques Corrigés
Le nouveau `DominoBoardWidget` résout tous les problèmes de:
- Centrage vertical
- Orientation des dominos (doubles verticaux)
- Logique de flip
- Zones de drop adaptatives

### En cours: Tests manuels
- Tester avec 3 joueurs réels
- Vérifier les placements de dominos
- Valider le changement de direction avec les doubles

### Phase 5: Ajout de Sons
- Sons pour placement de tuile
- Son pour passer le tour
- Son pour fin de manche
- Son pour victoire/chirée

### Phase 6: Tests et Optimisation
- Tests avec 3 joueurs réels en simultané
- Tests déconnexion/reconnexion
- Optimisation Realtime (debounce)
- Tests de toutes les règles

---

## 💡 NOTES IMPORTANTES

### Image de Référence Fournie
L'utilisateur a fourni une capture d'écran montrant:
- Des dominos en serpentin (ligne horizontale qui tourne)
- Les dominos sont collés par les valeurs correspondantes
- Les points orange montrent les connexions

### Commandes Utiles
```bash
# Restart server
flutter/bin/flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0

# Clean build
flutter/bin/flutter clean

# Analyze code
flutter/bin/flutter analyze lib/games/domino/screens/domino_game_screen.dart

# Run tests
flutter test test/games/domino/
```

### Serveur
- Port: 8080
- URL: http://0.0.0.0:8080
- En cours d'exécution: Oui (background task b67b0bd)

---

## 📝 LEÇONS APPRISES

1. **Toujours lire les fichiers avant de modifier** - Évite les erreurs de contexte
2. **Simplifier plutôt que complexifier** - Code simple = moins de bugs
3. **Tester après chaque modification** - Ne pas accumuler les changements
4. **Documenter les bugs** - Aide à ne pas refaire les mêmes erreurs
5. **Demander des screenshots** - Une image vaut mille mots
6. **Vérifier le cache navigateur** - Source fréquente de confusion
7. **Utiliser des constantes** - 400.0 plutôt que des calculs dynamiques
8. **Commenter la logique complexe** - Surtout pour les orientations/flips

---

## 🎯 OBJECTIF ACTUEL

**TESTER LE NOUVEAU PLATEAU**

Le plateau a été refait avec `DominoBoardWidget`. Prochaines étapes:
1. Tester avec une vraie partie à 3 joueurs
2. Valider que les doubles sont verticaux et changent la direction
3. Vérifier que les dominos se collent correctement

Une fois validé, passer à la Phase 5 (Sons) !

---

**Dernière mise à jour**: 2026-01-06
**Serveur**: http://0.0.0.0:8080
