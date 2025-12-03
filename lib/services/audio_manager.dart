import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  static const String _keyMaster = 'audio_master_volume';
  static const String _keyMusic = 'audio_music_volume';
  static const String _keySfx = 'audio_sfx_volume';

  double masterVolume = 1.0;
  double musicVolume = 1.0;
  double sfxVolume = 1.0;

  AudioPlayer? _currentMusicPlayer;
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    masterVolume = _prefs?.getDouble(_keyMaster) ?? 1.0;
    musicVolume = _prefs?.getDouble(_keyMusic) ?? 1.0;
    sfxVolume = _prefs?.getDouble(_keySfx) ?? 1.0;
  }

  double get effectiveMusicVolume => masterVolume * musicVolume;
  double get effectiveSfxVolume => masterVolume * sfxVolume;

  void setBytesPlayer(AudioPlayer player) {
    _currentMusicPlayer = player;
    _updateActivePlayerVolume();
  }

  void clearCurrentPlayer([AudioPlayer? player]) {
    if (player == null || identical(_currentMusicPlayer, player)) {
      _currentMusicPlayer = null;
    }
  }

  void _updateActivePlayerVolume() {
    if (_currentMusicPlayer != null) {
      try {
        _currentMusicPlayer!.setVolume(effectiveMusicVolume);
      } catch (e) {
        debugPrint('⚠️ AudioManager: No se pudo ajustar volumen (Player disposed o error): $e');
        _currentMusicPlayer = null;
      }
    }
  }

  /// Pause the currently registered music player, if any.
  void pauseCurrent() {
    final p = _currentMusicPlayer;
    if (p != null) {
      try {
        p.pause();
      } catch (_) {}
    }
  }

  /// Resume the currently registered music player, if any.
  void resumeCurrent() {
    final p = _currentMusicPlayer;
    if (p != null) {
      try {
        p.resume();
      } catch (_) {}
    }
  }

  /// Stop the currently registered music player, if any.
  void stopCurrent() {
    final p = _currentMusicPlayer;
    if (p != null) {
      try {
        p.stop();
      } catch (_) {}
    }
  }

  Future<void> setMasterVolume(double value) async {
    masterVolume = value.clamp(0.0, 1.0);
    await _prefs?.setDouble(_keyMaster, masterVolume);
    _updateActivePlayerVolume();
  }

  Future<void> setMusicVolume(double value) async {
    musicVolume = value.clamp(0.0, 1.0);
    await _prefs?.setDouble(_keyMusic, musicVolume);
    _updateActivePlayerVolume();
  }

  Future<void> setSfxVolume(double value) async {
    sfxVolume = value.clamp(0.0, 1.0);
    await _prefs?.setDouble(_keySfx, sfxVolume);
  }
}