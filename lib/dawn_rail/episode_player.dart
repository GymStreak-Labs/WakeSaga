import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/ink_signal.dart';
import '../widgets/cuts.dart';
import '../widgets/screentone.dart';
import 'card_mint.dart';

/// Dawn Rail step 4 — the Morning Episode player.
/// Audio is SIMULATED: a line timer stands in for narrated playback.
/// Narrator block, line-by-line subtitles (current white, past 35%),
/// big play/pause, SKIP visible from second zero, "Short" chip.
class EpisodePlayer extends StatefulWidget {
  const EpisodePlayer({super.key, this.replay = false});

  /// When true (Today-tab replay), finishing pops back instead of minting.
  final bool replay;

  @override
  State<EpisodePlayer> createState() => _EpisodePlayerState();
}

class _EpisodePlayerState extends State<EpisodePlayer> {
  static const _lineDuration = Duration(milliseconds: 2400);

  late final List<String> _lines;
  int _current = 0;
  bool _playing = true;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    final state = AppScope.of(context, listen: false);
    final ep = widget.replay ? state.episodeCount : state.nextEpisode;
    final mission = state.missionText.isEmpty
        ? 'hold the line until tonight'
        : state.missionText;
    _lines = [
      '${state.userName}. Episode $ep. You actually stood up.',
      'Yesterday is filed. Today is being written.',
      'The mission: $mission.',
      'Nobody is coming to do it for you.',
      'Go. The episode is live.',
    ];
    _armTicker();
  }

  void _armTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(_lineDuration, (_) => _tick());
  }

  void _tick() {
    if (!_playing) return;
    if (_current >= _lines.length - 1) {
      _finish();
      return;
    }
    setState(() => _current++);
  }

  void _togglePlay() {
    HapticFeedback.selectionClick();
    setState(() => _playing = !_playing);
  }

  void _short() {
    // 20s Short Mode: jump straight to the last two lines.
    HapticFeedback.selectionClick();
    setState(() => _current = (_lines.length - 2).clamp(0, _lines.length - 1));
  }

  void _finish() {
    _ticker?.cancel();
    if (!mounted) return;
    if (widget.replay) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).push(
      hardCut(const SmashCutFlash(child: CardMint())),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return PopScope(
      canPop: widget.replay,
      child: Scaffold(
        backgroundColor: InkSignal.base,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _NarratorBlock(narrator: state.narrator, playing: _playing),
                const SizedBox(height: 28),
                // Subtitle list, lower-third style: current line white,
                // past lines at 35%, future lines barely there.
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _lines.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: StrokedSubtitle(
                            _lines[i],
                            size: i == _current ? 20 : 17,
                            opacity: i == _current
                                ? 1
                                : i < _current
                                    ? 0.35
                                    : 0.12,
                          ),
                        ),
                    ],
                  ),
                ),
                // Transport: play/pause is the screen's one crimson element.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      key: const Key('shortChip'),
                      onTap: _short,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: InkSignal.panel(),
                        child: Text(
                          'Short',
                          style: InkSignal.ui(17, weight: FontWeight.w700),
                        ),
                      ),
                    ),
                    GestureDetector(
                      key: const Key('playPause'),
                      onTap: _togglePlay,
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: InkSignal.crimson,
                        ),
                        child: Icon(
                          _playing ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                    // SKIP: dim but present from second zero. Never punishes.
                    GestureDetector(
                      key: const Key('skipButton'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _finish,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        child: Opacity(
                          opacity: 0.4,
                          child: Text(
                            'SKIP',
                            style: InkSignal.ui(
                              17,
                              weight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NarratorBlock extends StatelessWidget {
  const _NarratorBlock({required this.narrator, required this.playing});

  final String narrator;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: InkSignal.panel(),
      child: Row(
        children: [
          // Flat-cel portrait placeholder (commissioned art later).
          Container(
            width: 64,
            height: 64,
            decoration: InkSignal.panel(
              color: const Color(0xFF21293A),
              borderColor: InkSignal.paper,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: ScreentonePainter(opacity: 0.1)),
                Center(
                  child: Text(
                    narrator.substring(0, 1).toUpperCase(),
                    style: InkSignal.display(34),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  narrator.toUpperCase(),
                  style: InkSignal.ui(
                    17,
                    weight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                // Static waveform placeholder (paper-white; gold is rationed).
                Row(
                  children: [
                    for (var i = 0; i < 24; i++)
                      Container(
                        width: 3,
                        height: playing ? (6 + (i * 7) % 18).toDouble() : 4,
                        margin: const EdgeInsets.only(right: 3),
                        color: InkSignal.paper
                            .withValues(alpha: playing ? 0.7 : 0.25),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            playing ? 'PLAYING' : 'PAUSED',
            style: InkSignal.mono(
              12,
              color: InkSignal.paper.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
