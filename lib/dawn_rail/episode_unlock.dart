import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/ink_signal.dart';
import '../widgets/cuts.dart';
import '../widgets/screentone.dart';
import 'title_card_slam.dart';

/// Dawn Rail step 3 — the earned unlock beat, staged like an anime cut:
/// 1. silence stamp — ALARM OFF slams in over black (the quiet after the
///    siren is the first reward);
/// 2. burst — speed lines flash out from the stamp;
/// 3. payoff — MORNING EPISODE UNLOCKED rises in gold (the one gold moment
///    of the morning) before the title card slams.
class EpisodeUnlock extends StatefulWidget {
  const EpisodeUnlock({super.key});

  @override
  State<EpisodeUnlock> createState() => _EpisodeUnlockState();
}

class _EpisodeUnlockState extends State<EpisodeUnlock>
    with SingleTickerProviderStateMixin {
  Timer? _hold;
  bool _payoffHapticFired = false;
  late final AnimationController _seq = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2150),
  );

  // Stage windows on the single sequence controller.
  static const _stamp = Interval(0.0, 0.30, curve: Curves.easeOutBack);
  static const _burst = Interval(0.24, 0.52, curve: Curves.easeOut);
  static const _payoff = Interval(0.40, 0.72, curve: Curves.easeOutCubic);
  static const _footer = Interval(0.72, 1.0, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _seq
      ..addListener(_onTick)
      ..forward();
    _hold = Timer(const Duration(milliseconds: 2350), _advance);
  }

  void _onTick() {
    // Second impact exactly when the gold payoff enters.
    if (!_payoffHapticFired && _seq.value >= 0.40) {
      _payoffHapticFired = true;
      HapticFeedback.mediumImpact();
    }
  }

  void _advance() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(hardCut(const SmashCutFlash(child: TitleCardSlam())));
  }

  @override
  void dispose() {
    _hold?.cancel();
    _seq.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedBuilder(
          animation: _seq,
          builder: (context, _) {
            final stamp = _stamp.transform(_seq.value);
            final burst = _burst.transform(_seq.value);
            final payoff = _payoff.transform(_seq.value);
            final footer = _footer.transform(_seq.value);
            return Stack(
              fit: StackFit.expand,
              children: [
                // The room stays near-black: the silence is the scene.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.42),
                      radius: 1.15,
                      colors: [Color(0xFF14202A), Colors.black],
                    ),
                  ),
                ),
                const CustomPaint(painter: ScreentonePainter(opacity: 0.045)),
                // Stage 2 — burst flashes out then settles to a faint hold.
                Opacity(
                  opacity: burst == 0
                      ? 0
                      : (0.12 + 0.5 * (1 - burst)) * burst.clamp(0.0, 1.0),
                  child: const CustomPaint(
                    painter: SpeedLinesPainter(opacity: 1),
                  ),
                ),
                // Stage 1 — the ALARM OFF stamp slams down to size.
                Align(
                  alignment: const Alignment(0, -0.34),
                  child: Opacity(
                    opacity: stamp.clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: -6 * math.pi / 180,
                      child: Transform.scale(
                        scale: 1.7 - 0.7 * stamp,
                        child: Container(
                          width: 252,
                          height: 252,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.55),
                            border: Border.all(
                              color: InkSignal.verifyGreen,
                              width: 5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: InkSignal.verifyGreen.withValues(
                                  alpha: 0.34,
                                ),
                                blurRadius: 48,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ALARM',
                                style: InkSignal.mono(
                                  13,
                                  color: InkSignal.paper.withValues(
                                    alpha: 0.62,
                                  ),
                                ),
                              ),
                              const SkewedDisplay(
                                'OFF',
                                size: 92,
                                color: InkSignal.verifyGreen,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'QUEST CLEARED · ${state.quest.toUpperCase()}',
                                style: InkSignal.mono(
                                  10,
                                  color: InkSignal.paper.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Stage 3 — the gold payoff rises from the lower third.
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.paddingOf(context).bottom + 64,
                  child: Transform.translate(
                    offset: Offset(0, 36 * (1 - payoff)),
                    child: Opacity(
                      opacity: payoff.clamp(0.0, 1.0),
                      child: Column(
                        children: [
                          Text(
                            'EP ${state.nextEpisode}',
                            style: InkSignal.mono(
                              12,
                              color: InkSignal.paper.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const SkewedDisplay('MORNING EPISODE', size: 36),
                          Transform(
                            transform: Matrix4.skewX(-6 * math.pi / 180),
                            alignment: Alignment.center,
                            child: Text(
                              'UNLOCKED',
                              textAlign: TextAlign.center,
                              style:
                                  InkSignal.display(
                                    56,
                                    color: InkSignal.gold,
                                  ).copyWith(
                                    shadows: [
                                      Shadow(
                                        color: InkSignal.gold.withValues(
                                          alpha: 0.45 * payoff,
                                        ),
                                        blurRadius: 30,
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Opacity(
                            opacity: footer.clamp(0.0, 1.0),
                            child: Text(
                              'TITLE CARD INCOMING',
                              style: InkSignal.mono(
                                12,
                                color: InkSignal.paper.withValues(alpha: 0.54),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
