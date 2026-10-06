import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  Future<void> playBackgroundMusic() async {
    if (_isPlaying) return;
    try {
      await _player.setSource(AssetSource('audio/game_music.wav'));
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.resume();
      _isPlaying = true;
    } catch (e) {
      debugPrint("Audio Playback Error: $e");
    }
  }

  // Smoothly fade out the volume over 1 second
  Future<void> fadeOutMusic() async {
    if (!_isPlaying) return;
    try {
      for (double vol = 1.0; vol >= 0.0; vol -= 0.1) {
        await _player.setVolume(vol);
        await Future.delayed(const Duration(milliseconds: 100));
      }
      await _player.stop();
      _isPlaying = false;
      await _player.setVolume(1.0); // Reset volume for next time
    } catch (e) {
      debugPrint("Fade Out Error: $e");
    }
  }

  void stopMusic() {
    _player.stop();
    _isPlaying = false;
  }

  void dispose() {
    _player.dispose();
  }
}