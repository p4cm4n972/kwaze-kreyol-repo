import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../models/dictionary_word.dart';

class TranslatorService {
  final SupabaseClient _supabase = SupabaseService.client;

  // Rechercher un mot dans le dictionnaire
  Future<List<DictionaryWord>> searchWord({
    required String query,
    String? language, // 'creole' ou 'francais'
  }) async {
    try {
      var queryBuilder = _supabase
          .from('dictionary_words')
          .select()
          .ilike('word', '%$query%');

      if (language != null) {
        queryBuilder = queryBuilder.eq('language', language);
      }

      final response = await queryBuilder
          .eq('is_official', true)
          .order('word', ascending: true)
          .limit(20);

      return (response as List)
          .map((json) => DictionaryWord.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Récupérer un mot spécifique par ID
  Future<DictionaryWord?> getWordById(String wordId) async {
    try {
      final response = await _supabase
          .from('dictionary_words')
          .select()
          .eq('id', wordId)
          .maybeSingle();

      if (response != null) {
        return DictionaryWord.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du mot: $e');
    }
  }

  // Traduire un mot (chercher dans une direction)
  Future<List<DictionaryWord>> translateWord({
    required String word,
    required String fromLanguage, // 'creole' ou 'francais'
  }) async {
    try {
      final response = await _supabase
          .from('dictionary_words')
          .select()
          .eq('word', word)
          .eq('language', fromLanguage)
          .eq('is_official', true);

      return (response as List)
          .map((json) => DictionaryWord.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la traduction: $e');
    }
  }

  // Soumettre une contribution au dictionnaire
  Future<DictionaryContribution> submitContribution({
    required String userId,
    required String word,
    required String translation,
    String? nature,
    String? example,
  }) async {
    try {
      final response = await _supabase
          .from('dictionary_contributions')
          .insert({
            'user_id': userId,
            'word': word,
            'translation': translation,
            'nature': nature,
            'example': example,
            'status': 'pending',
            'submitted_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return DictionaryContribution.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la soumission de la contribution: $e');
    }
  }

  // Récupérer les contributions d'un utilisateur
  Future<List<DictionaryContribution>> getUserContributions(
      String userId) async {
    try {
      final response = await _supabase
          .from('dictionary_contributions')
          .select()
          .eq('user_id', userId)
          .order('submitted_at', ascending: false);

      return (response as List)
          .map((json) => DictionaryContribution.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des contributions: $e');
    }
  }

  // Récupérer toutes les contributions en attente (pour modération)
  Future<List<DictionaryContribution>> getPendingContributions() async {
    try {
      final response = await _supabase
          .from('dictionary_contributions')
          .select()
          .eq('status', 'pending')
          .order('submitted_at', ascending: true);

      return (response as List)
          .map((json) => DictionaryContribution.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des contributions en attente: $e');
    }
  }

  // Obtenir des suggestions de mots (mots qui commencent par...)
  Future<List<DictionaryWord>> getSuggestions({
    required String prefix,
    String? language,
    int limit = 10,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('dictionary_words')
          .select()
          .ilike('word', '$prefix%');

      if (language != null) {
        queryBuilder = queryBuilder.eq('language', language);
      }

      final response = await queryBuilder
          .eq('is_official', true)
          .order('word', ascending: true)
          .limit(limit);

      return (response as List)
          .map((json) => DictionaryWord.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des suggestions: $e');
    }
  }

  // Récupérer les mots par nature grammaticale
  Future<List<DictionaryWord>> getWordsByNature({
    required String nature,
    String? language,
  }) async {
    try {
      var queryBuilder =
          _supabase.from('dictionary_words').select().eq('nature', nature);

      if (language != null) {
        queryBuilder = queryBuilder.eq('language', language);
      }

      final response = await queryBuilder
          .eq('is_official', true)
          .order('word', ascending: true);

      return (response as List)
          .map((json) => DictionaryWord.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des mots: $e');
    }
  }

  // Récupérer un mot aléatoire (mot du jour)
  Future<DictionaryWord?> getRandomWord({String? language}) async {
    try {
      var queryBuilder = _supabase.from('dictionary_words').select();

      if (language != null) {
        queryBuilder = queryBuilder.eq('language', language);
      }

      // Utiliser une fonction PostgreSQL pour obtenir un mot aléatoire
      final response = await _supabase.rpc('get_random_word', params: {
        if (language != null) 'p_language': language,
      });

      if (response != null) {
        return DictionaryWord.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du mot aléatoire: $e');
    }
  }

  // Compter le nombre de mots dans le dictionnaire
  Future<int> getWordCount({String? language}) async {
    try {
      var queryBuilder = _supabase
          .from('dictionary_words')
          .select('id', const FetchOptions(count: CountOption.exact));

      if (language != null) {
        queryBuilder = queryBuilder.eq('language', language);
      }

      final response =
          await queryBuilder.eq('is_official', true).count(CountOption.exact);

      return response.count;
    } catch (e) {
      throw Exception('Erreur lors du comptage des mots: $e');
    }
  }
}
