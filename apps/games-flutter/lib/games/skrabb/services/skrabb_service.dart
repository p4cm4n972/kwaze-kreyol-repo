import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../models/skrabb_game.dart';

/// Service pour gérer les parties Skrabb dans Supabase
class SkrabbService {
  final SupabaseClient _supabase = SupabaseService.client;

  /// Crée une nouvelle partie dans Supabase
  Future<SkrabbGame> createGame(SkrabbGame game) async {
    try {
      final data = await _supabase
          .from('skrabb_games')
          .insert(game.toJson())
          .select()
          .single();

      return SkrabbGame.fromJson(data);
    } catch (e) {
      throw Exception('Erreur lors de la création de la partie: $e');
    }
  }

  /// Sauvegarde la progression de la partie
  Future<void> saveGameProgress({
    required String gameId,
    required Map<String, dynamic> boardData,
    required List<Map<String, dynamic>> rack,
    required List<Map<String, dynamic>> tileBag,
    required List<Map<String, dynamic>> moveHistory,
    required int score,
    required int timeElapsed,
  }) async {
    try {
      await _supabase.from('skrabb_games').update({
        'board_data': boardData,
        'rack': rack,
        'tile_bag': tileBag,
        'move_history': moveHistory,
        'score': score,
        'time_elapsed': timeElapsed,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', gameId);
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  /// Termine une partie (marque comme completed)
  Future<void> completeGame({
    required String gameId,
    required Map<String, dynamic> boardData,
    required List<Map<String, dynamic>> rack,
    required List<Map<String, dynamic>> tileBag,
    required List<Map<String, dynamic>> moveHistory,
    required int score,
    required int timeElapsed,
  }) async {
    try {
      await _supabase.from('skrabb_games').update({
        'status': 'completed',
        'board_data': boardData,
        'rack': rack,
        'tile_bag': tileBag,
        'move_history': moveHistory,
        'score': score,
        'time_elapsed': timeElapsed,
        'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', gameId);
    } catch (e) {
      throw Exception('Erreur lors de la finalisation: $e');
    }
  }

  /// Charge la partie en cours de l'utilisateur (si elle existe)
  Future<SkrabbGame?> loadInProgressGame() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final data = await _supabase
          .from('skrabb_games')
          .select()
          .eq('user_id', userId)
          .eq('status', 'in_progress')
          .maybeSingle();

      if (data == null) return null;

      return SkrabbGame.fromJson(data);
    } catch (e) {
      throw Exception('Erreur lors du chargement: $e');
    }
  }

  /// Charge une partie spécifique par son ID
  Future<SkrabbGame?> loadGameById(String gameId) async {
    try {
      final data = await _supabase
          .from('skrabb_games')
          .select()
          .eq('id', gameId)
          .maybeSingle();

      if (data == null) return null;

      return SkrabbGame.fromJson(data);
    } catch (e) {
      throw Exception('Erreur lors du chargement de la partie: $e');
    }
  }

  /// Abandonne une partie (marque comme abandoned)
  Future<void> abandonGame(String gameId) async {
    try {
      await _supabase.from('skrabb_games').update({
        'status': 'abandoned',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', gameId);
    } catch (e) {
      throw Exception('Erreur lors de l\'abandon: $e');
    }
  }

  /// Supprime une partie
  Future<void> deleteGame(String gameId) async {
    try {
      await _supabase.from('skrabb_games').delete().eq('id', gameId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  /// Récupère le classement (top scores)
  Future<List<SkrabbLeaderboardEntry>> getLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final data = await _supabase.rpc(
        'get_skrabb_leaderboard',
        params: {
          'limit_count': limit,
          'offset_count': offset,
        },
      ) as List;

      return data
          .map((entry) => SkrabbLeaderboardEntry.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement du classement: $e');
    }
  }

  /// Récupère les statistiques d'un joueur
  Future<SkrabbPlayerStats> getPlayerStats([String? userId]) async {
    try {
      final playerId = userId ?? _supabase.auth.currentUser?.id;
      if (playerId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final data = await _supabase.rpc(
        'get_skrabb_player_stats',
        params: {'player_id': playerId},
      ) as Map<String, dynamic>;

      return SkrabbPlayerStats.fromJson(data);
    } catch (e) {
      throw Exception('Erreur lors du chargement des statistiques: $e');
    }
  }

  /// Récupère le rang d'un joueur dans le classement
  Future<int?> getPlayerRank([String? userId]) async {
    try {
      final playerId = userId ?? _supabase.auth.currentUser?.id;
      if (playerId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Récupérer le meilleur score du joueur
      final bestGame = await _supabase
          .from('skrabb_games')
          .select('score')
          .eq('user_id', playerId)
          .eq('status', 'completed')
          .order('score', ascending: false)
          .order('time_elapsed', ascending: true)
          .limit(1)
          .maybeSingle();

      if (bestGame == null) return null;

      final bestScore = bestGame['score'] as int;

      // Compter combien de joueurs ont un meilleur score
      final result = await _supabase.rpc(
        'get_skrabb_player_rank',
        params: {
          'player_id': playerId,
          'player_score': bestScore,
        },
      ) as int;

      return result;
    } catch (e) {
      // Si le joueur n'a aucune partie complétée, retourner null
      return null;
    }
  }

  /// Récupère toutes les parties d'un utilisateur
  Future<List<SkrabbGame>> getUserGames({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final data = status != null
          ? await _supabase
              .from('skrabb_games')
              .select()
              .eq('user_id', userId)
              .eq('status', status)
              .order('created_at', ascending: false)
              .limit(limit)
              .range(offset, offset + limit - 1) as List
          : await _supabase
              .from('skrabb_games')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(limit)
              .range(offset, offset + limit - 1) as List;

      return data
          .map((game) => SkrabbGame.fromJson(game as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des parties: $e');
    }
  }
}
