import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseService.client;
  static const String _guestNameKey = 'guest_name';
  static const String _isGuestKey = 'is_guest';

  // Inscription avec email/mot de passe
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (response.user != null) {
        // Le profil utilisateur est créé automatiquement par le trigger PostgreSQL
        // On retourne les infos de base sans interroger la table users
        return AppUser.fromJson({
          'id': response.user!.id,
          'email': email,
          'username': username ?? '',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  // Connexion avec email/mot de passe
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Récupérer les infos de l'utilisateur
        final userData = await _supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        // Désactiver le mode invité si activé
        await _clearGuestMode();

        return AppUser.fromJson(userData);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  // Mode invité - stocke le nom localement
  Future<String> signInAsGuest(String guestName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_guestNameKey, guestName);
      await prefs.setBool(_isGuestKey, true);
      return guestName;
    } catch (e) {
      throw Exception('Erreur lors de la connexion en invité: $e');
    }
  }

  // Vérifier si en mode invité
  Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isGuestKey) ?? false;
  }

  // Récupérer le nom d'invité
  Future<String?> getGuestName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_guestNameKey);
  }

  // Effacer le mode invité
  Future<void> _clearGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestNameKey);
    await prefs.remove(_isGuestKey);
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await _clearGuestMode();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  // Récupérer l'utilisateur actuel
  Future<AppUser?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final userData =
          await _supabase.from('users').select().eq('id', user.id).single();
      return AppUser.fromJson(userData);
    }
    return null;
  }

  // Vérifier si l'utilisateur est connecté (mode normal ou invité)
  Future<bool> isAuthenticated() async {
    final hasUser = _supabase.auth.currentUser != null;
    final isGuest = await isGuestMode();
    return hasUser || isGuest;
  }

  // Obtenir l'ID pour les opérations (user_id ou null si invité)
  String? getUserIdOrNull() {
    return _supabase.auth.currentUser?.id;
  }

  // Stream des changements d'authentification
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
