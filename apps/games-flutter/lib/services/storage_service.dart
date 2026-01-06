import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class StorageService {
  final SupabaseClient _supabase = SupabaseService.client;
  static const String avatarsBucket = 'avatars';

  /// Upload une image de profil et retourne l'URL publique
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      // Uploader le fichier
      await _supabase.storage.from(avatarsBucket).upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Récupérer l'URL publique
      final publicUrl = _supabase.storage.from(avatarsBucket).getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de l\'image: $e');
    }
  }

  /// Supprime l'ancienne photo de profil
  Future<void> deleteAvatar(String avatarUrl) async {
    try {
      // Extraire le chemin du fichier depuis l'URL
      final uri = Uri.parse(avatarUrl);
      final path = uri.pathSegments.last;

      await _supabase.storage.from(avatarsBucket).remove([path]);
    } catch (e) {
      // Silently fail - l'ancienne image peut ne pas exister
      debugPrint('Erreur lors de la suppression de l\'avatar: $e');
    }
  }

  /// Met à jour l'URL de l'avatar dans la base de données
  Future<void> updateUserAvatar({
    required String userId,
    required String avatarUrl,
  }) async {
    try {
      await _supabase.from('users').update({
        'avatar_url': avatarUrl,
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'avatar: $e');
    }
  }
}
