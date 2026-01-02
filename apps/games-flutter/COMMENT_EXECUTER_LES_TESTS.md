# 🧪 Comment exécuter les tests Met Double

## ⚠️ IMPORTANT

Je n'ai pas pu exécuter les tests dans l'environnement de développement car Flutter n'y est pas installé.

**Vous devez les exécuter sur votre machine locale** pour vérifier que tout fonctionne correctement et détecter les anomalies.

## 🚀 Méthode 1 : Script automatique (RECOMMANDÉ)

Le moyen le plus simple est d'utiliser le script fourni :

```bash
cd apps/games-flutter

# Tous les tests (unitaires + anomalies)
./run_tests.sh

# Seulement les tests de détection d'anomalies
./run_tests.sh anomalies

# Seulement les tests unitaires
./run_tests.sh unit

# Mode verbose (détails complets)
./run_tests.sh verbose

# Avec couverture de code
./run_tests.sh coverage
```

## 📝 Méthode 2 : Commandes manuelles

### Tests prioritaires - Détection d'anomalies

**EXÉCUTEZ CES TESTS EN PREMIER** pour détecter les bugs d'enregistrement multiple :

```bash
cd apps/games-flutter
flutter test test/met_double_integration_test.dart
```

Ces tests vont détecter :
- ✅ Si une manche est enregistrée 3 fois au lieu d'une (BUG RAPPORTÉ)
- ✅ Si la modal chirée revient en boucle (BUG RAPPORTÉ)
- ✅ Doublons de numéros de manche
- ✅ Incohérences entre victoires affichées et historique
- ✅ Race conditions (enregistrements multiples rapides)
- ✅ Cochons incohérents
- ✅ Problèmes de chronologie

### Tests unitaires - Modèles et logique

```bash
cd apps/games-flutter
flutter test test/met_double_test.dart
```

## 🔍 Comment lire les résultats

### ✅ Tous les tests passent
```
✓ ANOMALIE: Vérifier qu'une manche n'est enregistrée qu'une seule fois
✓ RÉGRESSION: Bug du comptage "3 manches au lieu de 1"
✓ RÉGRESSION: Bug de la modal chirée en boucle

All tests passed!
```
**→ Parfait ! Aucune anomalie détectée.**

### ❌ Un test échoue avec "ANOMALIE DÉTECTÉE"
```
✗ ANOMALIE: Vérifier qu'une manche n'est enregistrée qu'une seule fois
  ANOMALIE DÉTECTÉE: Il devrait y avoir exactement 1 manche, pas 3
```
**→ Bug détecté ! Il faut corriger le code.**

### ❌ Un test échoue avec "BUG RÉGRESSION"
```
✗ RÉGRESSION: Bug du comptage "3 manches au lieu de 1"
  BUG RÉGRESSION: Après la première manche, on devrait avoir 1 manche, pas 3
```
**→ Un bug qui avait été corrigé est revenu ! Il faut le corriger à nouveau.**

## 📊 Voir les résultats détaillés

Pour voir plus de détails sur un test qui échoue :

```bash
flutter test test/met_double_integration_test.dart --verbose
```

## 🐛 Si vous trouvez des bugs

1. Notez le message d'erreur complet
2. Identifiez quel test échoue
3. Vérifiez le code correspondant dans `met_double_service.dart` ou `met_double_game_screen.dart`
4. Corrigez le bug
5. Relancez les tests pour vérifier

## 📦 Tests créés

### `test/met_double_test.dart` (15 tests)
- Tests unitaires des modèles
- Tests de la logique de jeu de base
- Sérialisation JSON

### `test/met_double_integration_test.dart` (10 tests) ⭐
- **Tests spécifiques pour détecter les anomalies**
- Tests de régression pour les bugs rapportés
- Protection contre race conditions

## 💡 Conseils

1. **Exécutez les tests AVANT chaque commit**
   ```bash
   ./run_tests.sh && git commit
   ```

2. **Exécutez les tests APRÈS chaque modification du code Met Double**
   ```bash
   # Après avoir modifié met_double_service.dart ou met_double_game_screen.dart
   ./run_tests.sh anomalies
   ```

3. **Utilisez les tests comme documentation**
   Les tests montrent comment le jeu doit fonctionner

## ❓ Questions fréquentes

### Pourquoi les tests n'ont-ils pas été exécutés automatiquement ?
Flutter n'est pas installé dans l'environnement de développement distant.

### Combien de temps prennent les tests ?
Environ 1-2 secondes pour tous les tests.

### Que faire si tous les tests passent mais j'ai encore des bugs ?
Il faut créer de nouveaux tests qui reproduisent le bug observé.

### Comment ajouter un nouveau test ?
Ajoutez un nouveau `test('description', () { ... })` dans le fichier approprié.

## 📞 Support

Si vous avez des questions sur les tests ou si vous trouvez des anomalies :
1. Vérifiez les messages d'erreur dans le terminal
2. Relancez avec `--verbose` pour plus de détails
3. Vérifiez le code dans les fichiers concernés
