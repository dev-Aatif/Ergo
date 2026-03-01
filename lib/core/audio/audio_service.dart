import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  // We play the audio in "Low Latency" mode by default,
  // which works well for short sound effects.

  Future<void> playCorrect() async {
    await _player.play(AssetSource('audio/correct-answer.mp3'));
  }

  Future<void> playIncorrect() async {
    await _player.play(AssetSource('audio/wrong-answer.mp3'));
  }

  Future<void> playLevelUp() async {
    await _player.play(AssetSource('audio/level-up.mp3'));
  }

  Future<void> playFanfare() async {
    await _player.play(AssetSource('audio/fanfare.mp3'));
  }

  Future<void> playMagicalStreak() async {
    await _player.play(AssetSource('audio/magical-streak.mp3'));
  }

  Future<void> playClick() async {
    await _player.play(AssetSource('audio/click.mp3'));
  }
}
