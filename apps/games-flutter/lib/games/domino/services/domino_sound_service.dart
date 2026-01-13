import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service de gestion des sons pour le jeu de dominos
/// Utilise des players temporaires pour chaque son (plus fiable)
class DominoSoundService {
  static final DominoSoundService _instance = DominoSoundService._internal();
  factory DominoSoundService() => _instance;
  DominoSoundService._internal();

  bool _initialized = false;
  bool _soundEnabled = true;

  /// Volume global (0.0 à 1.0)
  double _volume = 0.7;

  /// Getter/Setter pour activer/désactiver les sons
  bool get soundEnabled => _soundEnabled;
  set soundEnabled(bool value) {
    _soundEnabled = value;
  }

  /// Getter/Setter pour le volume
  double get volume => _volume;
  set volume(double value) {
    _volume = value.clamp(0.0, 1.0);
  }

  /// Initialise le service
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (kDebugMode) {
      print('DominoSoundService initialisé');
    }
  }

  /// Joue le son de placement d'un domino
  Future<void> playPlace() async {
    await _playSound('sounds/domino/place_tile.mp3');
  }

  /// Joue le son quand un joueur passe son tour
  Future<void> playPass() async {
    await _playSound('sounds/domino/pass_turn.mp3');
  }

  /// Joue le son de victoire de manche
  Future<void> playRoundWin() async {
    await _playSound('sounds/domino/game_win.mp3');
  }

  /// Joue le son de victoire finale (3 manches)
  Future<void> playVictory() async {
    await _playSound('sounds/domino/game_win.mp3');
  }

  /// Joue le son de chirée (match nul)
  Future<void> playChiree() async {
    await _playSound('sounds/domino/pass_turn.mp3');
  }

  /// Joue un son avec un player temporaire (plus fiable)
  Future<void> _playSound(String assetPath) async {
    if (!_soundEnabled) return;

    try {
      final player = AudioPlayer();
      await player.setVolume(_volume);
      await player.setReleaseMode(ReleaseMode.release);

      // Jouer le son
      await player.play(AssetSource(assetPath));

      // Dispose automatique après la lecture
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });

      // Fallback: dispose après 5 secondes max
      Future.delayed(const Duration(seconds: 5), () {
        player.dispose();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lecture son $assetPath: $e');
      }
    }
  }

  /// Libère les ressources (rien à faire avec les players temporaires)
  void dispose() {
    _initialized = false;
  }
}
