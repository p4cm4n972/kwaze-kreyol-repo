# Tests Met Double

Ce fichier contient les tests pour vérifier le bon fonctionnement du jeu Met Double.

## Fichiers de tests

### 📄 `met_double_test.dart` - Tests unitaires (15 tests)
Tests de base pour les modèles et la logique métier

### 📄 `met_double_integration_test.dart` - Tests d'intégration (10 tests)
**Tests spécifiques pour détecter les anomalies et bugs**

## Tests inclus

### 1. Tests des modèles (met_double_test.dart)
- ✅ Création de session avec 3 joueurs (peut démarrer)
- ✅ Création de session avec moins de 3 joueurs (ne peut pas démarrer)
- ✅ Participants : utilisateurs inscrits vs invités
- ✅ Manches normales avec gagnant
- ✅ Manches chirées

### 2. Tests de la logique de jeu (met_double_test.dart)
- ✅ **Manche gagnée** : Identification du gagnant (3 victoires)
- ✅ **Manche chirée** : Tous les joueurs ont au moins 1 point
- ✅ **Cochons** : Identification des joueurs avec 0 point
- ✅ **Met Double** : Joueur qui donne le plus de cochons
- ✅ **Met Cochon** : Joueur qui reçoit le plus de cochons
- ✅ **Progression** : De "waiting" à "in_progress" à "completed"

### 3. Tests de sérialisation (met_double_test.dart)
- ✅ Conversion JSON des sessions
- ✅ Conversion JSON des participants
- ✅ Conversion JSON des manches avec cochons

### 4. 🔍 Tests de détection d'anomalies (met_double_integration_test.dart)
- 🚨 **Enregistrement multiple** : Une manche enregistrée 3 fois au lieu d'une
- 🚨 **Doublons de rounds** : Même numéro de manche plusieurs fois
- 🚨 **Cohérence victoires/historique** : Les victoires affichées correspondent à l'historique
- 🚨 **Chirée multiple** : Manche chirée enregistrée plusieurs fois
- 🚨 **Comptage manches** : Affichage vs réalité (UI dit 3, historique montre 1)
- 🚨 **Race condition** : Protection contre les enregistrements rapides multiples
- 🚨 **Cochons incohérents** : Joueurs marqués cochon mais avec des victoires
- 🚨 **Timestamps** : Ordre chronologique des manches

### 5. 🐛 Tests de régression (met_double_integration_test.dart)
- ✅ Bug du comptage "3 manches au lieu de 1" (BUG RAPPORTÉ)
- ✅ Bug de la modal chirée en boucle (BUG RAPPORTÉ)

## Exécuter les tests

### ⚠️ IMPORTANT - Tests de détection d'anomalies
**Exécutez ces tests en priorité pour détecter les bugs d'enregistrement multiple :**

```bash
cd apps/games-flutter
flutter test test/met_double_integration_test.dart
```

### Tests unitaires (modèles et logique)
```bash
cd apps/games-flutter
flutter test test/met_double_test.dart
```

### Tous les tests Met Double (unitaires + intégration)
```bash
cd apps/games-flutter
flutter test test/met_double_test.dart test/met_double_integration_test.dart
```

### Tous les tests du projet
```bash
cd apps/games-flutter
flutter test
```

### Tests avec couverture
```bash
cd apps/games-flutter
flutter test --coverage
```

### Tests en mode verbose (pour voir les détails des erreurs)
```bash
cd apps/games-flutter
flutter test test/met_double_integration_test.dart --verbose
```

### Exécuter un seul test spécifique
```bash
cd apps/games-flutter
# Exemple: tester uniquement le bug de comptage
flutter test test/met_double_integration_test.dart --name "3 manches au lieu de 1"
```

## Scénarios testés

### Scénario 1 : Création et ajout d'invités
1. Création d'une session
2. Session en statut "waiting"
3. Ajout de 2 joueurs inscrits
4. Ajout d'1 invité
5. Vérification que la partie peut démarrer (3 joueurs)

### Scénario 2 : Manche gagnée
1. Alice gagne la manche 1 (3 points)
2. Bob fait cochon (0 point)
3. Charlie obtient 1 point
4. Vérification de l'enregistrement dans l'historique
5. Identification d'Alice comme gagnante

### Scénario 3 : Manche chirée
1. Tous les joueurs ont au moins 1 point
2. Enregistrement d'une manche chirée
3. Vérification qu'aucun gagnant n'est défini
4. Vérification que la manche est marquée comme chirée

### Scénario 4 : Statistiques
1. Calcul du nombre de cochons donnés par joueur
2. Calcul du nombre de cochons reçus par joueur
3. Identification du "Met Double" (le plus de cochons donnés)
4. Identification du "Met Cochon" (le plus de cochons reçus)

## Structure des tests

```
test/
├── met_double_test.dart  # Tests Met Double
├── widget_test.dart      # Tests widgets par défaut
└── README_TESTS.md       # Ce fichier
```

## Ajouter de nouveaux tests

Pour ajouter de nouveaux tests, suivez ce modèle :

```dart
test('Description du test', () {
  // Arrange (Préparer les données)
  final session = MetDoubleSession(...);

  // Act (Exécuter l'action)
  final result = session.canStart;

  // Assert (Vérifier le résultat)
  expect(result, isTrue);
});
```

## Notes importantes

- Les tests sont unitaires et ne nécessitent pas de connexion à Supabase
- Ils testent la logique métier des modèles et des règles du jeu
- Pour tester les services (avec Supabase), des tests d'intégration seraient nécessaires
- Les tests s'exécutent rapidement et peuvent être lancés fréquemment pendant le développement
