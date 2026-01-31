import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// Provides a single point of control for audio playback across the app,
/// encapsulating player lifecycle management and audio session configuration.
class AudioPlaybackService {
  AudioPlaybackService._(this._player);

  final AudioPlayer _player;

  static Future<AudioPlaybackService> create() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    final player = AudioPlayer();
    return AudioPlaybackService._(player);
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration?> get bufferedPositionStream => _player.bufferedPositionStream;

  Future<void> loadFile(File file, {bool preload = true}) async {
    final source = AudioSource.uri(Uri.file(file.path));
    if (preload) {
      await _player.setAudioSource(source);
    } else {
      unawaited(_player.setAudioSource(source));
    }
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setVolume(double volume) => _player.setVolume(volume.clamp(0, 1));
  Future<void> setSpeed(double speed) => _player.setSpeed(speed.clamp(0.5, 2.0));

  Future<void> dispose() => _player.dispose();
}
