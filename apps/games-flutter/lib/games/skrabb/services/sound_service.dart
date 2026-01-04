import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer les sons et la musique du jeu Skrabb
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  bool _soundEnabled = true;
  bool _musicEnabled = false;
  bool _initialized = false;

  static const String _soundEnabledKey = 'skrabb_sound_enabled';
  static const String _musicEnabledKey = 'skrabb_music_enabled';

  /// Initialise le service audio
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
      _musicEnabled = prefs.getBool(_musicEnabledKey) ?? false;

      // Configuration du player de musique pour boucler
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.3);

      _initialized = true;
    } catch (e) {
      // Gérer gracieusement l'erreur
      _initialized = true;
    }
  }

  /// Active/désactive les effets sonores
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  /// Active/désactive la musique
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicEnabledKey, enabled);

    if (!enabled) {
      await _musicPlayer.stop();
    } else {
      await playMusic();
    }
  }

  /// Joue un son de placement de tuile
  Future<void> playTilePlacement() async {
    if (!_soundEnabled) return;
    await _playSound('tile_place.mp3', volume: 0.4);
  }

  /// Joue un son de validation
  Future<void> playValidation() async {
    if (!_soundEnabled) return;
    await _playSound('validate.mp3', volume: 0.5);
  }

  /// Joue un son d'erreur
  Future<void> playError() async {
    if (!_soundEnabled) return;
    await _playSound('error.mp3', volume: 0.3);
  }

  /// Joue un son de victoire
  Future<void> playVictory() async {
    if (!_soundEnabled) return;
    await _playSound('victory.mp3', volume: 0.6);
  }

  /// Joue un son de shuffle
  Future<void> playShuffle() async {
    if (!_soundEnabled) return;
    await _playSound('shuffle.mp3', volume: 0.3);
  }

  /// Joue un son d'annulation
  Future<void> playUndo() async {
    if (!_soundEnabled) return;
    await _playSound('undo.mp3', volume: 0.3);
  }

  /// Joue la musique de fond
  Future<void> playMusic() async {
    if (!_musicEnabled) return;

    try {
      await _musicPlayer.play(AssetSource('sounds/background_music.mp3'));
    } catch (e) {
      // Gérer gracieusement si le fichier n'existe pas
    }
  }

  /// Arrête la musique de fond
  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }

  /// Joue un son depuis les assets
  Future<void> _playSound(String filename, {double volume = 0.5}) async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(volume);
      await _sfxPlayer.play(AssetSource('sounds/$filename'));
    } catch (e) {
      // Gérer gracieusement si le fichier n'existe pas
      // Ne rien faire, le jeu continue sans son
    }
  }

  /// Libère les ressources audio
  Future<void> dispose() async {
    await _sfxPlayer.dispose();
    await _musicPlayer.dispose();
  }

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
}
