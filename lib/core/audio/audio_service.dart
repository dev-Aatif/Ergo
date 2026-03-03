import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

class AudioService {
  late final AudioPlayer _correctPlayer;
  late final AudioPlayer _incorrectPlayer;
  late final AudioPlayer _fanfarePlayer;
  late final AudioPlayer _clickPlayer;
  late final AudioPlayer _streakPlayer;

  AudioService() {
    _initPlayers();
  }

  void _initPlayers() {
    _correctPlayer = AudioPlayer(playerId: 'correct')
      ..setReleaseMode(ReleaseMode.stop);
    _incorrectPlayer = AudioPlayer(playerId: 'incorrect')
      ..setReleaseMode(ReleaseMode.stop);
    _fanfarePlayer = AudioPlayer(playerId: 'fanfare')
      ..setReleaseMode(ReleaseMode.stop);
    _clickPlayer = AudioPlayer(playerId: 'click')
      ..setReleaseMode(ReleaseMode.stop);
    _streakPlayer = AudioPlayer(playerId: 'streak')
      ..setReleaseMode(ReleaseMode.stop);

    // Preload sources for instant playback
    _correctPlayer.setSource(AssetSource('audio/correct-answer.mp3'));
    _incorrectPlayer.setSource(AssetSource('audio/wrong-answer.mp3'));
    _fanfarePlayer.setSource(AssetSource('audio/level-up.mp3'));
    _clickPlayer.setSource(AssetSource('audio/click.mp3'));
    _streakPlayer.setSource(AssetSource('audio/magical-streak.mp3'));
  }

  Future<void> _playFromStart(AudioPlayer player) async {
    try {
      await player.seek(Duration.zero).timeout(
            const Duration(milliseconds: 500),
            onTimeout: () {}, // Silently ignore if seek times out
          );
      await player.resume();
    } catch (_) {
      // Silently ignore audio errors — never block the UI
    }
  }

  Future<void> playCorrect() async => _playFromStart(_correctPlayer);
  Future<void> playIncorrect() async => _playFromStart(_incorrectPlayer);
  Future<void> playLevelUp() async => _playFromStart(_fanfarePlayer);
  Future<void> playMagicalStreak() async => _playFromStart(_streakPlayer);
  Future<void> playClick() async => _playFromStart(_clickPlayer);
}
