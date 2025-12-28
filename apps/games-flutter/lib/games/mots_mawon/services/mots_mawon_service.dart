import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/word.dart';
import '../models/mots_mawon_game.dart';

class MotsMawonService {
  final SupabaseClient _supabase = SupabaseService.client;
  final AuthService _authService = AuthService();

  /// Créer une nouvelle partie
  /// Retourne la partie créée
  Future<MotsMawonGame> createGame(WordSearchGrid gridData) async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Vérifier qu'il n'y a pas déjà une partie en cours
      final existingGame = await loadInProgressGame();
      if (existingGame != null) {
        throw Exception(
          'Vous avez déjà une partie en cours. Terminez-la ou abandonnez-la avant d\'en commencer une nouvelle.',
        );
      }

      final response = await _supabase
          .from('mots_mawon_games')
          .insert({
            'user_id': userId,
            'status': 'in_progress',
            'grid_data': MotsMawonGame.gridToJson(gridData),
            'found_words': [],
            'score': 0,
            'time_elapsed': 0,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return MotsMawonGame.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la création de la partie: $e');
    }
  }

  /// Sauvegarder la progression de la partie
  /// Appelé périodiquement et après chaque mot trouvé
  Future<void> saveGameProgress({
    required String gameId,
    required Set<String> foundWords,
    required int score,
    required int timeElapsed,
  }) async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      await _supabase.from('mots_mawon_games').update({
        'found_words': foundWords.toList(),
        'score': score,
        'time_elapsed': timeElapsed,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', gameId).eq('user_id', userId);
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de la progression: $e');
    }
  }

  /// Terminer une partie (tous les mots trouvés ou abandon)
  /// Retourne la partie complétée
  Future<MotsMawonGame> completeGame({
    required String gameId,
    required Set<String> foundWords,
    required int score,
    required int timeElapsed,
  }) async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await _supabase
          .from('mots_mawon_games')
          .update({
            'status': 'completed',
            'found_words': foundWords.toList(),
            'score': score,
            'time_elapsed': timeElapsed,
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', gameId)
          .eq('user_id', userId)
          .select()
          .single();

      return MotsMawonGame.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la complétion de la partie: $e');
    }
  }

  /// Charger la partie en cours (s'il y en a une)
  /// Retourne null si aucune partie en cours
  Future<MotsMawonGame?> loadInProgressGame() async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await _supabase
          .from('mots_mawon_games')
          .select()
          .eq('user_id', userId)
          .eq('status', 'in_progress')
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return MotsMawonGame.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement de la partie en cours: $e');
    }
  }

  /// Abandonner une partie en cours
  /// Change le statut à 'abandoned'
  Future<void> abandonGame(String gameId) async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      await _supabase
          .from('mots_mawon_games')
          .update({
            'status': 'abandoned',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', gameId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Erreur lors de l\'abandon de la partie: $e');
    }
  }

  /// Récupérer le leaderboard global
  /// limit: nombre d'entrées à récupérer (défaut: 50)
  /// offset: décalage pour la pagination (défaut: 0)
  Future<List<MotsMawonLeaderboardEntry>> getLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_mots_mawon_leaderboard',
        params: {
          'limit_count': limit,
          'offset_count': offset,
        },
      );

      return (response as List)
          .map((json) => MotsMawonLeaderboardEntry.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération du leaderboard: $e');
    }
  }

  /// Récupérer les statistiques du joueur connecté
  /// Retourne des stats vides si aucune partie jouée
  Future<MotsMawonPlayerStats> getPlayerStats() async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await _supabase.rpc(
        'get_mots_mawon_player_stats',
        params: {
          'player_id': userId,
        },
      );

      // Si aucune partie jouée, retourner des stats vides
      if (response == null) {
        return MotsMawonPlayerStats.empty();
      }

      return MotsMawonPlayerStats.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  /// Récupérer l'historique des parties complétées du joueur
  /// limit: nombre de parties à récupérer (défaut: 20)
  /// offset: décalage pour la pagination (défaut: 0)
  Future<List<MotsMawonGame>> getCompletedGames({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await _supabase
          .from('mots_mawon_games')
          .select()
          .eq('user_id', userId)
          .eq('status', 'completed')
          .order('completed_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => MotsMawonGame.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération de l\'historique: $e',
      );
    }
  }

  /// Supprimer une partie (utilisé pour nettoyer les parties abandonnées)
  /// Réservé pour usage admin ou maintenance
  Future<void> deleteGame(String gameId) async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      await _supabase
          .from('mots_mawon_games')
          .delete()
          .eq('id', gameId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la partie: $e');
    }
  }

  /// Récupérer le rang du joueur dans le leaderboard
  /// Retourne null si le joueur n'a pas de partie complétée
  Future<int?> getPlayerRank() async {
    try {
      final userId = _authService.getUserIdOrNull();
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer tout le leaderboard et chercher le joueur
      final leaderboard = await getLeaderboard(limit: 1000);

      final playerEntry = leaderboard.firstWhere(
        (entry) => entry.userId == userId,
        orElse: () => throw Exception('Joueur non trouvé dans le leaderboard'),
      );

      return playerEntry.rank;
    } catch (e) {
      // Le joueur n'est pas dans le leaderboard (aucune partie complétée)
      return null;
    }
  }
}
