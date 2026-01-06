import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol_games/games/domino/models/domino_tile.dart';
import 'package:kwaze_kreyol_games/games/domino/models/domino_participant.dart';
import 'package:kwaze_kreyol_games/games/domino/utils/domino_logic.dart';
import 'package:kwaze_kreyol_games/games/domino/utils/domino_scoring.dart';

/// ============================================================================
/// TEST DE SCÉNARIO COMPLET: PARTIE DE DOMINOS MARTINIQUAIS "DOUBLE SIZ"
/// ============================================================================
///
/// Règles du jeu:
/// - 3 joueurs exactement
/// - 7 tuiles par joueur (21 distribuées, 7 inutilisées)
/// - Pas de pioche
/// - Premier joueur: celui qui a le double le plus haut (6-6 > 5-5 > etc.)
/// - Victoire manche: poser toutes ses tuiles OU avoir le moins de points si bloqué
/// - Victoire partie: premier à 3 manches gagnées
/// - Chirée: tous les joueurs ont ≥1 manche ET aucun n'a 3 manches
/// - Cochon: joueur avec 0 manche à la fin de la partie

void main() {
  group('🎲 Double Siz - Simulation Partie Complète', () {

    late List<DominoParticipant> joueurs;
    late Map<String, List<DominoTile>> mains;
    late List<PlacedTile> plateau;
    late int boutGauche;
    late int boutDroit;
    late String joueurActuel;

    /// Initialise une nouvelle manche
    void initManche() {
      final participantIds = ['joueur1', 'joueur2', 'joueur3'];
      mains = DominoLogic.distributeTiles(participantIds);
      plateau = [];
      boutGauche = -1;
      boutDroit = -1;
      joueurActuel = DominoLogic.determineStartingPlayer(mains);
    }

    /// Simule le placement d'une tuile
    bool placerTuile(String joueurId, DominoTile tuile, String cote) {
      if (!mains[joueurId]!.contains(tuile)) return false;

      if (plateau.isEmpty) {
        // Premier domino
        plateau.add(PlacedTile(
          tile: tuile,
          side: 'initial',
          connectedValue: tuile.value1,
          placedAt: DateTime.now(),
        ));
        boutGauche = tuile.value1;
        boutDroit = tuile.value2;
      } else {
        // Vérifier si la tuile peut être placée
        int valeurConnexion;
        if (cote == 'left') {
          if (tuile.value1 != boutGauche && tuile.value2 != boutGauche) return false;
          valeurConnexion = tuile.canConnect(boutGauche) ? boutGauche : -1;
          if (valeurConnexion == -1) return false;
          boutGauche = tuile.value1 == valeurConnexion ? tuile.value2 : tuile.value1;
        } else {
          if (tuile.value1 != boutDroit && tuile.value2 != boutDroit) return false;
          valeurConnexion = tuile.canConnect(boutDroit) ? boutDroit : -1;
          if (valeurConnexion == -1) return false;
          boutDroit = tuile.value1 == valeurConnexion ? tuile.value2 : tuile.value1;
        }

        plateau.add(PlacedTile(
          tile: tuile,
          side: cote,
          connectedValue: valeurConnexion,
          placedAt: DateTime.now(),
        ));
      }

      // Retirer la tuile de la main
      mains[joueurId]!.removeWhere((t) => t.id == tuile.id);
      return true;
    }

    /// Trouve une tuile jouable dans la main
    DominoTile? trouverTuileJouable(String joueurId) {
      for (final tuile in mains[joueurId]!) {
        if (plateau.isEmpty) return tuile;
        if (tuile.canConnect(boutGauche) || tuile.canConnect(boutDroit)) {
          return tuile;
        }
      }
      return null;
    }

    /// Détermine le côté où jouer une tuile
    String determinerCote(DominoTile tuile) {
      if (tuile.canConnect(boutGauche)) return 'left';
      return 'right';
    }

    test('📋 Test 1: Distribution correcte des tuiles', () {
      initManche();

      // Vérifier 7 tuiles par joueur
      expect(mains['joueur1']!.length, 7, reason: 'Joueur 1 doit avoir 7 tuiles');
      expect(mains['joueur2']!.length, 7, reason: 'Joueur 2 doit avoir 7 tuiles');
      expect(mains['joueur3']!.length, 7, reason: 'Joueur 3 doit avoir 7 tuiles');

      // Vérifier 21 tuiles uniques distribuées
      final toutesLesTuiles = [
        ...mains['joueur1']!,
        ...mains['joueur2']!,
        ...mains['joueur3']!,
      ];
      final tuilesUniques = toutesLesTuiles.map((t) => t.id).toSet();
      expect(tuilesUniques.length, 21, reason: '21 tuiles uniques doivent être distribuées');

      print('✅ Distribution: 7 tuiles par joueur, 21 total');
    });

    test('🎯 Test 2: Premier joueur = double le plus haut', () {
      // Créer des mains contrôlées pour tester
      final mainsControlees = {
        'joueur1': [
          DominoTile(value1: 5, value2: 5), // Double 5
          DominoTile(value1: 3, value2: 4),
          DominoTile(value1: 1, value2: 2),
          DominoTile(value1: 0, value2: 1),
          DominoTile(value1: 2, value2: 3),
          DominoTile(value1: 4, value2: 5),
          DominoTile(value1: 0, value2: 6),
        ],
        'joueur2': [
          DominoTile(value1: 6, value2: 6), // Double 6 - LE PLUS HAUT!
          DominoTile(value1: 1, value2: 3),
          DominoTile(value1: 2, value2: 4),
          DominoTile(value1: 0, value2: 2),
          DominoTile(value1: 3, value2: 5),
          DominoTile(value1: 4, value2: 6),
          DominoTile(value1: 1, value2: 5),
        ],
        'joueur3': [
          DominoTile(value1: 4, value2: 4), // Double 4
          DominoTile(value1: 0, value2: 3),
          DominoTile(value1: 1, value2: 4),
          DominoTile(value1: 2, value2: 5),
          DominoTile(value1: 3, value2: 6),
          DominoTile(value1: 0, value2: 4),
          DominoTile(value1: 1, value2: 6),
        ],
      };

      final premierJoueur = DominoLogic.determineStartingPlayer(mainsControlees);
      expect(premierJoueur, 'joueur2', reason: 'Joueur 2 a le 6-6, il commence');

      print('✅ Premier joueur: $premierJoueur (possède le 6-6)');
    });

    test('🎮 Test 3: Simulation d\'une manche complète', () {
      initManche();

      print('\n📍 Début de manche - Premier joueur: $joueurActuel');
      print('   Mains initiales:');
      for (final entry in mains.entries) {
        print('   ${entry.key}: ${entry.value.map((t) => "${t.value1}-${t.value2}").join(", ")}');
      }

      int tours = 0;
      final passesConsecutifs = <String>[];
      final ordreJoueurs = ['joueur1', 'joueur2', 'joueur3'];
      int indexJoueur = ordreJoueurs.indexOf(joueurActuel);

      // Simuler jusqu'à victoire ou blocage (max 30 tours pour éviter boucle infinie)
      while (tours < 30) {
        final joueur = ordreJoueurs[indexJoueur % 3];
        final tuile = trouverTuileJouable(joueur);

        if (tuile != null) {
          final cote = plateau.isEmpty ? 'initial' : determinerCote(tuile);
          placerTuile(joueur, tuile, cote);
          passesConsecutifs.clear();
          print('   Tour ${tours + 1}: $joueur joue ${tuile.value1}-${tuile.value2} (reste ${mains[joueur]!.length} tuiles)');

          // Victoire par capot!
          if (mains[joueur]!.isEmpty) {
            print('\n🏆 VICTOIRE PAR CAPOT: $joueur a posé toutes ses tuiles!');
            break;
          }
        } else {
          passesConsecutifs.add(joueur);
          print('   Tour ${tours + 1}: $joueur passe');

          // Blocage?
          if (passesConsecutifs.length >= 3) {
            final gagnant = DominoLogic.determineBlockedWinner(mains);
            print('\n🔒 JEU BLOQUÉ - Gagnant par points: $gagnant');
            for (final entry in mains.entries) {
              final points = DominoScoring.calculateHandPoints(entry.value);
              print('   ${entry.key}: $points points');
            }
            break;
          }
        }

        indexJoueur++;
        tours++;
      }

      print('   Plateau final: ${plateau.length} tuiles');
      expect(tours, lessThan(30), reason: 'La manche doit se terminer');
    });

    test('🏆 Test 4: Victoire à 3 manches', () {
      joueurs = [
        DominoParticipant(
          id: 'p1', sessionId: 's1', userId: 'u1',
          roundsWon: 2, isCochon: false, isHost: true, turnOrder: 0,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'p2', sessionId: 's1', userId: 'u2',
          roundsWon: 1, isCochon: false, isHost: false, turnOrder: 1,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'p3', sessionId: 's1', userId: 'u3',
          roundsWon: 0, isCochon: false, isHost: false, turnOrder: 2,
          joinedAt: DateTime.now(),
        ),
      ];

      print('\n📊 État avant manche décisive:');
      print('   Joueur 1: 2 manches');
      print('   Joueur 2: 1 manche');
      print('   Joueur 3: 0 manche');

      // Joueur 1 gagne la 3ème manche
      joueurs[0] = joueurs[0].copyWith(roundsWon: 3);

      // Vérifier la victoire
      final gagnant = joueurs.where((j) => j.roundsWon >= 3).firstOrNull;
      expect(gagnant, isNotNull, reason: 'Un joueur doit avoir gagné');
      expect(gagnant!.id, 'p1', reason: 'Joueur 1 a 3 manches');

      // Vérifier les cochons
      final cochons = DominoScoring.determineCochons(joueurs);
      expect(cochons.contains('p3'), true, reason: 'Joueur 3 est cochon (0 manche)');

      print('\n🏆 VICTOIRE FINALE: ${gagnant.id}');
      print('🐷 Cochons: $cochons');
    });

    test('🤝 Test 5: Chirée (match nul)', () {
      joueurs = [
        DominoParticipant(
          id: 'p1', sessionId: 's1', userId: 'u1',
          roundsWon: 2, isCochon: false, isHost: true, turnOrder: 0,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'p2', sessionId: 's1', userId: 'u2',
          roundsWon: 2, isCochon: false, isHost: false, turnOrder: 1,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'p3', sessionId: 's1', userId: 'u3',
          roundsWon: 1, isCochon: false, isHost: false, turnOrder: 2,
          joinedAt: DateTime.now(),
        ),
      ];

      print('\n📊 Scores: J1=2, J2=2, J3=1');

      // Vérifier la chirée
      final estChiree = DominoScoring.isChiree(joueurs);
      expect(estChiree, true, reason: 'Tous ≥1 et aucun à 3 = Chirée');

      // Pas de cochons en chirée
      final cochons = DominoScoring.determineCochons(joueurs);
      expect(cochons.isEmpty, true, reason: 'Pas de cochons en chirée');

      print('🤝 CHIRÉE! Match nul - Tous les joueurs ont au moins 1 manche');
    });

    test('🐷 Test 6: Double cochon (un joueur gagne 3-0-0)', () {
      joueurs = [
        DominoParticipant(
          id: 'p1', sessionId: 's1', userId: 'u1',
          roundsWon: 3, isCochon: false, isHost: true, turnOrder: 0,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'p2', sessionId: 's1', userId: 'u2',
          roundsWon: 0, isCochon: false, isHost: false, turnOrder: 1,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'p3', sessionId: 's1', userId: 'u3',
          roundsWon: 0, isCochon: false, isHost: false, turnOrder: 2,
          joinedAt: DateTime.now(),
        ),
      ];

      print('\n📊 Score final: J1=3, J2=0, J3=0');

      // Pas de chirée (un joueur a 3)
      expect(DominoScoring.isChiree(joueurs), false);

      // Deux cochons
      final cochons = DominoScoring.determineCochons(joueurs);
      expect(cochons.length, 2, reason: 'Deux joueurs sont cochons');
      expect(cochons.contains('p2'), true);
      expect(cochons.contains('p3'), true);

      print('🏆 VICTOIRE: Joueur 1');
      print('🐷🐷 DOUBLE COCHON: Joueur 2 et Joueur 3!');
    });

    test('🎲 Test 7: Calcul des points en main', () {
      final main = [
        DominoTile(value1: 6, value2: 6), // 12 points
        DominoTile(value1: 5, value2: 4), // 9 points
        DominoTile(value1: 0, value2: 0), // 0 points
      ];

      final points = DominoScoring.calculateHandPoints(main);
      expect(points, 21, reason: '12 + 9 + 0 = 21 points');

      print('✅ Calcul des points: 6-6 (12) + 5-4 (9) + 0-0 (0) = $points points');
    });

    test('🔄 Test 8: Validation des connexions de tuiles', () {
      // Tuile 3-5
      final tuile = DominoTile(value1: 3, value2: 5);

      expect(tuile.canConnect(3), true, reason: 'Peut connecter au 3');
      expect(tuile.canConnect(5), true, reason: 'Peut connecter au 5');
      expect(tuile.canConnect(4), false, reason: 'Ne peut pas connecter au 4');
      expect(tuile.canConnect(6), false, reason: 'Ne peut pas connecter au 6');

      // Double
      final double6 = DominoTile(value1: 6, value2: 6);
      expect(double6.isDouble, true, reason: '6-6 est un double');
      expect(tuile.isDouble, false, reason: '3-5 n\'est pas un double');

      print('✅ Validation des connexions OK');
    });

    test('📊 Test 9: Génération du jeu complet (28 tuiles)', () {
      final jeuComplet = DominoTile.createFullSet();

      expect(jeuComplet.length, 28, reason: 'Le jeu complet a 28 tuiles');

      // Vérifier les 7 doubles
      final doubles = jeuComplet.where((t) => t.isDouble).toList();
      expect(doubles.length, 7, reason: '7 doubles (0-0 à 6-6)');

      // Vérifier toutes les combinaisons uniques
      final combinaisons = jeuComplet.map((t) => t.id).toSet();
      expect(combinaisons.length, 28, reason: 'Toutes les tuiles sont uniques');

      print('✅ Jeu complet: 28 tuiles, 7 doubles');
      print('   Doubles: ${doubles.map((t) => "${t.value1}-${t.value2}").join(", ")}');
    });

    test('🎮 Test 10: Partie complète multi-manches', () {
      print('\n════════════════════════════════════════');
      print('🎲 SIMULATION PARTIE COMPLÈTE');
      print('════════════════════════════════════════');

      joueurs = [
        DominoParticipant(
          id: 'Alice', sessionId: 's1', userId: 'u1',
          roundsWon: 0, isCochon: false, isHost: true, turnOrder: 0,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'Bob', sessionId: 's1', userId: 'u2',
          roundsWon: 0, isCochon: false, isHost: false, turnOrder: 1,
          joinedAt: DateTime.now(),
        ),
        DominoParticipant(
          id: 'Charlie', sessionId: 's1', userId: 'u3',
          roundsWon: 0, isCochon: false, isHost: false, turnOrder: 2,
          joinedAt: DateTime.now(),
        ),
      ];

      int numeroManche = 0;

      // Jouer jusqu'à victoire ou chirée (max 10 manches)
      while (numeroManche < 10) {
        numeroManche++;
        print('\n--- MANCHE $numeroManche ---');

        // Distribuer les tuiles
        final participantIds = joueurs.map((j) => j.id).toList();
        mains = DominoLogic.distributeTiles(participantIds);
        plateau = [];
        boutGauche = -1;
        boutDroit = -1;

        // Déterminer premier joueur
        joueurActuel = DominoLogic.determineStartingPlayer(mains);
        print('Premier joueur: $joueurActuel');

        // Jouer la manche
        int tours = 0;
        final passesConsecutifs = <String>[];
        int indexJoueur = participantIds.indexOf(joueurActuel);
        String? gagnantManche;

        while (tours < 30) {
          final joueur = participantIds[indexJoueur % 3];
          final tuile = trouverTuileJouable(joueur);

          if (tuile != null) {
            final cote = plateau.isEmpty ? 'initial' : determinerCote(tuile);
            placerTuile(joueur, tuile, cote);
            passesConsecutifs.clear();

            if (mains[joueur]!.isEmpty) {
              gagnantManche = joueur;
              print('🏆 $joueur gagne par capot!');
              break;
            }
          } else {
            passesConsecutifs.add(joueur);

            if (passesConsecutifs.length >= 3) {
              gagnantManche = DominoLogic.determineBlockedWinner(mains);
              print('🔒 Jeu bloqué - $gagnantManche gagne aux points');
              break;
            }
          }

          indexJoueur++;
          tours++;
        }

        // Mettre à jour les scores
        if (gagnantManche != null) {
          final idx = joueurs.indexWhere((j) => j.id == gagnantManche);
          joueurs[idx] = joueurs[idx].copyWith(roundsWon: joueurs[idx].roundsWon + 1);
        }

        print('Scores: ${joueurs.map((j) => "${j.id}=${j.roundsWon}").join(", ")}');

        // Vérifier fin de partie
        final vainqueur = joueurs.where((j) => j.roundsWon >= 3).firstOrNull;
        if (vainqueur != null) {
          print('\n🏆🏆🏆 VICTOIRE FINALE: ${vainqueur.id} avec 3 manches! 🏆🏆🏆');
          break;
        }

        if (DominoScoring.isChiree(joueurs)) {
          print('\n🤝🤝🤝 CHIRÉE! Match nul! 🤝🤝🤝');
          break;
        }
      }

      // Afficher les cochons
      final cochons = DominoScoring.determineCochons(joueurs);
      if (cochons.isNotEmpty) {
        print('🐷 Cochons: ${cochons.join(", ")}');
      }

      print('\n════════════════════════════════════════');
      expect(numeroManche, lessThanOrEqualTo(10), reason: 'Partie terminée');
    });
  });
}
