import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_stats.dart';
import 'supabase_service.dart';

/// Service pour les opérations du dashboard admin
class AdminService {
  final SupabaseClient _supabase = SupabaseService.client;

  /// Vérifie si l'utilisateur courant est admin
  Future<bool> isCurrentUserAdmin() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();
      return response['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // STATISTIQUES UTILISATEURS
  // ============================================================================

  /// Récupère les statistiques globales des utilisateurs
  Future<AdminUserStats> getUserStats() async {
    try {
      final response = await _supabase.rpc('get_admin_user_stats');
      return AdminUserStats.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des stats utilisateurs: $e');
    }
  }

  /// Récupère l'évolution des inscriptions dans le temps
  Future<List<TimeSeriesDataPoint>> getUsersOverTime({
    String period = 'daily',
    int daysBack = 30,
  }) async {
    try {
      final response = await _supabase.rpc('get_admin_users_over_time', params: {
        'period': period,
        'days_back': daysBack,
      });
      return (response as List)
          .map((e) => TimeSeriesDataPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Récupère les utilisateurs actifs par jeu
  Future<AdminActiveUsers> getActiveUsers({int days = 7}) async {
    try {
      final response = await _supabase.rpc('get_admin_active_users', params: {
        'days': days,
      });
      return AdminActiveUsers.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // ============================================================================
  // STATISTIQUES JEUX
  // ============================================================================

  /// Récupère les statistiques du jeu Domino
  Future<AdminGameStats> getDominoStats() async {
    try {
      final response = await _supabase.rpc('get_admin_domino_stats');
      return AdminGameStats.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Récupère les statistiques du jeu Skrabb
  Future<AdminGameStats> getSkrabbStats() async {
    try {
      final response = await _supabase.rpc('get_admin_skrabb_stats');
      return AdminGameStats.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Récupère les statistiques du jeu Mots Mawon
  Future<AdminGameStats> getMotsMawonStats() async {
    try {
      final response = await _supabase.rpc('get_admin_mots_mawon_stats');
      return AdminGameStats.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Récupère l'évolution des parties Domino dans le temps
  Future<List<TimeSeriesDataPoint>> getDominoOverTime({int daysBack = 30}) async {
    try {
      final response = await _supabase.rpc('get_admin_domino_over_time', params: {
        'days_back': daysBack,
      });
      return (response as List)
          .map((e) => TimeSeriesDataPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Récupère l'évolution des parties Skrabb dans le temps
  Future<List<TimeSeriesDataPoint>> getSkrabbOverTime({int daysBack = 30}) async {
    try {
      final response = await _supabase.rpc('get_admin_skrabb_over_time', params: {
        'days_back': daysBack,
      });
      return (response as List)
          .map((e) => TimeSeriesDataPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Récupère l'évolution des parties Mots Mawon dans le temps
  Future<List<TimeSeriesDataPoint>> getMotsMawonOverTime({int daysBack = 30}) async {
    try {
      final response = await _supabase.rpc('get_admin_mots_mawon_over_time', params: {
        'days_back': daysBack,
      });
      return (response as List)
          .map((e) => TimeSeriesDataPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // ============================================================================
  // TOP JOUEURS
  // ============================================================================

  /// Récupère les meilleurs joueurs Domino
  Future<List<TopPlayerEntry>> getTopDominoPlayers({int limit = 10}) async {
    try {
      final response = await _supabase.rpc('get_admin_top_domino_players', params: {
        'limit_count': limit,
      });
      return (response as List)
          .map((e) => TopPlayerEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Récupère les meilleurs joueurs Skrabb
  Future<List<TopPlayerEntry>> getTopSkrabbPlayers({int limit = 10}) async {
    try {
      final response = await _supabase.rpc('get_admin_top_skrabb_players', params: {
        'limit_count': limit,
      });
      return (response as List)
          .map((e) => TopPlayerEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Récupère les meilleurs joueurs Mots Mawon
  Future<List<TopPlayerEntry>> getTopMotsMawonPlayers({int limit = 10}) async {
    try {
      final response = await _supabase.rpc('get_admin_top_mots_mawon_players', params: {
        'limit_count': limit,
      });
      return (response as List)
          .map((e) => TopPlayerEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }
}
