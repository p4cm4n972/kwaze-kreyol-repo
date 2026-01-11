import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service de sons pour Mo Mawon
class MotsMawonSoundService {
  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;
  bool _soundEnabled = false; // Désactivé pour l'instant - en attente de sons dédiés

  /// Initialise le service audio
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _player.setVolume(0.5);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Erreur initialisation audio: $e');
    }
  }

  /// Active/désactive les sons
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Joue le son de sélection de cellule
  Future<void> playSelect() async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource('sounds/domino/place_tile.mp3'));
    } catch (e) {
      debugPrint('Erreur son select: $e');
    }
  }

  /// Joue le son quand un mot est trouvé
  Future<void> playWordFound() async {
    if (!_soundEnabled) return;
    try {
      await _player.setVolume(0.7);
      await _player.play(AssetSource('sounds/domino/game_win.mp3'));
    } catch (e) {
      debugPrint('Erreur son word found: $e');
    }
  }

  /// Joue le son d'erreur (mot invalide)
  Future<void> playError() async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource('sounds/domino/pass_turn.mp3'));
    } catch (e) {
      debugPrint('Erreur son error: $e');
    }
  }

  /// Joue le son de victoire (tous les mots trouvés)
  Future<void> playVictory() async {
    if (!_soundEnabled) return;
    try {
      await _player.setVolume(1.0);
      await _player.play(AssetSource('sounds/tambour_intro_2s.mp3'));
    } catch (e) {
      debugPrint('Erreur son victory: $e');
    }
  }

  /// Libère les ressources
  void dispose() {
    _player.dispose();
  }
}
