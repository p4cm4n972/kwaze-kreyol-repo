import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service de gestion des sons pour le jeu de dominos
class DominoSoundService {
  static final DominoSoundService _instance = DominoSoundService._internal();
  factory DominoSoundService() => _instance;
  DominoSoundService._internal();

  // Players pour chaque type de son
  final AudioPlayer _placePlayer = AudioPlayer();
  final AudioPlayer _passPlayer = AudioPlayer();
  final AudioPlayer _roundWinPlayer = AudioPlayer();
  final AudioPlayer _victoryPlayer = AudioPlayer();
  final AudioPlayer _chireePlayer = AudioPlayer();

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
    _updateVolumes();
  }

  void _updateVolumes() {
    _placePlayer.setVolume(_volume);
    _passPlayer.setVolume(_volume);
    _roundWinPlayer.setVolume(_volume);
    _victoryPlayer.setVolume(_volume);
    _chireePlayer.setVolume(_volume);
  }

  /// Initialise le service et précharge les sons
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Configuration des players
      await _placePlayer.setReleaseMode(ReleaseMode.stop);
      await _passPlayer.setReleaseMode(ReleaseMode.stop);
      await _roundWinPlayer.setReleaseMode(ReleaseMode.stop);
      await _victoryPlayer.setReleaseMode(ReleaseMode.stop);
      await _chireePlayer.setReleaseMode(ReleaseMode.stop);

      _updateVolumes();
      _initialized = true;

      if (kDebugMode) {
        print('DominoSoundService initialisé');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur initialisation sons: $e');
      }
    }
  }

  /// Joue le son de placement d'un domino
  Future<void> playPlace() async {
    if (!_soundEnabled) return;
    await _playSound(_placePlayer, 'assets/sounds/domino/place_tile.mp3');
  }

  /// Joue le son quand un joueur passe son tour
  Future<void> playPass() async {
    if (!_soundEnabled) return;
    await _playSound(_passPlayer, 'assets/sounds/domino/pass_turn.mp3');
  }

  /// Joue le son de victoire de manche (utilise game_win pour l'instant)
  Future<void> playRoundWin() async {
    if (!_soundEnabled) return;
    await _playSound(_roundWinPlayer, 'assets/sounds/domino/game_win.mp3');
  }

  /// Joue le son de victoire finale (3 manches)
  Future<void> playVictory() async {
    if (!_soundEnabled) return;
    await _playSound(_victoryPlayer, 'assets/sounds/domino/game_win.mp3');
  }

  /// Joue le son de chirée (match nul) - utilise pass_turn pour l'instant
  Future<void> playChiree() async {
    if (!_soundEnabled) return;
    await _playSound(_chireePlayer, 'assets/sounds/domino/pass_turn.mp3');
  }

  /// Joue un son avec gestion d'erreur
  Future<void> _playSound(AudioPlayer player, String assetPath) async {
    try {
      // Stop sans await pour éviter les blocages
      player.stop();
      // Petit délai pour laisser le stop se faire
      await Future.delayed(const Duration(milliseconds: 50));
      await player.play(AssetSource(assetPath.replaceFirst('assets/', '')));
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lecture son $assetPath: $e');
      }
      // Tentative de fallback: créer un nouveau player temporaire
      try {
        final tempPlayer = AudioPlayer();
        await tempPlayer.setVolume(_volume);
        await tempPlayer.play(AssetSource(assetPath.replaceFirst('assets/', '')));
        // Dispose après la lecture
        tempPlayer.onPlayerComplete.listen((_) => tempPlayer.dispose());
      } catch (_) {}
    }
  }

  /// Libère les ressources
  void dispose() {
    _placePlayer.dispose();
    _passPlayer.dispose();
    _roundWinPlayer.dispose();
    _victoryPlayer.dispose();
    _chireePlayer.dispose();
    _initialized = false;
  }
}
