import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';

/// Service pour valider les mots contre le dictionnaire créole
class WordValidator {
  final SupabaseClient _supabase = SupabaseService.client;

  // Cache des mots validés durant la session
  final Map<String, bool> _validationCache = {};

  /// Valide si un mot existe dans le dictionnaire créole officiel
  Future<bool> isValidWord(String word) async {
    if (word.isEmpty) return false;

    final normalizedWord = word.toLowerCase().trim();

    // Vérifier le cache d'abord
    if (_validationCache.containsKey(normalizedWord)) {
      return _validationCache[normalizedWord]!;
    }

    try {
      final result = await _supabase
          .from('dictionary_words')
          .select('id')
          .eq('word', normalizedWord)
          .eq('language', 'creole')
          .eq('is_official', true)
          .maybeSingle();

      final isValid = result != null;

      // Mettre en cache le résultat
      _validationCache[normalizedWord] = isValid;

      return isValid;
    } catch (e) {
      // En cas d'erreur réseau, on ne met pas en cache
      throw Exception('Erreur lors de la validation du mot "$word": $e');
    }
  }

  /// Valide plusieurs mots en une seule requête (batch)
  /// Retourne un Map avec le résultat pour chaque mot
  Future<Map<String, bool>> validateWords(List<String> words) async {
    if (words.isEmpty) return {};

    final results = <String, bool>{};
    final wordsToCheck = <String>[];

    // Séparer les mots en cache et ceux à vérifier
    for (final word in words) {
      final normalizedWord = word.toLowerCase().trim();
      if (_validationCache.containsKey(normalizedWord)) {
        results[word] = _validationCache[normalizedWord]!;
      } else {
        wordsToCheck.add(normalizedWord);
      }
    }

    // Si tous les mots sont en cache, retourner directement
    if (wordsToCheck.isEmpty) return results;

    try {
      final data = await _supabase
          .from('dictionary_words')
          .select('word')
          .inFilter('word', wordsToCheck)
          .eq('language', 'creole')
          .eq('is_official', true) as List;

      final validWords = data.map((row) => row['word'] as String).toSet();

      // Construire les résultats et mettre en cache
      for (final word in words) {
        final normalizedWord = word.toLowerCase().trim();
        if (!results.containsKey(word)) {
          final isValid = validWords.contains(normalizedWord);
          results[word] = isValid;
          _validationCache[normalizedWord] = isValid;
        }
      }

      return results;
    } catch (e) {
      throw Exception('Erreur lors de la validation des mots: $e');
    }
  }

  /// Valide une liste de mots et retourne seulement ceux qui sont invalides
  /// Utile pour afficher les erreurs à l'utilisateur
  Future<List<String>> getInvalidWords(List<String> words) async {
    final results = await validateWords(words);
    return results.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Valide une liste de mots et vérifie que TOUS sont valides
  Future<bool> areAllWordsValid(List<String> words) async {
    if (words.isEmpty) return false;

    final results = await validateWords(words);
    return results.values.every((isValid) => isValid);
  }

  /// Vide le cache de validation
  /// Utile si le dictionnaire est mis à jour pendant le jeu
  void clearCache() {
    _validationCache.clear();
  }

  /// Retourne le nombre de mots en cache
  int get cacheSize => _validationCache.length;

  /// Recherche des suggestions de mots similaires (pour aide)
  /// Utilise la similarité trigram de PostgreSQL
  Future<List<String>> findSimilarWords(String word, {int limit = 5}) async {
    if (word.isEmpty || word.length < 3) return [];

    try {
      final data = await _supabase
          .from('dictionary_words')
          .select('word')
          .eq('language', 'creole')
          .eq('is_official', true)
          .textSearch('word', word, config: 'french')
          .limit(limit) as List;

      return data.map((row) => row['word'] as String).toList();
    } catch (e) {
      // Fallback: chercher par préfixe si la recherche trigram échoue
      try {
        final data = await _supabase
            .from('dictionary_words')
            .select('word')
            .eq('language', 'creole')
            .eq('is_official', true)
            .ilike('word', '$word%')
            .limit(limit) as List;

        return data.map((row) => row['word'] as String).toList();
      } catch (e2) {
        return [];
      }
    }
  }

  /// Compte le nombre total de mots créoles officiels dans le dictionnaire
  Future<int> getTotalWordsCount() async {
    try {
      final response = await _supabase
          .from('dictionary_words')
          .select('id')
          .eq('language', 'creole')
          .eq('is_official', true)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      return 0;
    }
  }
}
