import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Runtime audio coordinator for the Dawn Rail prototype.
///
/// The production app will replace these bundled assets with a cached
/// `EpisodeAudioPackage` downloaded from the backend. The lifecycle should
/// remain the same:
/// alarm loop + Wake Jolt while ringing, stop on Wake Quest clear, then play
/// cached/generated voice over a bundled score bed.
class WakeSagaAudio {
  WakeSagaAudio._();

  static final WakeSagaAudio instance = WakeSagaAudio._();
  static const _fallbackVoiceAsset = 'assets/audio/episode_voice_sample.mp3';
  static const _fallbackMusicAsset = 'assets/audio/music_beds/dawn_rise.mp3';
  static const _episodeMusicVolume = 0.24;

  AudioPlayer? _alarmLoop;
  AudioPlayer? _wakeJolt;
  AudioPlayer? _questSting;
  AudioPlayer? _episodeVoice;
  AudioPlayer? _episodeMusic;
  StreamSubscription<void>? _episodeVoiceComplete;
  double _currentEpisodeMusicVolume = 0;
  int _episodeFadeToken = 0;

  bool _disabled = false;
  bool _alarmActive = false;

  Future<void> startAlarmJolt() async {
    if (_shouldSkipAudio || _alarmActive) return;
    _alarmActive = true;
    await _run(() async {
      final alarmLoop = _alarmLoopPlayer;
      final wakeJolt = _wakeJoltPlayer;
      await _stopMorningEpisodeNow();
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

  Future<void> playMorningEpisode({
    String? voiceAssetPath,
    String? musicAssetPath,
  }) async {
    await _run(() async {
      final voice = _episodeVoicePlayer;
      final music = _episodeMusicPlayer;
      await _stopMorningEpisodeNow();
      await music.setReleaseMode(ReleaseMode.loop);
      _currentEpisodeMusicVolume = 0;
      await music.play(
        _sourceForPath(musicAssetPath ?? _fallbackMusicAsset),
        volume: 0,
      );
      await voice.setReleaseMode(ReleaseMode.stop);
      await voice.play(
        _sourceForPath(voiceAssetPath ?? _fallbackVoiceAsset),
        volume: 1,
      );
      _episodeVoiceComplete = voice.onPlayerComplete.listen((_) {
        unawaited(_fadeOutAndStopMusic());
      });
      await _fadeMusicTo(
        _episodeMusicVolume,
        duration: const Duration(milliseconds: 1100),
      );
    });
  }

  Future<void> pauseMorningEpisode() async {
    await _run(() async {
      await Future.wait([
        if (_episodeVoice != null) _episodeVoice!.pause(),
        if (_episodeMusic != null) _episodeMusic!.pause(),
      ]);
    });
  }

  Future<void> resumeMorningEpisode() async {
    await _run(() async {
      await Future.wait([
        if (_episodeVoice != null) _episodeVoice!.resume(),
        if (_episodeMusic != null) _episodeMusic!.resume(),
      ]);
    });
  }

  Future<void> stopMorningEpisode() async {
    await _run(() async {
      await _stopMorningEpisodeNow(fadeMusic: true);
    });
  }

  Future<void> dispose() async {
    await _run(() async {
      _cancelEpisodeFade();
      await _episodeVoiceComplete?.cancel();
      await Future.wait([
        if (_alarmLoop != null) _alarmLoop!.dispose(),
        if (_wakeJolt != null) _wakeJolt!.dispose(),
        if (_questSting != null) _questSting!.dispose(),
        if (_episodeVoice != null) _episodeVoice!.dispose(),
        if (_episodeMusic != null) _episodeMusic!.dispose(),
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

  AudioPlayer get _episodeVoicePlayer =>
      _episodeVoice ??= AudioPlayer(playerId: 'wakeSagaEpisodeVoice');

  AudioPlayer get _episodeMusicPlayer =>
      _episodeMusic ??= AudioPlayer(playerId: 'wakeSagaEpisodeMusic');

  Future<void> _stopMorningEpisodeNow({bool fadeMusic = false}) async {
    _cancelEpisodeFade();
    await _episodeVoiceComplete?.cancel();
    _episodeVoiceComplete = null;
    if (fadeMusic) {
      await _fadeMusicTo(0, duration: const Duration(milliseconds: 260));
    }
    await Future.wait([
      if (_episodeVoice != null) _episodeVoice!.stop(),
      if (_episodeMusic != null) _episodeMusic!.stop(),
    ]);
    _currentEpisodeMusicVolume = 0;
  }

  Future<void> _fadeOutAndStopMusic() async {
    if (_shouldSkipAudio) return;
    try {
      await _fadeMusicTo(0, duration: const Duration(milliseconds: 700));
      await _episodeMusic?.stop();
    } on MissingPluginException {
      _disabled = true;
    } on PlatformException {
      _disabled = true;
    }
  }

  Future<void> _fadeMusicTo(
    double targetVolume, {
    required Duration duration,
  }) async {
    final player = _episodeMusic;
    if (player == null) return;
    final token = ++_episodeFadeToken;
    final startVolume = _currentEpisodeMusicVolume;
    const steps = 8;
    final stepDuration = Duration(
      milliseconds: duration.inMilliseconds ~/ steps,
    );
    for (var step = 1; step <= steps; step++) {
      if (token != _episodeFadeToken) return;
      final progress = step / steps;
      final volume = startVolume + ((targetVolume - startVolume) * progress);
      _currentEpisodeMusicVolume = volume;
      await player.setVolume(volume.clamp(0.0, 1.0).toDouble());
      if (step < steps) await Future<void>.delayed(stepDuration);
    }
  }

  void _cancelEpisodeFade() {
    _episodeFadeToken++;
  }

  Source _sourceForPath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return UrlSource(path);
    }
    if (path.startsWith('file://')) {
      return DeviceFileSource(path.substring('file://'.length));
    }
    if (path.startsWith('/')) return DeviceFileSource(path);
    return AssetSource(_assetSourcePath(path));
  }

  String _assetSourcePath(String path) {
    const prefix = 'assets/';
    if (path.startsWith(prefix)) return path.substring(prefix.length);
    return path;
  }
}
