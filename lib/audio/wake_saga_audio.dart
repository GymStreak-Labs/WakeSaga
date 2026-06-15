import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Runtime audio coordinator for the Dawn Rail prototype.
///
/// The production app will replace these bundled assets with a cached
/// `EpisodeAudioPackage` downloaded from the backend. The lifecycle should
/// remain the same:
/// alarm loop + Wake Jolt while ringing, stop on Wake Quest clear, then play
/// the scored Morning Episode.
class WakeSagaAudio {
  WakeSagaAudio._();

  static final WakeSagaAudio instance = WakeSagaAudio._();

  AudioPlayer? _alarmLoop;
  AudioPlayer? _wakeJolt;
  AudioPlayer? _questSting;
  AudioPlayer? _episode;

  bool _disabled = false;
  bool _alarmActive = false;

  Future<void> startAlarmJolt() async {
    if (_shouldSkipAudio || _alarmActive) return;
    _alarmActive = true;
    await _run(() async {
      final episode = _episodePlayer;
      final alarmLoop = _alarmLoopPlayer;
      final wakeJolt = _wakeJoltPlayer;
      await episode.stop();
      await alarmLoop.setReleaseMode(ReleaseMode.loop);
      await alarmLoop.play(
        AssetSource('audio/alarm_pulse_loop.mp3'),
        volume: 0.72,
      );
      await wakeJolt.setReleaseMode(ReleaseMode.stop);
      await wakeJolt.play(
        AssetSource('audio/wake_jolt_forceful.mp3'),
        volume: 1,
      );
    });
  }

  Future<void> stopAlarm() async {
    _alarmActive = false;
    await _run(() async {
      await Future.wait([
        if (_alarmLoop != null) _alarmLoop!.stop(),
        if (_wakeJolt != null) _wakeJolt!.stop(),
      ]);
    });
  }

  Future<void> markQuestCleared() async {
    await stopAlarm();
    await _run(() async {
      final questSting = _questStingPlayer;
      await questSting.stop();
      await questSting.setReleaseMode(ReleaseMode.stop);
      await questSting.play(
        AssetSource('audio/quest_clear_sting.mp3'),
        volume: 0.85,
      );
    });
  }

  Future<void> playMorningEpisode() async {
    await _run(() async {
      final episode = _episodePlayer;
      await episode.stop();
      await episode.setReleaseMode(ReleaseMode.stop);
      await episode.play(
        AssetSource('audio/morning_episode_scored.mp3'),
        volume: 1,
      );
    });
  }

  Future<void> pauseMorningEpisode() async {
    await _run(() async {
      await _episode?.pause();
    });
  }

  Future<void> resumeMorningEpisode() async {
    await _run(() async {
      await _episode?.resume();
    });
  }

  Future<void> stopMorningEpisode() async {
    await _run(() async {
      await _episode?.stop();
    });
  }

  Future<void> dispose() async {
    await _run(() async {
      await Future.wait([
        if (_alarmLoop != null) _alarmLoop!.dispose(),
        if (_wakeJolt != null) _wakeJolt!.dispose(),
        if (_questSting != null) _questSting!.dispose(),
        if (_episode != null) _episode!.dispose(),
      ]);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_shouldSkipAudio) return;
    try {
      await action();
    } on MissingPluginException {
      // Widget tests and unsupported hosts should keep rendering without audio.
      _disabled = true;
      _alarmActive = false;
    } on PlatformException {
      _disabled = true;
      _alarmActive = false;
    }
  }

  bool get _shouldSkipAudio {
    if (_disabled) return true;
    final bindingType = WidgetsBinding.instance.runtimeType.toString();
    return bindingType.contains('TestWidgetsFlutterBinding') ||
        bindingType.contains('AutomatedTestWidgetsFlutterBinding');
  }

  AudioPlayer get _alarmLoopPlayer =>
      _alarmLoop ??= AudioPlayer(playerId: 'wakeSagaAlarmLoop');

  AudioPlayer get _wakeJoltPlayer =>
      _wakeJolt ??= AudioPlayer(playerId: 'wakeSagaWakeJolt');

  AudioPlayer get _questStingPlayer =>
      _questSting ??= AudioPlayer(playerId: 'wakeSagaQuestSting');

  AudioPlayer get _episodePlayer =>
      _episode ??= AudioPlayer(playerId: 'wakeSagaEpisode');
}
